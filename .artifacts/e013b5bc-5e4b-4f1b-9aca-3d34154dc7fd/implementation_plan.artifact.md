# Implementation Plan - Clinical Report Sharing (PDF & Card)

This plan outlines the integration of PDF generation and sharing capabilities for the Glucorhythm Clinical Report, allowing users to share their glucose trends and lifestyle metrics professionally.

## User Review Required

> [!IMPORTANT]
> This feature requires adding two new dependencies: `pdf` and `printing`. These are standard and safe for Android/iOS/Web.
> The PDF will be generated entirely on-device for privacy.

## Proposed Changes

### Dependencies
#### [MODIFY] [pubspec.yaml](file:///C:/Users/pc/StudioProjects/kosmicowellness/pubspec.yaml)
- Add `pdf: ^3.10.8` for document structure.
- Add `printing: ^5.11.1` for easy sharing and printing of the PDF.

### Services
#### [NEW] [report_service.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/services/report_service.dart)
- Implement `ReportService` class.
- Method `generateClinicalPDF(CareManager manager)`:
    - Creates a multi-page PDF with the Kosmico logo.
    - Includes Glucose Summary (Avg, A1C, TIR).
    - Includes Lifestyle Metrics (Water, Stress).
    - Includes a table of Recent Meals.
- Method `shareReport(CareManager manager)`:
    - Triggers the system share sheet with the generated PDF.

### Care Network Module
#### [MODIFY] [care_network_module.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/screens/care/care_network_module.dart)
- Update `_showReportPreview` dialog:
    - Improve the visual "Card" design of the preview.
    - Add a **Share PDF** button.
    - Add a **Share as Text** button (Card fallback) using existing `share_plus`.

### Data Management
#### [MODIFY] [care_manager.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/managers/care_manager.dart)
- Small tweak to ensure `generateClinicalReport()` returns a more structured map if needed for the PDF service, or keep it as is if only text sharing is needed. (I will likely keep it for text sharing and use manager fields directly for PDF).

## Verification Plan

### Manual Verification
1. Go to **Care** -> **Care Network**.
2. Tap **View Clinical Report**.
3. Verify the new preview UI looks like a "Card".
4. Tap **Share PDF**:
    - Verify the system share sheet opens.
    - Select an app (e.g., WhatsApp/Files) and verify the PDF is generated correctly.
5. Tap **Share as Text**:
    - Verify the formatted report text is shared.
