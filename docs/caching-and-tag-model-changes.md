# Caching Strategy & Tag/Category Model — Design Decisions

Design-session output. Nothing here is implemented yet — this documents what was
settled before writing migrations/code.

## Summary of changes

1. Split `video#show`'s cached video data into `attrs` (static) and `counts` (volatile) caches, keyed per video.
2. Merge per-user, per-video lookups (liked-by-me, watch-progress) into a single live query — never cached.
3. Cache comments (with authors and per-comment like counts) per video; keep "liked by me" live.
4. Redefine "related videos" from same-channel to cross-channel, tag-based relatedness — computed live, not cached, hydrated from the per-video caches.
5. Cache the home page's infinite-scroll feed as a bounded, ordered index of video ids, hydrated the same way.
6. Replace free-text tags with a curated `Category` → `Tag` taxonomy, many-to-many, with separate pools/limits for channels vs. videos.

---

## 1. Video attrs/counts cache split

**What:** Two Redis cache-aside entries per video instead of one:
- `video:#{id}:attrs` — `title`, `description`, `thumbnail_url`, `duration_sec`, `playlist_master_file_url`, `status`. No TTL (or a long backstop, e.g. 24h). Invalidated explicitly, only on the writes that actually touch it: `VideoTranscodingService` completing, playlist version activation, a future edit action.
- `video:#{id}:counts` — `views_count`, `likes_count`. Short TTL (60–120s). No explicit invalidation.

**Why:** These two groups of columns have wildly different change frequency — attrs are effectively write-once, counts change on every view/like. Bundling them into one cache entry forces a bad tradeoff: either bust the whole thing on every view/like (defeating the cache) or let static data tolerate staleness it doesn't need. Splitting removes the conflict, and lets counts use pure TTL-based eventual consistency (acceptable — a vanity metric a few seconds stale is invisible) while attrs stay always-correct via targeted invalidation.

## 2. Per-user data merged into one live query

**What:** "Is this video liked by the current user" and "current user's watch-progress timestamp" — previously two separate queries — become one query, since both take the same `(video_id, user_id)` pair:
```sql
SELECT EXISTS(SELECT 1 FROM video_likes WHERE video_id = ? AND user_id = ?) AS liked,
       (SELECT last_timestamp_sec FROM watch_progresses WHERE video_id = ? AND user_id = ?) AS wp_timestamp
```
Not cached — inherently per-user, no sharing benefit.

**Why:** Free query-count reduction with no caching complexity, since the two lookups were already going to run on every request regardless of cache state.

## 3. Comments cache

**What:** `video:#{id}:comments` — comments + comment author data + per-comment `likes_count`, merged into one query and cached. TTL 120s as a backstop, but **explicit invalidation is the primary mechanism**: an `after_commit` callback on `Comment` and `CommentLike` deletes the cache key for the relevant `video_id`. "Liked by me" per comment stays a separate, live, per-user query — one batched `CommentLike.where(user_id:, comment_id: comment_ids).pluck(:comment_id)`, not N existence checks.

