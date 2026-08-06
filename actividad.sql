-- =====================================================
-- SCRIPT ÚNICO - FUNCIONES SQL
-- Motor: MySQL / MariaDB
-- =====================================================

-- Si ya tienes una base de datos creada, puedes comentar
-- las siguientes dos líneas y cambiar USE por tu base.
CREATE DATABASE IF NOT EXISTS funciones_ejemplo
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE funciones_ejemplo;

-- =====================================================
-- Si tienes error al crear funciones por binary log,
-- ejecuta antes, con permisos suficientes:
-- SET GLOBAL log_bin_trust_function_creators = 1;
-- =====================================================

SET FOREIGN_KEY_CHECKS = 0;

-- =====================================================
-- ELIMINAR OBJETOS SI YA EXISTEN
-- =====================================================

DROP FUNCTION IF EXISTS calcular_iva;
DROP FUNCTION IF EXISTS precio_con_iva;
DROP FUNCTION IF EXISTS celsius_a_fahrenheit;
DROP FUNCTION IF EXISTS precio_con_descuento;
DROP FUNCTION IF EXISTS promedio_ventas_vendedor;
DROP FUNCTION IF EXISTS mensaje_bienvenida;
DROP FUNCTION IF EXISTS obtener_poblacion_pais;
DROP FUNCTION IF EXISTS total_ciudades_y_hora;

DROP TABLE IF EXISTS ciudades;
DROP TABLE IF EXISTS paises;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS ventas;
DROP TABLE IF EXISTS vendedores;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================
-- CREAR TABLAS
-- =====================================================

