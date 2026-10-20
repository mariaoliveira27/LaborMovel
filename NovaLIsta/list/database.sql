-- Script de Criação do Banco de Dados e Tabela MySQL
-- Projeto: Aplicativo de Lista de Tarefas (Laboratório Móvel)

CREATE DATABASE IF NOT EXISTS `tarefas_db` 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE `tarefas_db`;

CREATE TABLE IF NOT EXISTS `tarefas` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `titulo` VARCHAR(255) NOT NULL,
  `concluida` TINYINT(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Inserção de dados de teste (opcional):
INSERT INTO `tarefas` (`titulo`, `concluida`) VALUES
('Preparar apresentação de Laboratório Móvel', 0),
('Comprar pão e leite', 1),
('Estudar Flutter e MySQL', 0);
