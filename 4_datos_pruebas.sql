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