# Android 配置说明

> 本项目 `lib/` 目录是完整的 Dart 源码；`android/` 平台目录需由 `flutter create` 生成（因为 Gradle Wrapper 等二进制文件无法以文本方式提供）。生成后按本文档修改两处即可。

## 1. 修改 `android/app/src/main/AndroidManifest.xml`

用下面内容**替换** `<manifest>` 标签内的权限部分（保留原有的 `<application>` 等标签）：

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- 读取照片/视频所需权限（按 Android 版本区分） -->
    <uses-permission
        android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    <uses-permission android:name="android.permission.ACCESS_MEDIA_LOCATION" />

    <!-- 删除照片所需（Android 10 及以下） -->
    <uses-permission
        android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="29" />

    <application
        android:label="照片整理"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- 原有 activity 等内容保持不变 -->
    </application>
</manifest>
```

**关键点**：
- `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO` 用于 Android 13+。
- `READ_EXTERNAL_STORAGE` 用 `maxSdkVersion="32"`，Android 13 起不再需要。
- `WRITE_EXTERNAL_STORAGE` 仅 Android 10 及以下删除时用到，`maxSdkVersion="29"`。

## 2. 修改 `android/app/build.gradle`（或 `.kts`）中的 SDK 版本

找到 `defaultConfig`，确保：

```gradle
android {
    defaultConfig {
        minSdk = 21        // 或 minSdkVersion 21
        targetSdk = 34     // ML Kit 1.x 建议 >= 34（最新可设 36）
        // ...
    }
    compileSdk = 36       // ML Kit 1.x 要求 >= 34
}
```

**关键点**：
- `minSdk >= 21`：`photo_manager` 与 ML Kit 的最低要求。
- `compileSdk >= 34`：ML Kit 1.x 建议 36；若你 Android Studio 里没有这么新的 SDK，打开 **SDK Manager** 安装最新的 Android SDK Platform 即可。
- 若编译报 “compileSdk 版本不足”，把 `compileSdk` 数字调高，并在 SDK Manager 里勾选对应平台安装。

## 3. ML Kit 说明

- `google_mlkit_image_labeling` 使用 **本地离线模型**（打包进 APK），人物/风景/食物识别**无需联网**，也无需 Google Play 服务。
- 代价是 APK 体积会增加约 5~10 MB，属正常现象。
- `MainActivity.kt` 无需任何修改，`flutter create` 默认生成的即可。

## 4. 应用中文名与图标（可选）

- 应用名已在 Manifest 中设为「照片整理」。
- 图标：替换 `android/app/src/main/res/mipmap-*` 下的 `ic_launcher.png` 即可（或用 Android Studio 的 Image Asset 工具生成）。
