import { Controller } from "@hotwired/stimulus"

// Flips data-theme on <html> and persists the choice in a cookie so the
// inline snippet in <head> can restore it before first paint on the next
// full page load (see app/views/layouts/application.html.erb).
export default class extends Controller {
  toggle() {
    const current = document.documentElement.dataset.theme ||
      (matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")
    const next = current === "dark" ? "light" : "dark"

    document.documentElement.dataset.theme = next
    document.cookie = `theme=${next}; path=/; max-age=31536000; samesite=lax`
  }
}
