import { Controller } from "@hotwired/stimulus"
import * as uploadManager from "../lib/upload_manager"

// Shows a live row in the channel owner's "in process" list while a video is
// still being uploaded to R2 - before any Video row (and thus the
// server-rendered #in_process_videos list) exists at all. Rendered as a
// sibling of #in_process_videos rather than inside it, so the Turbo Stream
// replace that partial receives on every AASM transition never wipes this
// placeholder out mid-render.
export default class extends Controller {
  static targets = ["title", "chip"]
  static values = { channelId: Number }

  connect() {
    this.unsubscribe = uploadManager.subscribe((state) => this.render(state))
  }

  disconnect() {
    if (this.unsubscribe) this.unsubscribe()
  }

  render(state) {
    const active = state.status === "uploading" && state.kind === "video" && state.channelId === this.channelIdValue
    this.element.classList.toggle("hidden", !active)
    if (!active) return

    this.titleTarget.textContent = state.title
    this.chipTarget.textContent = `Uploading ${state.progress}%`
  }
}
