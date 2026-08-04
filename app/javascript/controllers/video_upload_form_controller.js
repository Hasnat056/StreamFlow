import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import * as uploadManager from "../lib/upload_manager"

// Hands the file off to upload_manager and leaves the page immediately -
// the upload keeps running in the background regardless of where the user goes.
export default class extends Controller {
  static targets = ["title", "file", "warning", "tagCheckbox", "tagsWarning"]
  static values = {
    directUploadUrl: String,
    createUrl: String,
    redirectUrl: String,
    maxTags: Number,
    channelId: Number
  }

  toggleTag(event) {
    if (this.checkedTagIds().length > this.maxTagsValue) {
      event.target.checked = false
      this.showTagsWarning(`You can select up to ${this.maxTagsValue} tags.`)
    }
  }

  checkedTagIds() {
    return this.tagCheckboxTargets.filter((checkbox) => checkbox.checked).map((checkbox) => checkbox.value)
  }

  submit(event) {
    event.preventDefault()

    if (uploadManager.isUploading()) {
      this.showWarning("An upload is already in progress — wait for it to finish before starting another.")
      return
    }

    const file = this.fileTarget.files[0]
    const title = this.titleTarget.value.trim()

    if (!file || !title) {
      this.showWarning("Please choose a file and enter a title.")
      return
    }

    uploadManager.startVideoUpload({
      file,
      title,
      tagIds: this.checkedTagIds(),
      channelId: this.channelIdValue,
      directUploadUrl: this.directUploadUrlValue,
      createUrl: this.createUrlValue
    })

    Turbo.visit(this.redirectUrlValue)
  }

  showWarning(message) {
    this.warningTarget.textContent = message
    this.warningTarget.classList.remove("hidden")
  }

  showTagsWarning(message) {
    this.tagsWarningTarget.textContent = message
    this.tagsWarningTarget.classList.remove("hidden")
  }
}
