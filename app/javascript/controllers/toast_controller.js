import { Controller } from "@hotwired/stimulus"

// Auto-dismisses a toast notification a few seconds after it appears.
export default class extends Controller {
  static values = { duration: { type: Number, default: 3000 } }

  connect() {
    if (this.durationValue > 0) {
      this.timeout = setTimeout(() => this.dismiss(), this.durationValue)
    }
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.classList.add("toast--leaving")
    this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
  }
}