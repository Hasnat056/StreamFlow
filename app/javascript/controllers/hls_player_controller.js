import { Controller } from "@hotwired/stimulus"
import Hls from "hls.js"

export default class extends Controller {
    static values = { src: String, viewUrl: String, threshold: { type: Number, default: 0.2 } }

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
        this.onTimeUpdate = () => this.checkViewThreshold()
        video.addEventListener("timeupdate", this.onTimeUpdate)
    }

    disconnect() {
        if (this.hls) {
            this.hls.destroy()
            this.hls = null
        }
        this.element.removeEventListener("timeupdate", this.onTimeUpdate)
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
}
