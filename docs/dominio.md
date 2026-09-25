# Nuestro negocio

**Producto:** Patafiel - Sistema de Gestión de Cuidado y Bienestar Animal

## Entidades principales
1. **Mascota:** El perro o gato que requiere el servicio de cuidado.
2. **Solicitud de cuidado:** El pedido que realiza el dueño para contratar a un cuidador verificado.

## Entidad que cambia de estado
- **Entidad:** Solicitud de cuidado
- **Flujo de estados:** Pendiente -> Aceptada -> En progreso -> Completada
- **Quién cambia el estado:** El cuidador acepta la solicitud y actualiza el avance del trabajo.

## Roles del sistema
- **Dueño de mascota (Cliente):** Crea las solicitudes de cuidado y consulta su estado. No puede modificar estados ni aprobar solicitudes.
- **Cuidador (Proveedor):** Revisa las solicitudes que le llegan a la bandeja y actualiza el estado de cada servicio.

## Pantalla actual
- **Rol principal:** Cuidador
- **Pregunta clave:** ¿Qué solicitudes de cuidado he recibido y en qué estado está cada una?