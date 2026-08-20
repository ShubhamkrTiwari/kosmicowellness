# Implementation Plan - Fix Home Banner Visibility

The Home screen banner is currently too green because of a heavy primary color overlay (`alpha: 0.7`), making the content hard to see. I will remove this tint and improve the layout to ensure the banner image is clear.

## Proposed Changes

### 1. Banner Carousel Styling
#### [MODIFY] [banner_carousel.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/widgets/banner_carousel.dart)
- Remove the `colorFilter` from the `DecorationImage` to stop tinting the images green.
- Remove the default `color: colorScheme.primary` from the `BoxDecoration` when an image is present to avoid color bleeding.
- Add a subtle dark gradient overlay only if necessary for text readability, or allow the image to speak for itself.
- For the "Sweet Monk" banner specifically, I will check if the Flutter text should be hidden or adjusted since the image already contains text.

## Verification Plan

### Manual Verification
1. Open the Home screen.
2. Verify that the `adbannersweetmonk.png` image is displayed with its original colors (not tinted green).
3. Ensure that the banner text and button are still readable against the image background.
