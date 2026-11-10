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