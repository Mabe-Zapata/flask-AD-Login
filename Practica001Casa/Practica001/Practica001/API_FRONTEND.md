# API Practica001 — Guía para el frontend

Base URL (desarrollo): `https://localhost:<puerto>` — el puerto depende de `launchSettings.json`.
Todas las respuestas son JSON. CORS está abierto (`AllowAnyOrigin`).

## Flujo de autenticación

1. `POST /api/auth/login` → recibe un `token`.
2. Enviar el token en **cada** petición a `/api/product` y `/api/category`:
   `Authorization: Bearer <token>`
3. El token **expira a los 5 minutos** desde el login (campo `expiracion`). Pasado ese tiempo toda petición responde `401` y hay que volver a hacer login. No hay refresh token.

### Login

`POST /api/auth/login`

```json
{ "usuario": "admin", "password": "12345" }
```

Respuesta `200`:

```json
{
  "mensaje": "Login correcto",
  "usuario": { "id": 1, "usuarioNombre": "admin", "nombreCompleto": "Administrador", "rol": "Admin" },
  "token": "24A341C1...",
  "expiracion": "2026-10-23T16:07:46.600"
}
```

Errores: `401 { "error": "Usuario o contraseña incorrectos" }`.

`rol` es `"Admin"` o `"User"`. Úselo para ocultar los botones de crear, editar y borrar a los usuarios `User`.

### Validar token (opcional)

`GET /api/auth/validar` con el header `Authorization`.
`200 { "mensaje": "Token válido", "expiracion": "..." }` o `401 { "error": "Token inválido" | "Token expirado" }`.

## Permisos

| Acción | Admin | User |
|---|---|---|
| GET (listar / ver uno) | ✅ | ✅ |
| POST (crear) | ✅ | ❌ 403 |
| PUT (editar) | ✅ | ❌ 403 |
| DELETE (borrar) | ✅ | ❌ 403 |

## Códigos de error comunes

| Código | Cuándo | Cuerpo |
|---|---|---|
| 401 | Sin header, token inválido o vencido | `{ "error": "Token inválido" }` / `{ "error": "Token expirado" }` |
| 403 | Usuario `User` intenta crear, editar o borrar | `{ "error": "Solo un administrador puede realizar esta acción" }` |
| 404 | El id no existe | — |
| 409 | Versión desactualizada en PUT (ver abajo) | `{ "message": "...", "versionActual": 1, "versionEnviada": 0 }` |

Ante un `401`, redirigir al login.

## Productos — `/api/product`

Modelo:

```json
{
  "id": 6,
  "names": "Teclado",
  "price": 10.5,
  "stock": 3,
  "version": 0,
  "descriptions": "Mecánico",
  "imageUrl": "https://...",
  "isActive": true
}
```

| Método | Ruta | Respuesta |
|---|---|---|
| GET | `/api/product` | `200` lista |
| GET | `/api/product/{id}` | `200` producto / `404` |
| POST | `/api/product` | `201` producto creado (con `id`) |
| PUT | `/api/product/{id}` | `204` / `404` / `409` |
| DELETE | `/api/product/{id}` | `204` / `404` |

## Categorías — `/api/category`

Modelo: `{ "id": 3, "name": "Periféricos", "version": 0 }`

| Método | Ruta | Respuesta |
|---|---|---|
| GET | `/api/category` | `200` lista |
| GET | `/api/category/{id}` | `200` categoría / `404` |
| POST | `/api/category` | `201` categoría creada |
| PUT | `/api/category/{id}` | `204` / `404` / `409` |
| DELETE | `/api/category/{id}` | `204` / `404` |

## Edición concurrente (`version`)

En `PUT`, el body debe incluir `id` (igual al de la URL) y el `version` **que se leyó del GET**. Si alguien más editó antes, responde `409`. En ese caso, recargar el registro y reintentar. Cada edición exitosa incrementa `version` en 1.

## Usuarios de prueba

| usuario | password | rol |
|---|---|---|
| admin | 12345 | Admin |
| Juan | 12345 | User |
