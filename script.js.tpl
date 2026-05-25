// 🔥 Only required change: use Terraform vars names exactly
const API_UPLOAD = "${api_url}/upload-url";
const API_RESULT = "${api_url}/result";

// ================= IMAGE PREVIEW =================
function previewImage() {
  const file = document.getElementById("imageFile").files[0]
  if (!file) return

  const reader = new FileReader()
  reader.onload = function () {
    document.getElementById("previewImage").src = reader.result
  }
  reader.readAsDataURL(file)
}

document.getElementById("imageFile").addEventListener("change", previewImage)


// ================= GET GPS LOCATION =================
function getLocation() {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject("Geolocation not supported")
      return
    }

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        resolve({
          lat: pos.coords.latitude,
          lon: pos.coords.longitude
        })
      },
      (err) => reject(err),
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0
      }
    )
  })
}


// ================= UPLOAD IMAGE =================
async function uploadImage() {

  const fileInput = document.getElementById("imageFile")
  const messageInput = document.getElementById("message")

  if (!fileInput.files.length) {
    alert("Please select image")
    return
  }

  const file = fileInput.files[0]
  const message = messageInput ? messageInput.value : "No message"

  document.getElementById("loading").style.display = "block"
  document.getElementById("resultCard").style.display = "none"

  try {

    // 🔥 GET LOCATION (fallback if denied)
    let location = { lat: 0, lon: 0 }

    try {
      location = await getLocation()
    } catch (e) {
      console.warn("Location denied, using default")
    }

    // 🔥 GET PRESIGNED URL
    const res = await fetch(
      `${API_UPLOAD}?lat=${location.lat}&lon=${location.lon}&msg=${encodeURIComponent(message)}`
    )

    const data = await res.json()

    if (!data.upload_url) {
      throw new Error("Upload URL not received")
    }

    const uploadUrl = data.upload_url
    const imageName = data.image

    // 🔥 UPLOAD TO S3
    const uploadRes = await fetch(uploadUrl, {
      method: "PUT",
      body: file
    })

    if (!uploadRes.ok) {
      throw new Error("S3 upload failed")
    }

    // 🔥 START POLLING
    getResult(imageName)

  } catch (error) {
    console.error(error)
    alert("Upload failed")
    document.getElementById("loading").style.display = "none"
  }
}


// ================= GET RESULT =================
async function getResult(imageName) {

  let attempts = 0
  const maxAttempts = 20

  const interval = setInterval(async () => {

    attempts++

    try {

      const res = await fetch(`${API_RESULT}?image=${encodeURIComponent(imageName)}`)
      const data = await res.json()

      let result = data

      // 🔥 HANDLE API GATEWAY BODY
      if (typeof data.body === "string") {
        result = JSON.parse(data.body)
      }

      console.log("FINAL RESULT:", result)

      // 🔥 WAIT UNTIL READY
      if (result.severity && result.severity !== "Processing") {

        clearInterval(interval)

        document.getElementById("loading").style.display = "none"
        document.getElementById("resultCard").style.display = "block"

        // ================= BASIC =================
        document.getElementById("imageId").innerText = result.ImageID || "-"
        document.getElementById("garbageCount").innerText = result.garbageCount || 0
        document.getElementById("severity").innerText = result.severity || "-"

        // ================= LOCATION =================
        document.getElementById("location").innerText =
          result.location
            ? `${result.location.lat}, ${result.location.lon}`
            : "-"

        // ================= ADDRESS =================
        document.getElementById("address").innerText = result.address || "-"

        // ================= MESSAGE =================
        document.getElementById("userMessage").innerText = result.message || "-"

        // ================= TIMESTAMP =================
        document.getElementById("timestamp").innerText = result.timestamp || "-"

        // ================= LABELS =================
        const labelsList = document.getElementById("labels")
        labelsList.innerHTML = ""

        if (result.labels && result.labels.length > 0) {
          result.labels.forEach(label => {
            const li = document.createElement("li")
            li.innerText = label

            li.style.background = "#6c63ff"
            li.style.color = "white"
            li.style.padding = "5px 10px"
            li.style.borderRadius = "20px"

            labelsList.appendChild(li)
          })
        }

      }

    } catch (error) {
      console.error("Polling error:", error)
    }

    // 🔥 TIMEOUT STOP
    if (attempts >= maxAttempts) {
      clearInterval(interval)
      document.getElementById("loading").style.display = "none"
      alert("Processing taking longer than expected")
    }

  }, 2000)
}