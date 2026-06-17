-- ========================================================
-- mechanic_tablet :: Database
-- Persists stance/mods per vehicle plate.
-- ========================================================

CREATE TABLE IF NOT EXISTS `mechanic_tablet_vehicles` (
    `plate` VARCHAR(16) NOT NULL,
    -- stance
    `wheel_width`  FLOAT DEFAULT 1.0,
    `wheel_size`   FLOAT DEFAULT 1.0,
    `susp_height`  FLOAT DEFAULT 0.0,
    `track_width`  FLOAT DEFAULT 0.0,
    `camber_front` FLOAT DEFAULT 0.0,
    `camber_rear`  FLOAT DEFAULT 0.0,
    -- performance
    `engine_lvl`   INT   DEFAULT -1,
    `brake_lvl`    INT   DEFAULT -1,
    `trans_lvl`    INT   DEFAULT -1,
    `susp_lvl`     INT   DEFAULT -1,
    `turbo`        TINYINT(1) DEFAULT 0,
    -- looks
    `primary_r`    INT, `primary_g` INT, `primary_b` INT,
    `secondary_r`  INT, `secondary_g` INT, `secondary_b` INT,
    `neon_r`       INT, `neon_g`     INT, `neon_b`     INT,
    `xenon_idx`    INT,
    `plate_idx`    INT,
    `wheel_type`   INT,
    `wheel_mod`    INT,
    `updated_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
