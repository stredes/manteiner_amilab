# Amilab Maintenance Platform - Analisis funcional y tecnico

Estado: fase de diseno, sin codigo de aplicacion.

## 1. Resumen ejecutivo

La plataforma propuesta no debe ser un clon generico de un CMMS. Debe ser un CMMS/EAM especializado para laboratorios clinicos, con foco en equipamiento biomedico, calibraciones, metrologia, trazabilidad ISO 15189, ejecucion movil offline y evidencia auditable.

Fracttal cubre muy bien el nucleo CMMS moderno: gestion de activos, ordenes de trabajo, solicitudes, inventario, reportes, movilidad, offline, IoT, integraciones y trazabilidad. La oportunidad para Amilab esta en profundizar lo que un CMMS horizontal normalmente deja generico: criticidad clinica del activo, certificados de calibracion, trazabilidad metrologica, condiciones ambientales, POCT, evidencias listas para auditoria y flujos cerrados de aprobacion.

Repositorios objetivo:

- `amilab-maintenance-api`: backend NestJS con PostgreSQL, Prisma, Redis, BullMQ, JWT y Swagger.
- `amilab-maintenance-mobile`: Expo React Native offline first con Realm.
- `amilab-maintenance-admin`: Next.js para administracion, planificacion, dashboards y auditoria.
- `amilab-maintenance-shared`: contratos TypeScript compartidos, enums, schemas, permisos, DTOs y value objects.

Fuentes de referencia revisadas:

- Fracttal One: CMMS con activos, ordenes de trabajo, solicitudes, inventarios, IoT, IA, integraciones y movilidad. https://www.fracttal.com/en/
- Gestion de activos en Fracttal: jerarquia, historia, criticidad, reportes, trazabilidad e ISO 55001. https://www.fracttal.com/en/asset-management
- Ordenes de trabajo en Fracttal: historial digital, Kanban/calendario, offline, checklists, fotos e IA. https://www.fracttal.com/en/work-order-management
- Solicitudes en Fracttal: portal, QR/NFC, formularios, adjuntos, conversion a OT e integraciones. https://www.fracttal.com/en/maintenance-requests
- Inventario en Fracttal: multiples almacenes, ERP, stock critico, ordenes de reposicion y trazabilidad de movimientos. https://www.fracttal.com/en/warehouse-and-stocks
- Fracttal Sense: sensores, alertas, mantenimiento basado en condicion y trazabilidad. https://www.fracttal.com/en/fracttal-sense
- ISO 15189:2022: requisitos de calidad y competencia para laboratorios medicos, aplicable tambien a POCT. https://www.iso.org/standard/76677.html

## 2. Vision de producto

### Objetivo de negocio

Reducir fallas operativas y riesgo regulatorio en laboratorios clinicos mediante una plataforma que garantice disponibilidad de equipos, cumplimiento de calibraciones, trazabilidad de intervenciones y ejecucion movil controlada.

### Diferenciadores para Amilab

- Catalogo de activos biomedicos con atributos clinicos, metrologicos y de riesgo.
- Control de calibraciones, certificados, vencimientos y aprobaciones.
- Trazabilidad ISO 15189 desde la captura movil hasta reportes de auditoria.
- Offline first real para tecnicos en terreno, con colas de evidencia y firma.
- Motor de planes preventivos, calibraciones y alertas por vencimiento.
- Inventario ligado a OT, con consumo automatico, lotes, ubicaciones y stock critico.
- KPIs operacionales y regulatorios: cumplimiento de programa, activos criticos vencidos, MTTR, MTBF, backlog, SLA y hallazgos.
- Integraciones futuras con ERP, LIS, sensores ambientales, correo, WhatsApp y almacenamiento documental.

## 3. Principios arquitectonicos

