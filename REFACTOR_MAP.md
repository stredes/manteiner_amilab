# Refactor map from HC Soluciones to Amilab Maintenance

## Source to target

| Source | Target | Action |
| --- | --- | --- |
| `hc-backend` | `amilab-maintenance-api` | Keep NestJS base, auth, uploads, notifications and health. Replace course/service/booking domain modules. |
| `hc-app` | `amilab-maintenance-mobile` | Keep Expo, auth, API client, notifications, location and upload patterns. Replace booking/professional flows with technician workflows. |
| `hc_dashboard` | `amilab-maintenance-admin` | Keep Next.js architecture, auth, API client and dashboard shell. Replace HC dashboards with CMMS admin modules. |
| New | `amilab-maintenance-shared` | Own enums, permissions, DTO schemas, value objects and API contracts. |

## API module conversion

| Existing area | Keep | Replace with |
| --- | --- | --- |
| `auth` | Yes | Adapt roles and permissions to Amilab. |
| `users` | Yes | Add technician/provider/admin profiles. |
| `uploads` | Yes | Evidence, manuals, certificates and signatures. |
| `notifications` | Yes | Work orders, calibration due dates and stock alerts. |
| `geo` | Partial | Evidence geolocation and site/location support. |
| `services` | No | Asset categories, maintenance services only if needed later. |
| `bookings` | No | Work orders and assignments. |
| `availability` | Partial | Technician calendars and workload. |
| `specialties` | Partial | Technician specialties and certifications. |
| `chat` | Later | Optional collaboration per work order. |

## Mobile conversion

| Existing feature | Keep | Replace with |
| --- | --- | --- |
| Auth/session | Yes | Maintenance roles and permissions. |
| Location | Yes | Evidence geolocation. |
| Uploads | Yes | Photos, signatures and certificates. |
| Notifications | Yes | Assigned work orders and alerts. |
| Bookings | No | Assigned work orders. |
| Professional dashboard | No | Technician dashboard. |
| Calendar | Partial | Work order schedule. |
| Chat | Later | Optional work order comments. |

## Admin conversion

| Existing area | Keep | Replace with |
| --- | --- | --- |
| Auth shell | Yes | RBAC/ABAC. |
| Dashboard shell | Yes | CMMS KPIs. |
| Backend client | Yes | Maintenance API client. |
| Public pages | Optional | Internal product may not need public marketing. |
| Dashboard domain | No | Assets, requests, work orders, calibration, inventory, audit. |

## First implementation slice

1. `shared`: final enums, permissions and zod schemas.
2. `api`: assets vertical slice with persistence, tests and Swagger.
3. `admin`: asset list/create/detail.
4. `mobile`: scan asset QR and read asset summary.
5. `api`: audit events for asset creation/update.

This slice validates naming, contracts, auth, API/admin/mobile integration and audit before expanding into work orders.
