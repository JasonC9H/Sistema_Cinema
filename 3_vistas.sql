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