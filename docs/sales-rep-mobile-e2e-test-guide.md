# Sales Rep Mobile E2E Test Guide

This guide gives you a repeatable demo dataset plus the fastest path to test the sales-rep flow from `Start Route` up to `Daily Report`.

The SQL files below are now written for a database that already has the imported Nestle base dump. They reuse the existing `North Territory`, `North Warehouse`, and catalog products instead of trying to create a second territory/catalog set from scratch.

## SQL files

- Seed demo data: [2026-04-18-sales-rep-mobile-e2e-seed.sql](/c:/NestleInsight/nestleinsight-backend/database/sql/2026-04-18-sales-rep-mobile-e2e-seed.sql)
- Approve latest route with PIN `123456`: [2026-04-18-sales-rep-approve-latest-route.sql](/c:/NestleInsight/nestleinsight-backend/database/sql/2026-04-18-sales-rep-approve-latest-route.sql)
- Repair assisted-order shop-owner links in an existing seeded DB: [2026-04-18-sales-rep-fix-assisted-order-shop-owners.sql](/c:/NestleInsight/nestleinsight-backend/database/sql/2026-04-18-sales-rep-fix-assisted-order-shop-owners.sql)

Run the seed first:

```sql
\i 'C:/NestleInsight/nestleinsight-backend/database/sql/2026-04-18-sales-rep-mobile-e2e-seed.sql'
```

If you already seeded before this fix and do not want to reset the route data, run this once:

```sql
\i 'C:/NestleInsight/nestleinsight-backend/database/sql/2026-04-18-sales-rep-fix-assisted-order-shop-owners.sql'
```

## Demo credentials

- Sales rep username: `sr.demo`
- Sales rep email: `sr.demo@nestleinsight.local`
- Regional manager username: `rm.demo`
- Regional manager email: `rm.demo@nestleinsight.local`
- City Mini Mart shop-owner username: `so.city.demo`
- Lake View Stores shop-owner username: `so.lake.demo`
- Shared password: `Password123!`
- Demo territory: `North Territory`
- Demo warehouse: `North Warehouse`
- Demo vehicle ID: `77777777-7777-4777-8777-777777777777`

## Seeded demo IDs

- Territory ID: `a1000000-0000-0000-0000-000000000001`
- Warehouse ID: `b2000000-0000-0000-0000-000000000001`
- Sales rep ID: `44444444-4444-4444-8444-444444444444`
- Shop owner 1 ID: `88888888-8888-4888-8888-888888888881` (`City Mini Mart`)
- Shop owner 2 ID: `88888888-8888-4888-8888-888888888882` (`Lake View Stores`)
- Outlet 1: `55555555-5555-4555-8555-555555555555` (`City Mini Mart`)
- Outlet 2: `66666666-6666-4666-8666-666666666666` (`Lake View Stores`)
- Product 1: `138a9306-7b32-4d23-8666-fc0531082044` (`Milo`, SKU `MILO-400G`)
- Product 2: `c93ac227-e8fa-4e74-92cb-8e2e922b8056` (`Nescafe Classic`, SKU `NESCAFE-CLASSIC-200G`)
- Product 3: `1256697c-ea6e-4de9-94ed-d4d3a2a64bcb` (`Maggi Coconut Milk Powder`, SKU `MAGGI-COCONUT-300G`)

## Recommended test flow

1. Log into the mobile app as `sr.demo`.
2. Open `Start Route`.
3. Create a new route using warehouse `North Warehouse`.
4. Leave vehicle blank or paste `77777777-7777-4777-8777-777777777777`.
5. Submit a load request with sample lines like:

```text
Milo: 10 cases
Nescafe Classic: 8 cases
Maggi Coconut Milk Powder: 5 cases
```

6. Approve the load request by running:

```sql
\i 'C:/NestleInsight/nestleinsight-backend/database/sql/2026-04-18-sales-rep-approve-latest-route.sql'
```

