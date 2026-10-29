
<script lang="ts">
  import { onMount } from 'svelte';
  import { supabase } from './lib/supabase';
  import Formulario from './Formulario.svelte';

  import type {
    SolicitudDeCuidado,
    ComprobantePago,
    EstadoSolicitud
  } from './tipos';

  type SolicitudListado = SolicitudDeCuidado & {
    mascotas: {
      nombre: string;
      raza: string;
    } | null;
  };

  type DetalleSolicitud = SolicitudListado & {
    comprobantes_pago: ComprobantePago[];
  };

  let correo = $state('clientepatafiel@gmail.com');
  let contrasena = $state('');
  let sesionIniciada = $state(false);
  let cargando = $state(false);
  let mensaje = $state('');

  let solicitudes = $state<SolicitudListado[]>([]);
  let detalle = $state<DetalleSolicitud | null>(null);

  const nombresEstado: Record<EstadoSolicitud, string> = {
    pendiente_pago: 'Pendiente de pago',
    pago_por_verificar: 'Pago por verificar',
    confirmada: 'Confirmada',
    en_progreso: 'En progreso',
    completada: 'Completada',
    cancelada: 'Cancelada'
  };

  // Comprobar si existe una sesión al abrir Patafiel.
  onMount(() => {
    void comprobarSesion();
  });

  async function comprobarSesion() {
    const { data } = await supabase.auth.getSession();

    if (data.session) {
      sesionIniciada = true;
      await cargarSolicitudes();
    }
  }

  // Iniciar sesión usando Supabase Authentication.
  async function iniciarSesion(event: SubmitEvent) {
    event.preventDefault();
    mensaje = '';

    const { error } = await supabase.auth.signInWithPassword({
      email: correo.trim(),
      password: contrasena
    });

    if (error) {
      mensaje = 'No se pudo iniciar sesión: ' + error.message;
      return;
    }

    sesionIniciada = true;
    contrasena = '';
    await cargarSolicitudes();
  }

  // Cerrar sesión.
  async function cerrarSesion() {
    const { error } = await supabase.auth.signOut();

    if (error) {
      mensaje = error.message;
      return;
    }

    sesionIniciada = false;
    solicitudes = [];
    detalle = null;
    mensaje = '';
  }

  // Consultar las solicitudes reales en PostgreSQL.
  async function cargarSolicitudes() {
    cargando = true;
    mensaje = '';

    const { data, error } = await supabase
      .from('solicitudes_cuidado')
      .select(`
        *,
        mascotas (nombre, raza)
      `)
      .order('id', { ascending: false });

    cargando = false;

    if (error) {
      mensaje = 'Error al cargar solicitudes: ' + error.message;
      return;
    }

    solicitudes = (data ?? []) as SolicitudListado[];
  }

  // Consultar una solicitud y sus comprobantes.
  async function abrirDetalle(id: number) {
    mensaje = '';

    const { data, error } = await supabase
      .from('solicitudes_cuidado')
      .select(`
        *,
        mascotas (nombre, raza),
        comprobantes_pago (
          id,
          solicitud_id,
          numero_comprobante,
          archivo_url,
          estado_pago,
          creado
        )
      `)
      .eq('id', id)
      .single();

    if (error) {
      mensaje = 'Error al abrir el detalle: ' + error.message;
      return;
    }

    detalle = data as DetalleSolicitud;
  }
</script>

<header>
  <strong>Patafiel - Cuidado y Bienestar Animal</strong>
</header>

<main>
  <h1>Solicitudes de cuidado</h1>

  {#if !sesionIniciada}
    <section>
      <h2>Iniciar sesión</h2>

      <form onsubmit={iniciarSesion}>
        <label for="correo">Correo</label>
        <input
          id="correo"
          type="email"
          bind:value={correo}
          required
        />

        <label for="contrasena">Contraseña</label>
        <input
          id="contrasena"
          type="password"
          bind:value={contrasena}
          required
        />

        <button type="submit">Iniciar sesión</button>
      </form>
    </section>
  {:else}
    <p>Sesión iniciada como {correo}</p>

    <button onclick={cerrarSesion}>Cerrar sesión</button>
    <button onclick={cargarSolicitudes}>Actualizar solicitudes</button>

    {#if cargando}
      <p>Cargando solicitudes...</p>
    {:else}
      <div class="tabla-scroll">
        <table>
          <caption>Solicitudes registradas en Supabase</caption>

          <thead>
            <tr>
              <th>ID</th>
              <th>Mascota</th>
              <th>Fecha de inicio</th>
              <th>Total</th>
              <th>Estado</th>
              <th>Acción</th>
            </tr>
          </thead>

          <tbody>
            {#each solicitudes as solicitud (solicitud.id)}
              <tr>
                <td>{solicitud.id}</td>
                <td>{solicitud.mascotas?.nombre ?? 'Sin mascota'}</td>
                <td>{solicitud.fecha_inicio}</td>
                <td>${solicitud.total_pagar.toFixed(2)}</td>
                <td>{nombresEstado[solicitud.estado]}</td>
                <td>
                  <button onclick={() => abrirDetalle(solicitud.id)}>
                    Ver detalle
                  </button>
                </td>
              </tr>
            {:else}
              <tr>
                <td colspan="6">No hay solicitudes disponibles.</td>
              </tr>
            {/each}
          </tbody>
        </table>
      </div>
    {/if}

    {#if detalle}
      <section>
        <h2>Detalle de solicitud #{detalle.id}</h2>

        <p><strong>Mascota:</strong> {detalle.mascotas?.nombre}</p>
        <p><strong>Raza:</strong> {detalle.mascotas?.raza}</p>
        <p><strong>Inicio:</strong> {detalle.fecha_inicio}</p>
        <p><strong>Fin:</strong> {detalle.fecha_fin}</p>
        <p><strong>Total:</strong> ${detalle.total_pagar.toFixed(2)}</p>
        <p><strong>Estado:</strong> {nombresEstado[detalle.estado]}</p>

        <h3>Comprobantes de pago</h3>

        {#each detalle.comprobantes_pago as comprobante (comprobante.id)}
          <p>
            Comprobante: {comprobante.numero_comprobante}
            — Estado: {comprobante.estado_pago}
          </p>
        {:else}
          <p>Esta solicitud todavía no tiene comprobantes.</p>
        {/each}

        <button onclick={() => detalle = null}>Cerrar detalle</button>
      </section>
    {/if}
  {/if}

  {#if mensaje}
    <p role="alert" class="mensaje-error">{mensaje}</p>
  {/if}

  <Formulario />
</main>

<footer>
  <p>© 2026 Patafiel - Sistema de Gestión de Cuidado Animal</p>
</footer>
