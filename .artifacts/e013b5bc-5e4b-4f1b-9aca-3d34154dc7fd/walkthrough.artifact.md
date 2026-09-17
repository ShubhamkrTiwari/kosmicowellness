# Walkthrough - Multi-Language Support (English/Hindi)

I have implemented a comprehensive language switching system that allows users to toggle between English and Hindi across the entire app.

## Changes Made

### 1. Central Language Manager
- Created [language_manager.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/managers/language_manager.dart) to handle all translation logic.
- Implemented a "Single Source of Truth" for all app strings in both languages.
- Used `SharedPreferences` to ensure your language choice is remembered even after you close the app.

### 2. Global State Integration
- Updated [main.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/main.dart) to listen to language changes.
- When you switch languages, the entire app UI rebuilds instantly without needing a restart.

### 3. Profile Screen Language Toggle
- Added a new **Language** menu item in the Profile screen with a beautiful EN/हिं toggle.
- Localized all settings, headers, and menu labels in the Profile section.

### 4. Home Screen Localization
- Updated the **Bottom Navigation Bar** to show "होम", "उत्पाद", etc., when Hindi is selected.
- Localized bestsellers and category headers on the Home tab.

## How to Verify

1. Go to the **Profile** tab.
2. Find the **Language** option under "Support & Preferences".
3. Toggle the switch to the right (Hindi).
4. **Instant Change:** Notice how "My Orders" becomes "मेरे ऑर्डर" and "Dark Mode" becomes "डार्क मोड".
5. Navigate back to **Home** and see the bottom labels and headers update to Hindi.
6. Switch back to **English** anytime using the same toggle.

> [!TIP]
> This system is built to be scalable. If you want to add more languages or translate more screens, you only need to update the dictionary in `LanguageManager`.
