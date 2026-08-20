# Unified Order Endpoint Implementation Plan

The user has provided specific backend endpoints for both Cash on Delivery (COD) and Razorpay payments. This plan will synchronize the app's checkout logic with these endpoints, ensuring correct data formatting and order flow.

## Proposed Changes

### [Services]

#### [MODIFY] [api_service.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/services/api_service.dart)
- **Implement `placeCodOrder`**:
    - Endpoint: `/api/payment/cod`
    - Body: `{"amount": amount, "deliveryAddressId": addressId}`
- **Implement `createRazorpayOrder`**:
    - Endpoint: `/api/payment/razorpay/create`
    - Body: `{"amount": amount, "deliveryAddressId": addressId}`
    - Returns: Razorpay Order ID and other metadata.

#### [MODIFY] [razorpay_service.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/services/razorpay_service.dart)
- Update `openCheckout` to accept an `orderId` parameter, which is required for secure transactions.

### [Screens]

#### [MODIFY] [checkout_screen.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/screens/checkout_screen.dart)
- **Updated `_placeOrder` Logic**:
    - **If COD**: Call `ApiService.placeCodOrder` and show success on completion.
    - **If Online**:
        1. Call `ApiService.createRazorpayOrder` to get a backend-generated Order ID.
        2. Trigger Razorpay UI with this Order ID.
        3. Upon payment success, sync with Shiprocket.

## Verification Plan

### Manual Verification
- **Test COD**: Place an order using COD mode and verify the `/api/payment/cod` hit.
- **Test Online**:
    - Trigger "Place Order".
    - Check if `/api/payment/razorpay/create` is called.
    - Verify that the Razorpay window opens with the correct amount.
    - Verify Shiprocket sync after payment.
