<script lang="ts">
  import Formulario from './Formulario.svelte';
</script>

<header>
  <strong>Patafiel - Cuidado y Bienestar Animal</strong>
  <nav aria-label="Navegación principal">
    <a href="#mascotas">Mascotas</a>
    <a href="#solicitudes">Solicitudes de Cuidado</a>
  </nav>
</header>

<main>
  <h1>Solicitudes de cuidado recibidas</h1>

  <div class="tabla-scroll">
    <table>
      <caption>Registro de solicitudes de servicio de cuidado para perros y gatos</caption>
      <thead>
        <tr>
          <th scope="col">Mascota</th>
          <th scope="col">Dueño / Contacto</th>
          <th scope="col">Fecha</th>
          <th scope="col">Estado</th>
          <th scope="col">Acción</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>Luna (Gato)</td>
          <td>Carlos Mendoza</td>
          <td>16/Sep/2026</td>
          <td>Pendiente</td>
          <td><a href="#evaluar">Evaluar</a></td>
        </tr>
        <tr>
          <td>Max (Perro)</td>
          <td>María Arcentales</td>
          <td>15/Sep/2026</td>
          <td>Aceptada</td>
          <td><a href="#evaluar">Evaluar</a></td>
        </tr>
        <tr>
          <td>Rocky (Perro)</td>
          <td>Juan Delgado</td>
          <td>12/Sep/2026</td>
          <td>En progreso</td>
          <td><a href="#detalles">Ver detalles</a></td>
        </tr>
      </tbody>
    </table>
  </div>

  <Formulario />
</main>

<footer>
  <p>© 2026 Patafiel - Sistema de Gestión de Cuidado Animal</p>
</footer>