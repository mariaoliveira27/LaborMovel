-- Script para criação do banco de dados e tabela no MySQL
-- Caso queira executar manualmente no phpMyAdmin, MySQL Workbench ou terminal:

CREATE DATABASE IF NOT EXISTS lista_tarefas;
USE lista_tarefas;

CREATE TABLE IF NOT EXISTS tarefas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  titulo VARCHAR(255) NOT NULL,
  concluida TINYINT(1) NOT NULL DEFAULT 0
);

-- Exemplos iniciais (opcional):
INSERT INTO tarefas (titulo, concluida) VALUES 
('Estudar Flutter e Dart', 1),
('Fazer atividade de LaborMovel', 0),
('Conectar aplicativo ao MySQL', 1);

