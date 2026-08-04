import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import * as uploadManager from "../lib/upload_manager"

// Mirrors video-upload-form: hands avatar/banner off to upload_manager and
// leaves the page immediately - the create/update keeps running in the
// background regardless of where the user goes.
export default class extends Controller {
  static targets = [ "channelName", "category", "description", "avatar", "banner", "warning", "tagCheckbox", "tagsWarning" ]
  static values = {
    directUploadUrl: String,
    submitUrl: String,
    httpMethod: String,
    redirectUrl: String,
    generalCategoryId: Number,
    maxTags: Number
  }

  connect() {
    this.filterTags()
  }

  // Shows only the tag group belonging to the selected category (plus the
  // always-visible General group), and unchecks any tags that fall out of
  // pool so a leftover selection from a previous category can't sneak through.
  filterTags() {
    const selectedId = this.categoryTarget.value

    this.element.querySelectorAll(".tag-picker__group").forEach((group) => {
      const visible = group.dataset.categoryId === selectedId || group.dataset.categoryId === String(this.generalCategoryIdValue)
      group.classList.toggle("hidden", !visible)

      if (!visible) {
        group.querySelectorAll("input[type=checkbox]").forEach((checkbox) => { checkbox.checked = false })
      }
    })
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
        category_id: this.categoryTarget.value,
        description: this.descriptionTarget.value,
        tag_ids: this.checkedTagIds()
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

  showTagsWarning(message) {
    this.tagsWarningTarget.textContent = message
    this.tagsWarningTarget.classList.remove("hidden")
  }
}
