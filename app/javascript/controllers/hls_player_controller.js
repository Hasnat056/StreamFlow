import { Controller } from "@hotwired/stimulus"
import Hls from "hls.js"

const PROGRESS_SAVE_INTERVAL_SEC = 5

export default class extends Controller {
    static values = {
        src: String,
        viewUrl: String,
        threshold: { type: Number, default: 0.2 },
        watchProgressUrl: String,
        resumeAt: { type: Number, default: 0 }
    }

    connect() {
        const video = this.element
        if (video.canPlayType("application/vnd.apple.mpegurl")) {
            video.src = this.srcValue
        } else if (Hls.isSupported()) {
            this.hls = new Hls()
            this.hls.loadSource(this.srcValue)
            this.hls.attachMedia(video)
        }

        this.viewRecorded = false
        this.lastSavedTime = 0

        this.onTimeUpdate = () => {
            this.checkViewThreshold()
            this.maybeSaveProgress()
        }
        video.addEventListener("timeupdate", this.onTimeUpdate)

        this.onLoadedMetadata = () => {
            if (this.resumeAtValue > 0 && this.resumeAtValue < video.duration) {
                video.currentTime = this.resumeAtValue
            }
        }
        video.addEventListener("loadedmetadata", this.onLoadedMetadata)

        this.onPause = () => this.saveProgress()
        video.addEventListener("pause", this.onPause)

        this.onBeforeUnload = () => this.saveProgress(true)
        window.addEventListener("beforeunload", this.onBeforeUnload)
    }

    disconnect() {
        if (this.hls) {
            this.hls.destroy()
            this.hls = null
        }
        const video = this.element
        video.removeEventListener("timeupdate", this.onTimeUpdate)
        video.removeEventListener("loadedmetadata", this.onLoadedMetadata)
        video.removeEventListener("pause", this.onPause)
        window.removeEventListener("beforeunload", this.onBeforeUnload)
        this.saveProgress(true)
    }

    checkViewThreshold() {
        const video = this.element
        if (this.viewRecorded || !video.duration || !isFinite(video.duration)) return
        if (video.currentTime / video.duration < this.thresholdValue) return

        this.viewRecorded = true
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
        fetch(this.viewUrlValue, {
            method: "POST",
            headers: { "X-CSRF-Token": csrfToken },
            credentials: "same-origin"
        })
    }

    maybeSaveProgress() {
        const video = this.element
        if (!video.duration || !isFinite(video.duration)) return
        if (video.currentTime - this.lastSavedTime < PROGRESS_SAVE_INTERVAL_SEC) return

        this.saveProgress()
    }

    saveProgress(useBeacon = false) {
        const video = this.element
        if (!this.hasWatchProgressUrlValue || !video.duration || !isFinite(video.duration)) return

        this.lastSavedTime = video.currentTime

        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
        const body = new URLSearchParams({
            authenticity_token: csrfToken,
            last_timestamp_sec: Math.floor(video.currentTime),
            duration_sec: Math.floor(video.duration)
        }).toString()

        if (useBeacon && navigator.sendBeacon) {
            navigator.sendBeacon(this.watchProgressUrlValue, new Blob([body], { type: "application/x-www-form-urlencoded" }))
            return
        }

        fetch(this.watchProgressUrlValue, {
            method: "POST",
            headers: { "Content-Type": "application/x-www-form-urlencoded", "X-CSRF-Token": csrfToken },
            body,
            credentials: "same-origin",
            keepalive: true
        })
    }
}
