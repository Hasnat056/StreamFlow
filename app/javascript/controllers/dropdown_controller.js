import { Controller } from "@hotwired/stimulus"

// Generic click-to-open, click-outside/escape-to-close dropdown menu.
export default class extends Controller {
  static targets = ["menu"]

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")
  }

  hide() {
    this.menuTarget.classList.add("hidden")
  }
}
