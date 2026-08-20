# Amilab Maintenance - Plan de analisis y refactorizacion orquestada

Contrato compartido. Las 3 instancias opencode (Arch/Kali/Debian) trabajan en
paralelo con roles distintos sobre este mismo plan. NO edites secciones que no
sean de tu rol.

## 1. Estado actual (auditoria)

- `amilab-maintenance-api`: NestJS + TypeORM (NO Prisma). Modulos: auth, admin
  (delgado), availability, bookings, chat, inventory, maintenance (OT). Health
  trivial. `pnpm run typecheck` pasa. `coverage/` generado sin gitignore.
- `amilab-maintenance-admin`: Next.js App Router. 24 route handlers en
  `src/app/api/dashboard/*` que proxean al backend con cookie
  `amilab_maintenance_admin_token` + `x-token`, respuesta `{ok,data}`. Modulo
  maintenance presente. Dependencia `link:../amilab-maintenance-shared`.
- `amilab-maintenance-mobile`: Expo Router. auth/onboarding/user-tabs/
  professional-tabs. Tabs home/bookings/favorites/messages = shells con
  contenido mock. Ruta `professional/[id]` DEAD. Backend en
  `src/core/config/backend.ts`. No offline-first.
- `amilab-maintenance-shared`: 6 archivos src (index, enums, permissions,
  schemas, contracts, user-roles). Importado por api y admin.
- Todos: rama Development, 2 commits, origin gls-softwareDevelopment.

## 2. Brechas vs diseno objetivo (docs/amilab-maintenance-analysis.md)

1. API usa TypeORM, diseno pedia Prisma + Redis + BullMQ.
2. Mobile no es offline-first (diseno pedia Realm + outbox + sync).
3. Mobile: pantallas de mantenimiento son mocks, no flujos reales.
4. No hay modulos Calibracion/Metrologia ni Audit/Compliance implementados.
5. No hay value-objects, errors ni events en shared.
6. Admin es delgado (solo proxy), sin dashboards/planificacion reales.

## 3. Modulos y sub-modulos recalculados

### shared (rol ARCH)
enums (estados de ciclos), permissions, schemas, contracts, user-roles,
value-objects (Id, Money, DateTime, StatusTransition), errors, events.

### api (rol ARCH)
identity, organization, assets, requests, work-orders, maintenance-plans,
calibration, inventory, workforce, evidence, notifications, sync, reporting,
audit, common (auth/guards/filters/interceptors/persistencia).

### mobile (rol DEBIAN)
auth, home (trabajos de hoy), bookings, assets, work-orders (detalle:
checklist + fotos + firma + partes), requests, messages, inventory, sync,
profile.

### admin (rol KALI)
dashboard, assets, work-orders, requests, maintenance-plans, calibration,
inventory, technicians, reports, audit, settings.

## 4. Ciclos de negocio cerrados (maquina de estados)

Un ciclo se considera CERRADO cuando cada transicion tiene: validez,
autorizacion por rol, validacion, endpoint, UI y trazabilidad (audit log).

1. **Ciclo OT**: SOLICITADA -> VALIDADA -> AGENDADA -> EN_PROGRESO ->
   EN_PAUSA -> COMPLETADA (evidencia + firma) -> CERRADA -> FACTURADA.
   Ramas: RECHAZADA, CANCELADA, REPROGRAMADA.
2. **Ciclo booking**: SOLICITADA -> CONFIRMADA -> EJECUTADA -> CERRADA.
   Ramas: CANCELADA, NO_SHOW (reprogramar).
3. **Ciclo inventario**: DISPONIBLE -> RESERVADO -> CONSUMIDO (ligado a OT) ->
   REPOSICION (stock critico).
4. **Ciclo calibracion**: PROGRAMADO -> VENCIDO -> EJECUTADO -> CERTIFICADO
   PENDIENTE -> APROBADO.
5. **Ciclo preventivo**: PLAN -> GENERA_OT -> EJECUTADO -> HISTORIAL ->
   REPROGRAMADO.

## 5. Estandares UI/UX (investigacion 2026)

Mobile (Expo RN):
- Touch targets >= 48x48pt, minimo tipeo (dropdowns/fotos/QR/voz).
- Status glanceable: icono + etiqueta + color (NUNCA color solo).
- Offline-first con indicador de sync visible.
- Flujos lineales con pasos obligatorios y resumen antes de enviar.
- Perf: cold start <2s, transiciones <300ms, guardado local <100ms.
- Navegacion: bottom tabs (3-5) + stack para detalle. Job-centric: lista de
  "hoy" -> detalle con checklist/fotos antes-despues/firma/partes.
- Tokens semaniticos: background, surface, surfaceElevated, text, textMuted,
  border, primary, danger, warning, success. `userInterfaceStyle: automatic`,
  modo system + override.

Admin (Next.js):
- Shell: sidebar colapsable con secciones anidadas + header lean (breadcrumbs,
  theme toggle, user menu). Sticky headers en tablas.
- Tablas datos: sort + filtros persistidos + paginacion + seleccion/bulk +
  acciones inline visibles (no hover-only) + empty states que ensenan +
  skeleton loading + a11y (semantic table, aria-sort, keyboard).
- Vistas por rol: tecnico (tareas), planificador (workload), ejecutivo (KPIs).
- Graficos con drill-down (Recharts ya previsto en el diseno).

## 6. Fases de refactorizacion (por rol)

### ROL ARCH - API + shared
F1. shared: completar enums de estados (ciclos sec.4), value-objects, errors,
events; asegurar compatibilidad de exports (sin romper consumidores).
F2. api: implementar maquina de estados de OT y booking (transiciones con
validacion + roles + audit), consumos de inventario ligados a OT, endpoints
alineados a contracts. Quitar `coverage/`, dead code y referencias HC Soluciones.
F3. Verificar: `pnpm run typecheck` en shared y api.

### ROL KALI - admin
F1. Shell app (sidebar colapsable + header lean) y tema con tokens semanticos
(light/dark).
F2. Tablas datos (sort/filtro/paginacion/bulk/empty/skeleton) para
work-orders, requests, assets, inventory.
F3. Vista por rol y cierre de ciclo: acciones de transicion de OT
(validar/agendar/iniciar/completar/cerrar) contra el API.
F4. Quitar dead code y referencias HC Soluciones. Verificar `npm run build`.

### ROL DEBIAN - mobile
F1. Tema con tokens semanticos (light/dark, system) + componentes base.
F2. Home "hoy": lista real de trabajos con status glanceable (quitar mock).
F3. Detalle OT: checklist obligatorio + fotos antes/despues + firma + partes
(quitar mock). Bookings y favorites reales desde API.
F4. Eliminar ruta DEAD `professional/[id]` y leftovers de template.
   Quitar referencias HC Soluciones. Verificar `npx tsc --noEmit`.

## 7. Orquestacion

- Cada instancia escribe un LOG final: archivos tocados, validaciones
  (typecheck/build), y que quedo pendiente.
- Los cambios quedan en git sin commitear; el orquestador (phone) revisa,
  corrige si hace falta, y luego se hace commit en cada repo.
- No empujar (push) nada. No editar lo ajeno al rol. No borrar datos reales.
