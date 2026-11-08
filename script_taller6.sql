-- TALLER 6 | SISTEMA DE GESTION DE EVENTOS | PostgreSQL 16
-- SCRIPT AUTOCONTENIDO: esquema + datos de ejemplo + preparacion funcional
-- heredada del Taller 5 + roles, usuarios, permisos y 12 funciones del Taller 6.
-- Ejecutar UNA SOLA VEZ en una BASE DE DATOS VACIA, como postgres/administrador.
-- No ejecutar sobre la base con datos/capturas: no borra objetos preexistentes.
-- Los roles son globales al cluster: requiere que los nombres indicados no existan.
-- Cambiar las contrasenas de demostracion antes de instalar fuera de un entorno local.
-- Las llamadas SELECT de prueba se ejecutan al final, DESPUES del COMMIT.
-- Los cambios de las pruebas se revierten con ROLLBACK; instalacion y roles persisten.
-- Una unica transaccion: si falla una instruccion, hacer ROLLBACK y corregir la causa.
BEGIN;

-- Precondiciones: impedir que una instalacion accidental mezcle datos o roles ajenos.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_catalog.pg_class c
        JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
    ) OR EXISTS (
        SELECT 1 FROM pg_catalog.pg_proc p
        JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public'
    ) THEN
        RAISE EXCEPTION 'La base debe estar vacia: el esquema public ya contiene objetos';
    END IF;
    IF EXISTS (
        SELECT 1 FROM pg_catalog.pg_roles
        WHERE rolname IN ('rol_admin', 'rol_operador', 'rol_finanzas',
                          'rol_marketing', 'rol_auditor', 'usuario_admin',
                          'usuario_caja', 'usuario_reportes',
                          'usuario_marketing', 'usuario_auditoria')
    ) THEN
        RAISE EXCEPTION 'Ya existen roles del Taller 6 en este cluster; no ejecutar nuevamente';
    END IF;
END;
$$;

-- =============================================================
-- PARTE 1. ESQUEMA Y DATOS INICIALES (11 tablas, 40 filas cada una)
-- =============================================================

-- =====================================================
-- 1. TABLAS INDEPENDIENTES (NIVEL 1)
-- =====================================================

CREATE TABLE Organizador (
    id_organizador SERIAL PRIMARY KEY,
    rut_organizador VARCHAR(12) UNIQUE NOT NULL,
    nombre_empresa VARCHAR(150) NOT NULL,
    correo VARCHAR(100) UNIQUE NOT NULL,
    telefono VARCHAR(15) NOT NULL
);

CREATE TABLE Recinto (
    id_recinto SERIAL PRIMARY KEY,
    nombre_recinto VARCHAR(100) NOT NULL,
    direccion VARCHAR(150) NOT NULL,
    ciudad VARCHAR(50) NOT NULL,
    capacidad INTEGER NOT NULL CHECK (capacidad > 0)
);

CREATE TABLE Proveedor (
    id_proveedor SERIAL PRIMARY KEY,
    rut_proveedor VARCHAR(12) UNIQUE NOT NULL,
    nombre_empresa VARCHAR(150) NOT NULL,
    rubro VARCHAR(50) NOT NULL,
    telefono VARCHAR(15) NOT NULL
);

CREATE TABLE Artista (
    id_artista SERIAL PRIMARY KEY,
    nombre_artista VARCHAR(100) NOT NULL
);

CREATE TABLE Asistente (
    id_asistente SERIAL PRIMARY KEY,
    rut_asistente VARCHAR(12) UNIQUE NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    correo VARCHAR(100) UNIQUE NOT NULL
);

-- =====================================================
-- 2. TABLAS DEPENDIENTES (NIVEL 2)
-- =====================================================

CREATE TABLE Evento (
    id_evento SERIAL PRIMARY KEY,
    id_organizador INTEGER NOT NULL,
    id_recinto INTEGER NOT NULL,
    nombre_evento VARCHAR(150) NOT NULL,
    tipo_evento VARCHAR(50) NOT NULL,
    fecha DATE NOT NULL,
    FOREIGN KEY (id_organizador) REFERENCES Organizador(id_organizador),
    FOREIGN KEY (id_recinto) REFERENCES Recinto(id_recinto)
);

CREATE TABLE Tipo_entrada (
    id_entrada SERIAL PRIMARY KEY,
    id_evento INTEGER NOT NULL,
    nombre_zona VARCHAR(50) NOT NULL,
    precio INTEGER NOT NULL CHECK (precio >= 0),
    capacidad INTEGER NOT NULL CHECK (capacidad > 0),
    FOREIGN KEY (id_evento) REFERENCES Evento(id_evento)
);

-- =====================================================
-- 3. RELACIONES N:M Y TABLAS TRANSACCIONALES (NIVEL 3)
-- =====================================================

CREATE TABLE Contrata (
    id_proveedor INTEGER NOT NULL,
    id_evento INTEGER NOT NULL,
    PRIMARY KEY (id_proveedor, id_evento),
    FOREIGN KEY (id_proveedor) REFERENCES Proveedor(id_proveedor),
    FOREIGN KEY (id_evento) REFERENCES Evento(id_evento)
);

CREATE TABLE Participa (
    id_artista INTEGER NOT NULL,
    id_evento INTEGER NOT NULL,
    fecha_presentacion DATE NOT NULL,
    PRIMARY KEY (id_artista, id_evento),
    FOREIGN KEY (id_artista) REFERENCES Artista(id_artista),
    FOREIGN KEY (id_evento) REFERENCES Evento(id_evento)
);

CREATE TABLE Compra (
    id_compra SERIAL PRIMARY KEY,
    id_asistente INTEGER NOT NULL,
    id_entrada INTEGER NOT NULL,
    fecha_creacion TIMESTAMP NOT NULL,
    fecha_expiracion TIMESTAMP NOT NULL,
    estado_compra VARCHAR(30) NOT NULL,
    fecha_compra TIMESTAMP,
    monto_total INTEGER NOT NULL CHECK (monto_total >= 0),
    metodo_pago VARCHAR(50),
    FOREIGN KEY (id_asistente) REFERENCES Asistente(id_asistente),
    FOREIGN KEY (id_entrada) REFERENCES Tipo_entrada(id_entrada)
);

CREATE TABLE Ticket (
    id_ticket SERIAL PRIMARY KEY,
    id_compra INTEGER NOT NULL,
    codigo_qr VARCHAR(255) UNIQUE NOT NULL,
    estado VARCHAR(30) NOT NULL,
    FOREIGN KEY (id_compra) REFERENCES Compra(id_compra)
);




-- =====================================================
-- 1. INSERTAR 40 ARTISTAS
-- =====================================================
INSERT INTO Artista (nombre_artista) VALUES
('Los Bunkers'), ('Mon Laferte'), ('Los Tres'), ('Chancho en Piedra'), ('La Ley'),
('Lucybell'), ('Kudai'), ('Cami'), ('Gepe'), ('Javiera Mena'),
('Ana Tijoux'), ('Francisca Valenzuela'), ('Princesa Alba'), ('Paloma Mami'), ('Polimá Westcoast'),
('Pailita'), ('Cris MJ'), ('Marcianeke'), ('Young Cister'), ('Galee Galee'),
('Los Jaivas'), ('Illapu'), ('Inti-Illimani'), ('Quilapayún'), ('Congreso'),
('Victor Jara'), ('Violeta Parra'), ('Joe Vasconcellos'), ('Manuel García'), ('Nano Stern'),
('Camila Gallardo'), ('Denise Rosenthal'), ('C-Funk'), ('Pedropiedra'), ('Alex Anwandter'),
('Beto Cuevas'), ('Nicole'), ('Américo'), ('Noche de Brujas'), ('Santaferia');