CREATE TABLE vendedores (
    id_vendedor INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE ventas (
    id_venta INT PRIMARY KEY AUTO_INCREMENT,
    id_vendedor INT NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    fecha_venta DATE NULL,
    FOREIGN KEY (id_vendedor) REFERENCES vendedores(id_vendedor)
);

CREATE TABLE clientes (
    id_cliente INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    tipo_cliente VARCHAR(20) DEFAULT 'REGULAR'
);

CREATE TABLE paises (
    id_pais INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    poblacion BIGINT NOT NULL
);

CREATE TABLE ciudades (
    id_ciudad INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    id_pais INT,
    FOREIGN KEY (id_pais) REFERENCES paises(id_pais)
);

-- =====================================================
-- INSERTAR DATOS DE EJEMPLO
-- =====================================================

INSERT INTO vendedores (id_vendedor, nombre) VALUES
(1, 'Carlos Pérez'),
(2, 'María Gómez');

INSERT INTO ventas (id_venta, id_vendedor, total) VALUES
(1, 1, 150.00),
(2, 1, 200.00),
(3, 1, 250.00),
(4, 2, 500.00),
(5, 2, 300.00);

INSERT INTO clientes (id_cliente, nombre, tipo_cliente) VALUES
(1, 'Juan Rodríguez', 'REGULAR'),
(2, 'Ana Martínez', 'VIP'),
(3, 'Luis Torres', 'NUEVO');

INSERT INTO paises (id_pais, nombre, poblacion) VALUES
(1, 'México', 129000000),
(2, 'Colombia', 52000000),
(3, 'Argentina', 46000000),
(4, 'España', 48000000);

INSERT INTO ciudades (id_ciudad, nombre, id_pais) VALUES
(1, 'Ciudad de México', 1),
(2, 'Guadalajara', 1),
(3, 'Bogotá', 2),
(4, 'Medellín', 2),
(5, 'Buenos Aires', 3),
(6, 'Madrid', 4);

-- =====================================================
-- FUNCIONES
-- =====================================================

-- =====================================================
-- 1. Función para calcular el IVA de un producto
-- =====================================================

DELIMITER //

CREATE FUNCTION calcular_iva(
    precio DECIMAL(10,2),
    porcentaje_iva DECIMAL(5,2)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    RETURN precio * (porcentaje_iva / 100);
END //

DELIMITER ;

-- =====================================================
-- Función opcional: precio final con IVA incluido
-- =====================================================

DELIMITER //

CREATE FUNCTION precio_con_iva(
    precio DECIMAL(10,2),
    porcentaje_iva DECIMAL(5,2)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    RETURN precio * (1 + porcentaje_iva / 100);
END //

DELIMITER ;

-- =====================================================
-- 2. Función para convertir de Celsius a Fahrenheit
-- =====================================================

DELIMITER //

CREATE FUNCTION celsius_a_fahrenheit(
    grados_celsius DECIMAL(6,2)
)
RETURNS DECIMAL(6,2)
DETERMINISTIC
BEGIN
    RETURN (grados_celsius * 9 / 5) + 32;
END //

DELIMITER ;

-- =====================================================
-- 3. Función para calcular descuento según categoría
-- =====================================================

DELIMITER //

CREATE FUNCTION precio_con_descuento(
    precio DECIMAL(10,2),
    categoria VARCHAR(20)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE descuento DECIMAL(5,2) DEFAULT 0;

    SET descuento = CASE UPPER(TRIM(categoria))
        WHEN 'ESTANDAR' THEN 0
        WHEN 'VIP' THEN 15
        WHEN 'PALCO' THEN 25
        ELSE 0
    END;

    RETURN precio * (1 - descuento / 100);
END //

DELIMITER ;

-- =====================================================
-- 4. Función para calcular el promedio de ventas
--    de un vendedor específico
-- =====================================================

DELIMITER //

CREATE FUNCTION promedio_ventas_vendedor(
    p_id_vendedor INT
)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE promedio DECIMAL(10,2) DEFAULT 0;

    SELECT IFNULL(AVG(total), 0)
    INTO promedio
    FROM ventas
    WHERE id_vendedor = p_id_vendedor;

    RETURN promedio;
END //

DELIMITER ;

-- =====================================================
-- 5. Función para darle la bienvenida a un cliente
-- =====================================================

DELIMITER //

CREATE FUNCTION mensaje_bienvenida(
    p_id_cliente INT
)
RETURNS VARCHAR(255)
READS SQL DATA
BEGIN
    DECLARE v_nombre VARCHAR(100) DEFAULT NULL;
    DECLARE v_tipo VARCHAR(20) DEFAULT NULL;

    SELECT nombre, tipo_cliente
    INTO v_nombre, v_tipo
    FROM clientes
    WHERE id_cliente = p_id_cliente;

    IF v_nombre IS NULL THEN
        RETURN 'Cliente no encontrado.';
    END IF;

    RETURN CASE UPPER(TRIM(IFNULL(v_tipo, 'REGULAR')))
        WHEN 'VIP' THEN
            CONCAT(
                '¡Bienvenido(a) ', v_nombre,
                '! Gracias por su preferencia, usted es cliente VIP.'
            )
        WHEN 'NUEVO' THEN
            CONCAT(
                '¡Bienvenido(a) ', v_nombre,
                '! Nos alegra tenerle por primera vez.'
            )
        ELSE
            CONCAT(
                '¡Bienvenido(a) ', v_nombre,
                '! Gracias por visitarnos.'
            )
    END;
END //

DELIMITER ;

-- =====================================================
-- 6. Función para obtener la población de un país
-- =====================================================

DELIMITER //

CREATE FUNCTION obtener_poblacion_pais(
    p_nombre_pais VARCHAR(100)
)
RETURNS VARCHAR(150)
READS SQL DATA
BEGIN
    DECLARE v_poblacion BIGINT DEFAULT NULL;

    SELECT poblacion
    INTO v_poblacion
    FROM paises
    WHERE LOWER(TRIM(nombre)) = LOWER(TRIM(p_nombre_pais));

    IF v_poblacion IS NULL THEN
        RETURN 'País no encontrado.';
    END IF;

    RETURN CONCAT(
        'La población de ', TRIM(p_nombre_pais),
        ' es: ', FORMAT(v_poblacion, 0)
    );
END //

DELIMITER ;

-- =====================================================
-- 7. Función que devuelve el número de ciudades
--    y la hora actual
-- =====================================================

DELIMITER //

CREATE FUNCTION total_ciudades_y_hora()
RETURNS VARCHAR(150)
READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;

    SELECT COUNT(*)
    INTO v_total
    FROM ciudades;

    RETURN CONCAT(
        'Número de ciudades registradas: ', v_total,
        ' | Hora actual: ', NOW()
    );
END //

DELIMITER ;

-- =====================================================
-- PRUEBAS DE LAS FUNCIONES
-- =====================================================

SELECT
    100.00 AS precio,
    19 AS porcentaje_iva,
    calcular_iva(100.00, 19) AS iva,
    precio_con_iva(100.00, 19) AS precio_final;

SELECT celsius_a_fahrenheit(25) AS fahrenheit;

SELECT
    precio_con_descuento(200.00, 'ESTANDAR') AS precio_estandar,
    precio_con_descuento(200.00, 'VIP') AS precio_vip,
    precio_con_descuento(200.00, 'PALCO') AS precio_palco;

SELECT
    promedio_ventas_vendedor(1) AS promedio_vendedor_1,
    promedio_ventas_vendedor(2) AS promedio_vendedor_2;

SELECT
    mensaje_bienvenida(1) AS saludo_cliente_1,
    mensaje_bienvenida(2) AS saludo_cliente_2,
    mensaje_bienvenida(3) AS saludo_cliente_3;

SELECT obtener_poblacion_pais('México') AS poblacion_mexico;

SELECT obtener_poblacion_pais('Perú') AS pais_no_encontrado;

SELECT total_ciudades_y_hora() AS ciudades_y_hora;