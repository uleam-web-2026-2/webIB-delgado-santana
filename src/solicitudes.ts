
import type { EstadoSolicitud } from './tipos';

const URL_BASE = import.meta.env.VITE_SUPABASE_URL;
const CLAVE_PUBLICA = import.meta.env.VITE_SUPABASE_ANON_KEY;

interface FilaActualizada {
  id: number;
  estado: EstadoSolicitud;
}

export interface ResultadoCambio {
  codigo: number;
  filas: FilaActualizada[];
}

export async function cambiarEstadoSolicitud(
  id: number,
  nuevo: EstadoSolicitud,
  token: string
): Promise<ResultadoCambio> {
  const respuesta = await fetch(
    `${URL_BASE}/rest/v1/solicitudes_cuidado?id=eq.${id}`,
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
