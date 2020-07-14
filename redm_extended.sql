CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL,
  `license` varchar(50) NOT NULL,
  `vip_level` int(11) NOT NULL DEFAULT '0',
  `group` varchar(50) NOT NULL DEFAULT 'user',
  `registered` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`,`identifier`,`license`) USING BTREE
);

CREATE TABLE IF NOT EXISTS `characters` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(60) NOT NULL,
  `character_id` int(11) NOT NULL,
  `accounts` longtext,
  `inventory` longtext,
  `loadout` longtext,
  `skin` longtext,
  `job` varchar(50) DEFAULT 'unemployed',
  `job_grade` int(11) DEFAULT '0',
  `position` varchar(255) DEFAULT NULL,
  `firstname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'first',
  `lastname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'last',
  `sex` char(1) DEFAULT 'M',

  PRIMARY KEY (`id`,`identifier`,`character_id`) USING BTREE
);

CREATE TABLE IF NOT EXISTS `items` (
  `name` varchar(50) NOT NULL,
  `label` varchar(50) NOT NULL,
  `weight` int(11) NOT NULL DEFAULT '1',
  `rare` tinyint(4) NOT NULL DEFAULT '0',
  `can_remove` tinyint(4) NOT NULL DEFAULT '1',

  PRIMARY KEY (`name`)
);

CREATE TABLE IF NOT EXISTS `jobs` (
  `name` varchar(50) NOT NULL,
  `label` varchar(50) DEFAULT NULL,

  PRIMARY KEY (`name`)
);

INSERT INTO `jobs` VALUES ('unemployed','Unemployed');

CREATE TABLE IF NOT EXISTS `job_grades` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) DEFAULT NULL,
  `grade` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `label` varchar(50) NOT NULL,
  `salary` int(11) NOT NULL,
  `skin_male` longtext NOT NULL,
  `skin_female` longtext NOT NULL,

  PRIMARY KEY (`id`)
);

INSERT INTO `job_grades` VALUES (1,'unemployed',0,'unemployed','Unemployed',200,'{}','{}');