**Why:** Comment activity is bursty and a stale comment list is more jarring than a stale like-count, so this leans on invalidation rather than TTL, unlike the counts cache above. Using an `after_commit` model callback (rather than scattering cache-delete calls across controllers) matches the existing app convention of a single hook covering all write paths (see `Video#broadcast_in_process_update`'s `after_all_transitions` hook).

## 4. Related videos: cross-channel, tag-based

**What:** Redefined from "other videos in the same channel" to genuine content relatedness via tag overlap (`videos.tags && ARRAY[...]`, requires a `GIN` index on `videos.tags`). The id lookup is a **live** query, not cached — a GIN-indexed overlap query is cheap enough that caching the id list isn't worth the added invalidation surface (which would otherwise be global/fuzzy, since any video's tags changing could affect any other video's related set). Results are hydrated by reading `video:#{id}:attrs`/`:counts` for the matched ids via a single Redis `MGET`. Rendered in a lazy-loaded Turbo Frame, off the critical path of the main page render.

Description-based matching (full-text/trigram similarity) was considered and explicitly deferred — it needs `pg_search`/`tsvector` infrastructure not yet in the Gemfile, and tags are a stronger, more intentional relatedness signal than free-text prose anyway. Tags-only for v1.

**Why:** Same-channel "related" videos isn't really relatedness, just "more from this channel." Tag overlap is a real signal, and computing it live avoids inventing a whole new cache-invalidation problem for a query that's already cheap once indexed.

## 5. Home page feed cache

**What:** `home:recent_video_ids` — a Redis **sorted set** (score = `created_at`, member = video id), bounded to the most recent N (e.g. 200–500) ready videos. Pagination reads ordered ranges (`ZREVRANGE` for the first page, `ZREVRANGEBYSCORE created_at < cursor` for "load more"). Scrolling past the bound falls through to a live DB query with the same cursor — no caching there, since that traffic is rare/cold. New videos are appended (`ZADD`) when they transition to `ready` (same AASM hook as elsewhere), and the set is trimmed (`ZREMRANGEBYRANK`) to stay bounded. Hydration reuses the same per-video `attrs`/`counts` `MGET` pattern as related videos. `watch_progress_by_video` stays a live query scoped to just the current page's ids.

**Why:** The home feed has no fixed endpoint to cache — infinite scroll means an unbounded, per-request-different content set. Caching a bounded, ordered index (instead of "the page") mirrors the related-videos pattern and concentrates caching benefit where the traffic actually is: the first few screens, not the long scroll tail nobody reaches.

## 6. Tag/Category taxonomy

**What:** Replaces the current free-text `tags` (`text[]`) columns on both `channels` and `videos` with a curated, many-to-many taxonomy:

- `Category` — `id`, `name` (unique), `is_visible`. A hidden `General` row (`is_visible: false`) is never shown as a selectable category, but its tags are always included in every pool.
- `Tag` — `id`, `name` (unique, globally).
- `CategoryTag` — join table, `category_id` + `tag_id`, unique composite index. Many-to-many: a tag (e.g. "Comedy") can belong to multiple categories.
- `ChannelTag` — join table, `channel_id` + `tag_id`, unique composite index. `has_many :through`, matching the app's existing join-model convention (`Subscription`, `VideoLike`, `CommentLike`) rather than a bare `has_and_belongs_to_many`.
- `VideoTag` — join table, `video_id` + `tag_id`, unique composite index, same pattern.
- `Channel` gets a `category_id` FK (replacing the current string `category` validated against `Channel::CATEGORIES`). Its tag picker pool = `Tag.joins(:categories).where(categories: { id: [channel.category_id, general.id] }).distinct`. Max 5 tags.
- `Video` has no category of its own. Its tag picker draws from the **full** tag catalog (all categories), prefilled with the channel's tags as a convenience default, but not restricted to them. Max 8 tags.

**Why:**
- Free-text tags would defeat the relatedness feature outright — "gaming" vs. "Gaming" vs. "video games" wouldn't overlap-match even though they mean the same thing.
- Tag↔Category started as one-to-many but was changed to many-to-many: a strictly one-category-per-tag model forces either duplicate `Tag` rows with the same name under different categories (which breaks both the global-uniqueness rule and overlap matching between the duplicates, since they'd be different ids), or arbitrarily siloing a genuinely cross-category tag like "Comedy" into one category's pool only.
- Video tags are deliberately **not** restricted to the channel's category pool, even though channel tags are. A channel's category is an identity choice ("this channel is Science"), but a single video's content can legitimately diverge from it (a funny video on a Science channel) — and restricting its tag options to the parent category would make it untaggable as "funny," breaking the exact cross-channel relatedness matching this whole taxonomy exists to support.
- Join models (not HABTM) match every other many-to-many relation already in the app.

**Open / unresolved:**
- Whether a **minimum** tag count should be enforced (e.g. at least 1) for channels/videos, or whether zero is acceptable — raised, not yet answered.
- Existing channels already have real free-text tags (via `tags_input`); these won't map automatically onto the new curated `Tag` rows and will need a manual remap or reset at migration time — not a modeling concern, but a migration-time task to remember.