- Dominio primero: reglas en Domain/Application, nunca en UI.
- Arquitectura hexagonal: puertos de entrada y salida por modulo.
- Vertical slice: cada modulo encapsula dominio, casos de uso, adaptadores, DTOs y persistencia.
- DDD pragmatico: aggregates donde haya invariantes fuertes; entidades simples donde el CRUD sea suficiente.
- CQRS selectivo: comandos transaccionales separados de queries/reportes.
- Contratos compartidos: DTOs, enums y schemas en `amilab-maintenance-shared`.
- Seguridad por defecto: multi-tenant, RBAC/ABAC, auditoria inmutable y minimo privilegio.
- Offline by design: IDs cliente, outbox local, idempotencia, sync incremental y resolucion explicita de conflictos.

## 4. Modelo de negocio

### Actores

- Administrador Amilab: configura organizacion, usuarios, roles, sedes, permisos y parametros.
- Jefe de mantenimiento: planifica, prioriza, asigna, revisa KPIs y cierra OTs.
- Supervisor de laboratorio: genera o aprueba solicitudes, valida disponibilidad operacional.
- Tecnico biomedico: ejecuta OTs, checklists, evidencias, firma y consumos.
- Responsable metrologico: gestiona calibraciones, certificados, equipos criticos y vencimientos.
- Bodega/almacen: administra repuestos, herramientas, consumibles y movimientos.
- Auditor/calidad: consulta evidencia, historial, trazabilidad y no conformidades.
- Proveedor externo: ejecuta servicios autorizados, carga certificados y evidencia.
- Solicitante invitado: crea solicitudes desde QR/NFC sin acceso completo al sistema.

### Unidades organizacionales

- Tenant/organizacion.
- Sede.
- Edificio/piso/sala.
- Area de laboratorio: hematologia, bioquimica, microbiologia, inmunologia, toma de muestras, urgencia, POCT, bodega, calidad.
- Centro de costo.
- Equipo de mantenimiento.

### Objetos principales del negocio

- Activo biomedico.
- Ubicacion.
- Categoria y subcategoria.
- Solicitud de mantenimiento.
- Orden de trabajo.
- Checklist y respuesta.
- Plan preventivo.
- Plan de calibracion.
- Certificado.
- Repuesto, consumible y herramienta.
- Movimiento de inventario.
- Tecnico, especialidad y certificacion.
- Evidencia: foto, documento, firma, geolocalizacion.
- Auditoria.
- Notificacion.
- Sensor/lectura/alerta.
- Reporte/KPI.

## 5. Bounded contexts

### Identity and Access

Usuarios, roles, permisos, equipos, proveedores, sesiones, dispositivos moviles, refresh tokens y politicas de acceso.

### Organization

Tenant, sedes, areas, ubicaciones, centros de costo, calendarios laborales, feriados y horarios.

### Asset Management

Activos, componentes, jerarquias, codigos, QR/NFC, estados, criticidad, garantia, manuales, fotos, historial y baja.

### Requests

Solicitudes desde usuarios internos, invitados, QR/NFC, mobile y admin; validacion, aprobacion, rechazo y conversion a OT.

### Work Orders

OTs preventivas, correctivas, predictivas, calibracion, inspeccion y emergencia; asignacion, ejecucion, pausa, cierre y cancelacion.

### Maintenance Planning

Planes por dias, semanas, meses, horas de uso, ciclos y condicion; programacion y generacion automatica de OTs.

### Calibration and Metrology

Equipos criticos, instrumentos de medicion, certificados, vencimientos, proveedores, resultados, trazabilidad metrologica y aprobaciones.

### Inventory

Items, almacenes, stock, lotes, movimientos, reservas, consumos por OT, transferencias, ajustes y reposicion.

### Workforce

Tecnicos, especialidades, certificaciones, disponibilidad, rendimiento, horas trabajadas y asignaciones.

### Evidence and Documents

Archivos, fotos, firmas digitales, documentos, manuales, certificados y metadata de integridad.

### Audit and Compliance

Eventos auditables, cambios de estado, aprobaciones, evidencia asociada, exportes y reportes ISO 15189.

### Sync and Offline

Dispositivos, outbox, change log, conflictos, tombstones, adjuntos pendientes y politicas de reintento.

### Notifications

Email, push, WhatsApp futuro, tareas programadas, vencimientos, stock critico y SLA.

