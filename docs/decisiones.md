## Decisión 1 
Elegimos la Mecánica 1 que es el contenedor con el scroll horizontal, porque la tabla es la herramienta de trabajo principal de este rol.
Para el administrador, la consecuencia es que puede ver todas las columnas del registro deslizando la tabla horizontalmente en su celular y vimos que funciona bien en 360px

## Decisión 2 

Elegimos mostrar únicamente las columnas Mascota, Solicitante, Fecha, Estado y Acción porque son los datos mínimos e indispensables para que el administrador priorice su trabajo diario, lo que hace que se vea bien en los dispositivos y lo que se pierde es información secundaria de la postulación como el teléfono, cédula o dirección del solicitante, la cual se relega a la pantalla detallada mediante la acción "Ver detalles".

## Semana 10 · Dónde vive cada cosa

| Dato | Clase | Dónde vive | Por qué ahí | Qué arriesga |
|---|---|---|---|---|
| Solicitudes de cuidado | Negocio | Supabase (PostgreSQL) | Es la fuente principal de los registros y permite consultar los cambios persistentes. | Problemas de conexión o permisos RLS pueden impedir operaciones. |
| Token de autenticación | Sesión | localStorage, administrado por Supabase Auth | Permite mantener la sesión después de recargar la página. | Puede quedar expuesto si existe una vulnerabilidad XSS. |
| Filtro de estados | Interfaz | localStorage | Conserva la preferencia seleccionada después de recargar. | El valor puede ser alterado, por eso se valida antes de utilizarlo. |
| Borrador de solicitud | Interfaz | sessionStorage | Recupera los campos del formulario al recargar la pestaña. | Los datos pueden perderse al cerrar la pestaña y el almacenamiento es accesible desde scripts de la página. |

### La copia vieja

**Problema identificado:** Cuando dos sesiones consultan la misma solicitud, una de ellas puede conservar un estado anterior mientras otra ya lo modificó en Supabase.

**Alternativa 1: recargar antes de cambiar el estado.**
Permite consultar información reciente, pero no garantiza que el registro no cambie entre la consulta y la actualización.

**Alternativa 2: PATCH condicional.**
La actualización se realiza únicamente si el estado almacenado en Supabase todavía coincide con el estado esperado por la pantalla.

**Decisión:** Se eligió el PATCH condicional porque la comprobación del estado forma parte de la operación de actualización y evita sobrescribir un cambio posterior. Se descartó utilizar solamente una recarga previa porque no elimina el problema de concurrencia.

**Resultado:** Si la solicitud ya cambió, el PATCH devuelve una lista vacía. La aplicación consulta el estado actual, actualiza el listado y muestra un aviso. Por ejemplo, en la prueba de la solicitud #4, el PATCH devolvió [] y la consulta posterior confirmó el estado cancelada.

**Permisos:** Si Supabase no autoriza la actualización, la aplicación no debe presentar el cambio como exitoso.