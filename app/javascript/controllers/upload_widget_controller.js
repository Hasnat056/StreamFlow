import { Controller } from "@hotwired/stimulus"
import * as uploadManager from "../lib/upload_manager"

const RADIUS = 26
const CIRCUMFERENCE = 2 * Math.PI * RADIUS

// The ring's icon always reflects the current action: an upload arrow while
// in flight, a checkmark on success, an alert on failure.
const ICONS = {
  uploading: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 4v11M7 9l5-5 5 5M5 19h14"/></svg>',
  success: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M5 12l5 5L20 7"/></svg>',
  error: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 4l9 16H3z"/><path d="M12 10v4M12 17v.01"/></svg>'
}

// Attached to the permanent (data-turbo-permanent) widget in the layout -
// just renders whatever upload_manager's state currently is.
export default class extends Controller {
  static targets = ["status", "fill", "bar", "link", "progressCircle", "icon"]

  connect() {
    this.unsubscribe = uploadManager.subscribe((state) => this.render(state))
  }

  disconnect() {
    if (this.unsubscribe) this.unsubscribe()
  }

  dismiss() {
    uploadManager.dismiss()
  }

  render(state) {
    this.element.classList.toggle("upload-capsule--hidden", state.status === "idle")
    this.element.classList.toggle("upload-capsule--success", state.status === "success")
    this.element.classList.toggle("upload-capsule--error", state.status === "error")

    this.iconTarget.innerHTML = ICONS[state.status] || ICONS.uploading

    const ringPercent = state.status === "uploading" ? state.progress : 100
    this.progressCircleTarget.style.strokeDasharray = `${CIRCUMFERENCE}`
    this.progressCircleTarget.style.strokeDashoffset = `${CIRCUMFERENCE - (CIRCUMFERENCE * ringPercent) / 100}`

    this.fillTarget.style.width = `${state.progress}%`
    this.barTarget.classList.toggle("upload-capsule__bar--visible", state.status === "uploading")

    if (state.status === "uploading") {
      this.statusTarget.textContent = state.filename
    } else if (state.status === "success") {
      this.statusTarget.textContent = "Uploaded successfully"
    } else if (state.status === "error") {
      this.statusTarget.textContent = state.errorMessage || "Upload failed"
    }

    if (state.status === "success" && state.videoUrl) {
      this.linkTarget.href = state.videoUrl
      this.linkTarget.classList.remove("hidden")
    } else {
      this.linkTarget.classList.add("hidden")
    }
  }
}
