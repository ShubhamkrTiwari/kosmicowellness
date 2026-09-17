# Fix RenderFlex Overflow in CareNetworkModule

The goal is to resolve the layout overflow (8.8 pixels on the right) in the `CareNetworkModule` screen. This usually happens when `Row` children exceed the available width. We will apply `Expanded` and `TextOverflow.ellipsis` to potential culprits.

## Proposed Changes

### Care Screen Layout
#### [MODIFY] [care_network_module.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/screens/care/care_network_module.dart)
- Wrap "Emergency Contacts" title in `Expanded` in `_buildHeader`.
- Improve layout constraints in `_showEmergencySentDialog` for address and GPS rows.
- Use `Expanded` for demographic items in `_showReportPreview`.
- Add `TextOverflow.ellipsis` and `maxLines: 1` to various small labels in metric badges and table rows to ensure they don't push the layout outwards on narrow screens.

## Verification Plan

### Manual Verification
- Run the app and navigate to the Care/Emergency Contacts screen.
- Verify that the "Emergency Contacts" header doesn't overflow.
- Trigger the Hypo-Alert and verify the dialog layout doesn't overflow.
- View the Clinical Report and verify the metrics and table don't overflow on various screen sizes (or simulate a narrow screen).
