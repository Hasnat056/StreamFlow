// Holds in-flight upload state independent of any single page/DOM element,
// so it survives Turbo navigating between pages while an upload is running.
import { DirectUpload } from "@rails/activestorage"

let state = {
  status: "idle", // idle | uploading | success | error
  filename: "",
  progress: 0,
  videoUrl: null,
  errorMessage: null
}

const subscribers = new Set()

function setState(patch) {
  state = { ...state, ...patch }
  subscribers.forEach((callback) => callback(state))
}

export function subscribe(callback) {
  subscribers.add(callback)
  callback(state)
  return () => subscribers.delete(callback)
}

export function getState() {
  return state
}

export function isUploading() {
  return state.status === "uploading"
}

export function dismiss() {
  setState({ status: "idle", filename: "", progress: 0, videoUrl: null, errorMessage: null })
}

export function startUpload({ file, title, directUploadUrl, createUrl }) {
  if (state.status === "uploading") return false

  setState({ status: "uploading", filename: file.name, progress: 0, videoUrl: null, errorMessage: null })

  const upload = new DirectUpload(file, directUploadUrl, {
    directUploadWillStoreFileWithXHR(xhr) {
      xhr.upload.addEventListener("progress", (event) => {
        setState({ progress: Math.round((event.loaded / event.total) * 100) })
      })
    }
  })

  upload.create((error, blob) => {
    if (error) {
      setState({ status: "error", errorMessage: error.message || "Upload failed" })
      return
    }

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(createUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": csrfToken
      },
      credentials: "same-origin",
      body: JSON.stringify({ video: { title, source_file: blob.signed_id } })
    })
      .then(async (response) => {
        const data = await response.json()
        if (response.ok && data.status === "ok") {
          setState({ status: "success", progress: 100, videoUrl: data.url })
        } else {
          setState({ status: "error", errorMessage: (data.errors || ["Something went wrong"]).join(", ") })
        }
      })
      .catch(() => {
        setState({ status: "error", errorMessage: "Network error while saving the video" })
      })
  })

  return true
}
