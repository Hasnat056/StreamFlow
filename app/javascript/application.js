// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import * as ActiveStorage from "@rails/activestorage"
import { setupConfirmDialog } from "./lib/confirm_dialog"
ActiveStorage.start()

// The dialog element is re-rendered on every full Turbo Drive navigation
// (it isn't data-turbo-permanent), so re-bind on every turbo:load rather
// than once — otherwise the confirm handler ends up pointing at a detached
// element after the first page visit.
document.addEventListener("turbo:load", setupConfirmDialog)