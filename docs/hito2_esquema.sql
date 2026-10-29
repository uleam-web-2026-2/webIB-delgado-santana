-- TABLA 1: USUARIOS
-- Almacena los clientes y cuidadores de Patafiel.

CREATE TABLE IF NOT EXISTS public.usuarios (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    auth_id UUID UNIQUE REFERENCES auth.users(id),
    nombre TEXT NOT NULL,
    correo TEXT NOT NULL UNIQUE,
    telefono TEXT NOT NULL,
    rol TEXT NOT NULL CHECK (rol IN ('cliente', 'cuidador'))
);


-- TABLA 2: MASCOTAS
-- Cada mascota pertenece a un usuario.

CREATE TABLE IF NOT EXISTS public.mascotas (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_id BIGINT NOT NULL REFERENCES public.usuarios(id),
    nombre TEXT NOT NULL,
    raza TEXT NOT NULL,
    edad_anios INTEGER NOT NULL CHECK (edad_anios >= 0),
    observaciones TEXT
);


-- TABLA 3: CUIDADORES
-- Contiene los datos profesionales del cuidador.

CREATE TABLE IF NOT EXISTS public.cuidadores (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_id BIGINT NOT NULL UNIQUE REFERENCES public.usuarios(id),
    documento_identidad TEXT NOT NULL UNIQUE,
    tarifa_diaria NUMERIC(10,2) NOT NULL CHECK (tarifa_diaria >= 0),
    zona_cobertura TEXT NOT NULL,
    verificado BOOLEAN NOT NULL DEFAULT FALSE
);


-- TABLA 4: SOLICITUDES DE CUIDADO
-- Es la entidad principal de Patafiel.

CREATE TABLE IF NOT EXISTS public.solicitudes_cuidado (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id BIGINT NOT NULL REFERENCES public.usuarios(id),
    cuidador_id BIGINT NOT NULL REFERENCES public.cuidadores(id),
    mascota_id BIGINT NOT NULL REFERENCES public.mascotas(id),
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    total_pagar NUMERIC(10,2) NOT NULL CHECK (total_pagar > 0),
    estado TEXT NOT NULL DEFAULT 'pendiente_pago'
        CHECK (estado IN (
            'pendiente_pago',
            'pago_por_verificar',
            'confirmada',
            'en_progreso',
            'completada',
            'cancelada'
        )),
    creado TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fechas_validas CHECK (fecha_fin >= fecha_inicio)
);


-- TABLA 5: COMPROBANTES DE PAGO
-- Una solicitud puede tener varios comprobantes.

CREATE TABLE IF NOT EXISTS public.comprobantes_pago (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    solicitud_id BIGINT NOT NULL REFERENCES public.solicitudes_cuidado(id),
    numero_comprobante TEXT NOT NULL,
    archivo_url TEXT NOT NULL,
    estado_pago TEXT NOT NULL DEFAULT 'pendiente'
        CHECK (estado_pago IN (
            'pendiente',
            'aprobado',
            'rechazado'
        )),
    creado TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ACTIVAR LA SEGURIDAD EN LAS CINCO TABLAS

ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mascotas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cuidadores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.solicitudes_cuidado ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comprobantes_pago ENABLE ROW LEVEL SECURITY;

-- Retirar permisos automáticos de acceso desde la aplicación.
-- Más adelante concederemos solamente los permisos necesarios.

REVOKE ALL ON TABLE
    public.usuarios,
    public.mascotas,
    public.cuidadores,
    public.solicitudes_cuidado,
    public.comprobantes_pago
FROM anon, authenticated;


-- ========================================
-- PATAFIEL - SEGURIDAD HITO 2
-- ========================================

-- 1. Permisos SQL para usuarios autenticados

GRANT USAGE ON SCHEMA public TO authenticated;

GRANT SELECT ON
    public.usuarios,
    public.mascotas,
    public.cuidadores,
    public.solicitudes_cuidado,
    public.comprobantes_pago
TO authenticated;

GRANT INSERT ON public.solicitudes_cuidado
TO authenticated;


-- 2. Leer perfil propio

DROP POLICY IF EXISTS "Leer perfil propio"
ON public.usuarios;

CREATE POLICY "Leer perfil propio"
ON public.usuarios
FOR SELECT
TO authenticated
USING (
    auth_id = (SELECT auth.uid())
);


-- 3. Leer mascotas propias

DROP POLICY IF EXISTS "Leer mascotas propias"
ON public.mascotas;

CREATE POLICY "Leer mascotas propias"
ON public.mascotas
FOR SELECT
TO authenticated
USING (
    usuario_id IN (
        SELECT id
        FROM public.usuarios
        WHERE auth_id = (SELECT auth.uid())
    )
);


-- 4. Leer cuidadores verificados

DROP POLICY IF EXISTS "Leer cuidadores verificados"
ON public.cuidadores;

CREATE POLICY "Leer cuidadores verificados"
ON public.cuidadores
FOR SELECT
TO authenticated
USING (
    verificado = TRUE
);


-- 5. Leer solicitudes propias

DROP POLICY IF EXISTS "Leer solicitudes propias"
ON public.solicitudes_cuidado;

CREATE POLICY "Leer solicitudes propias"
ON public.solicitudes_cuidado
FOR SELECT
TO authenticated
USING (
    cliente_id IN (
        SELECT id
        FROM public.usuarios
        WHERE auth_id = (SELECT auth.uid())
          AND rol = 'cliente'
    )
);


-- 6. Leer comprobantes propios

DROP POLICY IF EXISTS "Leer comprobantes propios"
ON public.comprobantes_pago;

CREATE POLICY "Leer comprobantes propios"
ON public.comprobantes_pago
FOR SELECT
TO authenticated
USING (
    solicitud_id IN (
        SELECT id
        FROM public.solicitudes_cuidado
    )
);


-- 7. Crear solicitudes propias

DROP POLICY IF EXISTS "Crear solicitudes propias"
ON public.solicitudes_cuidado;

CREATE POLICY "Crear solicitudes propias"
ON public.solicitudes_cuidado
FOR INSERT
TO authenticated
WITH CHECK (
    estado = 'pendiente_pago'

    AND cliente_id IN (
        SELECT id
        FROM public.usuarios
        WHERE auth_id = (SELECT auth.uid())
          AND rol = 'cliente'
    )

    AND mascota_id IN (
        SELECT id
        FROM public.mascotas
        WHERE usuario_id = cliente_id
    )

    AND cuidador_id IN (
        SELECT id
        FROM public.cuidadores
        WHERE verificado = TRUE
    )
);
