import { Controller } from "@hotwired/stimulus"
import Hls from "hls.js"



export default class extends Controller {
    static values = { src: String}

    connect() {
        const video = this.element
        if (video.canPlayType("application/vnd.apple.mpegurl")) {
            video.src = this.srcValue
        } else if (Hls.isSupported()){
            this.hls = new Hls()
            this.hls.loadSource(this.srcValue)
            this.hls.attachMedia(video)
        }
    }

    disconnect() {
        if (this.hls) {
            this.hls.destroy()
            this.hls = null
        }
    }
}