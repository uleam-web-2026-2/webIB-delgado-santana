
<script lang="ts">
  import { onMount } from 'svelte';
  import { supabase } from './lib/supabase';
  import { cambiarEstadoSolicitud } from './solicitudes';
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

  // Identifica qué solicitud está siendo actualizada.
  let guardandoEstado = $state<number | null>(null);

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

  // FASE 3: guardar solo la preferencia de filtro, no las solicitudes.
  type FiltroEstado = EstadoSolicitud | 'todos';
  const CLAVE_FILTRO = 'patafiel.filtroEstado';
  const ESTADOS_SOLICITUD: EstadoSolicitud[] = [
    'pendiente_pago',
    'pago_por_verificar',
    'confirmada',
    'en_progreso',
    'completada',
    'cancelada'
  ];

  let filtroEstado = $state<FiltroEstado>('todos');
  let solicitudesFiltradas = $derived(
    filtroEstado === 'todos'
      ? solicitudes
      : solicitudes.filter(solicitud => solicitud.estado === filtroEstado)
  );

  function leerFiltro(): FiltroEstado {
    try {
      const valor = localStorage.getItem(CLAVE_FILTRO);
      if (valor === 'todos' ||
          (valor !== null && ESTADOS_SOLICITUD.includes(valor as EstadoSolicitud))) {
        return valor as FiltroEstado;
      }
      // Una preferencia manipulada o desconocida no debe romper la página.
      localStorage.removeItem(CLAVE_FILTRO);
    } catch (error) {
      console.warn('No se pudo recuperar el filtro:', error);
    }
    return 'todos';
  }

  function guardarFiltro(): void {
    try {
      localStorage.setItem(CLAVE_FILTRO, filtroEstado);
    } catch (error) {
      console.warn('No se pudo guardar el filtro:', error);
    }
  }

  // FASE 2: Supabase Auth conserva la sesión en el navegador.
  // Al abrir Patafiel comprobamos que la sesión sigue siendo válida.
  onMount(() => {
    filtroEstado = leerFiltro();
    void comprobarSesion();
  });

  function limpiarVistaSinSesion(): void {
    sesionIniciada = false;
    solicitudes = [];
    detalle = null;
    guardandoEstado = null;
  }

  function esErrorDeAutenticacion(status: number | undefined): boolean {
    return status === 400 || status === 401 || status === 403;
  }

  // Elimina la sesión local si el token ya no es válido.
  async function terminarSesionInvalida(aviso: string): Promise<void> {
    try {
      const { error } = await supabase.auth.signOut({ scope: 'local' });
      if (error) console.warn('No se pudo revocar la sesión en Supabase:', error);
    } catch (error) {
      console.error('Error al limpiar la sesión:', error);
    }

    limpiarVistaSinSesion();
    mensaje = aviso;
  }

  async function comprobarSesion(): Promise<void> {
    try {
      // getSession recupera la sesión guardada y renueva el token si hace falta.
      const { data, error } = await supabase.auth.getSession();

      if (error) {
        if (esErrorDeAutenticacion(error.status)) {
          await terminarSesionInvalida(
            'Tu sesión venció o dejó de ser válida. Inicia sesión nuevamente.'
          );
        } else {
          mensaje = 'No se pudo recuperar la sesión. Revisa tu conexión.';
        }
        return;
      }

      if (!data.session) {
        limpiarVistaSinSesion();
        return;
      }

      // getUser verifica la identidad contra el servidor de Supabase.
      const { data: datosUsuario, error: errorUsuario } =
        await supabase.auth.getUser();

      if (errorUsuario) {
        if (esErrorDeAutenticacion(errorUsuario.status)) {
          await terminarSesionInvalida(
            'Tu sesión ya no es válida. Inicia sesión nuevamente.'
          );
        } else {
          mensaje = 'No se pudo validar la sesión. Revisa tu conexión.';
        }
        return;
      }

      if (!datosUsuario.user) {
        await terminarSesionInvalida('La sesión no es válida. Inicia sesión nuevamente.');
        return;
      }

      correo = datosUsuario.user.email ?? correo;
      sesionIniciada = true;
      await cargarSolicitudes();

    } catch (error) {
      console.error('Error comprobando la sesión:', error);
      mensaje = 'No se pudo comprobar la sesión. Intenta recargar la página.';
    }
  }

  // Restauradas: estaban referenciadas en el HTML, pero no en el código pegado.
  async function iniciarSesion(event: SubmitEvent): Promise<void> {
    event.preventDefault();
    mensaje = '';

    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email: correo.trim(),
        password: contrasena
      });

      if (error || !data.session) {
        mensaje = 'No se pudo iniciar sesión: ' + (error?.message ?? 'Sesión no recibida.');
        return;
      }

      correo = data.user.email ?? correo;
      sesionIniciada = true;
      contrasena = '';
      await cargarSolicitudes();

    } catch (error) {
      console.error('Error al iniciar sesión:', error);
      mensaje = 'No hubo respuesta al iniciar sesión. Revisa tu conexión.';
    }
  }

  async function cerrarSesion(): Promise<void> {
    try {
      // Solo cierra esta sesión; no todas las sesiones del usuario.
      const { error } = await supabase.auth.signOut({ scope: 'local' });
      limpiarVistaSinSesion();
      contrasena = '';
      mensaje = error
        ? 'Se cerró la sesión local, pero no se confirmó la revocación remota.'
        : '';
    } catch (error) {
      console.error('Error al cerrar sesión:', error);
      mensaje = 'No se pudo cerrar la sesión. Inténtalo nuevamente.';
    }
  }

  // FASE 2: si Supabase rechaza el token al consultar, no romper el listado.
  async function cargarSolicitudes(): Promise<void> {
    cargando = true;
    mensaje = '';

    try {
      const { data, error, status } = await supabase
        .from('solicitudes_cuidado')
        .select(`
          *,
          mascotas (nombre, raza)
        `)
        .order('id', { ascending: false });

      if (error) {
        console.error('Error cargando solicitudes:', error);

        // 42501 también puede devolver HTTP 401: es falta de permisos,
        // NO necesariamente un token vencido. Evitar cerrar sesión por eso.
        if (status === 401 && error.code !== '42501') {
          const { data: usuario, error: errorUsuario } =
            await supabase.auth.getUser();

          if (errorUsuario && esErrorDeAutenticacion(errorUsuario.status)) {
            await terminarSesionInvalida(
              'Tu sesión venció. Inicia sesión para volver a cargar las solicitudes.'
            );
            return;
          }

          if (!errorUsuario && !usuario.user) {
            await terminarSesionInvalida(
              'Tu sesión ya no es válida. Inicia sesión nuevamente.'
            );
            return;
          }

          if (errorUsuario) {
            mensaje = 'No se pudo validar la sesión. Revisa tu conexión.';
            return;
          }
        }

        mensaje = 'Error al cargar solicitudes: ' + error.message;
        return;
      }

      solicitudes = (data ?? []) as SolicitudListado[];

    } catch (error) {
      console.error('Error de conexión cargando solicitudes:', error);
      mensaje = 'No se pudieron cargar las solicitudes. Revisa tu conexión.';
    } finally {
      cargando = false;
    }
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

  // FASE 5: cuando la petición no modifica filas, averiguamos si el
  // estado en Supabase cambió desde que esta pantalla cargó los datos.
  async function revisarCopiaVieja(
    id: number,
    estadoQueVioUsuario: EstadoSolicitud
  ): Promise<string> {
    const { data: actual, error } = await supabase
      .from('solicitudes_cuidado')
      .select('id, estado')
      .eq('id', id)
      .maybeSingle();

    if (error) {
      console.error('No se pudo comprobar el estado actual:', error);
      return 'No se actualizó la solicitud y no fue posible consultar su estado actual. Revisa tu conexión y los permisos.';
    }

    if (!actual) {
      return 'La solicitud no se actualizó. No se encontró el registro o no tienes permiso para verlo.';
    }

    const estadoActual = actual.estado as EstadoSolicitud;

    if (estadoActual !== estadoQueVioUsuario) {
      // La fuente cambió. Actualizamos la copia de esta pantalla, sin
      // intentar sobrescribir la decisión de la otra persona.
      solicitudes = solicitudes.map(s =>
        s.id === id ? { ...s, estado: estadoActual } : s
      );

      if (detalle?.id === id) {
        detalle = { ...detalle, estado: estadoActual };
      }

      return `La solicitud #${id} fue modificada por otra persona. ` +
        `Su estado actual es «${nombresEstado[estadoActual]}». ` +
        'Se actualizó tu pantalla sin sobrescribir el cambio.';
    }

    // Si el estado sigue igual, el PATCH pudo ser rechazado por RLS.
    return 'La solicitud no cambió. El estado sigue igual en Supabase, ' +
      'pero la actualización no fue permitida. Revisa los permisos.';
  }

  // FASE 1 + 5: primero cambia Supabase, luego la copia local.
  // El PATCH lleva el estado que vio esta persona, para impedir que
  // una pantalla desactualizada sobrescriba el cambio de otra.
  async function cancelarSolicitud(id: number): Promise<void> {
    if (guardandoEstado !== null) return;
    mensaje = '';

    const solicitud = solicitudes.find(s => s.id === id);
    if (!solicitud) {
      mensaje = 'No se encontró la solicitud seleccionada.';
      return;
    }

    const estadoObservado = solicitud.estado;
    if (estadoObservado !== 'pendiente_pago') {
      mensaje = 'Solo se pueden cancelar solicitudes pendientes de pago.';
      return;
    }

    guardandoEstado = id;
    mensaje = 'Guardando cambio en Supabase...';

    try {
      const { data, error } = await supabase.auth.getSession();
      if (error || !data.session) {
        mensaje = 'Debe iniciar sesión para cambiar el estado de la solicitud.';
        return;
      }

      // El filtro estado=eq.pendiente_pago se aplica en la BD junto con id.
      // Si otra persona ya cambió el estado, la respuesta será 200 con [].
      const resultado = await cambiarEstadoSolicitud(
        id,
        'cancelada',
        estadoObservado,
        data.session.access_token
      );

      if (resultado.codigo !== 200) {
        mensaje = 'Error: Supabase no actualizó la solicitud. ' +
          `Código HTTP: ${resultado.codigo}.`;
        return;
      }

      if (resultado.filas.length === 0) {
        // Puede ser copia vieja o RLS: jamás presentar 200 [] como éxito.
        mensaje = await revisarCopiaVieja(id, estadoObservado);
        return;
      }

      if (resultado.filas.length !== 1 || resultado.filas[0].id !== id) {
        mensaje = 'Supabase devolvió una respuesta inesperada. ' +
          'Actualiza el listado y verifica el resultado.';
        return;
      }

      const estadoConfirmado = resultado.filas[0].estado;
      solicitudes = solicitudes.map(s =>
        s.id === id ? { ...s, estado: estadoConfirmado } : s
      );

      if (detalle?.id === id) {
        detalle = { ...detalle, estado: estadoConfirmado };
      }

      mensaje = `La solicitud #${id} cambió correctamente a ` +
        `${nombresEstado[estadoConfirmado]}.`;

    } catch (error) {
      console.error(error);
      mensaje = 'Error de conexión con Supabase. No se actualizó ' +
        'la solicitud en pantalla; verifica el estado antes de reintentar.';
    } finally {
      guardandoEstado = null;
    }
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

        <button type="submit">
          Iniciar sesión
        </button>
      </form>
    </section>

  {:else}
    <p>Sesión iniciada como {correo}</p>

    <button onclick={cerrarSesion}>
      Cerrar sesión
    </button>

    <button onclick={cargarSolicitudes}>
      Actualizar solicitudes
    </button>

    <div class="filtro-solicitudes">
      <label for="filtro-estado">Filtrar solicitudes por estado</label>
      <select
        id="filtro-estado"
        bind:value={filtroEstado}
        onchange={guardarFiltro}
      >
        <option value="todos">Todos</option>
        {#each ESTADOS_SOLICITUD as estado}
          <option value={estado}>{nombresEstado[estado]}</option>
        {/each}
      </select>
    </div>

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
            {#each solicitudesFiltradas as solicitud (solicitud.id)}
              <tr>
                <td>{solicitud.id}</td>

                <td>
                  {solicitud.mascotas?.nombre ?? 'Sin mascota'}
                </td>

                <td>{solicitud.fecha_inicio}</td>

                <td>
                  ${solicitud.total_pagar.toFixed(2)}
                </td>

                <td>
                  {nombresEstado[solicitud.estado]}
                </td>

                <td>
                  <button
                    type="button"
                    onclick={() => abrirDetalle(solicitud.id)}
                  >
                    Ver detalle
                  </button>

                  {#if solicitud.estado === 'pendiente_pago'}
                    <button
                      type="button"
                      disabled={guardandoEstado !== null}
                      onclick={() => cancelarSolicitud(solicitud.id)}
                    >
                      {guardandoEstado === solicitud.id
                        ? 'Guardando...'
                        : 'Cancelar solicitud'}
                    </button>
                  {/if}
                </td>
              </tr>

            {:else}
              <tr>
                <td colspan="6">
                  {#if solicitudes.length === 0}
                    No hay solicitudes disponibles.
                  {:else}
                    Ninguna solicitud coincide con el filtro seleccionado.
                  {/if}
                </td>
              </tr>
            {/each}
          </tbody>
        </table>
      </div>
    {/if}

    {#if detalle}
      <section>
        <h2>Detalle de solicitud #{detalle.id}</h2>

        <p>
          <strong>Mascota:</strong>
          {detalle.mascotas?.nombre}
        </p>

        <p>
          <strong>Raza:</strong>
          {detalle.mascotas?.raza}
        </p>

        <p>
          <strong>Inicio:</strong>
          {detalle.fecha_inicio}
        </p>

        <p>
          <strong>Fin:</strong>
          {detalle.fecha_fin}
        </p>

        <p>
          <strong>Total:</strong>
          ${detalle.total_pagar.toFixed(2)}
        </p>

        <p>
          <strong>Estado:</strong>
          {nombresEstado[detalle.estado]}
        </p>

        <h3>Comprobantes de pago</h3>

        {#each detalle.comprobantes_pago as comprobante (comprobante.id)}
          <p>
            Comprobante: {comprobante.numero_comprobante}
            — Estado: {comprobante.estado_pago}
          </p>
        {:else}
          <p>Esta solicitud todavía no tiene comprobantes.</p>
        {/each}

        <button onclick={() => detalle = null}>
          Cerrar detalle
        </button>
      </section>
    {/if}
  {/if}

  {#if mensaje}
    <p role="status" class="mensaje-error">
      {mensaje}
    </p>
  {/if}

  <Formulario
    {sesionIniciada}
    alCrear={cargarSolicitudes}
  />
</main>

<footer>
  <p>© 2026 Patafiel - Sistema de Gestión de Cuidado Animal</p>
</footer>
