# Kosmico Wellness (`kosmico`)

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Material 3](https://img.shields.io/badge/Material%233-%23757575.svg?style=for-the-badge&logo=material-design&logoColor=white)](https://m3.material.io)

**Kosmico Wellness** is a comprehensive, feature-rich health, wellness, and e-commerce mobile application built with Flutter. It seamlessly combines a robust wellness storefront with advanced personal health tracking, AI-powered health consulting, smart device synchronization via Bluetooth LE, and community care networks.

---

## 🌟 Core Features

### 🛍️ E-Commerce & Storefront
- **Product Catalog & Details**: Browse curated wellness products with filters, search, image zoom, and ratings.
- **Cart & Wishlist**: Manage items, apply coupons, and save favorites.
- **Seamless Checkout**: Multi-step checkout with saved shipping addresses, geolocation map picker, and secure payments via **Razorpay**.
- **Order Management**: Track orders, view purchase history, manage returns, and generate/download official **PDF Invoices** using `pdf` and `printing`.

### 🩺 Care & Health Tracking Dashboard
- **Daily Health Overview (`Today Module`)**: Track daily wellness goals, water intake, steps, and progress.
- **Health Logging & Trends**: Log workouts, nutrition, sleep, and vital signs, with detailed graphical trend analysis.
- **Camera PPG & Vital Estimation**: Non-invasive camera-based pulse/blood pressure estimation (`camera_ppg_bp_screen.dart`).
- **Medication Reminders**: Timely alerts and tracking for daily medications and supplements.

### 🥗 AI Meal Scanner & Recipes
- **Smart Meal Scanning**: Scan food items using **Google ML Kit** image labeling and **Google Generative AI (Gemini)** to get instant nutritional insights and calorie breakdowns.
- **Healthy Recipes**: Browse, search, and view detailed recipe guides tailored to wellness goals.

### 🤖 AI Health Consultant
- **Conversational Assistant**: Powered by `google_generative_ai` (Gemini API) to answer health inquiries, provide wellness tips, and guide users through their health journey.

### 📶 Bluetooth LE Device Integration
- **Smart Device Syncing**: Scan, connect, and sync data from Bluetooth Low Energy (BLE) health and fitness devices using `flutter_blue_plus`.

### 👥 Care Network & Community
- **Community Feed**: Share wellness updates, posts, and interact with other health enthusiasts.
- **Care Network**: Build circles with friends and family to monitor shared health goals and support networks.

### ⚙️ App Settings & Utilities
- **Multi-Language Support**: Full localization management (`LanguageManager`).
- **Dynamic Theming**: Seamless toggling between Light and Dark modes (`ThemeManager`).
- **Push Notifications**: Local and remote notification management.
- **Admin Panel**: Dedicated administrative screens for backend data management.

---

## 📱 Tech Stack & Packages

- **Framework**: [Flutter](https://flutter.dev) (Dart SDK `>=3.0.0 <4.0.0`)
- **State Management**: `provider`, `ListenableBuilder`
- **AI & ML**: 
  - `google_generative_ai` (Gemini)
  - `google_mlkit_image_labeling`
- **Payments**: `razorpay_flutter`
- **Maps & Location**: `flutter_map`, `latlong2`, `geolocator`, `geocoding`
- **Hardware / BLE**: `flutter_blue_plus`, `camera`, `image_picker`
- **Storage**: `shared_preferences`
- **PDF & Printing**: `pdf`, `printing`
- **Network**: `http`, `http_parser`, `url_launcher`, `share_plus`

---

## 📂 Project Directory Structure

```text
lib/
├── admin/                  # Admin panel screens, models, & providers
├── models/                 # Core data models (Posts, Filters, Friend Requests)
├── managers/               # State managers (Cart, User, Theme, Notification, Payment, Care, Language, Bluetooth, Post, Wishlist)
├── screens/                # UI Screens & Modules
│   ├── care/               # Health care modules (Today, Trends, Meal Scanner, BLE Sync, Community, Camera PPG)
│   ├── ai_consultant_screen.dart
│   ├── auth_screen.dart
│   ├── cart_screen.dart
│   ├── checkout_screen.dart
│   ├── coupons_screen.dart
│   ├── home_screen.dart
│   ├── order_details_screen.dart
│   ├── profile_screen.dart
│   └── ...
├── services/               # API, Gemini, Location, Report, Shiprocket services
├── utils/                  # App keys & utility helpers
└── widgets/                # Reusable UI components (Carousels, Dialogs, Filter Sheets)
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0) installed on your machine.
- Android Studio / VS Code with Flutter and Dart plugins.
- A physical device or emulator for testing camera and Bluetooth features.

### Installation & Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/kosmicowellness.git
   cd kosmicowellness
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Environment / Keys**:
   - Ensure API keys for Razorpay, Gemini, and Shiprocket are configured in your service files or environment variables if required.

4. **Run the App**:
   ```bash
   flutter run
   ```

---

## 📄 License

This project is proprietary and confidential. All rights reserved.
