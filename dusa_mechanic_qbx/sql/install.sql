-- =========================================================
-- dusa_mechanic_qbx :: Database Schema
-- Run on your QBX database
-- =========================================================

CREATE TABLE IF NOT EXISTS `dusa_mechanic_vehicles` (
    `plate` VARCHAR(16) NOT NULL,
    `nos_installed` TINYINT(1) DEFAULT 0,
    `nos_fuel` FLOAT DEFAULT 0,
    `engine_wear` FLOAT DEFAULT 0,
    `brake_wear` FLOAT DEFAULT 0,
    `last_service` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `dusa_mechanic_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(64) NOT NULL,
    `action` VARCHAR(64) NOT NULL,
    `plate` VARCHAR(16),
    `amount` INT DEFAULT 0,
    `meta` LONGTEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY `idx_citizen` (`citizenid`),
    KEY `idx_plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `dusa_mechanic_society` (
    `name` VARCHAR(64) NOT NULL,
    `balance` INT DEFAULT 0,
    PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed society
INSERT IGNORE INTO `dusa_mechanic_society` (`name`, `balance`) VALUES ('mechanic', 0);

-- Optional ox_inventory items (add to your items.lua/database)
-- repairkit, advancedrepairkit, cleaningkit, nos_bottle, nos_refill, diagnostic_scanner, towrope