-- =====================================================
-- 2. INSERTAR 40 RECINTOS
-- =====================================================
INSERT INTO Recinto (nombre_recinto, direccion, ciudad, capacidad) VALUES
('Movistar Arena', 'Parque O''Higgins s/n', 'Santiago', 15000),
('Teatro Caupolicán', 'San Diego 850', 'Santiago', 4500),
('Quinta Vergara', 'Errázuriz 596', 'Viña del Mar', 15000),
('Estadio Nacional', 'Av. Grecia 2001', 'Santiago', 50000),
('Estadio Monumental', 'Av. Marathon 5300', 'Santiago', 47000),
('Teatro Coliseo', 'Nataniel Cox 59', 'Santiago', 2500),
('Club Chocolate', 'Ernesto Pinto Lagarrigue 192', 'Santiago', 1000),
('Blondie', 'Alameda 2879', 'Santiago', 1500),
('Teatro Cariola', 'San Diego 246', 'Santiago', 1200),
('Estadio Bicentenario', 'Enrique Olivares 1003', 'Santiago', 12000),
('Arena Puerto Montt', 'Egaña 1151', 'Puerto Montt', 5000),
('SurActivo', 'Autopista Concepción-Talcahuano 8590', 'Concepción', 3000),
('Gimnasio Municipal', 'Collao 480', 'Concepción', 2000),
('Teatro UdeC', 'O''Higgins 650', 'Concepción', 1200),
('Espacio Riesco', 'Av. El Salto 5000', 'Santiago', 10000),
('Centro Cultural Estación Mapocho', 'Plaza de la Cultura s/n', 'Santiago', 5000),
('Teatro Teletón', 'Mario Kreutzberger 1531', 'Santiago', 1000),
('Estadio Sausalito', 'Av. Sausalito s/n', 'Viña del Mar', 22000),
('Estadio Elías Figueroa', 'Subida Carvallo s/n', 'Valparaíso', 20000),
('Teatro Municipal', 'Agustinas 794', 'Santiago', 1500),
('Matucana 100', 'Matucana 100', 'Santiago', 800),
('Centro de Eventos Basel', 'Mall Barrio Independencia', 'Santiago', 1500),
('Arena Monticello', 'Panamericana Sur Km 57', 'San Francisco de Mostazal', 4000),
('Teatro Regional', 'Millán 342', 'Rancagua', 1000),
('Casino Enjoy', 'Av. San Martín 199', 'Viña del Mar', 1200),
('Teatro del Lago', 'Av. Philippi 1000', 'Frutillar', 1189),
('Estadio Regional', 'Av. Angamos s/n', 'Antofagasta', 21000),
('Sokol', 'Esmeralda 2116', 'Antofagasta', 1500),
('CasaPiedra', 'Av. San Josemaría Escrivá de Balaguer 5600', 'Santiago', 4000),
('Estadio La Portada', 'Av. Balmaceda s/n', 'La Serena', 10000),
('Coliseo Monumental', 'Av. Estadio s/n', 'La Serena', 4000),
('Teatro Centenario', 'Cordovez 391', 'La Serena', 600),
('Estadio Tierra de Campeones', 'Av. Salvador Allende s/n', 'Iquique', 13000),
('Casino Dreams', 'Arturo Prat 2755', 'Iquique', 1000),
('Gimnasio UFRO', 'Uruguay 1720', 'Temuco', 2500),
('Teatro Municipal Temuco', 'Pablo Neruda 01380', 'Temuco', 1000),
('Estadio Germán Becker', 'Av. Pablo Neruda 1110', 'Temuco', 18000),
('Estadio Chinquihue', 'Pelluco s/n', 'Puerto Montt', 10000),
('Teatro Diego Rivera', 'Quillota 116', 'Puerto Montt', 800),
('Centro de Eventos K', 'Ruta 5 Sur Km 10', 'Chillán', 1500);

-- =====================================================
-- 3. INSERTAR 40 ORGANIZADORES
-- =====================================================
INSERT INTO Organizador (rut_organizador, nombre_empresa, correo, telefono) VALUES
('76000001-1', 'Bizarro Live Entertainment', 'contacto@bizarro.cl', '+56911111111'),
('76000002-2', 'Lotus Producciones', 'info@lotus.cl', '+56922222222'),
('76000003-3', 'DG Medios', 'ayuda@dgmedios.com', '+56933333333'),
('76000004-4', 'Transistor', 'contacto@transistor.cl', '+56944444444'),
('76000005-5', 'Fauna Producciones', 'info@fauna.cl', '+56955555555'),
('76000006-6', 'Fenix Entertainment', 'contacto@fenix.cl', '+56966666666'),
('76000007-7', 'Cultura Capital', 'hola@culturacapital.cl', '+56977777777'),
('76000008-8', 'Swing Management', 'contacto@swing.cl', '+56988888888'),
('76000009-9', 'La Oreja', 'info@laoreja.cl', '+56999999999'),
('76000010-0', 'Productora 10', 'prod10@empresa.cl', '+56900000010'),
('76000011-1', 'Productora 11', 'prod11@empresa.cl', '+56900000011'),
('76000012-2', 'Productora 12', 'prod12@empresa.cl', '+56900000012'),
('76000013-3', 'Productora 13', 'prod13@empresa.cl', '+56900000013'),
('76000014-4', 'Productora 14', 'prod14@empresa.cl', '+56900000014'),
('76000015-5', 'Productora 15', 'prod15@empresa.cl', '+56900000015'),
('76000016-6', 'Productora 16', 'prod16@empresa.cl', '+56900000016'),
('76000017-7', 'Productora 17', 'prod17@empresa.cl', '+56900000017'),
('76000018-8', 'Productora 18', 'prod18@empresa.cl', '+56900000018'),
('76000019-9', 'Productora 19', 'prod19@empresa.cl', '+56900000019'),
('76000020-0', 'Productora 20', 'prod20@empresa.cl', '+56900000020'),
('76000021-1', 'Productora 21', 'prod21@empresa.cl', '+56900000021'),
('76000022-2', 'Productora 22', 'prod22@empresa.cl', '+56900000022'),
('76000023-3', 'Productora 23', 'prod23@empresa.cl', '+56900000023'),
('76000024-4', 'Productora 24', 'prod24@empresa.cl', '+56900000024'),
('76000025-5', 'Productora 25', 'prod25@empresa.cl', '+56900000025'),
('76000026-6', 'Productora 26', 'prod26@empresa.cl', '+56900000026'),
('76000027-7', 'Productora 27', 'prod27@empresa.cl', '+56900000027'),
('76000028-8', 'Productora 28', 'prod28@empresa.cl', '+56900000028'),
('76000029-9', 'Productora 29', 'prod29@empresa.cl', '+56900000029'),
('76000030-0', 'Productora 30', 'prod30@empresa.cl', '+56900000030'),
('76000031-1', 'Productora 31', 'prod31@empresa.cl', '+56900000031'),
('76000032-2', 'Productora 32', 'prod32@empresa.cl', '+56900000032'),
('76000033-3', 'Productora 33', 'prod33@empresa.cl', '+56900000033'),
('76000034-4', 'Productora 34', 'prod34@empresa.cl', '+56900000034'),
('76000035-5', 'Productora 35', 'prod35@empresa.cl', '+56900000035'),
('76000036-6', 'Productora 36', 'prod36@empresa.cl', '+56900000036'),
('76000037-7', 'Productora 37', 'prod37@empresa.cl', '+56900000037'),
('76000038-8', 'Productora 38', 'prod38@empresa.cl', '+56900000038'),
('76000039-9', 'Productora 39', 'prod39@empresa.cl', '+56900000039'),
('76000040-0', 'Productora 40', 'prod40@empresa.cl', '+56900000040');

