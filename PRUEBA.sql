CREATE TABLE PELICULA (
    id_pelicula SERIAL PRIMARY KEY,
    titulo VARCHAR(150) NOT NULL,
    clasificacion_edad VARCHAR(5) CHECK (clasificacion_edad IN ('TE', '+12', '+15', '+18')),
    duracion_minutos INT CHECK (duracion_minutos > 0),
    genero VARCHAR(50) NOT NULL,
    distribuidora VARCHAR(100) NOT NULL,
    estado VARCHAR(20) CHECK (estado IN ('Cartelera', 'Proximamente', 'Retirada'))
);

CREATE TABLE SALA (
    id_sala SERIAL PRIMARY KEY,
    numero_sala INT UNIQUE NOT NULL,
    capacidad_asientos INT CHECK (capacidad_asientos > 0),
    tipo_sala VARCHAR(10) CHECK (tipo_sala IN ('2D', '3D', 'IMAX')),
    fila_maxima INT NOT NULL CHECK (fila_maxima > 0),
    columna_maxima INT NOT NULL CHECK (columna_maxima > 0)
);

CREATE TABLE FUNCION (
    id_funcion SERIAL PRIMARY KEY,
    id_pelicula INT REFERENCES PELICULA(id_pelicula) ON DELETE CASCADE,
    id_sala INT REFERENCES SALA(id_sala) ON DELETE CASCADE,
    fecha_hora_inicio TIMESTAMP NOT NULL,
    fecha_hora_fin TIMESTAMP NOT NULL,
    precio_base DECIMAL(10,2) CHECK (precio_base >= 0),
    asientos_disponibles INT CHECK (asientos_disponibles >= 0),
    CONSTRAINT chk_fechas CHECK (fecha_hora_fin > fecha_hora_inicio)
);

CREATE TABLE CLIENTE (
    id_cliente SERIAL PRIMARY KEY,
    documento_identidad VARCHAR(20) UNIQUE NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    puntos_fidelidad INT DEFAULT 0 CHECK (puntos_fidelidad >= 0)
);

CREATE TABLE VENTA (
    id_venta SERIAL PRIMARY KEY,
    id_cliente INT REFERENCES CLIENTE(id_cliente) ON DELETE CASCADE,
    codigo_factura VARCHAR(50) UNIQUE NOT NULL,
    fecha_hora_venta TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_pagado DECIMAL(10,2) DEFAULT 0 CHECK (total_pagado >= 0),
    metodo_pago VARCHAR(20) CHECK (metodo_pago IN ('Tarjeta', 'Efectivo', 'Puntos'))
);

CREATE TABLE BOLETO (
    id_boleto SERIAL PRIMARY KEY,
    id_venta INT REFERENCES VENTA(id_venta) ON DELETE CASCADE,
    id_funcion INT REFERENCES FUNCION(id_funcion) ON DELETE CASCADE,
    fila_asiento INT NOT NULL CHECK (fila_asiento > 0),
    columna_asiento INT NOT NULL CHECK (columna_asiento > 0),
    precio_unitario DECIMAL(10,2) CHECK (precio_unitario >= 0),
    estado_asiento VARCHAR(20) CHECK (estado_asiento IN ('Vendido', 'Reservado', 'Cancelado'))
);

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
        RAISE EXCEPTION 'Concurrencia Asiento ya ocupado.';
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

CREATE VIEW V_CarteleraVigente AS
SELECT p.titulo, p.clasificacion_edad, p.duracion_minutos, s.numero_sala, s.tipo_sala, f.fecha_hora_inicio,
       ROUND(((s.capacidad_asientos - f.asientos_disponibles)::DECIMAL / s.capacidad_asientos) * 100, 2) AS porcentaje_ocupacion
FROM FUNCION f
JOIN PELICULA p ON f.id_pelicula = p.id_pelicula
JOIN SALA s ON f.id_sala = s.id_sala
WHERE p.estado = 'Cartelera' AND f.fecha_hora_inicio > CURRENT_TIMESTAMP;