### Reporting

KPIs operacionales, regulatorios, inventario, productividad, disponibilidad, MTTR, MTBF, backlog y cumplimiento.

## 6. Workflows principales

### Gestion de activos

1. Crear activo con codigo unico, categoria, marca, modelo, serie, sede, ubicacion, area y centro de costo.
2. Asignar criticidad clinica, estado, garantia, manuales, fotos y QR/NFC.
3. Asociar planes preventivos, planes de calibracion, checklist por tipo y repuestos compatibles.
4. Registrar historial automatico desde solicitudes, OTs, calibraciones, movimientos y eventos IoT.
5. Cambiar estado mediante reglas: operativo, fuera de servicio, en mantenimiento, dado de baja.

Mejora sobre CMMS generico: el activo no solo tiene mantenimiento; tiene riesgo clinico, impacto en continuidad del laboratorio, vencimientos metrologicos y evidencia de cumplimiento.

### Solicitud a orden de trabajo

1. Solicitante crea solicitud con titulo, descripcion, prioridad, evidencia y activo afectado.
2. Sistema valida campos obligatorios segun activo/categoria.
3. Supervisor revisa, cambia prioridad si corresponde y aprueba o rechaza.
4. Al aprobar, se genera OT con tipo sugerido, SLA, checklist y equipo tecnico.
5. Se notifica a responsables y queda auditoria completa.

### Ejecucion de OT

1. Jefe asigna tecnico, fecha, tiempo estimado y recursos.
2. Tecnico descarga OT en mobile.
3. En terreno, escanea QR/barcode, confirma activo y ubicacion.
4. Ejecuta checklist, adjunta fotos, registra observaciones, tiempos, repuestos y geolocalizacion.
5. Si no hay conexion, todo queda en Realm y en outbox.
6. Firma digital, cierre tecnico y sync.
7. Supervisor revisa y cierra administrativamente.

### Preventivo

1. Crear plan por intervalo calendario, horas, ciclos o condicion.
2. Asociar activos, checklist, repuestos sugeridos, ventanas y responsables.
3. Scheduler genera OTs automaticamente usando BullMQ.
4. Se evita duplicidad por idempotency key.
5. Cumplimiento alimenta KPIs y auditoria.

### Calibracion y metrologia

1. Responsable metrologico define equipo critico, periodicidad y proveedor.
2. Sistema crea calendario y alertas de proxima calibracion.
3. Se genera OT de calibracion.
4. Tecnico/proveedor ejecuta, carga certificado, resultado y trazabilidad.
5. Supervisor aprueba certificado.
6. Si falla o vence, activo puede pasar a fuera de servicio o en restriccion.

Mejora clave: separar calibracion de mantenimiento preventivo normal, porque tiene evidencia, aprobacion y riesgo regulatorio distinto.

### Inventario ligado a OT

1. OT solicita repuestos.
2. Bodega reserva items.
3. Tecnico consume repuesto durante ejecucion.
4. Al sincronizar, se registra movimiento de salida con idempotencia.
5. Si baja de stock minimo, se genera alerta o solicitud de reposicion.

### Auditoria ISO 15189

1. Cada accion relevante genera evento: usuario, fecha, entidad, cambio, valor anterior/nuevo, origen, dispositivo y evidencia.
2. Certificados, firmas y fotos quedan ligados a OT/activo.
3. El auditor exporta historial por activo, rango, certificado, tecnico o area.
4. La auditoria debe ser append-only; no se edita, solo se corrige con nuevos eventos.

## 7. Casos de uso por modulo

### Activos

- Crear activo.
- Editar activo con auditoria.
- Dar de baja activo.
- Cambiar estado operacional.
- Generar QR/NFC.
- Adjuntar manuales y fotos.
- Consultar historial completo.
- Definir criticidad y matriz de riesgo.
- Asociar activo padre/hijo.

### Solicitudes

- Crear solicitud interna.
- Crear solicitud invitada desde QR.
- Adjuntar evidencia.
- Aprobar solicitud.
- Rechazar solicitud con motivo.
- Convertir solicitud en OT.
- Consultar SLA y estado.