-- =====================================================
-- 4. INSERTAR 40 PROVEEDORES
-- =====================================================
INSERT INTO Proveedor (rut_proveedor, nombre_empresa, rubro, telefono) VALUES
('77000001-1', 'Securitas Chile', 'Seguridad', '+56911111111'),
('77000002-2', 'AudioPro', 'Audio e Iluminación', '+56922222222'),
('77000003-3', 'FoodTrucks Unidos', 'Catering', '+56933333333'),
('77000004-4', 'Vallas SPA', 'Infraestructura', '+56944444444'),
('77000005-5', 'LimpiaMax', 'Aseo', '+56955555555'),
('77000006-6', 'Ambulancias Chile', 'Salud', '+56966666666'),
('77000007-7', 'Visuales 3D', 'Pantallas LED', '+56977777777'),
('77000008-8', 'Carpas y Toldos', 'Infraestructura', '+56988888888'),
('77000009-9', 'Prosegur', 'Seguridad', '+56999999999'),
('77000010-0', 'Proveedor 10', 'Generadores', '+56900000010'),
('77000011-1', 'Proveedor 11', 'Logística', '+56900000011'),
('77000012-2', 'Proveedor 12', 'Aseo', '+56900000012'),
('77000013-3', 'Proveedor 13', 'Seguridad', '+56900000013'),
('77000014-4', 'Proveedor 14', 'Catering', '+56900000014'),
('77000015-5', 'Proveedor 15', 'Catering', '+56900000015'),
('77000016-6', 'Proveedor 16', 'Audio e Iluminación', '+56900000016'),
('77000017-7', 'Proveedor 17', 'Audio e Iluminación', '+56900000017'),
('77000018-8', 'Proveedor 18', 'Pantallas LED', '+56900000018'),
('77000019-9', 'Proveedor 19', 'Salud', '+56900000019'),
('77000020-0', 'Proveedor 20', 'Generadores', '+56900000020'),
('77000021-1', 'Proveedor 21', 'Seguridad', '+56900000021'),
('77000022-2', 'Proveedor 22', 'Logística', '+56900000022'),
('77000023-3', 'Proveedor 23', 'Catering', '+56900000023'),
('77000024-4', 'Proveedor 24', 'Audio e Iluminación', '+56900000024'),
('77000025-5', 'Proveedor 25', 'Aseo', '+56900000025'),
('77000026-6', 'Proveedor 26', 'Infraestructura', '+56900000026'),
('77000027-7', 'Proveedor 27', 'Salud', '+56900000027'),
('77000028-8', 'Proveedor 28', 'Seguridad', '+56900000028'),
('77000029-9', 'Proveedor 29', 'Catering', '+56900000029'),
('77000030-0', 'Proveedor 30', 'Pantallas LED', '+56900000030'),
('77000031-1', 'Proveedor 31', 'Audio e Iluminación', '+56900000031'),
('77000032-2', 'Proveedor 32', 'Logística', '+56900000032'),
('77000033-3', 'Proveedor 33', 'Generadores', '+56900000033'),
('77000034-4', 'Proveedor 34', 'Aseo', '+56900000034'),
('77000035-5', 'Proveedor 35', 'Seguridad', '+56900000035'),
('77000036-6', 'Proveedor 36', 'Infraestructura', '+56900000036'),
('77000037-7', 'Proveedor 37', 'Catering', '+56900000037'),
('77000038-8', 'Proveedor 38', 'Salud', '+56900000038'),
('77000039-9', 'Proveedor 39', 'Audio e Iluminación', '+56900000039'),
('77000040-0', 'Proveedor 40', 'Seguridad', '+56900000040');

-- =====================================================
-- 5. INSERTAR 40 ASISTENTES
-- =====================================================
INSERT INTO Asistente (rut_asistente, nombre, correo) VALUES
('11111111-1', 'Juan Perez', 'juan.perez@mail.com'),
('11111112-2', 'Maria Gonzalez', 'maria.g@mail.com'),
('11111113-3', 'Pedro Soto', 'pedro.soto@mail.com'),
('11111114-4', 'Ana Silva', 'ana.silva@mail.com'),
('11111115-5', 'Luis Tapia', 'luis.t@mail.com'),
('11111116-6', 'Camila Rojas', 'camila.r@mail.com'),
('11111117-7', 'Diego Araya', 'diego.a@mail.com'),
('11111118-8', 'Valentina Vega', 'vale.v@mail.com'),
('11111119-9', 'Jorge Castro', 'jorge.c@mail.com'),
('11111120-0', 'Sofia Flores', 'sofia.f@mail.com'),
('11111121-1', 'Asistente 11', 'a11@mail.com'),
('11111122-2', 'Asistente 12', 'a12@mail.com'),
('11111123-3', 'Asistente 13', 'a13@mail.com'),
('11111124-4', 'Asistente 14', 'a14@mail.com'),
('11111125-5', 'Asistente 15', 'a15@mail.com'),
('11111126-6', 'Asistente 16', 'a16@mail.com'),
('11111127-7', 'Asistente 17', 'a17@mail.com'),
('11111128-8', 'Asistente 18', 'a18@mail.com'),
('11111129-9', 'Asistente 19', 'a19@mail.com'),
('11111130-0', 'Asistente 20', 'a20@mail.com'),
('11111131-1', 'Asistente 21', 'a21@mail.com'),
('11111132-2', 'Asistente 22', 'a22@mail.com'),
('11111133-3', 'Asistente 23', 'a23@mail.com'),
('11111134-4', 'Asistente 24', 'a24@mail.com'),
('11111135-5', 'Asistente 25', 'a25@mail.com'),
('11111136-6', 'Asistente 26', 'a26@mail.com'),
('11111137-7', 'Asistente 27', 'a27@mail.com'),
('11111138-8', 'Asistente 28', 'a28@mail.com'),
('11111139-9', 'Asistente 29', 'a29@mail.com'),
('11111140-0', 'Asistente 30', 'a30@mail.com'),
('11111141-1', 'Asistente 31', 'a31@mail.com'),
('11111142-2', 'Asistente 32', 'a32@mail.com'),
('11111143-3', 'Asistente 33', 'a33@mail.com'),
('11111144-4', 'Asistente 34', 'a34@mail.com'),
('11111145-5', 'Asistente 35', 'a35@mail.com'),
('11111146-6', 'Asistente 36', 'a36@mail.com'),
('11111147-7', 'Asistente 37', 'a37@mail.com'),
('11111148-8', 'Asistente 38', 'a38@mail.com'),
('11111149-9', 'Asistente 39', 'a39@mail.com'),
('11111150-0', 'Asistente 40', 'a40@mail.com');

-- =====================================================
-- 6. INSERTAR 40 EVENTOS
-- =====================================================
INSERT INTO Evento (id_organizador, id_recinto, nombre_evento, tipo_evento, fecha) VALUES
(1, 1, 'Concierto Rock', 'Concierto', '2026-10-01'),
(2, 2, 'Festival Indie', 'Concierto', '2026-10-02'),
(3, 3, 'Gala Viña', 'Concierto', '2026-10-03'),
(4, 4, 'Mega Fest', 'Concierto', '2026-10-04'),
(5, 5, 'Cumbre Urbana', 'Concierto', '2026-10-05'),
(6, 6, 'Seminario Tech', 'Seminario', '2026-10-06'),
(7, 7, 'Noche Bohemia', 'Concierto', '2026-10-07'),
(8, 8, 'Fiesta 90s', 'Concierto', '2026-10-08'),
(9, 9, 'Congreso Médico', 'Congreso', '2026-10-09'),
(10, 10, 'Evento 10', 'Seminario', '2026-10-10'),
(11, 11, 'Evento 11', 'Concierto', '2026-10-11'),
(12, 12, 'Evento 12', 'Congreso', '2026-10-12'),
(13, 13, 'Evento 13', 'Seminario', '2026-10-13'),
(14, 14, 'Evento 14', 'Concierto', '2026-10-14'),
(15, 15, 'Evento 15', 'Concierto', '2026-10-15'),
(16, 16, 'Evento 16', 'Seminario', '2026-10-16'),
(17, 17, 'Evento 17', 'Congreso', '2026-10-17'),
(18, 18, 'Evento 18', 'Concierto', '2026-10-18'),
(19, 19, 'Evento 19', 'Concierto', '2026-10-19'),
(20, 20, 'Evento 20', 'Seminario', '2026-10-20'),
(21, 21, 'Evento 21', 'Congreso', '2026-10-21'),
(22, 22, 'Evento 22', 'Concierto', '2026-10-22'),
(23, 23, 'Evento 23', 'Concierto', '2026-10-23'),
(24, 24, 'Evento 24', 'Seminario', '2026-10-24'),
(25, 25, 'Evento 25', 'Congreso', '2026-10-25'),
(26, 26, 'Evento 26', 'Concierto', '2026-10-26'),
(27, 27, 'Evento 27', 'Concierto', '2026-10-27'),
(28, 28, 'Evento 28', 'Seminario', '2026-10-28'),
(29, 29, 'Evento 29', 'Congreso', '2026-10-29'),
(30, 30, 'Evento 30', 'Concierto', '2026-10-30'),
(31, 31, 'Evento 31', 'Concierto', '2026-11-01'),
(32, 32, 'Evento 32', 'Seminario', '2026-11-02'),
(33, 33, 'Evento 33', 'Congreso', '2026-11-03'),
(34, 34, 'Evento 34', 'Concierto', '2026-11-04'),
(35, 35, 'Evento 35', 'Concierto', '2026-11-05'),
(36, 36, 'Evento 36', 'Seminario', '2026-11-06'),
(37, 37, 'Evento 37', 'Congreso', '2026-11-07'),
(38, 38, 'Evento 38', 'Concierto', '2026-11-08'),
(39, 39, 'Evento 39', 'Concierto', '2026-11-09'),
(40, 40, 'Evento 40', 'Seminario', '2026-11-10');

