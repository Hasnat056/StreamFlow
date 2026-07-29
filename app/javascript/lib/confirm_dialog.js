import { Turbo } from "@hotwired/turbo-rails"

// Replaces Turbo's native window.confirm() with the app's own styled dialog
// for any element carrying data-turbo-confirm.
export function setupConfirmDialog() {
  const dialog = document.getElementById("confirm-dialog")
  if (!dialog) return

  const messageEl = dialog.querySelector("[data-confirm-dialog-message]")
  const confirmBtn = dialog.querySelector("[data-confirm-dialog-confirm]")
  const cancelBtn = dialog.querySelector("[data-confirm-dialog-cancel]")

  Turbo.config.forms.confirm = (message) => {
    messageEl.textContent = message
    dialog.showModal()

    return new Promise((resolve) => {
      const settle = (result) => {
        confirmBtn.removeEventListener("click", onConfirm)
        cancelBtn.removeEventListener("click", onCancel)
        dialog.removeEventListener("cancel", onCancel)
        dialog.close()
        resolve(result)
      }
      const onConfirm = () => settle(true)
      const onCancel = () => settle(false)

      confirmBtn.addEventListener("click", onConfirm)
      cancelBtn.addEventListener("click", onCancel)
      dialog.addEventListener("cancel", onCancel)
    })
  }
}
