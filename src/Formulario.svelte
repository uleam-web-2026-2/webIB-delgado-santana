
<script lang="ts">
  import { onMount } from 'svelte';
  import { supabase } from './lib/supabase';
  import type { Mascota, Cuidador } from './tipos';

  // Recibimos el estado de sesión y la función
  // para actualizar el listado después de guardar.
  let {
    sesionIniciada,
    alCrear
  }: {
    sesionIniciada: boolean;
    alCrear: () => Promise<void> | void;
  } = $props();

  type MascotaOpcion = Pick<Mascota, 'id' | 'nombre' | 'raza'>;
  type CuidadorOpcion = Pick<
    Cuidador,
    'id' | 'tarifa_diaria' | 'zona_cobertura'
  >;

  // Campos del formulario
  let clienteId = $state('');
  let mascotaId = $state('');
  let cuidadorId = $state('');
  let fechaInicio = $state('');
  let fechaFin = $state('');
  let totalSinSesion = $state('');

  // Estado de la interfaz
  let mascotas = $state<MascotaOpcion[]>([]);
  let cuidadores = $state<CuidadorOpcion[]>([]);
  let errores = $state<Record<string, string>>({});
  let mensaje = $state('');
  let guardando = $state(false);
  let cargandoOpciones = $state(false);

  // FASE 4: borrador por pestaña, no almacenado en Supabase.
  // No guardamos clienteId: con sesión se obtiene del perfil real.
  // Tampoco almacenamos credenciales ni tokens.
  const CLAVE_BORRADOR = 'patafiel.borradorSolicitud';
  const CAMPOS_BORRADOR = [
    'mascotaId',
    'cuidadorId',
    'fechaInicio',
    'fechaFin',
    'totalSinSesion'
  ] as const;

  type Borrador = Record<(typeof CAMPOS_BORRADOR)[number], string>;

  function guardarBorrador(evento: Event): void {
    const formulario = evento.currentTarget;
    if (!(formulario instanceof HTMLFormElement)) return;

    const datos = new FormData(formulario);
    const borrador = {} as Borrador;
    for (const campo of CAMPOS_BORRADOR) {
      borrador[campo] = String(datos.get(campo) ?? '');
    }

    try {
      sessionStorage.setItem(CLAVE_BORRADOR, JSON.stringify(borrador));
    } catch (error) {
      console.error('No se pudo guardar el borrador:', error);
    }
  }

  function recuperarBorrador(): void {
    const guardado = sessionStorage.getItem(CLAVE_BORRADOR);
    if (!guardado) return;

    try {
      const datos: unknown = JSON.parse(guardado);
      if (typeof datos !== 'object' || datos === null || Array.isArray(datos)) {
        throw new Error('El borrador tiene un formato inválido.');
      }
      const valores = datos as Record<string, unknown>;
      if (CAMPOS_BORRADOR.some(campo =>
        typeof valores[campo] !== 'string' ||
        (valores[campo] as string).length > 200
      )) {
        throw new Error('El borrador contiene valores inválidos.');
      }

      mascotaId = valores.mascotaId as string;
      cuidadorId = valores.cuidadorId as string;
      fechaInicio = valores.fechaInicio as string;
      fechaFin = valores.fechaFin as string;
      totalSinSesion = valores.totalSinSesion as string;
    } catch (error) {
      console.error('No se pudo recuperar el borrador:', error);
      sessionStorage.removeItem(CLAVE_BORRADOR);
    }
  }

  onMount(() => {
    recuperarBorrador();
  });

  // Cuando se inicia sesión cargamos las opciones reales.
  $effect(() => {
    if (sesionIniciada) {
      void cargarOpciones();
    } else {
      mascotas = [];
      cuidadores = [];
    }
  });

  async function cargarOpciones() {
    cargandoOpciones = true;
    const [perfil, resultadoMascotas, resultadoCuidadores] =
      await Promise.all([
        supabase.from('usuarios').select('id').single(),
        supabase.from('mascotas')
          .select('id, nombre, raza'),
        supabase.from('cuidadores')
          .select('id, tarifa_diaria, zona_cobertura')
          .eq('verificado', true)
      ]);

    cargandoOpciones = false;
    if (
      perfil.error ||
      resultadoMascotas.error ||
      resultadoCuidadores.error
    ) {
      mensaje = 'No se pudieron cargar las opciones de Supabase.';
      return;
    }

    clienteId = String(perfil.data.id);
    mascotas = resultadoMascotas.data ?? [];
    cuidadores = resultadoCuidadores.data ?? [];

    // Conservar la selección del borrador solo si sigue siendo válida.
    if (
      mascotas.length > 0 &&
      !mascotas.some(mascota => String(mascota.id) === mascotaId)
    ) {
      mascotaId = String(mascotas[0].id);
    }
    if (
      cuidadores.length > 0 &&
      !cuidadores.some(cuidador => String(cuidador.id) === cuidadorId)
    ) {
      cuidadorId = String(cuidadores[0].id);
    }
  }

  // Calcular días incluyendo la fecha inicial y final.
  let dias = $derived.by(() => {
    if (!fechaInicio || !fechaFin) return 0;

    const inicio = Date.parse(fechaInicio);
    const fin = Date.parse(fechaFin);

    if (!Number.isFinite(inicio) || !Number.isFinite(fin)) {
      return 0;
    }

    if (fin < inicio) return 0;

    return Math.round((fin - inicio) / 86400000) + 1;
  });
  let cuidadorElegido = $derived(
    cuidadores.find(c => c.id === Number(cuidadorId))
  );

  let totalCalculado = $derived(
    cuidadorElegido && dias > 0
      ? Math.round(dias * cuidadorElegido.tarifa_diaria * 100) / 100
      : 0
  );

  // Validamos antes de consultar Supabase.
  function validar(): boolean {
    const nuevos: Record<string, string> = {};
    if (!Number.isInteger(Number(clienteId)) ||
        Number(clienteId) <= 0) {
      nuevos.cliente = 'Debes indicar un cliente válido.';
    }

    if (!Number.isInteger(Number(mascotaId)) ||
        Number(mascotaId) <= 0) {
      nuevos.mascota = 'Debes seleccionar una mascota.';
    }

    if (!Number.isInteger(Number(cuidadorId)) ||
        Number(cuidadorId) <= 0) {
      nuevos.cuidador = 'Debes seleccionar un cuidador.';
    }
    if (!fechaInicio) {
      nuevos.inicio = 'La fecha de inicio es obligatoria.';
    }

    if (!fechaFin) {
      nuevos.fin = 'La fecha de fin es obligatoria.';
    } else if (fechaInicio && fechaFin < fechaInicio) {
      nuevos.fin =
        'La fecha de fin no puede ser anterior al inicio.';
    }

    const monto = sesionIniciada
      ? totalCalculado
      : Number(totalSinSesion);

    if (!Number.isFinite(monto) || monto <= 0) {
      nuevos.total = 'El total debe ser mayor que cero.';
    }
    errores = nuevos;

    return Object.keys(nuevos).length === 0;
  }

  async function crearSolicitud(event: SubmitEvent) {
    event.preventDefault();
    mensaje = '';

    // Si los datos son inválidos, terminamos aquí.
    // NO se envía ninguna petición de creación.
    if (!validar()) return;

    guardando = true;

    const monto = sesionIniciada
      ? totalCalculado
      : Number(totalSinSesion);

    try {
      const { error } = await supabase
        .from('solicitudes_cuidado')
        .insert({
          cliente_id: Number(clienteId),
          mascota_id: Number(mascotaId),
          cuidador_id: Number(cuidadorId),
          fecha_inicio: fechaInicio,
          fecha_fin: fechaFin,
          total_pagar: monto,
          estado: 'pendiente_pago'
        });

      if (error) {
        mensaje = sesionIniciada
          ? 'No se pudo guardar: ' + error.message
          : 'Supabase rechazó la creación sin sesión. ' +
            'Inicia sesión e inténtalo nuevamente.';
        return;
      }

      // Solo después de confirmar el INSERT quitamos el borrador.
      sessionStorage.removeItem(CLAVE_BORRADOR);
      mascotaId = '';
      cuidadorId = '';
      fechaInicio = '';
      fechaFin = '';
      totalSinSesion = '';
      errores = {};
      mensaje = 'Solicitud creada correctamente.';

      // Actualizar el listado sin convertir un error de refresco
      // en un segundo intento de creación.
      try {
        await alCrear();
      } catch (errorAlActualizar) {
        console.error('No se pudo actualizar el listado:', errorAlActualizar);
      }
    } catch (error) {
      console.error('Error al crear solicitud:', error);
      mensaje = 'Error de conexión. Se conservó el borrador.';
    } finally {
      guardando = false;
    }
  }
