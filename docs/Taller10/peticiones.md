
# Semana 10 - Pruebas contra Supabase

## Resultados de las peticiones HTTP

| Caso | Petición | Código | Cuerpo de la respuesta | Qué mostró la pantalla |
|---|---|---|---|---|
| 1. Con sesión y con política | PATCH | 200 | `[{"id":2,"estado":"cancelada"}]` | La solicitud #2 cambió correctamente a Cancelada. |
| 2. Sin sesión | PATCH | 401 | `{"code":"42501","hint":"Grant the required privileges..."}` | La aplicación mostró el formulario de inicio de sesión. Supabase rechazó la actualización por falta de permisos. |
| 3. Con sesión y sin política | PATCH | Pendiente | Pendiente | Pendiente |
| 4. Token alterado al recargar | GET | Pendiente | Pendiente | Pendiente |
| 5. Copia vieja, persona A | PATCH | 200 | `[]` | Detectó el conflicto en la solicitud #4 y actualizó la pantalla a Cancelada sin sobrescribirla. |

## Observaciones

Los resultados corresponden a las pruebas realizadas contra Supabase desde Patafiel.

Las capturas se encuentran en `docs/taller10/capturas/`.

Los casos pendientes se completarán con las respuestas reales obtenidas en Network.
