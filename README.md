# Ride Match (Comunidad)

Aplicación móvil desarrollada en Flutter para coordinar viajes compartidos (carpooling) en comunidad. El enfoque es permitir que varios pasajeros creen/encuentren un grupo con origen y destino similares, se coordinen mediante chat y, si aplica, soliciten un conductor disponible.

Este README documenta qué se utilizó (stack/herramientas) y qué se implementó en el proyecto (funcionalidades, arquitectura y base de datos).

## Funcionalidades implementadas

### 1) Autenticación y perfiles (Supabase Auth)
- Registro e inicio de sesión con correo/contraseña.
- Verificación de correo (si el correo no está confirmado, se muestra la opción de re-enviar verificación).
- Roles de usuario: `passenger` (pasajero) y `driver` (conductor).
- Perfil básico en tabla `profiles` (nombre y rol) para mostrar información en la app.

Archivos clave:
- [auth_service.dart](file:///c:/flutter/proyecto_flutter/lib/services/auth_service.dart)
- [auth_screen.dart](file:///c:/flutter/proyecto_flutter/lib/screens/auth_screen.dart)
- [20260511130000_profiles.sql](file:///c:/flutter/proyecto_flutter/supabase/migrations/20260511130000_profiles.sql)

### 2) Mapa, GPS y rutas
- Obtención de ubicación actual con permisos (Geolocator).
- Visualización de mapa con `flutter_map`.
- Cálculo de ruta y métricas (distancia/tiempo) usando OSRM.
- Búsquedas recientes guardadas localmente (SharedPreferences).

Archivos clave:
- [location_service.dart](file:///c:/flutter/proyecto_flutter/lib/services/location_service.dart)
- [home_controller.dart](file:///c:/flutter/proyecto_flutter/lib/core/controllers/home_controller.dart)
- [trips_tab.dart](file:///c:/flutter/proyecto_flutter/lib/screens/home/tabs/trips_tab.dart)

### 3) Arquitectura de grupos (carpooling)
Modelo principal para el flujo de viajes compartidos.

- Creación de grupo con:
  - Origen (lat/lng)
  - Destino (lat/lng)
  - `available_seats` (cupos disponibles para pasajeros)
  - `offered_price` (precio total propuesto)
- Solicitudes para unirse a un grupo (`group_members`), con estados: `pending`, `accepted`, `rejected`.
- Estados del grupo (flujo típico):
  - `gathering` → esperando miembros
  - `searching_driver` → buscando conductor
  - `driver_assigned` → conductor asignado
  - `active` → viaje en curso
  - `payment_pending` / `payment_confirmed` → etapa de pago/confirmación
  - `completed` / `cancelled` → finalización/cancelación
- Contador de integrantes en tiempo real: total = `1 (creador) + miembros aceptados`.
- Sección “Mis viajes”: lista únicamente grupos del usuario autenticado (si es creador, conductor o miembro).

Archivos clave:
- [ride_service.dart](file:///c:/flutter/proyecto_flutter/lib/services/ride_service.dart)
- [community_tab.dart](file:///c:/flutter/proyecto_flutter/lib/screens/home/tabs/community_tab.dart)
- [trips_tab.dart](file:///c:/flutter/proyecto_flutter/lib/screens/home/tabs/trips_tab.dart)
- [ride_card.dart](file:///c:/flutter/proyecto_flutter/lib/screens/home/widgets/ride_card.dart)
- [my_trips_screen.dart](file:///c:/flutter/proyecto_flutter/lib/screens/my_trips_screen.dart)

### 4) Sugerencia inteligente de grupos (matching geográfico)
Antes de crear un grupo nuevo, la app consulta grupos existentes y sugiere los mejores candidatos.

Criterios y scoring usados:
- Radio de origen: 2.5 km (por defecto).
- Radio de destino: 4.0 km (por defecto).
- Se calcula el rumbo aproximado (bearing) origen→destino y se compara con candidatos para evitar sugerencias “en dirección contraria”.
- Se calcula un puntaje compuesto:
  - 45% cercanía de origen
  - 45% cercanía de destino
  - 10% similitud de dirección

Archivos clave:
- [RideService.getSuggestedGroups](file:///c:/flutter/proyecto_flutter/lib/services/ride_service.dart#L136-L232)
- [geo_match_utils.dart](file:///c:/flutter/proyecto_flutter/lib/core/utils/geo_match_utils.dart)

### 5) Modo Conductor (online, pings y tracking)
- Un conductor puede ponerse “online” guardando/actualizando su ubicación en la tabla de conductores activos.
- Cuando un grupo cambia a `searching_driver`, se emite un ping (Realtime) para que conductores puedan aceptar.
- Si el conductor acepta, el grupo pasa a `driver_assigned` y se registra `driver_id`.
- Durante `driver_assigned` y `active` se escucha en tiempo real la ubicación del conductor para mostrar tracking.

Archivos clave:
- [RideService.goOnline / updateLocation / listenForDriverPings](file:///c:/flutter/proyecto_flutter/lib/services/ride_service.dart#L499-L575)
- [HomeController](file:///c:/flutter/proyecto_flutter/lib/core/controllers/home_controller.dart)

### 6) Chat del grupo (Realtime)
- Mensajería en tiempo real por grupo (tabla `group_messages`).
- Mensaje inicial automático (sistema) cuando se abre un chat vacío.

Archivos clave:
- [RideService.getChatMessagesStream / sendChatMessage](file:///c:/flutter/proyecto_flutter/lib/services/ride_service.dart#L581-L621)
- [chat_screen.dart](file:///c:/flutter/proyecto_flutter/lib/screens/chat_screen.dart)

### 7) Asistente IA (Groq)
Se integró un asistente para soporte, sugerencias de precio, consejos de seguridad y “icebreakers”. Usa una API compatible con el esquema de OpenAI Chat Completions (Groq).

Importante:
- La clave se lee desde `.env` vía `flutter_dotenv` (no debe subirse al repositorio).

Archivos clave:
- [groq_service.dart](file:///c:/flutter/proyecto_flutter/lib/services/groq_service.dart)
- [ai_assistant_screen.dart](file:///c:/flutter/proyecto_flutter/lib/screens/ai_assistant_screen.dart)

### 8) Notificaciones locales (Android)
- Inicialización y permisos con `flutter_local_notifications`.
- Notificación genérica (por ejemplo, confirmaciones locales en flujos).
- Existe soporte para una acción “Aceptar” que actualiza `ride_requests` (módulo legado), útil como base para extender a solicitudes de grupo.

Archivos clave:
- [notification_service.dart](file:///c:/flutter/proyecto_flutter/lib/services/notification_service.dart)
- [20260510120000_rides_and_requests.sql](file:///c:/flutter/proyecto_flutter/supabase/migrations/20260510120000_rides_and_requests.sql)

### 9) UI/UX, tema y localización
- Tema global con `FlexColorScheme` + Material 3 y tipografía Poppins (Google Fonts).
- Modo oscuro/claro.
- “Madrid Mode”: overlay visual temático cuando está activado (opcional).
- Localización ES/EN centralizada en un diccionario simple.
- Animaciones con `lottie` (estados del flujo del viaje y elementos de UI) y marca en SVG con `flutter_svg`.

Archivos clave:
- [app_theme.dart](file:///c:/flutter/proyecto_flutter/lib/theme/app_theme.dart)
- [theme_controller.dart](file:///c:/flutter/proyecto_flutter/lib/theme/theme_controller.dart)
- [app_dictionary.dart](file:///c:/flutter/proyecto_flutter/lib/core/localization/app_dictionary.dart)
- [main.dart](file:///c:/flutter/proyecto_flutter/lib/main.dart)
- [home_screen.dart](file:///c:/flutter/proyecto_flutter/lib/screens/home_screen.dart)

## Stack y dependencias principales

### Frontend
- Flutter (Dart) con Material Design / Material 3.
- Gestión de estado: `provider`.
- UI/tema: `flex_color_scheme`, `google_fonts`, `shimmer`, `awesome_dialog`, `lottie`, `flutter_svg`.

### Mapas y geolocalización
- `geolocator` para GPS y permisos.
- `flutter_map` + `latlong2` para mapa y coordenadas.
- `osrm` + `http` para cálculo de rutas y consumo de endpoints.

### Backend
- `supabase_flutter`:
  - Auth
  - Postgres (tablas)
  - Realtime (streams y eventos de cambios en tablas)

### IA (opcional)
- Integración con Groq vía HTTP y `.env`.

## Estructura del proyecto

Carpetas más importantes:
- `lib/core`: controladores (estado), localización, utils de geocálculo, config.
- `lib/services`: servicios de dominio (auth, rides/grupos, ubicación, notificaciones, IA).
- `lib/screens`: pantallas y widgets.
- `supabase/migrations`: scripts SQL (base para armar la BD en Supabase).

## Configuración y ejecución

### Requisitos
- Flutter SDK (proyecto configurado para Dart `^3.11.0`).
- Un proyecto en Supabase (URL + anon key).
- Android Studio/Xcode (según plataforma) o un emulador/dispositivo físico.

### 1) Instalar dependencias

```bash
flutter pub get
```

### 2) Variables de entorno (.env)

Este proyecto carga `.env` al iniciar y además lo declara como asset (ver `pubspec.yaml`).

1. Crea un archivo `.env` en la raíz (o copia desde `.env.example`).
2. Define las siguientes variables (ejemplo con placeholders):

```env
SUPABASE_URL=https://TU_PROYECTO.supabase.co
SUPABASE_ANON_KEY=TU_SUPABASE_ANON_KEY
GROQ_API_KEY=TU_GROQ_API_KEY
```

Notas:
- No pegues claves reales en documentación ni las subas al repositorio.
- Actualmente la inicialización de Supabase también está escrita de forma directa en [main.dart](file:///c:/flutter/proyecto_flutter/lib/main.dart). El proyecto incluye [environment.dart](file:///c:/flutter/proyecto_flutter/lib/core/config/environment.dart) para mover esa configuración a `.env` si se desea unificar.

### 3) Base de datos (Supabase)

En `supabase/migrations` hay scripts SQL de referencia. Para que la app funcione completa con la arquitectura de grupos, además se requieren (o deben existir) tablas acordes a lo que el código consume:

**Tablas mínimas que la app utiliza en tiempo de ejecución**
- `profiles` (nombre y rol)
- `groups` (grupo de viaje)
- `group_members` (solicitudes/miembros)
- `active_drivers` (ubicación de conductores online)
- `group_messages` (chat)

Si tu Supabase no tiene estas tablas, créalas (adaptando a tus necesidades de RLS). Ejemplo de estructura mínima (orientativa):

```sql
create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references auth.users(id) on delete cascade,
  origin_lat double precision not null,
  origin_lng double precision not null,
  dest_lat double precision not null,
  dest_lng double precision not null,
  status text not null default 'gathering',
  available_seats int not null default 1,
  offered_price double precision,
  driver_id uuid references auth.users(id),
  cancel_reason text,
  cancelled_by uuid references auth.users(id),
  cancelled_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.group_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending',
  created_at timestamptz not null default now()
);

create table if not exists public.active_drivers (
  id uuid primary key references auth.users(id) on delete cascade,
  last_lat double precision,
  last_lng double precision,
  is_online boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.group_messages (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  sender_id text not null,
  content text not null,
  created_at timestamptz not null default now()
);
```

**Realtime**
- Para streams en Flutter (por ejemplo, `stream(primaryKey: ...)`), habilita Realtime en las tablas usadas (`groups`, `group_members`, `active_drivers`, `group_messages`).

### 4) Ejecutar

```bash
flutter run
```

## Flujo de uso (resumen)

### Pasajero
1. Inicia sesión o regístrate (rol pasajero).
2. Selecciona un destino.
3. La app muestra sugerencias de grupos existentes cercanos; puedes unirte o crear tu propio grupo.
4. Espera a que se unan personas (estado `gathering`).
5. Solicita conductor (estado `searching_driver`) y coordina por chat.
6. Cuando el conductor acepta: `driver_assigned` → `active` → etapa de pago → cierre.

### Conductor
1. Inicia sesión (rol conductor).
2. Activa modo online para publicar tu ubicación.
3. Recibe pings cuando haya grupos buscando conductor.
4. Acepta un grupo y sigue el flujo del viaje.

## Seguridad y buenas prácticas
- Nunca subas `.env` con claves reales.
- Si una clave se filtró, rótala en el proveedor (Groq/Supabase) y reemplázala.
- Aunque `SUPABASE_ANON_KEY` es una clave pública (cliente), la seguridad real depende de RLS en Supabase.

## Referencias rápidas
- Punto de entrada: [main.dart](file:///c:/flutter/proyecto_flutter/lib/main.dart)
- Estado y lógica principal del mapa/viaje: [home_controller.dart](file:///c:/flutter/proyecto_flutter/lib/core/controllers/home_controller.dart)
- Operaciones de grupos + realtime: [ride_service.dart](file:///c:/flutter/proyecto_flutter/lib/services/ride_service.dart)
