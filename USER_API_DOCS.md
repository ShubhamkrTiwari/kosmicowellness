# 🌐 Kosmico Wellness - User Side Full API Documentation

This document provides a comprehensive reference for all client/user-side API endpoints implemented in the Kosmico Wellness application (`ApiService`).

---

## Base Configuration

- **Base URL:** `https://api.kosmicowellness.com/api`
- **Global Headers:**
  - `Content-Type`: `application/json`
  - `Accept`: `application/json`
  - `x-platform`: `ios` / `android` / `web`
  - `x-app-version`: `1.0.3`
  - `User-Agent`: `KosmicoApp/1.0`
  - `Authorization`: `Bearer <JWT_TOKEN>` *(Required for protected routes)*

---

## 1. Authentication Module (`/api/auth`)

### 1. Register User
- **Endpoint:** `POST /api/auth/register`
- **Auth Required:** No
- **Request Body:**
  ```json
  {
    "name": "User Name",
    "email": "user@example.com"
  }
  ```

### 2. Login User
- **Endpoint:** `POST /api/auth/login`
- **Auth Required:** No
- **Request Body:**
  ```json
  {
    "email": "user@example.com"
  }
  ```

### 3. Verify Signup OTP
- **Endpoint:** `POST /api/auth/signup-verify`
- **Auth Required:** No
- **Request Body:**
  ```json
  {
    "email": "user@example.com",
    "otp": "123456"
  }
  ```

### 4. Verify Login OTP
- **Endpoint:** `POST /api/auth/login-verify`
- **Auth Required:** No
- **Request Body:**
  ```json
  {
    "email": "user@example.com",
    "otp": "123456"
  }
  ```

### 5. Resend OTP
- **Endpoint:** `POST /api/auth/resend-otp`
- **Auth Required:** No
- **Request Body:**
  ```json
  {
    "email": "user@example.com"
  }
  ```

### 6. Update Profile (with Image)
- **Endpoint:** `PUT /api/auth/profile`
- **Auth Required:** Yes (`Bearer Token`)
- **Content-Type:** `multipart/form-data`
- **Form Fields:**
  - `name`: String
  - `phoneNumber`: String
  - `profilePicture`: File (Binary image)

### 7. Remove Profile Picture
- **Endpoint:** `DELETE /api/auth/remove-profile-picture`
- **Auth Required:** Yes (`Bearer Token`)

---

## 2. Address Management Module (`/api/address`)

### 1. Save Address
- **Endpoint:** `POST /api/address`
- **Auth Required:** Yes
- **Request Body:**
  ```json
  {
    "addressLabel": "Home",
    "fullName": "John Doe",
    "streetAddress": "123 Main St",
    "city": "Delhi",
    "pincode": "110001",
    "phoneNumber": "9876543210",
    "isDefault": true
  }
  ```

### 2. Get Saved Addresses
- **Endpoint:** `GET /api/address`
- **Auth Required:** Yes

### 3. Update Address
- **Endpoint:** `PUT /api/address/{addressId}`
- **Auth Required:** Yes
- **Request Body:** Same as Save Address fields.

### 4. Set Default Address
- **Endpoint:** `PUT /api/address/set-default/{addressId}`
- **Auth Required:** Yes

### 5. Delete Address
- **Endpoint:** `DELETE /api/address/{addressId}`
- **Auth Required:** Yes

---

## 3. Products & Categories Module (`/api/products`, `/api/categories`)

### 1. Get User Products List
- **Endpoint:** `GET /api/products/user/list`
- **Query Parameters:**
  - `page` (default: 1)
  - `limit` (default: 12)
  - `category` (optional)
  - `search` (optional)
  - `sortBy` (optional)
  - `minPrice`, `maxPrice`, `minRating` (optional filters)

### 2. Get Categories List
- **Endpoint:** `GET /api/categories/user/list`
- **Auth Required:** No

### 3. Submit Product Review
- **Endpoint:** `POST /api/products/{productId}/reviews`
- **Auth Required:** Yes
- **Request Body:**
  ```json
  {
    "rating": 4.5,
    "comment": "Great product!"
  }
  ```

---

## 4. Wishlist Module (`/api/wishlist`)

### 1. Get Wishlist
- **Endpoint:** `GET /api/wishlist`
- **Auth Required:** Yes

### 2. Add to Wishlist
- **Endpoint:** `POST /api/wishlist/add`
- **Auth Required:** Yes
- **Request Body:**
  ```json
  {
    "productId": "string"
  }
  ```

### 3. Remove from Wishlist
- **Endpoint:** `POST /api/wishlist/remove`
- **Auth Required:** Yes
- **Request Body:**
  ```json
  {
    "productId": "string"
  }
  ```

---

## 5. Coupons & Discounts (`/api/coupons`)

### 1. Get Available Coupons
- **Endpoint:** `GET /api/coupons`
- **Auth Required:** Yes

### 2. Apply Coupon
- **Endpoint:** `POST /api/coupons/apply`
- **Auth Required:** Yes
- **Request Body:**
  ```json
  {
    "code": "KOSMICO10",
    "orderAmount": 500.0
  }
  ```

