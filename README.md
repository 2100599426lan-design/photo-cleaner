# 照片整理（Photo Cleaner）

一款安卓照片分类筛选与一键删除工具，用 Flutter 开发，**全程本地运行、不上传照片**。

## 功能

| 分类/筛选 | 说明 |
| --- | --- |
| 全部 | 浏览所有照片/视频 |
| 截图 | 按来源目录 + 屏幕宽高比识别 |
| 自拍 | 按来源目录识别（弱启发式，可配合 AI） |
| 文档 | 按纸张宽高比 + 目录识别 |
| 视频 | 所有视频 |
| 连拍 | 2 秒内连续拍摄 ≥3 张的连拍照片 |
| 重复/相似 | 差异哈希（dHash）+ 汉明距离分组 |
| 模糊 | 拉普拉斯方差检测低清晰度照片 |
| 人物 / 风景 / 食物 | 本地 AI 图像标签（ML Kit，离线模型） |
| 大文件 | 大于 50MB 的视频/文件，按大小排序 |
| 早期照片 | 一年前的照片 |
| 时间 + 大小筛选 | 自定义拍摄时间范围与文件大小范围 |

**删除**：多选后一键删除，走 Android 系统回收站（Android 11+ 可恢复）。

## 技术栈

- Flutter / Dart
- `photo_manager`：相册读取、权限、分页、缩略图
- `image`：本地图像解码（缩略图 → 哈希 / 清晰度）
- `provider`：状态管理
- `google_mlkit_image_labeling`：本地 AI 标签（人物/风景/食物等）

## 目录结构

```
lib/
├── main.dart                  # 入口
├── app.dart                   # 根组件与主题
├── models/
│   ├── photo_item.dart        # 照片数据模型
│   └── filter_category.dart   # 分类枚举 + 时间大小筛选
├── services/
│   ├── gallery_service.dart   # 相册读取与权限
│   ├── image_processor.dart   # dHash + 拉普拉斯清晰度
│   ├── photo_classifier.dart  # 类型启发式分类
│   ├── duplicate_detector.dart# 重复/相似分组
│   ├── blur_detector.dart     # 模糊判断
│   ├── ai_labeler.dart        # AI 标签
│   ├── delete_service.dart    # 删除（回收站）
│   └── analysis_service.dart  # 分析聚合 + 连拍 + 筛选
├── state/
│   └── gallery_state.dart     # 全局状态
└── ui/
    └── home_page.dart         # 首页（网格 + 分类 + 筛选 + 删除）
```

## 快速开始

完整零基础教程见 [`docs/搭建教程.md`](docs/搭建教程.md)，Android 权限配置见 [`docs/Android配置.md`](docs/Android配置.md)。

简要步骤：

```bash
# 1. 安装 Flutter SDK + Android Studio（见教程）
# 2. 生成工程骨架（用 flutter create 补齐 android/ios 平台目录）
flutter create --org com.example --project-name photo_cleaner .

# 3. 安装依赖（若版本报错，见教程中的修复方法）
flutter pub get

# 4. 连接安卓手机（开启 USB 调试）后运行
flutter run
```

## 注意事项

- 首次使用前建议先备份相册。
- “模糊”与“重复”阈值可能与不同机型存在偏差，可在 `lib/services/blur_detector.dart`、`lib/services/duplicate_detector.dart` 中调整。
- 删除走系统回收站，删除后仍可在系统相册的“回收站/已删除”中恢复。
