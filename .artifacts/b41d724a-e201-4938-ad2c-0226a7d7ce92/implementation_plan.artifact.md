# Implementation Plan - Final Release Build Fixes (Stripping & 16KB Alignment)

This plan addresses the persistent "failed to strip debug symbols" warning and ensures the app meets the latest Google Play requirement for 16KB/4KB page alignment (Android 15+).

## Research Findings
- **Build Status**: The release build **is actually succeeding** (verified `app-release.aab` exists), but the message "failed to strip" is appearing as a notification from the new Flutter/AGP 9.0 toolchain.
- **16KB Alignment**: To support 16KB pages on Android 15+, native libraries must be uncompressed and aligned.

## Proposed Changes

### 1. Build Optimization & Alignment

#### [MODIFY] [gradle.properties](file:///C:/Users/pc/StudioProjects/kosmicowellness/android/gradle.properties)
- Add flags to ensure native libraries are handled correctly for the App Bundle:
  - `android.bundle.enableUncompressedNativeLibs=false` (Ensures compatibility with `extractNativeLibs=false`).

#### [MODIFY] [build.gradle.kts](file:///C:/Users/pc/StudioProjects/kosmicowellness/android/app/build.gradle.kts)
- Refine the `packaging` block to use a more stable syntax for AGP 9.0.
- Switch from `doNotStrip` back to letting the system try to strip, but ignoring errors for specific third-party libs if they persist. Or keep `doNotStrip` but with `excludes` to reduce size.
- **Correction**: We will use `jniLibs.keepDebugSymbol.add("**/*.so")` with a more explicit exclusion list if the bundle remains too large.

### 2. Manifest Refinement

#### [MODIFY] [AndroidManifest.xml](file:///C:/Users/pc/StudioProjects/kosmicowellness/android/app/src/main/AndroidManifest.xml)
- Double-check `android:extractNativeLibs="false"`. (Already added, but critical for 16KB).

## Verification Plan

### Manual Verification
1.  Run `flutter build appbundle`.
2.  Verify the final message. Even if the "strip" warning appears, check if the "Built build\app\outputs\bundle\release\app-release.aab" success message shows at the bottom.
3.  **Size Check**: Monitor the `.aab` size. 140MB is large; I will try to optimize assets or libs if possible.
4.  **Alignment Check**: If possible, I will provide a command to verify 16KB alignment using `zipalign`.
