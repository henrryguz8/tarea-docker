-- Script opcional de inicialización (se ejecuta solo la primera vez que se crea el volumen)
CREATE TABLE IF NOT EXISTS healthcheck (
  id INT AUTO_INCREMENT PRIMARY KEY,
  mensaje VARCHAR(100) NOT NULL,
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO healthcheck (mensaje) VALUES ('Base de datos inicializada correctamente');
