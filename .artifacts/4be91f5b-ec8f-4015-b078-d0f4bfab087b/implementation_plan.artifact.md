# Fix Build Failures: AGP 9.0 Compatibility and Environment Conflicts

The previous fix addressed the deprecated `android.bundle.enableUncompressedNativeLibs` property. However, the build is now failing due to:
1.  **Environment Variable Conflict**: Both `ANDROID_PREFS_ROOT` and `ANDROID_USER_HOME` are set, which AGP 9.0 prohibits.
2.  **DSL Error**: `keepDebugSymbol` is unresolved in `build.gradle.kts`.

## User Action Required

> [!IMPORTANT]
> **Fix Environment Variable Conflict**: Please remove the `ANDROID_PREFS_ROOT` environment variable from your system and keep only `ANDROID_USER_HOME`. AGP 9.0 is strict about having only one of these set.

## Proposed Changes

### Android Configuration

#### [MODIFY] [app/build.gradle.kts](file:///C:/Users/pc/StudioProjects/kosmicowellness/android/app/build.gradle.kts)
- Change `keepDebugSymbol` to `keepDebugSymbols` (plural) as required by the AGP 9.0 DSL.

## Verification Plan

### Automated Tests
- Run `flutter build appbundle` (with the environment variable workaround if not yet fixed by the user) to verify the build completes.

### Manual Verification
- Verify the build success.
