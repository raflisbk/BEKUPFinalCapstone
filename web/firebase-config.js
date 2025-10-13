// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";
import { getMessaging } from "firebase/messaging";

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyBugpuZTTIJKRBLejc1Tb9o7BMdIuEaKmM",
  authDomain: "relink-app-a96f3.firebaseapp.com",
  projectId: "relink-app-a96f3",
  storageBucket: "relink-app-a96f3.firebasestorage.app",
  messagingSenderId: "809876881035",
  appId: "1:809876881035:web:f2c5f579fca42bc8955e8e",
  measurementId: "G-VYJGMVWC92"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase services
const analytics = getAnalytics(app);
const auth = getAuth(app);
const db = getFirestore(app);
const storage = getStorage(app);

// Initialize messaging (optional - requires service worker)
let messaging = null;
try {
  messaging = getMessaging(app);
} catch (err) {
  console.warn("Firebase Messaging not supported in this browser:", err);
}

// Export Firebase services for use in your app
export { app, analytics, auth, db, storage, messaging };
