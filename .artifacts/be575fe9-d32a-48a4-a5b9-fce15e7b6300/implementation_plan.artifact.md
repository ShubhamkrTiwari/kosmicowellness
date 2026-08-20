# Implementation Plan - Dynamic Return/Refund Button Visibility

I will enhance the `OrderDetailsScreen` to dynamically show the "Return / Refund" button when an order is delivered, and ensure the "Cancel Order" button is hidden in that state. I will also incorporate tracking data to update the order status in real-time.

## User Review Required

> [!IMPORTANT]
> The button visibility will now depend on both the initial order status passed to the screen and the live tracking status fetched from Shiprocket. If either indicates the order is "Delivered", the "Return / Refund" option will be presented.

## Proposed Changes

### Order Details Screen

#### [MODIFY] [order_details_screen.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/screens/order_details_screen.dart)
- Introduce `_currentStatus` state variable to track the order's status, initializing it from `widget.order['status']`.
- Update `_currentStatus` when tracking data is fetched if the live status is "Delivered".
- Refine button visibility logic to use `_currentStatus` with robust string comparison (`trim().toLowerCase()`).
- Ensure "Cancel Order" is hidden and "Return / Refund" is shown exactly when the status is "delivered".

## Verification Plan

### Manual Verification
- I will verify that the status comparison logic is robust against casing and whitespace.
- I will ensure that the "Cancel Order" and "Return / Refund" buttons are mutually exclusive based on the "delivered" status.