</script>

<section aria-labelledby="titulo-nuevo">
  <h2 id="titulo-nuevo">Nueva solicitud de cuidado</h2>
  <p>
    {sesionIniciada
      ? 'Completa los datos para crear una solicitud.'
      : 'Prueba de creación sin sesión.'}
  </p>

  <form onsubmit={crearSolicitud} oninput={guardarBorrador} onchange={guardarBorrador} novalidate>
    <label for="cliente">ID del cliente</label>
    <input
      id="cliente"
      type="text"
      inputmode="numeric"
      bind:value={clienteId}
      readonly={sesionIniciada}
      aria-invalid={Boolean(errores.cliente)}
    />
    {#if errores.cliente}
      <p class="mensaje-error" role="alert">{errores.cliente}</p>
    {/if}
    <label for="mascota">Mascota</label>
    {#if sesionIniciada}
      <select id="mascota" name="mascotaId" bind:value={mascotaId}>
        <option value="">Selecciona una mascota</option>
        {#each mascotas as mascota}
          <option value={String(mascota.id)}>
            {mascota.nombre} - {mascota.raza}
          </option>
        {/each}
      </select>
    {:else}
      <input
        id="mascota"
        name="mascotaId"
        type="text"
        inputmode="numeric"
        bind:value={mascotaId}
        placeholder="ID de la mascota, ejemplo: 1"
      />
    {/if}
    {#if errores.mascota}
      <p class="mensaje-error" role="alert">{errores.mascota}</p>
    {/if}
    <label for="cuidador">Cuidador</label>
    {#if sesionIniciada}
      <select id="cuidador" name="cuidadorId" bind:value={cuidadorId}>
        <option value="">Selecciona un cuidador</option>
        {#each cuidadores as cuidador}
          <option value={String(cuidador.id)}>
            Cuidador #{cuidador.id} - {cuidador.zona_cobertura}
            - ${cuidador.tarifa_diaria} por día
          </option>
        {/each}
      </select>
    {:else}
      <input
        id="cuidador"
        name="cuidadorId"
        type="text"
        inputmode="numeric"
        bind:value={cuidadorId}
        placeholder="ID del cuidador, ejemplo: 1"
      />
    {/if}
    {#if errores.cuidador}
      <p class="mensaje-error" role="alert">{errores.cuidador}</p>
    {/if}
    <label for="inicio">Fecha de inicio</label>
    <input
      id="inicio"
      name="fechaInicio"
      type="date"
      bind:value={fechaInicio}
    />
    {#if errores.inicio}
      <p class="mensaje-error" role="alert">{errores.inicio}</p>
    {/if}

    <label for="fin">Fecha de finalización</label>
    <input
      id="fin"
      name="fechaFin"
      type="date"
      bind:value={fechaFin}
    />
    {#if errores.fin}
      <p class="mensaje-error" role="alert">{errores.fin}</p>
    {/if}
    <label for="total">Total a pagar (USD)</label>
    {#if sesionIniciada}
      <input
        id="total"
        type="text"
        value={totalCalculado.toFixed(2)}
        readonly
      />
      <small>{dias} día(s) de cuidado</small>
    {:else}
      <input
        id="total"
        name="totalSinSesion"
        type="text"
        inputmode="decimal"
        bind:value={totalSinSesion}
        placeholder="Ejemplo: 46.50"
      />
    {/if}
    {#if errores.total}
      <p class="mensaje-error" role="alert">{errores.total}</p>
    {/if}
    <button
      type="submit"
      disabled={guardando || (sesionIniciada && cargandoOpciones)}
    >
      {guardando ? 'Guardando...' : 'Crear solicitud'}
    </button>
  </form>

  {#if mensaje}
    <p role="status">{mensaje}</p>
  {/if}
</section>

