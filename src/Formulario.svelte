<section aria-labelledby="titulo-nuevo">
  <h2 id="titulo-nuevo">Nueva solicitud de cuidado de mascota</h2>

  <form action="#" method="post">
    <label for="nombre_mascota">Nombre de la mascota</label>
    <input 
      type="text" 
      id="nombre_mascota" 
      name="nombre_mascota" 
      required 
      aria-invalid="true" 
      aria-describedby="nombre_mascota-error"
    >
    <p id="nombre_mascota-error" class="mensaje-error">Error: Ingrese el nombre de su mascota.</p>

    <label for="especie">Especie de la mascota</label>
    <select id="especie" name="especie">
      <option value="perro">Perro</option>
      <option value="gato">Gato</option>
    </select>

    <label for="dias_cuidado">Número de días de cuidado</label>
    <input 
      type="number" 
      id="dias_cuidado" 
      name="dias_cuidado" 
      required 
      aria-invalid="true" 
      aria-describedby="dias_cuidado-error"
    >
    <p id="dias_cuidado-error" class="mensaje-error">Error: Ingrese una cantidad de días válida (mínimo 1).</p>

    <label for="nombre_dueno">Nombre del dueño / contacto</label>
    <input 
      type="text" 
      id="nombre_dueno" 
      name="nombre_dueno" 
      required 
      aria-invalid="true" 
      aria-describedby="nombre_dueno-error"
    >
    <p id="nombre_dueno-error" class="mensaje-error">Error: Ingrese su nombre completo.</p>

    <label for="instrucciones">Instrucciones de alimentación / medicamentos</label>
    <textarea id="instrucciones" name="instrucciones"></textarea>

    <button type="submit">Solicitar servicio de cuidado</button>
  </form>
</section>