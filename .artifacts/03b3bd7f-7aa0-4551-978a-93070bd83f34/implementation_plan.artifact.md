# Stock-Based Quantity Limit Implementation Plan

This plan outlines the steps to restrict the quantity of items that can be added to the cart based on the available stock mentioned by the admin.

## User Review Required

> [!IMPORTANT]
> The app will now prevent users from selecting or adding a quantity that exceeds the `countInStock` (or equivalent field) provided by the backend.

## Proposed Changes

### [Product Details Screen](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/screens/product_details_screen.dart)

#### [MODIFY] [product_details_screen.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/screens/product_details_screen.dart)
- **Quantity Selector**: Update the `+` button logic in `_buildQuantitySelector` to disable it once the selected quantity reaches the available stock.
- **Add to Cart Logic**: Update `_buildBottomAction` to check if the sum of (existing cart quantity + newly selected quantity) exceeds the available stock.
- **User Feedback**: Show a descriptive SnackBar if the user tries to add more than what's in stock.

### [Cart Manager](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/managers/cart_manager.dart)

#### [MODIFY] [cart_manager.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/managers/cart_manager.dart)
- **Validation Method**: Add a new method `canAddMore(product, requestedQty)` that checks available stock against current cart items.
- **Enforcement**: Update `addItem` and `incrementItem` to respect stock limits (if stock data is present in the product object).

## Verification Plan

### Manual Verification
1.  **Select Product**: Open a product with a known stock count (e.g., 10).
2.  **Increment Quantity**: Try to increment the quantity to 11 in the details screen. The `+` button should become inactive or show a message.
3.  **Cart Addition**: Add 5 items to the cart, then go back and try to add another 6. The app should prevent this and notify that only 5 more are available.
4.  **Cart Screen**: Try to increment quantity directly in the cart screen beyond the stock limit.
5.  **Fallback**: Ensure products with no stock info (N/A) still allow adding a reasonable default (e.g., 10 or 99).
