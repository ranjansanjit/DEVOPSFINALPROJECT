// api.js - Frontend API handler

// --------------------------
// API URL Configuration
// --------------------------
const HOST_API = "http://localhost:5000"; // For browser development
const DOCKER_API = "http://backend:5000"; // For Docker container
const API_URL = HOST_API; // change to DOCKER_API when running inside Docker

// --------------------------
// Send Birthday Wish
// --------------------------
export async function sendWish(name) {
  if (!name || !name.trim()) throw new Error("Name is required");

  try {
    const res = await fetch(`${API_URL}/api/wish`, {
      method: "POST", // Use POST as backend expects
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: name.trim() }),
    });

    if (!res.ok) throw new Error("Backend error");

    const data = await res.json();
    return data; // { message: "Happy Birthday, NAME! 🎉" }
  } catch (err) {
    console.error("Error fetching backend:", err);
    throw err;
  }
}
