CREATE TABLE IF NOT EXISTS `police_role_definitions` (
    `name` VARCHAR(50) NOT NULL PRIMARY KEY,
    `label` VARCHAR(100) NOT NULL,
    `description` TEXT NULL,
    `permissions` LONGTEXT NULL,
    `is_default` TINYINT(1) NOT NULL DEFAULT 0,
    `created_by` VARCHAR(50) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_roles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `role` VARCHAR(50) NOT NULL,
    `granted_by` VARCHAR(50) NULL,
    `granted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uniq_player_role` (`citizenid`, `role`),
    KEY `idx_citizenid` (`citizenid`),
    KEY `idx_role` (`role`),
    CONSTRAINT `fk_police_roles_def` FOREIGN KEY (`role`)
        REFERENCES `police_role_definitions`(`name`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_weapon_licenses` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `class` TINYINT NOT NULL,
    `issued_by` VARCHAR(50) NULL,
    `issued_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `revoked` TINYINT(1) NOT NULL DEFAULT 0,
    `revoked_by` VARCHAR(50) NULL,
    `revoked_at` TIMESTAMP NULL DEFAULT NULL,
    KEY `idx_wl_cid` (`citizenid`),
    KEY `idx_wl_active` (`citizenid`, `class`, `revoked`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_mdt_records` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `type` VARCHAR(20) NOT NULL,
    `title` VARCHAR(200) NULL,
    `body` TEXT NULL,
    `severity` VARCHAR(20) NULL,
    `fine` INT NOT NULL DEFAULT 0,
    `jail_minutes` INT NOT NULL DEFAULT 0,
    `officer_cid` VARCHAR(50) NULL,
    `officer_name` VARCHAR(100) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `resolved` TINYINT(1) NOT NULL DEFAULT 0,
    KEY `idx_mdt_cit` (`citizenid`),
    KEY `idx_mdt_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_mdt_bolos` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `subject` VARCHAR(200) NOT NULL,
    `description` TEXT NULL,
    `severity` VARCHAR(20) NULL,
    `created_by` VARCHAR(50) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    KEY `idx_bolo_active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
