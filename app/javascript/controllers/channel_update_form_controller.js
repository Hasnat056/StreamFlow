import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import * as uploadManager from "../lib/upload_manager"

// Mirrors video-upload-form: hands avatar/banner off to upload_manager and
// leaves the page immediately - the create/update keeps running in the
// background regardless of where the user goes.
export default class extends Controller {
  static targets = [ "channelName", "category", "description", "tagsInput", "avatar", "banner", "warning" ]
  static values = {
    directUploadUrl: String,
    submitUrl: String,
    httpMethod: String,
    redirectUrl: String
  }

  submit(event) {
    event.preventDefault()

    if (uploadManager.isUploading()) {
      this.showWarning("An upload is already in progress — wait for it to finish before saving again.")
      return
    }

    const channelName = this.channelNameTarget.value.trim()
    if (!channelName) {
      this.showWarning("Channel name can't be blank.")
      return
    }

    const isUpdate = this.httpMethodValue === "PATCH"

    uploadManager.startChannelSave({
      label: isUpdate ? `Updating "${channelName}"…` : `Creating "${channelName}"…`,
      successMessage: isUpdate ? "Channel updated" : "Channel created",
      method: this.httpMethodValue,
      submitUrl: this.submitUrlValue,
      fields: {
        channel_name: channelName,
        category: this.categoryTarget.value,
        description: this.descriptionTarget.value,
        tags_input: this.tagsInputTarget.value
      },
      avatarFile: this.avatarTarget.files[0] || null,
      bannerFile: this.bannerTarget.files[0] || null,
      directUploadUrl: this.directUploadUrlValue
    })

    Turbo.visit(this.redirectUrlValue)
  }

  showWarning(message) {
    this.warningTarget.textContent = message
    this.warningTarget.classList.remove("hidden")
  }
}
