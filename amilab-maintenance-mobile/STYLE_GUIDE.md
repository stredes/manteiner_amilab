# Amilab Mobile UI/UX Refactor — Style Guide (v1)

## Objetivo
Rediseñar pantallas en dark premium (2026) para una app de mantenimiento en campo.
**CAMBIA SOLO PRESENTACIÓN. NO toques lógica, stores, mutaciones, queries ni rutas.**

## REGLA DE ORO (crítica)
Los colores tailwind **NO funcionan en release** (bug de CSS vars): está PROHIBIDO usar
`bg-background`, `bg-surface`, `bg-primary`, `text-text`, `text-text-muted`, `border-border`,
`text-white`, `bg-danger`, etc.
Siempre usar **colores explícitos** desde `@/src/core/theme`:

```tsx
import { colors, gradient, radius, shadow } from '@/src/core/theme';
// style={{ backgroundColor: colors.surface, color: colors.text }}
```

Las clases tailwind de **layout** (flex, flex-1, flex-row, items-center, justify-center,
px-*, py-*, gap-*, mb-*, mt-*, rounded-*, w-full, min-h-*, absolute, inset-0, z-*) **SÍ** se pueden usar.

## Componentes UI disponibles (importar de `@/src/shared/components/ui`)
- `AppScreen` — contenedor pantalla. Props: `scroll?`, `orbs?`, `edges?`, `style?`, `contentContainerStyle?`, `backgroundColor?`
- `AppText` — Props: `variant` (display|title|heading|subheading|body|bodyStrong|muted|caption|label|error), `color?`, `center?`
- `AppButton` — Props: `variant` (primary|secondary|outline|ghost|danger), `size` (sm|md|lg), `loading?`, `disabled?`, `icon?` (MaterialIcons name), `fullWidth?`, `onPress`. Primary/danger tienen gradiente automático.
- `AppInput` — Props: `label?`, `icon?`, `error?`, `rightIcon?`, `onRightPress?`, + todas las de TextInput. El secureTextEntry muestra eye toggle solo.
- `AppCard` — Props: `variant?` (surface|elevated|muted), `elevation?` (none|sm|md|lg), `onPress?`, `entering?`, `enteringDelay?`
- `AppBadge` — Props: `label`, `severity?` (primary|secondary|success|warning|danger|neutral)
- `AppChip` — Props: `label`, `selected?`, `onPress?`
- `AppHeader` — Props: `title?`, `subtitle?`, `onBack?`, `right?`, `onRight?`, `rightIcon?`, `translucent?`
- `AppSheet` — bottom sheet animado. Props: `visible`, `onClose`, `title?`, `maxHeightRatio?`, `header?`
- `AppProgressSteps` — Props: `total`, `current`
- `AppSkeleton` — Props: `width?`, `height?`, `radius?`, `style?`
- `AppIconBadge` — Props: `icon` (ReactNode), `size?`, `color?`
- `AppOrbs` — orbes de gradiente flotantes de fondo
- `PressableScale` — Pressable con escala al presionar. Props: estándar de Pressable + `scaleTo?`, `haptic?`
- `FadeInView` — animación de entrada. Props: `direction?` (up|down|left|right|zoom|fade), `delay?`, `duration?`, `spring?`

## Iconos
`@expo/vector-icons` → `MaterialIcons`. Ej: `<MaterialIcons name="home" size={24} color={colors.primary} />`

## Patrones recomendados
- Entrada escalonada: `<FadeInView direction="up" delay={i * 90}>` para listas/cards.
- Botón principal: `<AppButton onPress={...}>Texto</AppButton>`.
- Separador "o": `View h-px flex-1 bg-...` → usar `backgroundColor: colors.border`.
- Overlays de modales: `backgroundColor: 'rgba(3, 5, 10, 0.55)'`.
- Texto sobre gradiente/botón: siempre `colors.white` explícito.
- Radio/inputs: `AppInput`.
- Tarjetas de lista: `AppCard variant="surface"` + `AppText`.
- Loaders: `AppSkeleton`.

## Verificación
Después de editar, corre: `npx tsc --noEmit` (en Arch) y reporta errores de TUS archivos.

## PROHIBIDO
- Cambiar rutas, lógica, import/export de stores/mutations.
- Agregar dependencias npm.
- Tocar archivos fuera de tu lista asignada.
- Correr gradle/builds. Solo `tsc`.
