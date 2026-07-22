import { Controller } from "@hotwired/stimulus"
import * as uploadManager from "../lib/upload_manager"

// Attached to the permanent (data-turbo-permanent) widget in the layout -
// just renders whatever upload_manager's state currently is.
export default class extends Controller {
  static targets = ["status", "filename", "fill", "link"]

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
    this.element.classList.toggle("upload-widget--hidden", state.status === "idle")
    this.element.classList.toggle("upload-widget--success", state.status === "success")
    this.element.classList.toggle("upload-widget--error", state.status === "error")

    this.filenameTarget.textContent = state.filename
    this.fillTarget.style.width = `${state.progress}%`

    if (state.status === "uploading") {
      this.statusTarget.textContent = `Uploading… ${state.progress}%`
    } else if (state.status === "success") {
      this.statusTarget.textContent = "Uploaded successfully"
    } else if (state.status === "error") {
      this.statusTarget.textContent = state.errorMessage || "Upload failed"
    }

    if (state.status === "success" && state.videoUrl) {
      this.linkTarget.href = state.videoUrl
      this.linkTarget.classList.remove("upload-widget__link--hidden")
    } else {
      this.linkTarget.classList.add("upload-widget__link--hidden")
    }
  }
}
