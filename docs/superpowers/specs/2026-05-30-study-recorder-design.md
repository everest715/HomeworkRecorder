# 学习记录器 (Study Recorder) — 设计文档

> 日期：2026-05-30
> 状态：已审核

## 1. 概述

一款跨平台（Android / iOS / Windows）学习记录应用，核心场景为**家长监督孩子学习**，同时支持孩子自主操作。主要功能包括计时器（正计时 + 可选倒计时）、学习记录与多维度完成情况评估、以及周/月/学期统计。

### 目标用户

- **主要**：家长 — 监督学习质量、查看统计数据
- **次要**：孩子 — 自主启动计时器、完成学习任务

### 设计原则

- 本地优先，离线可用，后期可选云同步
- 轻量架构，快速交付 MVP
- 双角色（家长/孩子）权限区分

## 2. 页面结构与导航

### 底部导航 4 Tab

| Tab | 图标 | 功能 |
|-----|------|------|
| 记录 | 📋 | 今日/本周学习记录概览，快速新建，查看历史 |
| 计时 | ⏱️ | 大字体计时显示，正计时/倒计时切换，暂停/继续/结束 |
| 统计 | 📊 | 周/月/学期视图切换，多维度图表 |
| 设置 | ⚙️ | 科目/类型管理、角色切换、云同步、主题 |

### 子页面

- **新建记录**：选择科目 + 类型 → 启动计时
- **记录详情**：查看/编辑完成情况评分
- **单科目统计**：某科目的深度趋势分析

### 核心用户流程

```
① 新建记录 → 选择科目 & 类型 → 启动计时器 → 学习中…
② 计时结束 → 自动弹出完成情况表单 → 录入正确率/专注度/速度/难度
③ 查看统计 → 切换周/月/学期 → 图表展示各维度趋势
```

## 3. 数据模型

### 3.1 学习记录 (StudyRecord)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String (UUID) | 主键 |
| subjectId | String | 关联科目 |
| typeId | String | 关联类型 |
| date | DateTime | 学习日期 |
| durationSeconds | int | 实际耗时（秒） |
| timerMode | enum | countup / countdown |
| targetSeconds | int? | 倒计时时长（仅倒计时模式） |
| note | String? | 文字备注 |

### 3.2 完成情况 (CompletionRating) — 与记录 1:1

| 字段 | 类型 | 说明 |
|------|------|------|
| recordId | String | 关联学习记录 |
| accuracy | int (1-5) | 正确率评分 |
| focus | int (1-5) | 专注度评分 |
| speed | int (1-5) | 完成速度评分 |
| difficulty | int (1-5) | 难易度评分 |
| note | String? | 补充备注 |

### 3.3 科目 (Subject)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 主键 |
| name | String | 科目名（语文、数学…） |
| icon | String | 图标标识 |
| color | String | 主题色 |
| isCustom | bool | 是否用户自定义 |
| sortOrder | int | 排序 |

### 3.4 类型 (StudyType)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 主键 |
| name | String | 类型名（练习卷、作文、朗读…） |
| isCustom | bool | 是否用户自定义 |
| sortOrder | int | 排序 |

### 3.5 用户设置 (UserSettings)

| 字段 | 类型 | 说明 |
|------|------|------|
| currentRole | enum | parent / child |
| defaultTimerMode | enum | countup / countdown |
| defaultCountdownMinutes | int | 默认倒计时分钟数 |
| cloudSyncEnabled | bool | 云同步开关 |
| themeMode | enum | light / dark / system |

### 实体关系

```
Subject 1───N StudyRecord N───1 StudyType
                    │
                    1
                    │
              CompletionRating
```

## 4. 核心 UI 设计

### 4.1 记录列表页

- 顶部：日期 + "今日学习"标题 + 新建按钮
- 概览卡片：今日时长 / 完成数 / 平均专注度
- 记录条目：按科目分色左边框，显示科目图标+名称、类型、时长、专注度和正确率星级

### 4.2 计时器页

