import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import * as uploadManager from "../lib/upload_manager"

// Mirrors video-upload-form: hands avatar/banner off to upload_manager and
// leaves the page immediately - the update keeps running in the background
// regardless of where the user goes.
export default class extends Controller {
  static targets = [ "channelName", "category", "description", "tagsInput", "avatar", "banner", "warning" ]
  static values = {
    directUploadUrl: String,
    updateUrl: String,
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

    uploadManager.startChannelUpdate({
      label: `Updating "${channelName}"…`,
      fields: {
        channel_name: channelName,
        category: this.categoryTarget.value,
        description: this.descriptionTarget.value,
        tags_input: this.tagsInputTarget.value
      },
      avatarFile: this.avatarTarget.files[0] || null,
      bannerFile: this.bannerTarget.files[0] || null,
      directUploadUrl: this.directUploadUrlValue,
      updateUrl: this.updateUrlValue
    })

    Turbo.visit(this.redirectUrlValue)
  }

  showWarning(message) {
    this.warningTarget.textContent = message
    this.warningTarget.classList.remove("hidden")
  }
}
