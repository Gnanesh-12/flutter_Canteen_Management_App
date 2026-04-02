# 🍱 Amrita Canteen Management System

A comprehensive dual-application solution designed to streamline canteen operations, order management, and user experience at Amrita Vishwa Vidyapeetham. This project consists of a high-performance **User App** for seamless ordering and a powerful **Admin App** for real-time canteen oversight.

---

## 📱 User Application (`amritacanteenapp`)

The user-facing mobile application focuses on providing a fast, intuitive, and secure ordering experience.

### Key Features:
- **🔐 Flexible Authentication**: Sign up and log in using either your **Email Address** or **University Roll Number**.
- **🏬 Multi-Canteen Support**: Choose from various campus canteens (IT, Main, MBA).
- **🛒 Smart Cart & Ordering**: Browse categorized menus, manage your cart, and place orders with a single tap.
- **🕒 Order History**: Track past purchases and view detailed receipts directly from your profile.
- **👤 User Profile**: Manage personal details and university credentials effortlessly.

---

## 🛠️ Admin Application (`canteen_admin_app`)

A real-time dashboard for canteen administrators to manage menus, track live orders, and control store availability.

### Key Features:
- **📊 Live Order Tracking**: Monitor incoming orders in real-time with token-based tracking.
- **✅ Status Management**: Update order status from 'Preparing' to 'Ready' instantly.
- **📜 Menu Management**: Add, edit, or delete menu items and categories with live synchronization.
- **🏪 Store Control**: Toggle the canteen's operation status (Open/Closed) to manage traffic.
- **🛡️ Multi-Admin Security**: Secure role-based access for different canteen departments.

---

## 🚀 Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Cross-platform UI)
- **Language**: [Dart](https://dart.dev/)
- **Backend**: [Firebase Authentication](https://firebase.google.com/products/auth) & [Cloud Firestore](https://firebase.google.com/products/firestore) (NoSQL)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Utilities**: `intl` (Formatting), `cupertino_icons` (Design)

---

## ⚙️ Setup & Installation

### Prerequisites:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and configured.
- [Firebase Project](https://console.firebase.google.com/) set up with Android/iOS/Web apps.

### Installation Steps:
1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/your-username/flutter_Canteen_Management_App.git
    cd flutter_Canteen_Management_App
    ```

2.  **User App Setup**:
    ```bash
    cd amritacanteenapp
    flutter pub get
    # Add your firebase_options.dart in lib/
    flutter run
    ```

3.  **Admin App Setup**:
    ```bash
    cd ../canteen_admin_app
    flutter pub get
    # Add your firebase_options.dart in lib/
    flutter run
    ```

---

> [!IMPORTANT]
> To initialize these administrators, use the **"ONE-TIME ADMIN INITIALIZATION"** button on the Admin App's login screen during your first run.

---

## 📁 Project Structure

```text
flutter_Canteen_Management_App/
├── amritacanteenapp/        # User-facing Flutter project
│   ├── lib/pages/           # Login, Register, Cart, Profile screens
│   └── lib/models/          # Order and Item classes
└── canteen_admin_app/       # Admin-facing Flutter project
    ├── lib/pages/           # Dashboard, Menu, Orders screens
    └── lib/services/        # Firebase and Auth handling
```

Developed with ❤️ for the Amrita Community.