---

## 6. Payment & Orders Module (`/api/payment`, `/api/orders`, `/api/order`)

### 1. Saved Payment Methods
- **GET /api/payment/saved-methods** (Get saved payment methods)
- **POST /api/payment/save-method** (Save payment method)
- **PUT /api/payment/save-method/{methodId}** (Update saved method)
- **DELETE /api/payment/save-method/{methodId}** (Delete saved method)

### 2. Place COD Order
- **Endpoint:** `POST /api/payment/cod`
- **Auth Required:** Yes
- **Request Body:**
  ```json
  {
    "amount": 499.0,
    "deliveryAddressId": "address_id",
    "items": [{"productId": "...", "quantity": 1, "price": 499.0}],
    "couponCode": "...",
    "discountAmount": 0.0,
    "deliveryFee": 50.0,
    "gstCharge": 0.0
  }
  ```

### 3. COD Upfront Payment (Partial COD via Razorpay)
- **Create:** `POST /api/payment/cod-upfront/create`
- **Verify:** `POST /api/payment/cod-upfront/verify`

### 4. Razorpay Orders
- **Create Order:** `POST /api/payment/razorpay/create`
- **Cancel Pending Order:** `POST /api/payment/razorpay/cancel-pending`
- **Verify Payment:** `POST /api/payment/verify`
  ```json
  {
    "razorpay_payment_id": "pay_...",
    "razorpay_order_id": "order_...",
    "razorpay_signature": "..."
  }
  ```

### 5. User Orders & Tracking
- **Get My Orders:** `GET /api/payment/myorders?page=1&limit=10`
- **Track Order:** `GET /api/order/track/{orderId}`
- **Cancel Order:** `POST /api/order/cancel/{orderId}`
- **Return Order:** `POST /api/order/return/{orderId}` (Body: `{"reason": "..."}`)

---

## 7. Refunds & Replacements (`/api/refund`, `/api/return`)

- **Initiate Refund:** `POST /api/refund/initiate` (Body: `{"orderId": "...", "reason": "..."}`)
- **Get My Refunds:** `GET /api/refund/my-refunds`
- **Initiate Replacement:** `POST /api/return/initiate` (Body: `{"orderId": "...", "reason": "..."}`)
- **Get My Returns:** `GET /api/return/my-returns`

---

## 8. Shipping & Delivery Estimation (`/api/shiprocket`)

- **Estimate Delivery:** `POST /api/shiprocket/estimate-delivery`
  - **Request Body:**
    ```json
    {
      "deliveryPincode": "110001",
      "weight": 0.5,
      "paymentMethod": "COD"
    }
    ```

---

## 9. GlucoRhythm Module (`/api/gluco`)

- **Dashboard:** `GET /api/gluco/dashboard`
- **Log Glucose Reading:** `POST /api/gluco/reading`
  ```json
  {
    "glucoseLevel": 110.5,
    "timeOfDay": "Morning",
    "readingTime": "2023-10-25T10:00:00.000Z",
    "readingType": "Fasting",
    "notes": "Feeling good"
  }
  ```
- **Log Meal:** `POST /api/gluco/meal`
  ```json
  {
    "mealType": "Breakfast",
    "carbs": 45.0,
    "logTime": "...",
    "status": "Logged"
  }
  ```

---

## 10. Social / Community Posts Module (`/api/posts`)

- **Create Post:** `POST /api/posts` (Multipart, fields: `content`, `privacyLevel`, `tags`, `location`, file: `media`)
- **Get Feed:** `GET /api/posts/feed?page=1&limit=10`
- **Get User Posts:** `GET /api/posts/user/{userId}`
- **Like Post:** `POST /api/posts/{postId}/like`
- **Get Comments:** `GET /api/posts/{postId}/comments`
- **Add Comment:** `POST /api/posts/{postId}/comments` (Body: `{"text": "..."}`)
- **Edit Post:** `PUT /api/posts/{postId}` or `PATCH /api/posts/{postId}`
- **Delete Post:** `DELETE /api/posts/{postId}`
- **Friends / Requests:**
  - Send Request: `POST /api/posts/friend-request/send/{friendId}`
  - Get Friends: `GET /api/posts/friends`
  - Get Requests: `GET /api/posts/friend-requests`
  - Accept Request: `POST /api/posts/friend-request/accept/{requestId}`
  - Reject Request: `POST /api/posts/friend-request/reject/{requestId}`

---

## 11. Notifications Module (`/api/notifications`)

- **Get Notifications:** `GET /api/notifications?page=1&limit=20`
- **Mark as Read:** `PUT /api/notifications/{notificationId}/read`
- **Delete Notification:** `DELETE /api/notifications/{notificationId}`
- **Clear All:** `DELETE /api/notifications`

---

## 12. Emergency & System Status (`/api/emergency`, `/api/system`)

- **Emergency Message Generator:** `POST /api/emergency/generate-message` (Fallback to GET)
  - **Body:** `{"latitude": 28.6139, "longitude": 77.2090}`
- **System Status / Maintenance:** `GET /api/system/status`
- **App Update Check:** `GET /api/updates/check?version=1.0.3`