7. Back in the app, refresh `Start Route` and enter PIN `123456`.
8. Open `Outlet Visit`, choose `City Mini Mart`, and complete a visit.
9. Use sample visit values:

```text
OSA notes: NESCAFE low on shelf, requested refill tomorrow.
Planogram OK: true
POSM OK: true
Store feedback: Owner asked for faster replenishment on weekends.
```

10. Open `Report Incident` and submit a sample incident:

```text
Type: VEHICLE_ISSUE
Severity: MEDIUM
Description: Minor cooling issue noticed in the van during afternoon rounds.
```

11. Open `Register New Outlet` and create a new sample outlet:

```text
Outlet Name: Sunrise Grocery
Owner Name: Dilshan Fernando
Phone: +94773333333
Email: sunrise.grocery@example.com
Address: No. 12, Duplication Road, Colombo 04
```

12. Open `Returning Products` and log at least one return:

```text
Product ID: 1256697c-ea6e-4de9-94ed-d4d3a2a64bcb
Product Name: Maggi Coconut Milk Powder
Cases: 2
Reason: OVERSTOCK
Notes: Customer branch closed early.
```

13. Go back to `Start Route` and close the route.
14. Use closing-stock sample values and the same PIN `123456`.

```text
Milo: 3 cases, 0 units
Nescafe Classic: 2 cases, 0 units
Maggi Coconut Milk Powder: 2 cases, 0 units
Variance reason: Demo close-out after outlet visit and return logging.
```

15. Open `Uploads / Daily Report`.
16. Generate the daily report for the closed route.

## Quick verification queries

Check the latest route:

```sql
SELECT id, status, territory_id, warehouse_id, started_at, closed_at
FROM sales_routes
WHERE sales_rep_id = '44444444-4444-4444-8444-444444444444'
ORDER BY created_at DESC
LIMIT 1;
```

Check store visits:

```sql
SELECT id, shop_name_snapshot, status, duration_seconds, created_at
FROM store_visits
WHERE sales_rep_id = '44444444-4444-4444-8444-444444444444'
ORDER BY created_at DESC;
```

Check incidents:

```sql
SELECT id, incident_type, severity, description, created_at
FROM sales_incidents
WHERE sales_rep_id = '44444444-4444-4444-8444-444444444444'
ORDER BY created_at DESC;
```

Check outlet registrations:

```sql
SELECT id, outlet_name, status, territory_id, registered_by_sales_rep_id, created_at
FROM outlets
WHERE registered_by_sales_rep_id = '44444444-4444-4444-8444-444444444444'
ORDER BY created_at DESC;
```

Check generated daily reports:

```sql
SELECT id, route_id, report_date, status, submitted_at
FROM daily_reports
WHERE sales_rep_id = '44444444-4444-4444-8444-444444444444'
ORDER BY created_at DESC;
```

## Current blockers in the codebase

These are worth knowing before you spend time debugging the seed:

- Assisted order now has backend support for `/orders/sales-rep/request-pin` and `/orders/sales-rep/:id/confirm-pin`. The latest demo seed links `City Mini Mart` and `Lake View Stores` to active demo shop-owner accounts, so the PIN flow should work for those outlets. Custom outlets still need a matching active shop-owner account or they will save as drafts.
- The sales-rep product catalog route now allows `SALES_REP`, so the order page can load catalog products in the current backend.
- Daily report draft review endpoints are present for generate, fetch, draft update, and submit. The feature should be testable against the current backend.

## Most useful shortcut

If you only want to validate the main sales-rep flow quickly, focus on this sequence:

1. Seed data.
2. Login as `sr.demo`.
3. Create route.
4. Submit load request.
5. Run the approval SQL helper.
6. Start route with PIN `123456`.
7. Complete one outlet visit.
8. Log one incident.
9. Log one return item.
10. Close route.
11. Generate the daily report.
