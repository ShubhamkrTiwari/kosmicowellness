# Return and Refund Lifecycle Walkthrough

I have successfully added the **Return Order** and **Refund** lifecycle to the Kosmico app. This allows users to request returns for delivered orders and automatically triggers the reverse pickup process in Shiprocket.

## Changes Made

### Services

#### [UPDATED] [api_service.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/services/api_service.dart)
- **New Method: `returnOrder`**: Notifies the backend of a return request using `/api/order/return/<order_id>`. It sends the user-selected reason for the return.

#### [UPDATED] [shiprocket_service.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/services/shiprocket_service.dart)
- **New Method: `createReturnOrder`**: Creates a **Reverse Pickup** order in Shiprocket. This automatically initiates the process of a courier collecting the product from the customer's doorstep and returning it to your warehouse.

### Screens

#### [UPDATED] [order_details_screen.dart](file:///C:/Users/pc/StudioProjects/kosmicowellness/lib/screens/order_details_screen.dart)
- **Smart Button Visibility**:
    - The "Cancel Order" button is hidden if the order is already delivered or cancelled.
    - A new **"Return Order"** button appears **only** after an order is marked as "Delivered".
- **Return Workflow**:
    - Tapping "Return Order" opens a dialog where users can select a reason (e.g., Wrong item, Defective).
    - Upon selection, the app first notifies your backend and then creates the return shipment in Shiprocket.
- **Reverse Pickup Mapping**: Automatically maps the customer's address as the "Pickup Location" and your warehouse as the "Shipping Destination" for Shiprocket.

## How to Test

1.  **Deliver an Order**: In your database/Shiprocket panel, mark a test order as "Delivered".
2.  **View Details**: Open that order in the app.
3.  **Initiate Return**: Tap the orange **"Return Order"** button.
4.  **Select Reason**: Choose a reason from the list.
5.  **Verify Sync**:
    - Check the debug console for `Shiprocket: Return Order synced!`.
    - Check your [Shiprocket Dashboard](https://app.shiprocket.in/) -> "Returns" to see the reverse pickup request.

> [!TIP]
> The return flow is fully automated. As soon as the customer requests a return, the courier pickup is scheduled, saving you manual work!
