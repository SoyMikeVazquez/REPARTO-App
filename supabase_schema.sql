-- 1. Habilitar la extensión de PostGIS (Opcional, pero muy útil para cálculos de < 6km si usas geometrías)
-- CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. Tipo Enum para Roles
CREATE TYPE user_role AS ENUM ('cliente', 'repartidor', 'broker', 'restaurante');

-- 3. Tipo Enum para Estatus de Pedido
CREATE TYPE order_status AS ENUM ('pendiente', 'preparando', 'listo_para_entregar', 'en_camino', 'entregado', 'cancelado');


-- ==========================================
-- TABLA: profiles
-- ==========================================
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    phone TEXT,
    role user_role NOT NULL DEFAULT 'cliente',
    broker_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL, -- El broker asignado al repartidor
    commission_rate DECIMAL(5,2) DEFAULT 0.00, -- Ej. 15.00 para 15%
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habilitar RLS (Seguridad de Nivel de Fila)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Políticas de Profiles: Un usuario puede ver su propio perfil.
CREATE POLICY "Users can view own profile" 
ON public.profiles FOR SELECT USING (auth.uid() = id);

-- Políticas de Profiles: Un broker puede ver a sus repartidores.
CREATE POLICY "Brokers can view their couriers" 
ON public.profiles FOR SELECT USING (auth.uid() = broker_id);


-- ==========================================
-- TABLA: orders
-- ==========================================
CREATE TABLE public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID NOT NULL REFERENCES public.profiles(id),
    client_id UUID NOT NULL REFERENCES public.profiles(id),
    driver_id UUID REFERENCES public.profiles(id), -- Null si aún no lo toma un repartidor
    status order_status NOT NULL DEFAULT 'pendiente',
    delivery_lat DOUBLE PRECISION NOT NULL,
    delivery_lng DOUBLE PRECISION NOT NULL,
    driver_current_lat DOUBLE PRECISION,
    driver_current_lng DOUBLE PRECISION,
    total_amount DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Los clientes pueden ver sus propias órdenes
CREATE POLICY "Clients can view their own orders" 
ON public.orders FOR SELECT USING (auth.uid() = client_id);

-- Los repartidores pueden ver órdenes 'listo_para_entregar' O aquellas donde ellos son el driver_id
CREATE POLICY "Drivers can view available and own orders" 
ON public.orders FOR SELECT 
USING (
    status = 'listo_para_entregar' 
    OR driver_id = auth.uid()
);

-- Los repartidores pueden actualizar órdenes que han aceptado
CREATE POLICY "Drivers can update their own orders" 
ON public.orders FOR UPDATE 
USING (driver_id = auth.uid());


-- ==========================================
-- TABLA: driver_sessions
-- ==========================================
CREATE TABLE public.driver_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    session_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    session_end TIMESTAMPTZ,
    last_known_lat DOUBLE PRECISION,
    last_known_lng DOUBLE PRECISION,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.driver_sessions ENABLE ROW LEVEL SECURITY;

-- Repartidor ve sus sesiones
CREATE POLICY "Drivers can view their sessions" 
ON public.driver_sessions FOR SELECT USING (auth.uid() = driver_id);
CREATE POLICY "Drivers can update their sessions" 
ON public.driver_sessions FOR UPDATE USING (auth.uid() = driver_id);


-- ==========================================
-- TABLA: finances
-- ==========================================
CREATE TABLE public.finances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id),
    driver_id UUID NOT NULL REFERENCES public.profiles(id),
    broker_id UUID REFERENCES public.profiles(id),
    total_charged DECIMAL(10,2) NOT NULL,
    driver_earnings DECIMAL(10,2) NOT NULL,
    broker_commission DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.finances ENABLE ROW LEVEL SECURITY;

-- Cada quien puede ver su lado de las finanzas
CREATE POLICY "Drivers can view own finances" 
ON public.finances FOR SELECT USING (auth.uid() = driver_id);

CREATE POLICY "Brokers can view own finances" 
ON public.finances FOR SELECT USING (auth.uid() = broker_id);


-- ==========================================
-- TRIGGERS DE AUTH Y UPDATED_AT
-- ==========================================

-- Trigger para crear Profile automáticamente al registrar usuario
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, phone, role)
  VALUES (new.id, new.phone, 'cliente'); -- Por defecto se crean como cliente, el broker puede cambiarlo.
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Trigger para actualizar updated_at
CREATE OR REPLACE FUNCTION public.set_current_timestamp_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE PROCEDURE public.set_current_timestamp_updated_at();

CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.set_current_timestamp_updated_at();


-- ==========================================
-- FUNCIÓN: nearby_ready_orders (Filtro < 6km)
-- ==========================================
-- Utiliza la fórmula de Haversine para encontrar órdenes listas a menos de un radio en kilómetros.
CREATE OR REPLACE FUNCTION public.nearby_ready_orders(
  driver_lat DOUBLE PRECISION,
  driver_lng DOUBLE PRECISION,
  radius_km DOUBLE PRECISION DEFAULT 6.0
)
RETURNS SETOF public.orders
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT *
  FROM public.orders
  WHERE status = 'listo_para_entregar'
  AND (
    6371 * acos(
      cos(radians(driver_lat)) * cos(radians(delivery_lat)) *
      cos(radians(delivery_lng) - radians(driver_lng)) +
      sin(radians(driver_lat)) * sin(radians(delivery_lat))
    )
  ) <= radius_km;
$$;
