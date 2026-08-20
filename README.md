# manteiner_amilab

Workspace generated from the HC Soluciones codebase as the base for the Amilab
Maintenance CMMS/EAM platform.

## Repositories

- `amilab-maintenance-api`: NestJS backend base.
- `amilab-maintenance-mobile`: Expo React Native mobile base.
- `amilab-maintenance-admin`: Next.js admin portal base.
- `amilab-maintenance-shared`: shared TypeScript contracts, enums, schemas and permissions.

## Current refactor status

- Original `.git` folders were not copied.
- Repositories were renamed from `hc-*` to `amilab-maintenance-*`.
- Mobile app metadata was renamed to Amilab Maintenance.
- A new shared package was created for maintenance domain contracts.
- Existing HC domain modules are still present and must be replaced module by module with the Amilab maintenance domain.

## Target domain modules

- Identity and access.
- Organization, sites, areas and locations.
- Asset management.
- Maintenance requests.
- Work orders.
- Preventive maintenance plans.
- Calibration and metrology.
- Inventory and stock movements.
- Technicians and certifications.
- Evidence and documents.
- Audit and ISO 15189 traceability.
- Offline sync.
- Notifications.
- Reports and KPIs.

## Recommended next command order

1. Refactor API module graph and remove HC-specific booking/service flows.
2. Add Prisma, Redis and BullMQ to the API.
3. Build `amilab-maintenance-shared` and consume it from API/admin/mobile.
4. Replace admin dashboard views with assets, requests, work orders, calibration and inventory.
5. Replace mobile flows with scanner, assigned work orders, evidence, signature and sync.