CREATE VIEW V_RecaudacionPorPelicula AS
SELECT p.titulo, COUNT(b.id_boleto) AS total_boletos_vendidos, COALESCE(SUM(b.precio_unitario), 0) AS recaudacion_monetaria,
       ROUND(COUNT(b.id_boleto)::DECIMAL / NULLIF(COUNT(DISTINCT f.id_funcion), 0), 2) AS promedio_asistentes_por_funcion
FROM PELICULA p
LEFT JOIN FUNCION f ON p.id_pelicula = f.id_pelicula
LEFT JOIN BOLETO b ON f.id_funcion = b.id_funcion AND b.estado_asiento = 'Vendido'
WHERE EXTRACT(MONTH FROM f.fecha_hora_inicio) = EXTRACT(MONTH FROM CURRENT_DATE)
GROUP BY p.id_pelicula, p.titulo;

CREATE VIEW V_HistorialComprasCliente AS
SELECT c.documento_identidad, c.nombres, c.apellidos, v.codigo_factura, v.fecha_hora_venta,
       p.titulo AS pelicula, s.numero_sala AS sala, b.fila_asiento, b.columna_asiento, b.precio_unitario AS monto_pagado
FROM CLIENTE c
JOIN VENTA v ON c.id_cliente = v.id_cliente JOIN BOLETO b ON v.id_venta = b.id_venta
JOIN FUNCION f ON b.id_funcion = f.id_funcion JOIN PELICULA p ON f.id_pelicula = p.id_pelicula JOIN SALA s ON f.id_sala = s.id_sala
ORDER BY c.documento_identidad, v.fecha_hora_venta DESC;

-- Insertar 10 Peliculas
INSERT INTO PELICULA (titulo, clasificacion_edad, duracion_minutos, genero, distribuidora, estado) VALUES
('Inception', '+12', 148, 'Ciencia Ficción', 'Warner', 'Cartelera'),
('Dune 2', '+12', 166, 'Ficción', 'Legendary', 'Cartelera'),
('Avatar 3', '+12', 190, 'Ficción', 'Disney', 'Proximamente'),
('Deadpool & Wolverine', '+15', 127, 'Acción', 'Marvel', 'Cartelera'),
('Intensamente 2', 'TE', 96, 'Animación', 'Pixar', 'Cartelera'),
('Gladiador 2', '+18', 150, 'Épico', 'Paramount', 'Proximamente'),
('El Padrino', '+18', 175, 'Drama', 'Paramount', 'Retirada'),
('Spider-Man', '+12', 140, 'Acción', 'Sony', 'Cartelera'),
('Super Mario Bros', 'TE', 92, 'Animación', 'Illumination', 'Retirada'),
('Oppenheimer', '+15', 180, 'Drama', 'Universal', 'Cartelera');

-- Insertar 10 Salas
INSERT INTO SALA (numero_sala, capacidad_asientos, tipo_sala, fila_maxima, columna_maxima) VALUES
(1, 100, 'IMAX', 10, 10),
(2, 50, '2D', 5, 10),
(3, 60, '3D', 6, 10),
(4, 50, '2D', 5, 10),
(5, 80, '3D', 8, 10),
(6, 100, 'IMAX', 10, 10),
(7, 40, '2D', 4, 10),
(8, 50, '2D', 5, 10),
(9, 70, '3D', 7, 10),
(10, 120, 'IMAX', 12, 10);

-- Insertar 10 Funciones
INSERT INTO FUNCION (id_pelicula, id_sala, fecha_hora_inicio, fecha_hora_fin, precio_base, asientos_disponibles) VALUES
(1, 1, '2026-12-01 18:00:00', '2026-12-01 20:30:00', 25000, 100),
(2, 2, '2026-12-01 21:00:00', '2026-12-01 23:50:00', 18000, 50),
(4, 3, '2026-12-02 15:00:00', '2026-12-02 17:10:00', 20000, 60),
(5, 4, '2026-12-02 10:00:00', '2026-12-02 11:40:00', 15000, 50),
(8, 5, '2026-12-03 19:00:00', '2026-12-03 21:20:00', 20000, 80),
(10, 6, '2026-12-03 20:00:00', '2026-12-03 23:00:00', 25000, 100),
(1, 7, '2026-12-04 14:00:00', '2026-12-04 16:30:00', 15000, 40),
(2, 8, '2026-12-04 17:00:00', '2026-12-04 19:50:00', 18000, 50),
(4, 9, '2026-12-05 20:00:00', '2026-12-05 22:10:00', 20000, 70),
(5, 10, '2026-12-05 16:00:00', '2026-12-05 17:40:00', 25000, 120);

