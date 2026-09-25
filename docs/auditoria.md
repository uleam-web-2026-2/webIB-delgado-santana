# Auditoría de accesibilidad - Patafiel

## 1. Lo que vio la herramienta
Semana 4
Antes (listado de la semana 3): 100 / 100
hallazgos: ninguno

Con el formulario recién agregado, primera pasada: 100 / 100
hallazgos: ninguno

## 2. Lo que no vio y cómo lo encontramos
Barrera 1: Los mensajes de error de los campos obligatorios del servicio de cuidado se comunicaban únicamente mediante un borde rojo sin descripción en texto accesible.
A quién dejaba afuera: Personas ciegas que utilizan lector de pantalla y personas con daltonismo.
Cómo la encontramos: Inspeccionando la pestaña Accessibility en las Herramientas de Desarrollo (DevTools) y verificando la falta de asociación explicativa mediante `aria-describedby`.

Barrera 2: El atributo de idioma principal del documento HTML estaba en inglés (`lang="en"`).
A quién dejaba afuera: Usuarios de lector de pantalla, ya que el sintetizador de voz leía las etiquetas en español utilizando pronunciación y fonética inglesa.
Cómo la encontramos: Revisando directamente la etiqueta `<html>` en el código fuente de `index.html`.

## 3. Después:
100 / 100 informe en auditoria_despues.html

## 4. La paleta
- Color anterior: #ff0000 | Color nuevo: #b3261e | Contraste antes: 3.9:1 | Contraste después: 5.7:1
  Por qué: Se ajustó el tono del texto de error para garantizar un ratio de contraste accesible superior a 4.5:1 sobre fondo blanco.