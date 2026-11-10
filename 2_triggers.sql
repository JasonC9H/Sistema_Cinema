-- Trigger de Disponibilidad
CREATE OR REPLACE FUNCTION fn_validar_disponibilidad_asiento() RETURNS TRIGGER AS $$
DECLARE
    v_fila_max INT; v_col_max INT; v_asiento_ocupado INT;
BEGIN
    SELECT s.fila_maxima, s.columna_maxima INTO v_fila_max, v_col_max
    FROM FUNCION f JOIN SALA s ON f.id_sala = s.id_sala WHERE f.id_funcion = NEW.id_funcion;
    
    IF NEW.fila_asiento > v_fila_max OR NEW.columna_asiento > v_col_max THEN
        RAISE EXCEPTION 'Error Asiento fuera de dimensiones (Max: %, %).', v_fila_max, v_col_max;
    END IF;
    
    SELECT COUNT(*) INTO v_asiento_ocupado FROM BOLETO
    WHERE id_funcion = NEW.id_funcion AND fila_asiento = NEW.fila_asiento 
      AND columna_asiento = NEW.columna_asiento AND estado_asiento IN ('Vendido', 'Reservado');
      
    IF v_asiento_ocupado > 0 THEN
        RAISE EXCEPTION 'Concurrencia: Asiento ya ocupado.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_ValidarDisponibilidadAsiento
BEFORE INSERT ON BOLETO FOR EACH ROW EXECUTE FUNCTION fn_validar_disponibilidad_asiento();

-- Trigger de Aforo
CREATE OR REPLACE FUNCTION fn_actualizar_aforo() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE FUNCION SET asientos_disponibles = asientos_disponibles - 1 WHERE id_funcion = NEW.id_funcion;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE FUNCION SET asientos_disponibles = asientos_disponibles + 1 WHERE id_funcion = OLD.id_funcion;
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_ActualizarAforoFuncion
AFTER INSERT OR DELETE ON BOLETO FOR EACH ROW EXECUTE FUNCTION fn_actualizar_aforo();

-- Trigger de Total Venta
CREATE OR REPLACE FUNCTION fn_actualizar_total_venta() RETURNS TRIGGER AS $$
DECLARE
    v_id_venta INT;
BEGIN
    IF TG_OP = 'DELETE' THEN v_id_venta := OLD.id_venta; ELSE v_id_venta := NEW.id_venta; END IF;
    
    UPDATE VENTA SET total_pagado = COALESCE((SELECT SUM(precio_unitario) FROM BOLETO WHERE id_venta = v_id_venta), 0)
    WHERE id_venta = v_id_venta;
    
    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TR_ActualizarTotalVenta
AFTER INSERT OR UPDATE OR DELETE ON BOLETO FOR EACH ROW EXECUTE FUNCTION fn_actualizar_total_venta();