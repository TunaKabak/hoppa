# Story 16 - Merchant Lifecycle & Order Cancellation Plan

This plan details the technical steps to fulfill the requirements of Story 16. It ensures proper order state management, cancellation flows for both consumer and merchant, real-time dashboard statistics, and graceful error handling.

## User Review Required

> [!WARNING]
> This plan modifies the Prisma schema and updates the database. The `npx prisma db push` command will be executed.
> Please confirm if you want to apply these database migrations directly.

## Open Questions

> [!IMPORTANT]
> 1. Should the `weeklyTrend` graph in the Merchant Dashboard use a specific library like `fl_chart` (which is already installed), or a custom UI widget? (I will assume `fl_chart` as suggested).
> 2. Should we implement the Consumer App's "Cancel Order" button directly inside the order list/detail view, similar to the Merchant App?

## Proposed Changes

---

### Database Schema Updates

#### [MODIFY] [schema.prisma](file:///c:/Users/tunah/Sources/Hoppa/hoppa/backend/prisma/schema.prisma)
Add cancellation tracking fields to the `Order` model:
- `cancelReason String?`
- `cancelledAt DateTime?`
- `cancelledBy String?`

---

### Backend API

#### [MODIFY] [ShopController.ts](file:///c:/Users/tunah/Sources/Hoppa/hoppa/backend/src/controllers/ShopController.ts)
- Add `getDashboardStats` method to calculate:
  - Today's successful order count.
  - Total historical revenue (`paymentStatus === 'SUCCESS'`).
  - Cancellation rate (total cancelled / total orders).
  - Last 7 days order count trend for charting.

#### [MODIFY] [merchantRoutes.ts](file:///c:/Users/tunah/Sources/Hoppa/hoppa/backend/src/routes/merchantRoutes.ts)
- Expose `GET /dashboard/stats` mapping to `shopController.getDashboardStats`.
- Expose `POST /orders/:id/cancel` mapping to `orderController.cancelOrder`.

#### [MODIFY] [consumerRoutes.ts](file:///c:/Users/tunah/Sources/Hoppa/hoppa/backend/src/routes/consumerRoutes.ts)
- Expose `POST /orders/:id/cancel` mapping to `orderController.cancelOrder`.

#### [MODIFY] [OrderController.ts](file:///c:/Users/tunah/Sources/Hoppa/hoppa/backend/src/controllers/OrderController.ts)
- **Bugfix**: In `updateOrderStatus`, if the status is changing to `DELIVERED` and `paymentMethod` is not `ONLINE_PAYMENT`, auto-set `paymentStatus` to `SUCCESS`.
- Add `cancelOrder` method:
  - If requested by consumer: Allowed only when status is `PENDING`. No reason required. Sets `cancelledBy` to `CONSUMER`.
  - If requested by merchant: Allowed when `PREPARING` or `ON_THE_WAY`. Reason is required. Sets `cancelledBy` to `MERCHANT`.

---

### Flutter Core Packages

#### [MODIFY] [exceptions.dart](file:///c:/Users/tunah/Sources/Hoppa/hoppa/packages/core_network/lib/src/exceptions.dart)
- Replace technical exception messages with user-friendly Turkish messages (e.g., "İnternet bağlantınızı kontrol ederek lütfen tekrar deneyiniz.").

---

### Merchant App UI

#### [MODIFY] [merchant_order_repository.dart](file:///c:/Users/tunah/Sources/Hoppa/hoppa/lib/apps/merchant/repositories/merchant_order_repository.dart)
- Add API clients for `/api/merchant/dashboard/stats` and `/api/merchant/orders/:id/cancel`.

#### [MODIFY] [merchant_dashboard_page.dart](file:///c:/Users/tunah/Sources/Hoppa/hoppa/lib/apps/merchant/merchant_dashboard_page.dart)
- Refactor KPI cards to consume data from the new `getDashboardStats` endpoint.
- Integrate `fl_chart` to display the weekly order trend below the KPI cards.

#### [MODIFY] [merchant_order_list_page.dart](file:///c:/Users/tunah/Sources/Hoppa/hoppa/lib/apps/merchant/merchant_order_list_page.dart)
- Add a "Siparişi İptal Et" button for `PREPARING` and `ON_THE_WAY` statuses.
- Show a BottomSheet upon clicking the button, asking the merchant to select a predefined cancellation reason.
- Dispatch cancel request to backend and refresh the list.

---

### Consumer App UI

#### [MODIFY] [consumer_order_repository.dart] (or similar)
- Add API client for `/api/orders/:id/cancel`.

#### [MODIFY] Consumer Order Details View
- Provide an "Siparişi İptal Et" button when order is `PENDING`.
- Dispatch cancel request to backend and refresh list.

## Verification Plan

### Automated Tests
- Run `npm run build` in the backend to ensure no compilation errors.
- Run `flutter analyze` in both `consumer_app` and `merchant_app` to verify Dart correctness.

### Manual Verification
- Test placing an order as a consumer and cancelling it immediately (status: PENDING).
- Test placing an order, accepting it as a merchant, and cancelling it with a reason.
- Check Merchant Dashboard to verify charts and statistics update correctly.
