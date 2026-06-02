# 学习记录器

一款帮助家长记录和管理孩子学习情况的 Flutter 应用。通过正计时/倒计时、学习记录追踪和可视化统计图表，让学习过程透明可量化。

## 特性

- **计时学习**：支持正计时和倒计时两种模式，可自由选择科目和学习类型，实时追踪学习时长
- **完成评价**：学习结束后对准确性、专注度、速度、难易程度四维度进行 1-5 分评价
- **学习记录**：所有计时记录持久保存，支持按日期筛选查看历史，可删除误录记录
- **数据统计**：按科目/类型维度展示学习时长分布柱状图，按天聚合展示时长趋势
- **科目管理**：支持自定义科目和学习类型，提供图标、颜色个性化设置，默认科目可隐藏
- **深色模式**：支持浅色/深色/跟随系统三种主题模式

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter 3.x + Dart 3.12 |
| 状态管理 | flutter_riverpod + riverpod_annotation |
| 路由 | go_router（StatefulShellRoute 底部导航） |
| 本地数据库 | Drift (SQLite) |
| 图表 | fl_chart |
| 本地存储 | shared_preferences + path_provider |
| 唯一标识 | uuid |

## 快速开始

### 环境要求

- Flutter SDK >= 3.12（[安装指南](https://docs.flutter.dev/get-started/install/windows)）
- Android Studio 或 Visual Studio Code
- Android SDK / iOS Xcode（按目标平台）

### 安装运行

```bash
# 克隆项目
git clone <repo-url> && cd HomeworkRecorder

# 安装依赖
flutter pub get

# 生成数据库代码
dart run build_runner build

# 运行
flutter run
```

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── app.dart                  # 根组件：路由配置 + 主题 + 底部导航
├── database/
│   ├── app_database.dart    # Drift 数据库实例
│   ├── tables.dart          # 数据表定义（科目/类型/记录/评价）
│   └── daos/               # 数据访问对象
├── models/
│   ├── timer_state.dart      # 计时器状态模型（模式/状态/已用时间）
│   └── user_settings.dart   # 用户设置模型（角色/主题/默认模式）
├── providers/               # Riverpod 状态提供者
├── pages/
│   ├── timer/              # 计时页面 + 完成评价弹窗
│   ├── records/            # 学习记录列表 + 详情页
│   ├── stats/              # 统计图表页
│   └── settings/           # 设置页（科目/类型管理 + 主题切换）
└── widgets/                # 复用组件（计时器显示）
```

## 页面一览

| 页面 | 功能 |
|------|------|
| 记录 | 按日期查看历史学习记录列表，支持点击查看详情和删除 |
| 计时 | 选择科目和类型后开始计时，结束后弹出完成评价表单 |
| 统计 | 柱状图展示各科目/类型学习时长分布，折线图展示每日时长趋势 |
| 设置 | 管理科目和类型（增删改、隐藏默认科目），切换主题模式 |