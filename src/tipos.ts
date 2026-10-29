
export type RolUsuario = 'cliente' | 'cuidador';

export type EstadoSolicitud =
  | 'pendiente_pago'
  | 'pago_por_verificar'
  | 'confirmada'
  | 'en_progreso'
  | 'completada'
  | 'cancelada';

export type EstadoPago =
  | 'pendiente'
  | 'aprobado'
  | 'rechazado';

export interface Usuario {
  id: number;
  auth_id: string | null;
  nombre: string;
  correo: string;
  telefono: string;
  rol: RolUsuario;
}

export interface Mascota {
  id: number;
  usuario_id: number;
  nombre: string;
  raza: string;
  edad_anios: number;
  observaciones: string | null;
}

export interface Cuidador {
  id: number;
  usuario_id: number;
  documento_identidad: string;
  tarifa_diaria: number;
  zona_cobertura: string;
  verificado: boolean;
}

export interface SolicitudDeCuidado {
  id: number;
  cliente_id: number;
  cuidador_id: number;
  mascota_id: number;
  fecha_inicio: string;
  fecha_fin: string;
  total_pagar: number;
  estado: EstadoSolicitud;
  creado: string;
}

export interface ComprobantePago {
  id: number;
  solicitud_id: number;
  numero_comprobante: string;
  archivo_url: string;
  estado_pago: EstadoPago;
  creado: string;
}