### Ordenes de trabajo

- Crear OT manual.
- Generar OT desde solicitud.
- Asignar tecnico.
- Reasignar OT.
- Iniciar, pausar, reanudar, completar, cerrar o cancelar.
- Ejecutar checklist.
- Registrar repuestos.
- Registrar tiempo real.
- Firmar OT.
- Reabrir cierre con permiso especial y auditoria.

### Planes

- Crear plan preventivo.
- Crear plan de calibracion.
- Programar por calendario, horas, ciclos o condicion.
- Suspender plan.
- Generar OTs automaticamente.
- Medir cumplimiento.

### Inventario

- Crear item.
- Definir stock minimo/maximo.
- Entrada, salida, ajuste y transferencia.
- Reserva para OT.
- Consumo por OT.
- Reporte de valorizacion.
- Alerta de stock critico.

### Tecnicos

- Registrar especialidades.
- Registrar certificaciones.
- Controlar vencimiento de certificaciones.
- Ver carga de trabajo.
- Medir productividad.

### Compliance

- Consultar auditoria.
- Exportar historial de activo.
- Exportar certificados.
- Gestionar no conformidades futuras.
- Evidenciar cumplimiento de planes y calibraciones.

## 8. Arquitectura de repositorios

### `amilab-maintenance-shared`

Responsabilidad: fuente unica de contratos.

Arbol propuesto:

```text
src/
  dto/
    assets/
    work-orders/
    requests/
    inventory/
    calibration/
  enums/
  permissions/
  roles/
  schemas/
    zod/
  value-objects/
  interfaces/
  errors/
  events/
  index.ts
```

Regla: no depende de API, mobile ni admin. Solo TypeScript, Zod y tipos puros.

### `amilab-maintenance-api`

Responsabilidad: dominio, aplicacion, persistencia, APIs, jobs e integraciones.

Arbol propuesto:

```text
src/
  modules/
    assets/
      domain/
      application/
        commands/
        queries/
        ports/
      infrastructure/
        prisma/
        http/
      assets.module.ts
    requests/
    work-orders/
    maintenance-plans/
    calibration/
    inventory/
    workforce/
    documents/
    audit/
    sync/
    notifications/
    reporting/
    identity/
    organization/
  common/
    auth/
    guards/
    decorators/
    filters/
    interceptors/
    prisma/
    redis/
    bullmq/
    observability/
  main.ts
prisma/
  schema.prisma
  migrations/
test/
  unit/
  integration/
  e2e/
```

### `amilab-maintenance-mobile`

Responsabilidad: ejecucion en terreno offline first.

Arbol propuesto:

```text
src/
  app/
  features/
    auth/
    dashboard/
    scanner/
    assets/
    work-orders/
    requests/
    inventory/
    sync/
    evidence/
    signature/
  core/
    api/
    realm/
    query/
    store/
    permissions/
    navigation/
    config/
  shared/
    components/
    ui/
    hooks/
    utils/
```

Regla: UI solo orquesta casos de uso locales y llamadas a servicios. Nada de reglas de negocio en pantallas.

### `amilab-maintenance-admin`

Responsabilidad: administracion, planificacion, dashboards y compliance.

Arbol propuesto:

```text
src/
  app/
    (auth)/
    (dashboard)/
      assets/
      work-orders/
      requests/
      maintenance-plans/
      calibration/
      inventory/
      technicians/
      reports/
      audit/
      settings/
  features/
  components/
    ui/
    data-table/
    forms/
    charts/
  lib/
    api/
    auth/
    permissions/
    query/
```

## 9. Diagrama de dependencias

```text
amilab-maintenance-shared
  -> usado por api
  -> usado por mobile
  -> usado por admin

amilab-maintenance-api
  -> PostgreSQL
  -> Redis
  -> BullMQ
  -> Object storage
  -> Email/push providers
  -> ERP/LIS/IoT futuros

amilab-maintenance-mobile
  -> API REST
  -> Realm local
  -> Camera/scanner/signature/location

amilab-maintenance-admin
  -> API REST
  -> TanStack Query
  -> Recharts
```

