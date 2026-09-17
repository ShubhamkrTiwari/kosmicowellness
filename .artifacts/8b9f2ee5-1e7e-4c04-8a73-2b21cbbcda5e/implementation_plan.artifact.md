# Add Quantity Selector (Add/Minus) to Product Cards

This plan adds a plus/minus quantity selector to the product cards in both the Home screen and the Product List screen. This allows users to easily manage their cart contents directly from the product lists.

## User Review Required

> [!NOTE]
> The design of the quantity selector will be compact to fit within the existing product card layouts.
> When the quantity is 0, the standard "Add to Cart" button/icon will be shown.
> When the quantity is greater than 0, a "-" button, the current quantity, and a "+" button will be displayed.

## Proposed Changes

### [managers]

#### [MODIFY] [cart_manager.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/managers/cart_manager.dart)
- Added `incrementItemByName(String name)` and `decrementItemByName(String name)` for easier access from UI components. (Already done)

### [screens]

#### [MODIFY] [home_screen.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/home_screen.dart)
- Update `_buildAddToCartButton` to return a quantity selector (Row with `-`, `quantity`, `+`) when the item is already in the cart.

#### [MODIFY] [product_list_screen.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/screens/product_list_screen.dart)
- Update the "Add to Cart" button in `_buildProductListItem` to show the quantity selector when the item is already in the cart.

## Verification Plan

### Manual Verification
- Go to the Home screen.
- Tap "Add to Cart" on a product.
- Verify that the button changes to a quantity selector with `[-] 1 [+]`.
- Tap `+` and verify quantity increases.
- Tap `-` and verify quantity decreases.
- Tap `-` when quantity is 1 and verify it changes back to the "Add to Cart" icon.
- Repeat the same steps on the Product List screen.
