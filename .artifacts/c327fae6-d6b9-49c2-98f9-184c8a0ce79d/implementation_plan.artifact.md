# Implementation Plan - Back Navigation & Logo Enhancement

Improve the app's back navigation by handling the system back button on the Home Screen and ensuring consistent back buttons across all sub-screens. Also, set the "Kosmico Logo" as the primary brand element across the app.

## User Review Required

> [!NOTE]
> I will implement a "Back to Home Tab" behavior: if the user is on the Products or Profile tab and presses the system back button, the app will switch to the Home tab instead of exiting.

## Proposed Changes

### Home Screen Navigation

#### [MODIFY] [home_screen.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/home_screen.dart)
- Wrap the `Scaffold` in a `PopScope`.
- Implement logic in `onPopInvokedWithResult`:
    - If `_selectedIndex != 0`, set `_selectedIndex = 0` and prevent the pop by setting `canPop` to `false`.
    - If `_selectedIndex == 0`, allow the pop (exit app).

### Branding Updates

#### [MODIFY] [profile_screen.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/screens/profile_screen.dart)
- In `AboutKosmicoScreen`, replace the `Icons.spa_rounded` placeholder with the `assets/images/kosmicologo.png` asset.

### Sub-Screen Consistency

#### [MODIFY] [checkout_screen.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/screens/checkout_screen.dart)
- Explicitly add a `leading` back button to the `AppBar` for consistency with other screens (`Icons.arrow_back_ios_new`).

## Verification Plan

### Manual Verification
- **Home Screen**:
    - Go to the "Profile" tab. Press the back button. Verify it switches to the "Home" tab.
    - Go to the "Products" tab. Press the back button. Verify it switches to the "Home" tab.
- **Branding**:
    - Open the "About Kosmico" screen from the Profile. Verify the logo is shown instead of the leaf icon.
- **Sub-Screens**:
    - Navigate to `CheckoutScreen`. Verify it has the same back button style as `CartScreen` and `MyOrdersScreen`.
