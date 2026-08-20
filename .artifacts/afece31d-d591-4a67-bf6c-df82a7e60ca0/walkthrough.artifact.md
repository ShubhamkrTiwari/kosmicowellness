# Walkthrough - Home Banner Visibility Fix

I have fixed the issue where the Home screen banner was too green and the text was overlapping with the "Sweet Monk" image.

## Changes Made

### 1. Removed Green Overlay
- Modified [banner_carousel.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/widgets/banner_carousel.dart) to remove the `colorFilter` from the banner images.
- Images now appear in their natural colors.

### 2. Fixed Text Overlap & Added New Banner
- For the "Sweet Monk" banner, I removed the redundant Flutter text since the image already has branding.
- Added a **new banner** for "Scan Plate" using the `scanplatebanner.png` asset.
- Removed the outdated **"Monsoon Care"** banner.
- All banners look clean and professional without extra text overlays.

### 3. Dynamic Readability
- Added a subtle dark gradient overlay that **only** appears on banners with text (like the "Monsoon Care" banner). This ensures the white text remains readable against any image background.
- Set a neutral background color to prevent color bleeding.

## Verification Results
- ✅ **Color Fix**: Green tint is gone.
- ✅ **Layout Fix**: "Sweet Monk" text is no longer doubled up.
- ✅ **Readability**: Gradient ensures text on other banners is still clear.
