importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCVGaDaJ-pXIhIbYVoHrEHZq5z03gBMLLE",
  authDomain: "khuzdar-services.firebaseapp.com",
  databaseURL: "https://khuzdar-services-default-rtdb.europe-west1.firebasedatabase.app",
  projectId: "khuzdar-services",
  storageBucket: "khuzdar-services.firebasestorage.app",
  messagingSenderId: "462613436846",
  appId: "1:462613436846:web:45454d2c6da2affc3ad03f",
  measurementId: "G-DTCTXTSZXS"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Received background message ", payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/icons/Icon-192.png"
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