-- Insertar 10 Clientes
INSERT INTO CLIENTE (documento_identidad, nombres, apellidos, email, telefono) VALUES
('1001', 'Juan', 'Perez', 'juan@email.com', '300111'),
('1002', 'Maria', 'Gomez', 'maria@email.com', '300222'),
('1003', 'Carlos', 'Ruiz', 'carlos@email.com', '300333'),
('1004', 'Ana', 'Lopez', 'ana@email.com', '300444'),
('1005', 'Luis', 'Diaz', 'luis@email.com', '300555'),
('1006', 'Jorge', 'Mendez', 'jorge@email.com', '300666'),
('1007', 'Laura', 'Soto', 'laura@email.com', '300777'),
('1008', 'Diana', 'Rojas', 'diana@email.com', '300888'),
('1009', 'Pedro', 'Vega', 'pedro@email.com', '300999'),
('1010', 'Sofia', 'Luna', 'sofia@email.com', '300000');

-- Insertar 10 Ventas (Total 0 por ahora, el trigger lo actualizará)
INSERT INTO VENTA (id_cliente, codigo_factura, metodo_pago) VALUES
(1, 'FAC-001', 'Tarjeta'),
(2, 'FAC-002', 'Efectivo'),
(3, 'FAC-003', 'Tarjeta'),
(4, 'FAC-004', 'Puntos'),
(5, 'FAC-005', 'Efectivo'),
(6, 'FAC-006', 'Tarjeta'),
(7, 'FAC-007', 'Efectivo'),
(8, 'FAC-008', 'Tarjeta'),
(9, 'FAC-009', 'Efectivo'),
(10, 'FAC-010', 'Tarjeta');

-- Insertar 10 Boletos (Prueba de Trigger de Total Venta y Aforo)
INSERT INTO BOLETO (id_venta, id_funcion, fila_asiento, columna_asiento, precio_unitario, estado_asiento) VALUES
(1, 1, 5, 5, 25000.00, 'Vendido'),
(2, 2, 3, 4, 18000.00, 'Vendido'),
(3, 3, 4, 6, 20000.00, 'Vendido'),
(4, 4, 2, 2, 15000.00, 'Reservado'),
(5, 5, 7, 8, 20000.00, 'Vendido'),
(6, 6, 9, 9, 25000.00, 'Vendido'),
(7, 7, 1, 1, 15000.00, 'Vendido'),
(8, 8, 4, 5, 18000.00, 'Reservado'),
(9, 9, 6, 7, 20000.00, 'Vendido'),
(10, 10, 10, 5, 25000.00, 'Vendido');

-- SCRIPT DE VALIDACION

-- Prueba: Violacion de Concurrencia (Doble Reserva en la misma silla)
-- INSERT INTO BOLETO (id_venta, id_funcion, fila_asiento, columna_asiento, precio_unitario, estado_asiento) 
-- VALUES (1, 1, 5, 5, 25000.00, 'Vendido'); 

-- Prueba: Violacion de Dimensiones (Fila 12 en Sala 1 que tiene max 10)
-- INSERT INTO BOLETO (id_venta, id_funcion, fila_asiento, columna_asiento, precio_unitario, estado_asiento) 
-- VALUES (2, 1, 12, 5, 25000.00, 'Vendido');


-- Tablas
SELECT * FROM FUNCION;
SELECT * FROM VENTA;

-- Reportes
SELECT * FROM V_CarteleraVigente;
SELECT * FROM V_RecaudacionPorPelicula;
SELECT * FROM V_HistorialComprasCliente;