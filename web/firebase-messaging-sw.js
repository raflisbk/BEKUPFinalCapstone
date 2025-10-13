// Firebase Cloud Messaging Service Worker
// This service worker is required for Firebase Cloud Messaging to work on web

importScripts('https://www.gstatic.com/firebasejs/11.1.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.1.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker
firebase.initializeApp({
  apiKey: "AIzaSyBugpuZTTIJKRBLejc1Tb9o7BMdIuEaKmM",
  authDomain: "relink-app-a96f3.firebaseapp.com",
  projectId: "relink-app-a96f3",
  storageBucket: "relink-app-a96f3.firebasestorage.app",
  messagingSenderId: "809876881035",
  appId: "1:809876881035:web:f2c5f579fca42bc8955e8e",
  measurementId: "G-VYJGMVWC92"
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const notificationTitle = payload.notification.title || 'ReLink Notification';
  const notificationOptions = {
    body: payload.notification.body || 'You have a new notification',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.tag || 'default',
    requireInteraction: false,
    data: payload.data
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click received.');

  event.notification.close();

  // Handle the notification click action
  event.waitUntil(
    clients.openWindow(event.notification.data?.click_action || '/')
  );
});
