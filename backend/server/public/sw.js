self.addEventListener("install", (e) => {
  console.log("[ServiceWorker] - Install");
  self.skipWaiting(); // Force activate immediately
});

self.addEventListener("activate", (e) => {
  console.log("[ServiceWorker] - Activated");
  self.clients.claim(); // Take control immediately
});

// In your Service Worker file (e.g., service-worker.js)
self.addEventListener("message", (event) => {
  console.log("Service Worker received message:", event.data);
  if (event.data && event.data.type === "session") {
    console.log("Session data:", event.data.payload);
    // Process the data received from the main page
  } else if (event.data && event.data.type === "magData") {
    console.log(`Magazine data ${event.data.payload}`);
  }
});