-- =====================================================
-- 7. INSERTAR 40 TIPOS DE ENTRADA
-- =====================================================
INSERT INTO Tipo_entrada (id_evento, nombre_zona, precio, capacidad) VALUES
(1, 'VIP', 50000, 500), (2, 'Cancha', 30000, 1000), (3, 'Platea Baja', 25000, 800), (4, 'Platea Alta', 15000, 1200),
(5, 'Cancha VIP', 60000, 300), (6, 'General', 10000, 2000), (7, 'Tribuna', 20000, 500), (8, 'VIP', 45000, 400),
(9, 'Cancha', 28000, 1500), (10, 'General', 12000, 800), (11, 'Zona 11', 10000, 1000), (12, 'Zona 12', 15000, 1000),
(13, 'Zona 13', 20000, 1000), (14, 'Zona 14', 25000, 1000), (15, 'Zona 15', 30000, 1000), (16, 'Zona 16', 35000, 1000),
(17, 'Zona 17', 10000, 1000), (18, 'Zona 18', 15000, 1000), (19, 'Zona 19', 20000, 1000), (20, 'Zona 20', 25000, 1000),
(21, 'Zona 21', 30000, 1000), (22, 'Zona 22', 35000, 1000), (23, 'Zona 23', 10000, 1000), (24, 'Zona 24', 15000, 1000),
(25, 'Zona 25', 20000, 1000), (26, 'Zona 26', 25000, 1000), (27, 'Zona 27', 30000, 1000), (28, 'Zona 28', 35000, 1000),
(29, 'Zona 29', 10000, 1000), (30, 'Zona 30', 15000, 1000), (31, 'Zona 31', 20000, 1000), (32, 'Zona 32', 25000, 1000),
(33, 'Zona 33', 30000, 1000), (34, 'Zona 34', 35000, 1000), (35, 'Zona 35', 10000, 1000), (36, 'Zona 36', 15000, 1000),
(37, 'Zona 37', 20000, 1000), (38, 'Zona 38', 25000, 1000), (39, 'Zona 39', 30000, 1000), (40, 'Zona 40', 35000, 1000);

