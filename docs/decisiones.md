## 1. El listado de tickets
**Elegido:** Usamos una `<table>` completa con `<thead>`, `<tbody>` y `<th scope="col">` para las columnas.
**Descartado:** Armar el listado usando listas `<ul>` o a punta de puros contenedores `<div>`.
**Consecuencia que evita:** Si usábamos `divs`, una persona con lector de pantalla solo escucharía palabras sueltas como "Abierto" o "Alta" sin contexto. Al usar la tabla semántica, el lector primero anuncia el nombre de la columna y luego el dato.

## 2. Los campos de los filtros
**Elegido:** Usamos la etiqueta `<label>` enlazada al campo correspondiente usando el atributo `for` y el `id` del `<select>` o `<input>`.
**Descartado:** Dejar el texto suelto (como un `<p>` o `<span>`) puesto al lado del selector.
**Consecuencia que evita:** Evita que el lector de pantalla anuncie un "cuadro combinado" genérico sin que el usuario sepa para qué sirve. Al conectarlos, el sistema dice "Estado, menú desplegable", y como extra, si le das clic a la palabra, el foco salta directamente al campo.

---

## Preguntas del taller

1. Jerarquía de encabezados
Dejamos "Bandeja de tickets" como el único `<h1>` porque es el título principal de toda la página. Luego, usamos `<h2>` para separar las tres zonas de contenido: Filtros, Resumen y Listado de tickets. La cabecera y el pie de página no llevan encabezados porque al usar las etiquetas nativas `<header>` y `<footer>`, el navegador y los lectores de pantalla ya reconocen esas regiones por sí solos.

2. Enlaces vs Botones
La regla que aplicamos fue: si nos lleva a otra ruta, es enlace; si ejecuta algo en la misma pantalla, es botón. Por eso, "Nuevo ticket" y las acciones de "Ver" los maquetamos con `<a>` (enlaces). Por otro lado, "Aplicar filtros" lo dejamos como `<button>` porque solo procesa información ahí mismo en la vista actual.

3. El desacuerdo
El bloque donde más dimos vueltas y discutimos fue el de los Filtros. Dudamos bastante en si todo ese bloque debía ser solo un `<form>` o si debíamos meterlo en un `<section>`. Al final acordamos envolver todo en un `<section aria-labelledby="titulo-filtros">` para mantener la estructura lógica de las regiones de la página, y pusimos el `<form>` por dentro para agrupar los controles.