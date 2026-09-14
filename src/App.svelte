HTML
<header>
  <p>Nombre de la aplicación : Mesa de Ayuda</p>
  <nav aria-label="Navegación principal">
    <ul>
      <li><a href="/tickets">Tickets</a></li>
      <li><a href="/clientes">Clientes</a></li>
      <li><a href="/reportes">Reportes</a></li>
    </ul>
  </nav>
  <a href="/tickets/nuevo">Nuevo ticket</a>
</header>

<main id="contenido-principal">
  <h1>Bandeja de tickets</h1>
  <p>Agente: Mariela Zambrano <span>6 tickets asignados</span></p>

  <section aria-labelledby="titulo-filtros">
    <h2 id="titulo-filtros">Filtros</h2>
    <form>
      <p>
        <label for="filtro-estado">Estado:</label>
        <select id="filtro-estado">
          <option value="todos">Todos</option>
          <option value="abierto">Abierto</option>
          <option value="en-progreso">En progreso</option>
          <option value="en-espera">En espera</option>
          <option value="resuelto">Resuelto</option>
          <option value="cerrado">Cerrado</option>
        </select>
      </p>

      <p>
        <label for="filtro-prioridad">Prioridad:</label>
        <select id="filtro-prioridad">
          <option value="todas">Todas</option>
          <option value="alta">Alta</option>
          <option value="media">Media</option>
          <option value="baja">Baja</option>
        </select>
      </p>

      <p>
        <label for="filtro-buscar">Buscar:</label>
        <input type="text" id="filtro-buscar" placeholder="Asunto o cliente" />
      </p>

      <button type="button">Aplicar filtros</button>
    </form>
  </section>

Abiertos: 2. En progreso: 2. En espera: 1 Resueltos: 1

N° | Asunto | Cliente | Estado | Prioridad | Última actualización | Acción
1041 | No puedo iniciar sesión en el portal | Comercial Vélez | Abierto | Alta | hace 20 min | Ver
1038 | La factura electrónica no llega al correo | Ferretería El Progreso | En progreso | Media | hace 2 h | Ver
1035 | Error al exportar el reporte mensual | Distribuidora Manabí | En espera | Media | ayer | Ver
1031 | Solicitud de un usuario adicional | Clínica San Rafael | Abierto | Baja | ayer | Ver
1027 | Lentitud al cargar el inventario | Comercial Vélez | En progreso | Alta | hace 3 días | Ver
1019 | Cambio de RUC en la cuenta | Panadería Doña Luz | Resuelto | Baja | hace 5 días | Ver

Mesa de Ayuda Proyecto docente 2026-2 - Última sincronización: hoy, 13:50