-- =====================================================
-- 8. INSERTAR 40 RELACIONES CONTRATA
-- =====================================================
INSERT INTO Contrata (id_proveedor, id_evento) VALUES
(1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (6, 6), (7, 7), (8, 8), (9, 9), (10, 10),
(11, 11), (12, 12), (13, 13), (14, 14), (15, 15), (16, 16), (17, 17), (18, 18), (19, 19), (20, 20),
(21, 21), (22, 22), (23, 23), (24, 24), (25, 25), (26, 26), (27, 27), (28, 28), (29, 29), (30, 30),
(31, 31), (32, 32), (33, 33), (34, 34), (35, 35), (36, 36), (37, 37), (38, 38), (39, 39), (40, 40);

-- =====================================================
-- 9. INSERTAR 40 RELACIONES PARTICIPA
-- =====================================================
INSERT INTO Participa (id_artista, id_evento, fecha_presentacion) VALUES
(1, 1, '2026-10-01'), (2, 2, '2026-10-02'), (3, 3, '2026-10-03'), (4, 4, '2026-10-04'), (5, 5, '2026-10-05'),
(6, 6, '2026-10-06'), (7, 7, '2026-10-07'), (8, 8, '2026-10-08'), (9, 9, '2026-10-09'), (10, 10, '2026-10-10'),
(11, 11, '2026-10-11'), (12, 12, '2026-10-12'), (13, 13, '2026-10-13'), (14, 14, '2026-10-14'), (15, 15, '2026-10-15'),
(16, 16, '2026-10-16'), (17, 17, '2026-10-17'), (18, 18, '2026-10-18'), (19, 19, '2026-10-19'), (20, 20, '2026-10-20'),
(21, 21, '2026-10-21'), (22, 22, '2026-10-22'), (23, 23, '2026-10-23'), (24, 24, '2026-10-24'), (25, 25, '2026-10-25'),
(26, 26, '2026-10-26'), (27, 27, '2026-10-27'), (28, 28, '2026-10-28'), (29, 29, '2026-10-29'), (30, 30, '2026-10-30'),
(31, 31, '2026-11-01'), (32, 32, '2026-11-02'), (33, 33, '2026-11-03'), (34, 34, '2026-11-04'), (35, 35, '2026-11-05'),
(36, 36, '2026-11-06'), (37, 37, '2026-11-07'), (38, 38, '2026-11-08'), (39, 39, '2026-11-09'), (40, 40, '2026-11-10');

-- =====================================================
-- 10. INSERTAR 40 COMPRAS
-- =====================================================
INSERT INTO Compra (id_asistente, id_entrada, fecha_creacion, fecha_expiracion, estado_compra, fecha_compra, monto_total, metodo_pago) VALUES
(1, 1, '2026-09-01 10:00:00', '2026-09-01 10:15:00', 'Completada', '2026-09-01 10:05:00', 50000, 'Tarjeta de Crédito'),
(2, 2, '2026-09-02 11:00:00', '2026-09-02 11:15:00', 'Completada', '2026-09-02 11:03:00', 30000, 'Débito'),
(3, 3, '2026-09-03 12:00:00', '2026-09-03 12:15:00', 'Expirada', NULL, 25000, NULL),
(4, 4, '2026-09-04 13:00:00', '2026-09-04 13:15:00', 'Completada', '2026-09-04 13:10:00', 15000, 'Transferencia'),
(5, 5, '2026-09-05 14:00:00', '2026-09-05 14:15:00', 'Completada', '2026-09-05 14:02:00', 60000, 'Tarjeta de Crédito'),
(6, 6, '2026-09-06 15:00:00', '2026-09-06 15:15:00', 'Completada', '2026-09-06 15:05:00', 10000, 'Débito'),
(7, 7, '2026-09-07 16:00:00', '2026-09-07 16:15:00', 'Completada', '2026-09-07 16:14:00', 20000, 'Transferencia'),
(8, 8, '2026-09-08 17:00:00', '2026-09-08 17:15:00', 'Expirada', NULL, 45000, NULL),
(9, 9, '2026-09-09 18:00:00', '2026-09-09 18:15:00', 'Completada', '2026-09-09 18:05:00', 28000, 'Tarjeta de Crédito'),
(10, 10, '2026-09-10 19:00:00', '2026-09-10 19:15:00', 'Completada', '2026-09-10 19:10:00', 12000, 'Débito'),
(11, 11, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 10000, 'Débito'),
(12, 12, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 15000, 'Débito'),
(13, 13, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 20000, 'Débito'),
(14, 14, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 25000, 'Débito'),
(15, 15, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 30000, 'Débito'),
(16, 16, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 35000, 'Débito'),
(17, 17, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 10000, 'Débito'),
(18, 18, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 15000, 'Débito'),
(19, 19, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 20000, 'Débito'),
(20, 20, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 25000, 'Débito'),
(21, 21, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 30000, 'Débito'),
(22, 22, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 35000, 'Débito'),
(23, 23, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 10000, 'Débito'),
(24, 24, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 15000, 'Débito'),
(25, 25, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 20000, 'Débito'),
(26, 26, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 25000, 'Débito'),
(27, 27, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 30000, 'Débito'),
(28, 28, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 35000, 'Débito'),
(29, 29, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 10000, 'Débito'),
(30, 30, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 15000, 'Débito'),
(31, 31, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 20000, 'Débito'),
(32, 32, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 25000, 'Débito'),
(33, 33, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 30000, 'Débito'),
(34, 34, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 35000, 'Débito'),
(35, 35, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 10000, 'Débito'),
(36, 36, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 15000, 'Débito'),
(37, 37, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 20000, 'Débito'),
(38, 38, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 25000, 'Débito'),
(39, 39, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 30000, 'Débito'),
(40, 40, '2026-09-11 10:00:00', '2026-09-11 10:15:00', 'Completada', '2026-09-11 10:05:00', 35000, 'Débito');

-- =====================================================
-- 11. INSERTAR 40 TICKETS
-- =====================================================
INSERT INTO Ticket (id_compra, codigo_qr, estado) VALUES
(1, 'QR_HASH_001_A', 'Emitido'),
(2, 'QR_HASH_002_B', 'Usado'),
(3, 'QR_HASH_003_C', 'Anulado'),
(4, 'QR_HASH_004_D', 'Emitido'),
(5, 'QR_HASH_005_E', 'Emitido'),
(6, 'QR_HASH_006_F', 'Emitido'),
(7, 'QR_HASH_007_G', 'Usado'),
(8, 'QR_HASH_008_H', 'Anulado'),
(9, 'QR_HASH_009_I', 'Emitido'),
(10, 'QR_HASH_010_J', 'Emitido'),
(11, 'QR_HASH_011_K', 'Emitido'),
(12, 'QR_HASH_012_L', 'Emitido'),
(13, 'QR_HASH_013_M', 'Emitido'),
(14, 'QR_HASH_014_N', 'Emitido'),
(15, 'QR_HASH_015_O', 'Emitido'),
(16, 'QR_HASH_016_P', 'Emitido'),
(17, 'QR_HASH_017_Q', 'Emitido'),
(18, 'QR_HASH_018_R', 'Emitido'),
(19, 'QR_HASH_019_S', 'Emitido'),
(20, 'QR_HASH_020_T', 'Emitido'),
(21, 'QR_HASH_021_U', 'Emitido'),
(22, 'QR_HASH_022_V', 'Emitido'),
(23, 'QR_HASH_023_W', 'Emitido'),
(24, 'QR_HASH_024_X', 'Emitido'),
(25, 'QR_HASH_025_Y', 'Emitido'),
(26, 'QR_HASH_026_Z', 'Emitido'),
(27, 'QR_HASH_027_AA', 'Emitido'),
(28, 'QR_HASH_028_BB', 'Emitido'),
(29, 'QR_HASH_029_CC', 'Emitido'),
(30, 'QR_HASH_030_DD', 'Emitido'),
(31, 'QR_HASH_031_EE', 'Emitido'),
(32, 'QR_HASH_032_FF', 'Emitido'),
(33, 'QR_HASH_033_GG', 'Emitido'),
(34, 'QR_HASH_034_HH', 'Emitido'),
(35, 'QR_HASH_035_II', 'Emitido'),
(36, 'QR_HASH_036_JJ', 'Emitido'),
(37, 'QR_HASH_037_KK', 'Emitido'),
(38, 'QR_HASH_038_LL', 'Emitido'),
(39, 'QR_HASH_039_MM', 'Emitido'),
(40, 'QR_HASH_040_NN', 'Emitido');

-- =============================================================
-- PARTE 2. PREPARACION DEL CASO (14 instrucciones del Taller 5)
-- =============================================================

-- =============================================================
-- TALLER 5 - SUBQUERIES (DDL / DML)
-- Asignatura: Base de Datos
-- Caso de estudio: Sistema de gestión de eventos (plataforma de eventos en vivo)
-- Motor: PostgreSQL
-- Orden de ejecución: secuencial (Instrucción 1 -> 14)
-- =============================================================
-- IMPORTANTE: ejecutar este script UNA SOLA VEZ sobre una base de datos
-- recién creada con el esquema y datos base (Hola.sql), para que las
-- evidencias de conteo sean reproducibles.
-- =============================================================


-- =============================================================
-- BLOQUE 1: PREPARACIÓN ESTRUCTURAL DEL MODELO (ALTER TABLE)
-- =============================================================

-- -------------------------------------------------------------
-- Instrucción 1: Habilitación de gestión de estados en la cartelera
-- -------------------------------------------------------------
ALTER TABLE Evento ADD COLUMN estado_evento VARCHAR(30) DEFAULT 'Programado';

-- Consulta de verificación 1
SELECT * FROM Evento;


-- -------------------------------------------------------------
-- Instrucción 2: Segmentación del público para programas de fidelización
-- -------------------------------------------------------------
ALTER TABLE Asistente ADD COLUMN categoria_vip BOOLEAN DEFAULT FALSE;

-- Consulta de verificación 2
SELECT * FROM Asistente;


-- =============================================================
-- BLOQUE 2: CONTINGENCIA OPERATIVA (UPDATE / DELETE + SUBQUERIES)
-- =============================================================

-- -------------------------------------------------------------
-- Instrucción 3: Suspensión masiva de eventos por emergencia climática
-- -------------------------------------------------------------
UPDATE Evento
SET estado_evento = 'Cancelado'
WHERE id_recinto IN (
    SELECT id_recinto
    FROM Recinto
    WHERE ciudad = 'Concepción'
);

-- Consulta de verificación 3
SELECT ev.id_evento, ev.nombre_evento, r.ciudad, ev.estado_evento
FROM Evento ev
INNER JOIN Recinto r ON ev.id_recinto = r.id_recinto
WHERE ev.estado_evento = 'Cancelado';


-- -------------------------------------------------------------
-- Instrucción 4: Prevención de fraudes en puertas
-- -------------------------------------------------------------
DELETE FROM Ticket
WHERE id_compra IN (
    SELECT c.id_compra
    FROM Compra c
    INNER JOIN Tipo_entrada te ON c.id_entrada = te.id_entrada
    INNER JOIN Evento ev ON te.id_evento = ev.id_evento
    WHERE ev.estado_evento = 'Cancelado'
);

-- Consulta de verificación 4
SELECT COUNT(*) AS total_tickets_restantes
FROM Ticket;


-- -------------------------------------------------------------
-- Instrucción 5: Liberación de contratos logísticos retenidos
-- -------------------------------------------------------------
DELETE FROM Contrata ct
WHERE EXISTS (
    SELECT 1
    FROM Evento ev
    WHERE ev.id_evento = ct.id_evento
      AND ev.estado_evento = 'Cancelado'
);

-- Consulta de verificación 5
SELECT COUNT(*) AS contratos_activos
FROM Contrata;


-- =============================================================
-- BLOQUE 3: MOTOR DE FIDELIZACIÓN (CTE + AGREGACIONES)
-- =============================================================

-- -------------------------------------------------------------
-- Instrucción 6: Sistema de categorización VIP
-- -------------------------------------------------------------
WITH CompradoresFrecuentes AS (
    SELECT id_asistente
    FROM Compra
    WHERE estado_compra = 'Completada'
    GROUP BY id_asistente
    HAVING SUM(monto_total) >= 30000
)
UPDATE Asistente
SET categoria_vip = TRUE
WHERE id_asistente IN (SELECT id_asistente FROM CompradoresFrecuentes);

-- Consulta de verificación 6
SELECT id_asistente, nombre, categoria_vip
FROM Asistente
WHERE categoria_vip = TRUE;


-- -------------------------------------------------------------
-- Instrucción 7: Automatización de recompensas a clientes fieles
-- -------------------------------------------------------------
WITH EntradaCortesia AS (
    SELECT id_entrada
    FROM Tipo_entrada
    ORDER BY precio ASC
    LIMIT 1
)
INSERT INTO Compra (id_asistente, id_entrada, fecha_creacion, fecha_expiracion,
                    estado_compra, fecha_compra, monto_total, metodo_pago)
SELECT a.id_asistente, e.id_entrada, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
       'Completada', CURRENT_TIMESTAMP, 0, 'Cortesía VIP'
FROM Asistente a
CROSS JOIN EntradaCortesia e
WHERE a.categoria_vip = TRUE;

-- Consulta de verificación 7
SELECT id_compra, id_asistente, id_entrada, monto_total, metodo_pago
FROM Compra
WHERE metodo_pago = 'Cortesía VIP';


-- =============================================================
-- BLOQUE 4: COMERCIALIZACIÓN DINÁMICA (SUBQUERIES + CTE + AGREGACIONES)
-- =============================================================

-- -------------------------------------------------------------
-- Instrucción 8: Salvavidas financiero "Last Minute Tickets"
-- -------------------------------------------------------------
UPDATE Tipo_entrada
SET precio = precio * 0.8
WHERE id_entrada IN (
    SELECT te.id_entrada
    FROM Tipo_entrada te
    LEFT JOIN Compra c ON te.id_entrada = c.id_entrada
    GROUP BY te.id_entrada
    HAVING COUNT(c.id_compra) < 2
);

-- Consulta de verificación 8
SELECT id_entrada, nombre_zona, precio
FROM Tipo_entrada
ORDER BY precio ASC
LIMIT 10;


-- -------------------------------------------------------------
-- Instrucción 9: Estrategia comercial "Meet & Greet"
-- -------------------------------------------------------------
WITH MaxPrecios AS (
    SELECT id_evento, MAX(precio) AS precio_tope
    FROM Tipo_entrada
    GROUP BY id_evento
)
INSERT INTO Tipo_entrada (id_evento, nombre_zona, precio, capacidad)
SELECT id_evento, 'Meet & Greet', precio_tope + 20000, 50
FROM MaxPrecios;

-- Consulta de verificación 9
SELECT id_evento, nombre_zona, precio, capacidad
FROM Tipo_entrada
WHERE nombre_zona = 'Meet & Greet';


-- -------------------------------------------------------------
-- Instrucción 10: Refuerzo operativo para eventos de alta demanda
-- -------------------------------------------------------------
WITH VentasPorEvento AS (
    SELECT te.id_evento,
           SUM(c.monto_total) AS recaudacion,
           COUNT(c.id_compra) AS entradas_vendidas
    FROM Tipo_entrada te
    INNER JOIN Compra c ON te.id_entrada = c.id_entrada
    WHERE c.estado_compra = 'Completada'
    GROUP BY te.id_evento
),
PromedioGeneral AS (
    SELECT AVG(recaudacion) AS recaudacion_promedio
    FROM VentasPorEvento
)
UPDATE Evento ev
SET estado_evento = 'Alta demanda'
FROM VentasPorEvento v, PromedioGeneral p
WHERE ev.id_evento = v.id_evento
  AND v.recaudacion > p.recaudacion_promedio
  AND v.recaudacion >= 30000
  AND ev.estado_evento <> 'Cancelado';

-- Consulta de verificación 10
SELECT ev.id_evento, ev.nombre_evento, ev.estado_evento,
       SUM(c.monto_total) AS recaudacion, COUNT(c.id_compra) AS entradas_vendidas
FROM Evento ev
INNER JOIN Tipo_entrada te ON ev.id_evento = te.id_evento
INNER JOIN Compra c ON te.id_entrada = c.id_entrada
WHERE ev.estado_evento = 'Alta demanda'
GROUP BY ev.id_evento, ev.nombre_evento, ev.estado_evento
ORDER BY recaudacion DESC;


-- -------------------------------------------------------------
-- Instrucción 11: Podado de zonas experimentales sin rotación
-- -------------------------------------------------------------
WITH ZonasSinRotacion AS (
    SELECT te.id_entrada
    FROM Tipo_entrada te
    INNER JOIN Evento ev ON te.id_evento = ev.id_evento
    LEFT JOIN Compra c ON te.id_entrada = c.id_entrada
    WHERE te.nombre_zona = 'Meet & Greet'
      AND ev.estado_evento <> 'Alta demanda'
    GROUP BY te.id_entrada
    HAVING COUNT(c.id_compra) = 0
)
DELETE FROM Tipo_entrada
WHERE id_entrada IN (SELECT id_entrada FROM ZonasSinRotacion);

-- Consulta de verificación 11
SELECT COUNT(*) AS zonas_meet_greet_restantes
FROM Tipo_entrada
WHERE nombre_zona = 'Meet & Greet';


-- =============================================================
-- BLOQUE 5: AUDITORÍA TRANSITORIA (CREATE / DROP + EXISTS)
-- =============================================================

-- -------------------------------------------------------------
-- Instrucción 12: Creación de entorno transitorio de auditoría
-- -------------------------------------------------------------
CREATE TABLE Log_Auditoria_Precios (
    id_log SERIAL PRIMARY KEY,
    fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    alerta VARCHAR(255)
);

-- Consulta de verificación 12
SELECT * FROM Log_Auditoria_Precios;


-- -------------------------------------------------------------
-- Instrucción 13: Disparo de alarma de ingresos
-- -------------------------------------------------------------
INSERT INTO Log_Auditoria_Precios (alerta)
SELECT 'Alerta: Localidades vendiéndose bajo el costo de corte ($10.000)'
WHERE EXISTS (
    SELECT 1
    FROM Tipo_entrada
    WHERE precio < 10000
);

-- Consulta de verificación 13
SELECT * FROM Log_Auditoria_Precios;


-- -------------------------------------------------------------
-- Instrucción 14: Destrucción de la infraestructura transitoria
-- -------------------------------------------------------------
DROP TABLE Log_Auditoria_Precios;

-- Consulta de verificación 14 (debe retornar NULL: la tabla ya no existe)
SELECT to_regclass('public.log_auditoria_precios') AS tabla_log;

-- =============================================================
-- PARTE 3. SEGURIDAD Y FUNCIONES (Taller 6)
-- =============================================================

CREATE ROLE rol_admin NOLOGIN;
CREATE ROLE rol_operador NOLOGIN;
CREATE ROLE rol_finanzas NOLOGIN;
CREATE ROLE rol_marketing NOLOGIN;
CREATE ROLE rol_auditor NOLOGIN;
CREATE USER usuario_admin PASSWORD 'CAMBIAR_admin_6';
CREATE USER usuario_caja PASSWORD 'CAMBIAR_caja_6';
CREATE USER usuario_reportes PASSWORD 'CAMBIAR_reportes_6';
CREATE USER usuario_marketing PASSWORD 'CAMBIAR_marketing_6';
CREATE USER usuario_auditoria PASSWORD 'CAMBIAR_auditoria_6';
GRANT rol_admin TO usuario_admin;
GRANT rol_operador TO usuario_caja;
GRANT rol_finanzas TO usuario_reportes;
GRANT rol_marketing TO usuario_marketing;
GRANT rol_auditor TO usuario_auditoria;

GRANT USAGE ON SCHEMA public TO rol_admin, rol_operador, rol_finanzas, rol_marketing, rol_auditor;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO rol_admin;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rol_admin;
GRANT SELECT ON public.evento, public.tipo_entrada, public.compra TO rol_finanzas;
GRANT SELECT ON public.evento, public.tipo_entrada, public.compra, public.ticket TO rol_auditor;
GRANT SELECT ON public.evento, public.organizador TO rol_marketing;
-- El operador solo ve el estado del QR; la transicion se realiza mediante funcion controlada.
GRANT SELECT ON public.ticket TO rol_operador;
REVOKE DELETE ON public.compra, public.ticket FROM rol_operador;

-- Funciones SECURITY DEFINER: propietario confiable, objetos calificados y busqueda fija.
-- El rol invocador no recibe privilegios directos de escritura en las tablas financieras.

-- 1. Ingreso confirmado de un evento (valor escalar).
CREATE FUNCTION public.fn_calcular_recaudacion_evento(p_id_evento integer)
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
DECLARE v_total bigint;
BEGIN
    -- Las compras no completadas y las cortesias de monto cero no suman ingresos.
    SELECT COALESCE(SUM(c.monto_total), 0) INTO v_total
    FROM public.compra c JOIN public.tipo_entrada te ON te.id_entrada = c.id_entrada
    WHERE te.id_evento = p_id_evento AND c.estado_compra = 'Completada';
    RETURN v_total;
END;
$$;

-- 2. Credencial solo para asistentes clasificados como VIP (texto escalar).
CREATE FUNCTION public.fn_generar_credencial_asistente(p_id_asistente integer)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
DECLARE v_credencial text;
BEGIN
    -- Si el id no existe o no es VIP se devuelve NULL, sin inventar credenciales.
    SELECT 'CREDENCIAL VIP | ' || a.nombre || ' | RUT: ' || a.rut_asistente
    INTO v_credencial FROM public.asistente a
    WHERE a.id_asistente = p_id_asistente AND a.categoria_vip IS TRUE;
    RETURN v_credencial;
END;
$$;

-- 3. Diferencia de dias: negativa si el evento ya paso.
CREATE FUNCTION public.fn_dias_para_evento(p_id_evento integer)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
DECLARE v_dias integer;
BEGIN
    -- NULL si no existe el evento; no se falsea la fecha historica del dataset.
    SELECT ev.fecha - CURRENT_DATE INTO v_dias
    FROM public.evento ev WHERE ev.id_evento = p_id_evento;
    RETURN v_dias;
END;
$$;

-- 4. Alta de un nuevo artista en el catalogo.
CREATE FUNCTION public.fn_registrar_artista(p_nombre varchar)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
BEGIN
    -- Impide crear registros vacios por error de digitacion.
    IF NULLIF(btrim(p_nombre), '') IS NULL THEN
        RAISE EXCEPTION 'El nombre del artista es obligatorio';
    END IF;
    INSERT INTO public.artista(nombre_artista) VALUES (btrim(p_nombre));
    RAISE NOTICE 'Artista % registrado.', btrim(p_nombre);
END;
$$;

-- 5. Uso unico del codigo QR, solo de compras confirmadas y shows activos.
CREATE FUNCTION public.fn_validar_ingreso_ticket(p_qr varchar)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
BEGIN
    -- UPDATE atomico: una segunda lectura ya no cumple estado Emitido.
    UPDATE public.ticket t SET estado = 'Usado'
    FROM public.compra c JOIN public.tipo_entrada te ON te.id_entrada = c.id_entrada
         JOIN public.evento ev ON ev.id_evento = te.id_evento
    WHERE t.id_compra = c.id_compra AND t.codigo_qr = p_qr
      AND t.estado = 'Emitido' AND c.estado_compra = 'Completada'
      AND ev.estado_evento <> 'Cancelado';
    IF FOUND THEN RAISE NOTICE 'Acceso autorizado para QR %.', p_qr;
    ELSE RAISE NOTICE 'Acceso denegado: QR inexistente, usado o invalidado.';
    END IF;
END;
$$;

-- 6. Suspender evento sin perder historico; invalidar entradas aun emitidas.
CREATE FUNCTION public.fn_suspender_evento(p_id_evento integer)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
DECLARE v_anulados integer;
BEGIN
    -- Marca el estado y distingue entre un id inexistente y una cancelacion valida.
    UPDATE public.evento SET estado_evento = 'Cancelado'
    WHERE id_evento = p_id_evento AND estado_evento <> 'Cancelado';
    IF NOT FOUND THEN
        RAISE NOTICE 'Evento % inexistente o ya cancelado.', p_id_evento;
        RETURN;
    END IF;
    -- El QR emitido queda inutilizable; las filas de compra se conservan para auditoria.
    UPDATE public.ticket t SET estado = 'Anulado'
    FROM public.compra c JOIN public.tipo_entrada te ON te.id_entrada = c.id_entrada
    WHERE t.id_compra = c.id_compra AND te.id_evento = p_id_evento AND t.estado = 'Emitido';
    GET DIAGNOSTICS v_anulados = ROW_COUNT;
    RAISE NOTICE 'Evento % cancelado; % QR emitidos anulados.', p_id_evento, v_anulados;
END;
$$;

-- 7. Aforo emitido, NO personas fisicamente presentes (esas tienen QR Usado).
CREATE FUNCTION public.fn_aforo_por_zona(p_id_evento integer)
RETURNS TABLE(zona varchar, tickets_emitidos bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
BEGIN
    -- LEFT JOIN incluye zonas sin tickets; alias evitan conflicto con columnas de salida.
    RETURN QUERY SELECT te.nombre_zona, COUNT(t.id_ticket)
    FROM public.tipo_entrada te
    LEFT JOIN public.compra c ON c.id_entrada = te.id_entrada AND c.estado_compra = 'Completada'
    LEFT JOIN public.ticket t ON t.id_compra = c.id_compra AND t.estado = 'Emitido'
    WHERE te.id_evento = p_id_evento
    GROUP BY te.id_entrada, te.nombre_zona ORDER BY te.nombre_zona;
END;
$$;

-- 8. Contactos de productoras para shows activos desde una fecha.
CREATE FUNCTION public.fn_contactos_productoras(p_fecha_inicio date)
RETURNS TABLE(show varchar, productora varchar, contacto varchar)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
BEGIN
    -- Evita contactar por actuaciones suspendidas.
    RETURN QUERY SELECT ev.nombre_evento, org.nombre_empresa, org.correo
    FROM public.evento ev JOIN public.organizador org ON org.id_organizador = ev.id_organizador
    WHERE ev.fecha >= p_fecha_inicio AND ev.estado_evento <> 'Cancelado'
    ORDER BY ev.fecha, ev.id_evento;
END;
$$;

-- 9. Segmento VIP para campanas de fidelizacion (sin exponer el correo).
CREATE FUNCTION public.fn_obtener_clientes_vip()
RETURNS TABLE(rut varchar, nombre varchar)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
BEGIN
    -- Alias a evita la ambiguedad del nombre de la columna de salida.
    RETURN QUERY SELECT a.rut_asistente, a.nombre
    FROM public.asistente a WHERE a.categoria_vip IS TRUE ORDER BY a.id_asistente;
END;
$$;

-- 10. Proveedores de un rubro asociados a eventos no cancelados.
CREATE FUNCTION public.fn_proveedores_por_rubro(p_rubro varchar)
RETURNS TABLE(empresa varchar, telefono varchar, evento varchar)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
BEGIN
    -- Contrata enlaza las empresas con la necesidad operativa concreta.
    RETURN QUERY SELECT p.nombre_empresa, p.telefono, ev.nombre_evento
    FROM public.proveedor p JOIN public.contrata ct ON ct.id_proveedor = p.id_proveedor
         JOIN public.evento ev ON ev.id_evento = ct.id_evento
    WHERE p.rubro ILIKE '%' || p_rubro || '%' AND ev.estado_evento <> 'Cancelado'
    ORDER BY p.nombre_empresa, ev.id_evento;
END;
$$;

-- 11. Venta con serializacion por zona; precio oficial tomado del catalogo.
CREATE FUNCTION public.fn_procesar_venta_segura(p_asistente integer, p_entrada integer)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
DECLARE v_capacidad integer; v_precio integer; v_estado varchar; v_vendidas bigint;
BEGIN
    -- Bloquea la zona: las ventas concurrentes de esa zona cuentan tras esperar.
    SELECT te.capacidad, te.precio, ev.estado_evento
    INTO v_capacidad, v_precio, v_estado
    FROM public.tipo_entrada te JOIN public.evento ev ON ev.id_evento = te.id_evento
    WHERE te.id_entrada = p_entrada FOR UPDATE OF te;
    IF NOT FOUND THEN RAISE EXCEPTION 'Zona % inexistente', p_entrada; END IF;
    IF v_estado = 'Cancelado' THEN
        RAISE NOTICE 'Venta rechazada: evento cancelado.'; RETURN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.asistente a WHERE a.id_asistente = p_asistente) THEN
        RAISE EXCEPTION 'Asistente % inexistente', p_asistente;
    END IF;
    SELECT COUNT(*) INTO v_vendidas FROM public.compra c
    WHERE c.id_entrada = p_entrada AND c.estado_compra = 'Completada';
    IF v_vendidas >= v_capacidad THEN
        RAISE NOTICE 'Venta rechazada: zona sin cupos.'; RETURN;
    ELSE
        -- No acepta un importe suministrado por cliente; usa el precio vigente.
        INSERT INTO public.compra(id_asistente, id_entrada, fecha_creacion, fecha_expiracion,
                                  estado_compra, fecha_compra, monto_total, metodo_pago)
        VALUES (p_asistente, p_entrada, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + interval '15 minutes',
                'Completada', CURRENT_TIMESTAMP, v_precio, 'Débito');
        RAISE NOTICE 'Venta aprobada: precio %, cupos restantes %.', v_precio, v_capacidad - v_vendidas - 1;
    END IF;
END;
$$;

-- 12. Limpieza de reservas vencidas; solo filas Pendiente.
CREATE FUNCTION public.fn_limpiar_reservas_expiradas()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
DECLARE r record; v_total integer := 0;
BEGIN
    -- FOR LOOP permite auditar cada id realmente modificado.
    FOR r IN SELECT c.id_compra FROM public.compra c
             WHERE c.estado_compra = 'Pendiente' AND c.fecha_expiracion < CURRENT_TIMESTAMP
             FOR UPDATE SKIP LOCKED
    LOOP
        UPDATE public.compra SET estado_compra = 'Expirada' WHERE id_compra = r.id_compra;
        v_total := v_total + 1;
        RAISE NOTICE 'Reserva % expirada.', r.id_compra;
    END LOOP;
    RAISE NOTICE 'Total de reservas expiradas: %.', v_total;
END;
$$;

-- En PostgreSQL las funciones nuevas son ejecutables por PUBLIC por defecto.
-- Limitar REVOKE/GRANT a estas 12: no alterar funciones ajenas del mismo esquema.
REVOKE EXECUTE ON FUNCTION public.fn_calcular_recaudacion_evento(integer),
    public.fn_generar_credencial_asistente(integer), public.fn_dias_para_evento(integer),
    public.fn_registrar_artista(varchar), public.fn_validar_ingreso_ticket(varchar),
    public.fn_suspender_evento(integer), public.fn_aforo_por_zona(integer),
    public.fn_contactos_productoras(date), public.fn_obtener_clientes_vip(),
    public.fn_proveedores_por_rubro(varchar),
    public.fn_procesar_venta_segura(integer, integer), public.fn_limpiar_reservas_expiradas()
    FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fn_calcular_recaudacion_evento(integer),
    public.fn_generar_credencial_asistente(integer), public.fn_dias_para_evento(integer),
    public.fn_registrar_artista(varchar), public.fn_validar_ingreso_ticket(varchar),
    public.fn_suspender_evento(integer), public.fn_aforo_por_zona(integer),
    public.fn_contactos_productoras(date), public.fn_obtener_clientes_vip(),
    public.fn_proveedores_por_rubro(varchar),
    public.fn_procesar_venta_segura(integer, integer), public.fn_limpiar_reservas_expiradas()
    TO rol_admin;
GRANT EXECUTE ON FUNCTION public.fn_validar_ingreso_ticket(varchar),
    public.fn_procesar_venta_segura(integer, integer), public.fn_aforo_por_zona(integer)
    TO rol_operador;
GRANT EXECUTE ON FUNCTION public.fn_calcular_recaudacion_evento(integer),
    public.fn_dias_para_evento(integer), public.fn_contactos_productoras(date)
    TO rol_finanzas;
GRANT EXECUTE ON FUNCTION public.fn_generar_credencial_asistente(integer),
    public.fn_obtener_clientes_vip(), public.fn_dias_para_evento(integer)
    TO rol_marketing;
GRANT EXECUTE ON FUNCTION public.fn_calcular_recaudacion_evento(integer),
    public.fn_aforo_por_zona(integer), public.fn_proveedores_por_rubro(varchar)
    TO rol_auditor;
-- Las tareas administrativas de mantenimiento y catalogo quedan solo en admin.

COMMIT;

-- =============================================================
-- PARTE 4. PRUEBAS DE LAS 12 FUNCIONES Y DE LOS PERMISOS
-- =============================================================
-- Para capturas en pgAdmin, seleccionar y ejecutar cada sentencia por separado
-- dentro de la MISMA sesion; no ejecutar la instalacion por segunda vez.
-- Pruebas reproducibles DESPUES de instalar script_taller6.sql.
-- Ejecutar con el propietario (postgres); transaccion reversible para no alterar datos.
-- En pgAdmin: ejecutar las consultas por separado para capturar Data Output y Messages.
BEGIN;
SELECT public.fn_calcular_recaudacion_evento(1) AS recaudacion_evento_1;
SELECT public.fn_generar_credencial_asistente(1) AS credencial_vip;
SELECT public.fn_dias_para_evento(1) AS dias_relativos; -- Negativo si fecha pasada.
SELECT public.fn_aforo_por_zona(1);
SELECT public.fn_contactos_productoras(DATE '2026-01-01') LIMIT 5;
SELECT public.fn_obtener_clientes_vip() LIMIT 5;
SELECT public.fn_proveedores_por_rubro('Seguridad') LIMIT 5;

SELECT public.fn_registrar_artista('Artista demostracion T6');
SELECT nombre_artista FROM public.artista WHERE nombre_artista = 'Artista demostracion T6';
SELECT public.fn_validar_ingreso_ticket('QR_HASH_001_A');
SELECT estado FROM public.ticket WHERE codigo_qr = 'QR_HASH_001_A';
SELECT public.fn_validar_ingreso_ticket('QR_HASH_001_A'); -- Rechaza segundo acceso.
SELECT public.fn_procesar_venta_segura(1, 1);
SELECT id_compra, monto_total, estado_compra FROM public.compra
 WHERE id_entrada = 1 ORDER BY id_compra DESC LIMIT 1;
-- Se usa el evento 5 para mostrar la anulación de un QR todavía emitido.
SELECT public.fn_suspender_evento(5);
SELECT estado_evento FROM public.evento WHERE id_evento = 5;
SELECT codigo_qr, estado FROM public.ticket WHERE codigo_qr = 'QR_HASH_005_E';
SELECT public.fn_procesar_venta_segura(1, 5); -- Rechaza venta de evento cancelado.

-- No hay compras Pendiente en los datos originales: crear una muestra reversible.
INSERT INTO public.compra(id_asistente, id_entrada, fecha_creacion, fecha_expiracion,
                           estado_compra, fecha_compra, monto_total, metodo_pago)
VALUES (1, 2, CURRENT_TIMESTAMP - interval '2 hours', CURRENT_TIMESTAMP - interval '1 hour',
        'Pendiente', NULL, 30000, NULL);
SELECT public.fn_limpiar_reservas_expiradas();
SELECT id_compra, estado_compra FROM public.compra
 WHERE estado_compra = 'Expirada' ORDER BY id_compra DESC LIMIT 3;
ROLLBACK; -- Todos los cambios de esta prueba desaparecen; las funciones permanecen.

-- Comprobaciones de permisos (solo lectura). t=permitido, f=denegado.
SELECT has_function_privilege('usuario_caja', 'public.fn_procesar_venta_segura(integer,integer)', 'EXECUTE') AS caja_vende,
       has_function_privilege('usuario_caja', 'public.fn_calcular_recaudacion_evento(integer)', 'EXECUTE') AS caja_no_finanzas,
       has_table_privilege('usuario_caja', 'public.compra', 'DELETE') AS caja_no_borra;
SELECT has_function_privilege('usuario_reportes', 'public.fn_calcular_recaudacion_evento(integer)', 'EXECUTE') AS reportes_finanzas,
       has_function_privilege('usuario_reportes', 'public.fn_proveedores_por_rubro(varchar)', 'EXECUTE') AS reportes_no_auditoria,
       has_function_privilege('usuario_auditoria', 'public.fn_proveedores_por_rubro(varchar)', 'EXECUTE') AS auditoria_proveedores,
       has_function_privilege('usuario_marketing', 'public.fn_obtener_clientes_vip()', 'EXECUTE') AS marketing_vip;
-- Conectar efectivamente como cada usuario para evidencia de uso real (no probar como superusuario).
