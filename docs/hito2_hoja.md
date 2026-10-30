# Hito 2 · Patafiel — Hoja del hito

**Pareja:** Jonathan Delgado · Colon Moreira (verificar nombres completos antes de entregar)
**Asignatura:** Aplicaciones Web I, paralelo B · ULEAM · Período 2026-2
**Entidad principal:** `solicitudes_cuidado`
**Tecnologías:** Svelte, TypeScript y Supabase (PostgreSQL).

## 1 · Tablas

| Tabla                 | Columnas                                                                                                        | Relación                                                                                          |
| --------------------- | --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `usuarios`            | `id`, `auth_id`, `nombre`, `correo`, `telefono`, `rol`                                                          | `auth_id` se relaciona con Supabase Auth. Un usuario puede tener varias mascotas y solicitudes.   |
| `mascotas`            | `id`, `usuario_id`, `nombre`, `raza`, `edad_anios`, `observaciones`                                             | `usuario_id` referencia a `usuarios.id`.                                                          |
| `cuidadores`          | `id`, `usuario_id`, `documento_identidad`, `tarifa_diaria`, `zona_cobertura`, `verificado`                      | Cada cuidador tiene un perfil relacionado con `usuarios`.                                         |
| `solicitudes_cuidado` | `id`, `cliente_id`, `cuidador_id`, `mascota_id`, `fecha_inicio`, `fecha_fin`, `total_pagar`, `estado`, `creado` | Una solicitud pertenece a un cliente, una mascota y un cuidador; puede tener varios comprobantes. |
| `comprobantes_pago`   | `id`, `solicitud_id`, `numero_comprobante`, `archivo_url`, `estado_pago`, `creado`                              | `solicitud_id` referencia a `solicitudes_cuidado.id`.                                             |

**Estados de `solicitudes_cuidado`:** `pendiente_pago` (inicial), `pago_por_verificar`, `confirmada`, `en_progreso`, `completada` y `cancelada`.

Estos estados están definidos como unión de tipos en `src/tipos.ts`. Las propiedades de las interfaces corresponden a las columnas de Supabase.

## 2 · Vista × consulta

| Vista                             | Qué pide                      | A qué tabla                                            | Filtro u orden                                                               | Qué puede fallar                                       | ¿Funciona ya? |
| --------------------------------- | ----------------------------- | ------------------------------------------------------ | --------------------------------------------------------------------- | ---------------------------------------------- | ------------- |
| Mis solicitudes (cliente)         | Leer listado                  | `solicitudes_cuidado`, `mascotas`                      | Solicitudes del cliente autenticado, ordenadas por ID descendente     | Sin sesión o error de conexión                 | Sí            |
| Detalle de mi solicitud (cliente) | Leer solicitud y comprobantes | `solicitudes_cuidado`, `mascotas`, `comprobantes_pago` | Solicitud seleccionada por ID                                         | Registro inexistente o sin autorización        | Sí            |
| Nueva solicitud (cliente)         | Crear                         | `solicitudes_cuidado`                                  | Estado inicial `pendiente_pago`, mascota propia y cuidador verificado | Fechas inválidas o rechazo sin sesión          | Por verificar |
| Solicitudes asignadas (cuidador)  | Leer                          | `solicitudes_cuidado`, `mascotas`                      | Solo solicitudes asignadas al cuidador                                | Acceso no autorizado                           | Plan          |
| Gestión de solicitud (cuidador)   | Leer y cambiar estado         | `solicitudes_cuidado`, `comprobantes_pago`             | Solicitudes asignadas y transiciones válidas                          | Pago rechazado o cambio de estado no permitido | Plan          |

Las vistas de listado y detalle están funcionando con consultas reales a Supabase y respuestas HTTP 200.

Las vistas marcadas como **Plan** corresponden a funcionalidades del cuidador que se implementarán posteriormente. La creación está desarrollada, pero debe comprobarse completamente en la demostración.

## 3 · Matriz rol × tabla × operación

| Tabla y operación                      | Sin sesión | Cliente                                       | Cuidador                | ¿Política escrita?             |
| -------------------------------------- | ---------- | --------------------------------------------- | ----------------------- | ------------------------------ |
| `usuarios` · leer                      | No         | Solo su perfil                                | Solo su perfil          | Sí                             |
| `mascotas` · leer                      | No         | Solo sus mascotas                             | Pendiente de diseño     | Sí, para cliente               |
| `cuidadores` · leer                    | No         | Verificados                                   | Verificados             | Sí                             |
| `solicitudes_cuidado` · leer           | No         | Solo propias                                  | Solo asignadas (futuro) | Sí, cliente / Diseño, cuidador |
| `comprobantes_pago` · leer             | No         | Solo de sus solicitudes                       | Solo asignadas (futuro) | Sí, cliente / Diseño, cuidador |
| `solicitudes_cuidado` · crear          | No         | Solo con mascota propia y cuidador verificado | No                      | Sí                             |
| `solicitudes_cuidado` · cambiar estado | No         | Cancelación futura                            | Solo asignadas (futuro) | Diseño                         |
| `comprobantes_pago` · crear            | No         | Solo en sus solicitudes (futuro)              | No                      | Diseño                         |

**Seguridad implementada:** se activó Row Level Security (RLS) en las cinco tablas y se configuraron seis políticas para lectura y creación. Los permisos de gestión de solicitudes por parte del cuidador quedan como diseño, de acuerdo con el alcance del Hito 2.

## 4 · Usuario de ejemplo

**Correo de prueba:** `clientepatafiel@gmail.com`

**Contraseña de prueba:** `[COMPLETAR CON UNA CONTRASEÑA EXCLUSIVA DE DEMOSTRACIÓN]`

**Rol:** Cliente.

**Datos de prueba:** Ana Demo como cliente, Tommy como mascota y Carlos Demo como cuidador. La solicitud inicial #1 contiene el comprobante `DEMO-001`, mientras que la solicitud inicial #2 se registró con estado `pendiente_pago`.

La cuenta de demostración se encuentra en Supabase Authentication y está vinculada con `usuarios.auth_id`.

La contraseña debe ser ficticia y exclusiva para la demostración. Nunca se deben incluir contraseñas personales ni claves administrativas de Supabase.

## 5 · Recuadro de cumplimiento

- [x] Las cinco tablas existen en Supabase y tienen registros.
- [x] `src/tipos.ts` contiene las interfaces de las entidades, relaciones y estados como unión.
- [x] El listado y detalle consultan datos reales desde Supabase, con respuestas HTTP 200 y estados visibles en texto.
- [x] El formulario muestra errores junto a los campos, conserva lo escrito y no envía peticiones con datos inválidos. Pendiente de verificar con evidencia final.
- [x] Sin sesión Supabase rechaza la creación; con sesión la permite y muestra el registro en el listado. Pendiente de comprobar ambas situaciones.
- [x] Se dispone de una captura de cada demostración dentro de `docs/hito2_capturas/`. Verificar que estén guardadas las cuatro evidencias.

**Declaración de uso de inteligencia artificial:** Se utilizó ChatGPT como herramienta de apoyo para comprender la rúbrica, organizar el modelo de datos, explicar las políticas de seguridad, revisar consultas SQL y orientar la implementación de componentes Svelte y TypeScript. Los integrantes son responsables de revisar el código, ejecutar las pruebas y comprender las decisiones realizadas.