Regla de oro: `shared` no contiene infraestructura; `api` no importa componentes UI; `mobile/admin` no duplican reglas del dominio.

## 10. Modelo entidad relacion

Relaciones principales:

- Organization 1-N Site.
- Site 1-N Location.
- Location 1-N Asset.
- Asset N-1 AssetCategory.
- Asset 0-N AssetComponent mediante parentAssetId.
- Asset 1-N WorkOrder.
- Asset 1-N MaintenancePlanAsset.
- Asset 1-N CalibrationRecord.
- Asset 1-N AssetDocument.
- Request 0-1 WorkOrder.
- WorkOrder N-1 WorkOrderType.
- WorkOrder 1-N WorkOrderAssignment.
- WorkOrder 1-N ChecklistResponse.
- WorkOrder 1-N Evidence.
- WorkOrder 1-N InventoryConsumption.
- Technician 1-N WorkOrderAssignment.
- Technician N-N Specialty.
- Technician 1-N Certification.
- InventoryItem 1-N StockLevel.
- Warehouse 1-N StockLevel.
- InventoryItem 1-N InventoryMovement.
- CalibrationPlan 1-N CalibrationRecord.
- CalibrationRecord 1-N CalibrationCertificate.
- Every auditable entity 1-N AuditEvent.
- Device 1-N SyncSession.
- SyncSession 1-N SyncConflict.

## 11. Diseno PostgreSQL

### Tablas base

- `organizations`
- `sites`
- `locations`
- `cost_centers`
- `areas`
- `users`
- `roles`
- `permissions`
- `user_roles`
- `teams`
- `team_members`
- `devices`

### Activos

- `asset_categories`
- `assets`
- `asset_components`
- `asset_documents`
- `asset_photos`
- `asset_status_history`
- `asset_qr_tags`

Indices recomendados:

- Unique `(organization_id, code)` en `assets`.
- Index `(organization_id, status)`.
- Index `(organization_id, category_id)`.
- Index `(organization_id, location_id)`.
- Full text para nombre, marca, modelo y serie.

### Solicitudes y OTs

- `maintenance_requests`
- `request_evidence`
- `work_orders`
- `work_order_assignments`
- `work_order_state_history`
- `checklist_templates`
- `checklist_items`
- `checklist_responses`
- `work_order_evidence`
- `work_order_signatures`
- `work_order_observations`
- `work_order_time_logs`

Indices recomendados:

- Index `(organization_id, status, priority)`.
- Index `(organization_id, assigned_team_id)`.
- Index `(organization_id, due_at)`.
- Index `(asset_id, created_at)`.

### Planes

- `maintenance_plans`
- `maintenance_plan_assets`
- `maintenance_plan_schedules`
- `maintenance_plan_runs`
- `usage_counters`
- `condition_rules`

### Calibracion y metrologia

- `calibration_plans`
- `calibration_records`
- `calibration_certificates`
- `metrology_requirements`
- `measurement_ranges`
- `calibration_providers`

Indices recomendados:

- Index `(organization_id, next_due_at)`.
- Index `(asset_id, result)`.
- Unique certificado externo por proveedor cuando aplique.

### Inventario

- `warehouses`
- `inventory_items`
- `stock_levels`
- `inventory_movements`
- `inventory_reservations`
- `inventory_consumptions`
- `purchase_requisitions`
- `item_compatible_assets`

Reglas criticas:

- Movimientos son append-only.
- Stock actual puede ser proyeccion derivada, pero debe actualizarse transaccionalmente.
- Consumo offline requiere idempotency key para evitar doble descuento.

### Auditoria y sync

- `audit_events`
- `sync_changes`
- `sync_sessions`
- `sync_conflicts`
- `outbox_events`
- `notifications`
- `files`

Indices recomendados:

- `audit_events (organization_id, entity_type, entity_id, occurred_at)`.
- `sync_changes (organization_id, sequence)`.
- `outbox_events (status, next_attempt_at)`.