- 顶部：科目选择 Chips + 类型选择
- 中部：大字体计时环（180px 圆环），显示当前计时
- 模式切换：正计时 / 倒计时 Toggle
- 控制按钮：暂停 ⏸️ / 停止 ⏹️ / 重置 🔄

### 4.3 完成情况录入

- 计时结束后自动弹出
- 4 个滑块评分：🎯正确率 / 🧠专注度 / ⚡完成速度 / 💪难易度（1-5 分）
- 选填文字备注
- 保存按钮

### 4.4 统计页

- **周视图**：每日学习时长柱状图 + 科目时间分布饼图 + 概览数据（总时长/完成数/综合评分）
- **月视图**：正确率/专注度趋势折线图
- **学期视图**：各科目累计时长 + 综合评分横向对比条

## 5. 技术架构

### 5.1 技术栈

| 层面 | 选型 | 理由 |
|------|------|------|
| 框架 | Flutter 3.x | 多平台需求 |
| 状态管理 | Riverpod 2.x | 轻量、编译安全 |
| 本地数据库 | Drift (SQLite) | 类型安全、迁移支持好 |
| 本地 KV | SharedPreferences | 简单配置存储 |
| 图表 | fl_chart | 纯 Dart 实现、跨平台一致 |
| 路由 | GoRouter | 声明式路由、深链接支持 |
| 云同步 (后期) | Supabase | 开源、国内可用、REST API |
| 国际化 | flutter_localizations | 首版中文，架构预留 i18n |

### 5.2 项目结构

```
lib/
├── main.dart
├── app.dart                    # MaterialApp + GoRouter
├── models/                     # 纯数据模型类
│   ├── study_record.dart
│   ├── completion_rating.dart
│   ├── subject.dart
│   ├── study_type.dart
│   └── user_settings.dart
├── database/                   # Drift 数据层
│   ├── app_database.dart       # Database 定义 + 表
│   ├── app_database.g.dart     # 生成代码
│   └── daos/                   # 数据访问对象
│       ├── records_dao.dart
│       ├── subjects_dao.dart
│       └── stats_dao.dart
├── providers/                  # Riverpod providers
│   ├── database_provider.dart
│   ├── records_provider.dart
│   ├── timer_provider.dart
│   ├── stats_provider.dart
│   └── settings_provider.dart
├── pages/                      # 页面
│   ├── records/
│   │   ├── records_page.dart
│   │   ├── record_detail_page.dart
│   │   └── new_record_page.dart
│   ├── timer/
│   │   └── timer_page.dart
│   ├── stats/
│   │   ├── stats_page.dart
│   │   └── subject_stats_page.dart
│   └── settings/
│       └── settings_page.dart
├── widgets/                    # 共享组件
│   ├── rating_slider.dart
│   ├── subject_chip.dart
│   └── timer_display.dart
└── utils/
    ├── constants.dart
    └── formatters.dart
```

### 5.3 关键实现细节

**计时器**：使用 `Stream.periodic` 驱动，Riverpod `Notifier` 管理状态。App 进入后台时记录暂停时间戳，恢复时计算差值，确保计时准确。

**统计查询**：在 DAO 层用 SQL 聚合（按日/周/月分组），避免全量加载到内存。

**角色切换**：家长可查看所有功能包括统计和设置；孩子模式隐藏设置中的敏感项，简化界面。

**云同步（后期）**：通过 Repository 抽象层平滑引入 Supabase，本地优先策略不变。

## 6. 预设数据

### 科目预设

| 名称 | 图标 | 主题色 |
|------|------|--------|
| 语文 | 📖 | #FFA726 |
| 数学 | 📐 | #E94560 |
| 英语 | 🔤 | #AB47BC |
| 物理 | ⚡ | #4FC3F7 |
| 化学 | 🧪 | #66BB6A |
| 生物 | 🌱 | #8BC34A |
| 历史 | 🏛️ | #8D6E63 |
| 地理 | 🌍 | #26A69A |
| 政治 | 📜 | #78909C |

### 类型预设

练习卷、作业本、作文、朗读、背诵、预习、复习、笔记
