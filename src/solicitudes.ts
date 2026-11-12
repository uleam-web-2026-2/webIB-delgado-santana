
import type { EstadoSolicitud } from './tipos';

const URL_BASE: string = import.meta.env.VITE_SUPABASE_URL;
const CLAVE_PUBLICA: string = import.meta.env.VITE_SUPABASE_ANON_KEY;

interface FilaActualizada {
  id: number;
  estado: EstadoSolicitud;
}

export interface ResultadoCambio {
  codigo: number;
  filas: FilaActualizada[];
}

// Fase 5: el estadoEsperado se valida en la propia sentencia UPDATE
// realizada por PostgREST, no con una consulta previa separada.
export async function cambiarEstadoSolicitud(
  id: number,
  nuevo: EstadoSolicitud,
  estadoEsperado: EstadoSolicitud,
  token: string
): Promise<ResultadoCambio> {
  const parametros = new URLSearchParams({
    id: `eq.${id}`,
    estado: `eq.${estadoEsperado}`,
    select: 'id,estado'
  });

  const respuesta = await fetch(
    `${URL_BASE}/rest/v1/solicitudes_cuidado?${parametros.toString()}`,
    {
      method: 'PATCH',
      headers: {
        apikey: CLAVE_PUBLICA,
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        Prefer: 'return=representation'
      },
      body: JSON.stringify({ estado: nuevo })
    }
  );

  const filas: FilaActualizada[] = respuesta.ok
    ? await respuesta.json()
    : [];

  return {
    codigo: respuesta.status,
    filas
  };
}
