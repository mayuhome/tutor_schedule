# 家教日程管家 (TutorSchedule)

一款专为私人家庭教师设计的本地日程管理工具，无需联网，数据全本地存储。

## 功能特性

- **学生信息管理** - 管理学生档案、联系方式、科目标签
- **课程安排** - 周视图/月视图排课，支持重复规则和冲突检测
- **课程记录** - 记录教学内容、作业布置、学生表现评分
- **数据分析** - 课时统计、收入预估、科目分布图表
- **课程提醒** - 本地通知推送
- **数据导出** - CSV/Excel 格式导出

## 技术栈

| 技术 | 用途 |
|------|------|
| Flutter 3.x | 跨平台 UI 框架 |
| Riverpod | 状态管理 |
| Drift (SQLite) | 本地数据库 |
| go_router | 路由管理 |
| fl_chart | 图表渲染 |
| flutter_local_notifications | 本地通知 |

## 快速开始

### 前置要求

1. 安装 [Flutter SDK](https://flutter.dev/docs/get-started/install)
2. 配置 Flutter 环境变量
3. 运行 `flutter doctor` 检查环境

### 安装依赖

```bash
cd tutor_schedule
flutter pub get
```

### 生成数据库代码

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 运行应用

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome
```

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── app.dart                  # 应用配置
├── config/                   # 配置文件
│   ├── theme/               # 主题配置
│   ├── routes/              # 路由配置
│   └── constants.dart       # 常量定义
├── core/                    # 核心模块
│   ├── database/            # 数据库
│   │   ├── tables/          # 表定义
│   │   └── daos/            # 数据访问对象
│   ├── utils/               # 工具类
│   └── extensions/          # 扩展方法
├── features/                # 功能模块
│   ├── home/               # 首页
│   ├── students/           # 学生管理
│   ├── schedule/           # 课程安排
│   ├── course_records/     # 课程记录
│   ├── analytics/          # 数据分析
│   └── settings/           # 设置
└── shared/                  # 共享组件
    ├── widgets/            # 通用组件
    └── models/             # 通用模型
```

## 数据库表结构

- **students** - 学生信息表
- **course_records** - 课程记录表
- **schedules** - 课程安排表
- **progress_entries** - 学习进度表

## 平台支持

- Android (API 21+)
- iOS (13.0+)
- Web (Chrome, Safari, Firefox)

## 开发说明

### 生成代码

```bash
# 一次性生成
dart run build_runner build

# 监听文件变化自动生成
dart run build_runner watch
```

### 清理生成文件

```bash
dart run build_runner clean
```

## License

MIT License
