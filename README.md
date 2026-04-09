# 🚀 Khuzdar Service Marketplace — Admin Dashboard

[![Flutter](https://img.shields.io/badge/Flutter-3.41+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Hosting-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A premium, high-performance **Flutter Web** administrative dashboard designed for the **Khuzdar Service Marketplace** ecosystem. This dashboard provides real-time oversight of users, service providers, active chats, and system analytics.

---

## ✨ Key Features

- **📊 Dynamic Dashboard**: Real-time analytics, growth charts, and status snapshots using `FL Chart`.
- **👥 User Management**: Monitor and manage customer accounts, including blocking/unblocking capabilities.
- **🛠️ Provider Verification**: Review and approve service providers with a detailed verification workflow.
- **💬 Chat Monitoring**: Real-time oversight of active service conversations and agreements.
- **📢 Broadcast System**: Send mass push notifications to all marketplace users via Firebase Cloud Messaging.
- **📑 Activity Reports**: Generate and view detailed reports on marketplace transactions and user activities.
- **🔐 Secure RBAC**: Role-Based Access Control enforcing strict admin-only entry.

---

## 🛠️ Tech Stack

- **Frontend**: Flutter Web (Stable Channel)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router)
- **UI Components**: `DataTable2`, `Flutter Animate`, `FL Chart`
- **Backend Services**: 
  - **Firebase Auth** (Admin Authentication)
  - **Cloud Firestore** (Real-time Database)
  - **Cloud Messaging** (Push Notifications)
  - **Firebase Hosting** (Web Deployment)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (v3.41 or higher recommended)
- Firebase CLI (`npm install -g firebase-tools`)
- A Firebase Project with Firestore and Auth enabled

### Installation

1. **Clone & Navigate**:
   ```bash
   git clone <your-repo-url>
   cd khuzdar_admin_panel
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**:
   Ensure you have configured your project using the FlutterFire CLI:
   ```bash
   flutterfire configure --project=khuzdar-services
   ```

4. **Run Locally**:
   ```bash
   flutter run -d chrome
   ```

---

## 🔐 Creating your first Admin

Since the Admin Panel does not allow public signups, you must manually promote your first account:

1. Create a user via **Firebase Console -> Authentication**.
2. Copy the **UID** of the new user.
3. In **Firestore**, create a document in the `users` collection with that UID as the Document ID.
4. Add these fields:
   - `role`: "admin"
   - `isBlocked`: false
   - `name`: "Your Admin Name"
   - `email`: "your-email@example.com"

---

## 🌐 Deployment

To build and deploy the production-ready dashboard to Firebase Hosting:

1. **Build the release**:
   ```bash
   flutter build web --release
   ```

2. **Initialize & Deploy**:
   ```bash
   firebase deploy --only hosting
   ```

---

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 👨‍💻 Developed By

Part of the **Khuzdar Service Marketplace** project.
