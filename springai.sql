/*
 Navicat Premium Data Transfer

 Source Server         : localhost
 Source Server Type    : MySQL
 Source Server Version : 80032 (8.0.32)
 Source Host           : localhost:3306
 Source Schema         : springai

 Target Server Type    : MySQL
 Target Server Version : 80032 (8.0.32)
 File Encoding         : 65001

 Date: 19/04/2025 22:04:07
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for history
-- ----------------------------
DROP TABLE IF EXISTS `history`;
CREATE TABLE `history`  (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `question` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL,
  `result` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL,
  `username` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `user_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `time` timestamp NULL DEFAULT NULL
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Table structure for user
-- ----------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user`  (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `username` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `phone` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

SET FOREIGN_KEY_CHECKS = 1;


-- 创建简历表
CREATE TABLE `resume` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `user_id` VARCHAR(32) NOT NULL COMMENT '用户ID',
    `name` VARCHAR(50) DEFAULT NULL COMMENT '姓名',
    `phone` VARCHAR(20) DEFAULT NULL COMMENT '电话',
    `email` VARCHAR(100) DEFAULT NULL COMMENT '邮箱',
    `job_status` VARCHAR(20) DEFAULT NULL COMMENT '求职状态',
    `job_title` VARCHAR(100) DEFAULT NULL COMMENT '期望职位',
    `salary_expectation` VARCHAR(50) DEFAULT NULL COMMENT '期望薪资',
    `education` TEXT DEFAULT NULL COMMENT '教育经历(JSON)',
    `profession` TEXT DEFAULT NULL COMMENT '专业技能(JSON)',
    `work` TEXT DEFAULT NULL COMMENT '工作经历(JSON)',
    `project` TEXT DEFAULT NULL COMMENT '项目经历(JSON)',
    `award` TEXT DEFAULT NULL COMMENT '获奖情况(JSON)',
    `update_time` DATETIME NOT NULL COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_update_time` (`update_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='简历信息表';


-- 职位分类表
CREATE TABLE `job_category` (
    `id` INT NOT NULL AUTO_INCREMENT COMMENT '分类ID',
    `name` VARCHAR(50) NOT NULL COMMENT '分类名称',
    `description` VARCHAR(200) DEFAULT NULL COMMENT '分类描述',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='职位分类表';

-- 职位表
CREATE TABLE `job_position` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '职位ID',
    `category_id` INT NOT NULL COMMENT '分类ID',
    `title` VARCHAR(100) NOT NULL COMMENT '职位名称',
    `description` TEXT NOT NULL COMMENT '职位描述',
    `required_skills` TEXT NOT NULL COMMENT '所需技能',
    `experience_requirement` VARCHAR(50) DEFAULT NULL COMMENT '经验要求',
    `education_requirement` VARCHAR(50) DEFAULT NULL COMMENT '学历要求',
    `salary_range` VARCHAR(50) DEFAULT NULL COMMENT '薪资范围',
    `company_name` VARCHAR(100) DEFAULT NULL COMMENT '公司名称',
    `location` VARCHAR(200) DEFAULT NULL COMMENT '工作地点',
    `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态(1:启用 0:禁用)',
    `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_category` (`category_id`),
    CONSTRAINT `fk_job_category` FOREIGN KEY (`category_id`) REFERENCES `job_category` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='职位信息表';