## 12. Blueprint de Prisma Schema

No se escribe sintaxis Prisma todavia. El schema debe organizarse por estas familias de modelos:

- Identity: Organization, User, Role, Permission, Team, Device, Session.
- Organization: Site, Location, Area, CostCenter.
- Assets: Asset, AssetCategory, AssetDocument, AssetPhoto, AssetStatusHistory, AssetQrTag.
- Requests: MaintenanceRequest, RequestEvidence, RequestApproval.
- WorkOrders: WorkOrder, WorkOrderAssignment, WorkOrderStateHistory, ChecklistTemplate, ChecklistItem, ChecklistResponse, WorkOrderEvidence, WorkOrderSignature, WorkOrderTimeLog.
- Planning: MaintenancePlan, MaintenancePlanAsset, MaintenancePlanSchedule, MaintenancePlanRun, UsageCounter, ConditionRule.
- Calibration: CalibrationPlan, CalibrationRecord, CalibrationCertificate, CalibrationProvider, MetrologyRequirement.
- Inventory: Warehouse, InventoryItem, StockLevel, InventoryMovement, InventoryReservation, InventoryConsumption, PurchaseRequisition.
- Workforce: TechnicianProfile, Specialty, Certification, TechnicianSpecialty, TechnicianCertification.
- Documents: FileObject, FileLink.
- Audit: AuditEvent.
- Sync: SyncChange, SyncSession, SyncConflict.
- Notifications: Notification, NotificationPreference.

Enums compartidos:

- AssetStatus: OPERATIVE, OUT_OF_SERVICE, UNDER_MAINTENANCE, RETIRED.
- WorkOrderType: PREVENTIVE, CORRECTIVE, PREDICTIVE, CALIBRATION, INSPECTION, EMERGENCY.
- WorkOrderStatus: PENDING, ASSIGNED, IN_PROGRESS, PAUSED, COMPLETED, CLOSED, CANCELLED.
- RequestStatus: DRAFT, SUBMITTED, UNDER_REVIEW, APPROVED, REJECTED, CONVERTED.
- Priority: LOW, MEDIUM, HIGH, CRITICAL.
- InventoryMovementType: IN, OUT, ADJUSTMENT, TRANSFER, RESERVATION, CONSUMPTION.
- CalibrationResult: PASSED, FAILED, CONDITIONAL, NOT_APPLICABLE.
- EvidenceType: PHOTO, DOCUMENT, SIGNATURE, GEOLOCATION, NOTE.
- AuditAction: CREATE, UPDATE, DELETE, STATUS_CHANGE, APPROVE, REJECT, LOGIN, SYNC, EXPORT.

## 13. Offline first

### Datos locales en Realm

Mobile debe almacenar localmente:

- Usuario y permisos efectivos.
- OTs asignadas.
- Activos vinculados a esas OTs.
- Checklists.
- Repuestos reservados o sugeridos.
- Evidencias pendientes.
- Outbox de operaciones.
- Metadata de sync.

No debe descargar todo el universo de activos salvo que se configure una bodega/sede pequena. La descarga debe ser por asignacion, sede, tecnico, favoritos y busqueda bajo demanda.

### Outbox local

Cada accion offline genera una operacion:

- `operationId` UUID.
- `entityType`.
- `entityId`.
- `action`.
- `payload`.
- `baseVersion`.
- `createdAt`.
- `deviceId`.
- `userId`.

El servidor procesa operaciones de forma idempotente. Si recibe dos veces la misma `operationId`, responde el resultado ya aplicado.

### Sync incremental

El API mantiene `sync_changes` con secuencia monotona por organizacion:

- Mobile envia `lastSequence`.
- API responde cambios desde esa secuencia.
- Mobile aplica cambios en transaccion local.
- Mobile sube outbox pendiente.
- API devuelve aceptados, rechazados o conflictos.

### Resolucion de conflictos

