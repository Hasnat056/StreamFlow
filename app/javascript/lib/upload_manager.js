// Holds in-flight background-task state independent of any single page/DOM
// element, so it survives Turbo navigating between pages while a video
// upload or channel update is running.
import { DirectUpload } from "@rails/activestorage"

let state = {
  status: "idle", // idle | uploading | success | error
  label: "",
  progress: 0,
  resultUrl: null,
  successMessage: "Uploaded successfully",
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
  setState({ status: "idle", label: "", progress: 0, resultUrl: null, errorMessage: null })
}

function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content
}

function directUpload(file, directUploadUrl, onProgress) {
  return new Promise((resolve, reject) => {
    const upload = new DirectUpload(file, directUploadUrl, {
      directUploadWillStoreFileWithXHR(xhr) {
        xhr.upload.addEventListener("progress", (event) => onProgress(event.loaded, event.total))
      }
    })

    upload.create((error, blob) => {
      if (error) reject(error)
      else resolve(blob)
    })
  })
}

function finish(response, data) {
  if (response.ok && data.status === "ok") {
    setState({ status: "success", progress: 100, resultUrl: data.url })
  } else {
    setState({ status: "error", errorMessage: (data.errors || ["Something went wrong"]).join(", ") })
  }
}

export function startVideoUpload({ file, title, directUploadUrl, createUrl }) {
  if (state.status === "uploading") return false

  setState({
    status: "uploading",
    label: file.name,
    progress: 0,
    resultUrl: null,
    successMessage: "Uploaded successfully",
    errorMessage: null
  })

  directUpload(file, directUploadUrl, (loaded, total) => {
    setState({ progress: Math.round((loaded / total) * 100) })
  })
    .then((blob) =>
      fetch(createUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": csrfToken() },
        credentials: "same-origin",
        body: JSON.stringify({ video: { title, source_file: blob.signed_id } })
      })
    )
    .then(async (response) => finish(response, await response.json()))
    .catch((error) => {
      setState({ status: "error", errorMessage: error.message || "Network error while saving the video" })
    })

  return true
}

export function startChannelUpdate({ label, fields, avatarFile, bannerFile, directUploadUrl, updateUrl }) {
  if (state.status === "uploading") return false

  setState({
    status: "uploading",
    label,
    progress: 0,
    resultUrl: null,
    successMessage: "Channel updated",
    errorMessage: null
  })

  const totalBytes = [ avatarFile, bannerFile ].filter(Boolean).reduce((sum, file) => sum + file.size, 0)
  const loadedByFile = new Map()

  function reportProgress() {
    const loaded = [ ...loadedByFile.values() ].reduce((sum, n) => sum + n, 0)
    setState({ progress: totalBytes ? Math.round((loaded / totalBytes) * 100) : 100 })
  }

  const uploadField = (file) =>
    file
      ? directUpload(file, directUploadUrl, (loaded) => {
          loadedByFile.set(file, loaded)
          reportProgress()
        }).then((blob) => blob.signed_id)
      : Promise.resolve(null)

  Promise.all([ uploadField(avatarFile), uploadField(bannerFile) ])
    .then(([ avatarSignedId, bannerSignedId ]) => {
      const body = { channel: { ...fields } }
      if (avatarSignedId) body.channel.avatar = avatarSignedId
      if (bannerSignedId) body.channel.banner = bannerSignedId

      return fetch(updateUrl, {
        method: "PATCH",
        headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": csrfToken() },
        credentials: "same-origin",
        body: JSON.stringify(body)
      })
    })
    .then(async (response) => finish(response, await response.json()))
    .catch((error) => {
      setState({ status: "error", errorMessage: error.message || "Network error while updating the channel" })
    })

  return true
}
