
import { createClient } from '@supabase/supabase-js';

// Dirección del proyecto en Supabase
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;

// Clave pública para conectarnos a Supabase
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

// Creamos y exportamos el cliente de Supabase
export const supabase = createClient(supabaseUrl, supabaseKey);