- Estados de OT: servidor manda, cliente propone. Transiciones invalidas se rechazan.
- Checklist: merge por item, con version por respuesta.
- Evidencias: append-only, no conflicto.
- Inventario: servidor manda. Consumos offline se aplican si hay reserva o stock; si no, quedan como conflicto operativo.
- Datos maestros: admin manda; mobile recibe.
- Observaciones: append-only.

### Adjuntos

Fotos, certificados y firmas deben sincronizarse en dos fases:

1. Crear metadata e idempotency key.
2. Subir binario a storage con URL firmada.
3. Confirmar checksum.

## 14. Seguridad

- JWT access token corto y refresh token rotativo.
- MFA opcional para perfiles admin/calidad.
- RBAC por rol y ABAC por sede, area, equipo y propiedad de OT.
- Multi-tenant obligatorio en todas las queries.
- Guards por permiso en API.
- Auditoria para toda accion sensible.
- Rate limit en login, sync y uploads.
- Password hashing con algoritmo moderno.
- Storage privado con URLs firmadas.
- Cifrado local en mobile si el dispositivo lo permite.
- Device enrollment y revocacion.
- Exportes de auditoria con registro de quien exporto, cuando y que filtro uso.
- Evitar datos de pacientes en el CMMS; si una integracion LIS lo requiere en el futuro, usar referencias anonimizadas o minimizadas.

## 15. Estrategia CI/CD

### Pull requests

- Lint.
- Typecheck.
- Unit tests.
- Integration tests API.
- Contract validation shared.
- Build admin.
- Build mobile TypeScript.
- Prisma format/validate.

### Ambientes

- Local: Docker Compose para PostgreSQL, Redis y storage compatible S3.
- Staging: base aislada, seeds realistas, migraciones automaticas.
- Production: migraciones controladas, backups, rollback plan y health checks.

### Versionado

- SemVer para shared.
- API versionada por ruta o header.
- Mobile debe tolerar versiones atrasadas con feature flags.

## 16. Estrategia de testing

- Unit tests de dominio: invariantes de estados, prioridades, vencimientos, stock y calibracion.
- Tests de casos de uso: crear OT, aprobar solicitud, completar checklist, consumir repuesto.
- Integration tests con PostgreSQL y Redis reales.
- Contract tests entre shared y API.
- E2E API con supertest.
- Mobile tests para sync, outbox, conflictos y Realm migrations.
- Admin tests para formularios criticos y permisos.
- Tests de seguridad: permisos, tenant leakage, rate limit y archivos privados.
- Tests de performance: sync incremental, reportes y busqueda de activos.

## 17. Observabilidad

- Logs estructurados JSON con correlationId, userId, organizationId, requestId y deviceId.
- OpenTelemetry para traces API, jobs y queries lentas.
- Metricas: latencia API, errores, jobs fallidos, cola BullMQ, conflictos sync, uploads fallidos, uso offline.
- Dashboards: disponibilidad API, sync health, vencimientos proximos, OTs vencidas, stock critico.
- Alertas: jobs detenidos, Redis caido, DB saturada, errores 5xx, spike de conflictos.
- Auditoria separada de logs tecnicos.

## 18. Roadmap MVP

### Fase 0 - Fundacion

- Monorepo o multi-repo con shared versionado.
- API NestJS base.
- PostgreSQL, Prisma, Redis, BullMQ.
- Auth, roles, permisos y tenant.
- CI inicial.

### Fase 1 - Core CMMS

- Activos, categorias, ubicaciones y QR.
- Solicitudes.
- Ordenes de trabajo.
- Checklists.
- Evidencia fotografica.
- Admin basico.

### Fase 2 - Mobile offline

- Login.
- OTs asignadas.
- Scanner QR/barcode.
- Realm.
- Outbox.
- Sync incremental.
- Firma digital.

### Fase 3 - Planes e inventario

- Planes preventivos.
- Generacion automatica de OTs.
- Repuestos e inventario.
- Consumo por OT.
- Alertas de stock.

### Fase 4 - Calibracion y compliance

- Planes de calibracion.
- Certificados.
- Aprobacion.
- Reporte de vencimientos.
- Auditoria exportable.

## 19. Roadmap Enterprise

- Integracion ERP.
- Integracion LIS limitada y segura.
- IoT para temperatura, humedad, energia, vibracion y alertas.
- Mantenimiento predictivo.
- Portal de proveedores.
- CAPA/no conformidades.
- SLA avanzados.
- Multi-idioma.
- Analitica avanzada por costo, disponibilidad y riesgo.
- Firma avanzada y sellado de tiempo.
- Retencion documental configurable.
- Data warehouse operacional.
- AI assistant para diagnostico, busqueda de historial y sugerencia de repuestos, siempre con trazabilidad y revision humana.

## 20. Convenciones de codigo

- TypeScript `strict` en todos los repos.
- Nombres de dominio en ingles para codigo; textos UI en i18n.
- DTOs y schemas nacen en shared.
- Casos de uso nombrados como comando o query: `CreateWorkOrder`, `ApproveRequest`, `CloseWorkOrder`.
- Entidades de dominio no importan Prisma, Nest, React ni librerias de UI.
- Adaptadores implementan puertos.
- Controladores del API no contienen reglas de negocio.
- Pantallas no calculan transiciones de estado.
- Errores de dominio tipados y mapeados a HTTP en infraestructura.
- Migraciones Prisma revisadas en PR.
- Commits y PRs con alcance pequeno.

## 21. Mejoras especificas frente a Fracttal para Amilab

- Perfil de activo biomedico mas profundo: rango de medicion, variable controlada, tolerancia, criticidad, area clinica, POCT y condiciones ambientales.
- Workflow metrologico separado: calibracion, verificacion, certificado, proveedor, resultado, aprobacion y restriccion de uso.
- Evidencia audit-ready: paquetes exportables por activo/periodo con OT, firmas, fotos, certificados y auditoria.
- Riesgo clinico operacional: score por impacto, probabilidad, vencimientos, historial y criticidad del proceso.
- Control de equipos fuera de tolerancia: bloqueo o advertencia al crear OT/solicitud si el activo no esta apto.
- Offline con integridad: firmas, geolocalizacion, timestamps del dispositivo y validacion posterior del servidor.
- Inventario sensible a laboratorio: consumibles, repuestos, herramientas, lotes y vencimientos futuros.
- Compliance nativo: ISO 15189 como lenguaje de producto, no como reporte posterior.
- Integracion futura con sensores de temperatura para refrigeradores/congeladores y alertas automaticas.

## 22. Riesgos tecnicos

- Sync offline mal definido puede duplicar consumos, cerrar OTs invalidas o perder evidencia.
- El alcance enterprise puede crecer demasiado si no se protege el MVP.
- Reportes de auditoria pueden volverse lentos sin indices y proyecciones.
- Archivos pesados en mobile pueden saturar almacenamiento y red.
- La trazabilidad pierde valor si se permite editar eventos historicos.
- Inventario offline requiere reglas estrictas para stock negativo y reservas.
- Calibraciones vencidas deben tener consecuencias operacionales claras.
- Multi-tenant mal aplicado puede filtrar informacion entre clientes.
- Shared puede convertirse en un cajon de sastre si no se mantiene como contratos puros.
- Integraciones LIS/ERP/IoT deben aislarse por adaptadores para no contaminar dominio.

## 23. Recomendacion de siguiente paso

Antes de generar codigo, conviene cerrar estas decisiones:

- Alcance exacto del MVP: modulos, roles y pantallas.
- Si sera multi-tenant desde el dia uno.
- Politica de inventario offline: permitir consumo sin reserva o no.
- Politica de cierre de OT: cierre tecnico y cierre administrativo separados o unificados.
- Campos obligatorios por tipo de activo biomedico.
- Formato de certificado y retencion documental.
- Integraciones obligatorias para la primera version.
- Reglas de auditoria y exportacion para calidad.

La implementacion deberia iniciar por `amilab-maintenance-shared` y `amilab-maintenance-api`, definiendo permisos, enums, DTOs, schemas, modelo Prisma y casos de uso base. Despues se construye admin para operar el dato maestro, y finalmente mobile con sync sobre contratos ya estables.
