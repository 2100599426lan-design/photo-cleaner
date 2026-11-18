# 云端自动编译 APK（不用装 Flutter，最省事）

如果你**不想**在自己电脑上装 Flutter、Android Studio（这几个 GB 太折腾），可以用 GitHub 的免费服务器帮你编译出 APK。全程只需一个 GitHub 账号，在网页上操作，约 10~15 分钟出结果。

> 原理：GitHub 的“Actions”会在云端帮你自动跑 `flutter build apk`，编好后把 APK 上传，你直接下载即可。本项目里已经配好了自动编译脚本（`.github/workflows/build-apk.yml`），你只需把代码传上去。

---

## 第 1 步：注册 GitHub 账号

1. 打开 **https://github.com** ，点右上角 **Sign up** 注册。
2. 邮箱验证完成后登录。

---

## 第 2 步：新建仓库

1. 登录后，点右上角 **+** → **New repository**。
2. 仓库名随便填（如 `photo-cleaner`），选 **Public**（公开，免费）。
3. **不要**勾选 “Add a README”（保持空白）。
4. 点 **Create repository**。

---

## 第 3 步：上传项目文件

1. 进入新建的仓库，页面上会出现 “**uploading an existing file**” 链接，点它。
2. 在电脑上打开 `photo-cleaner` 文件夹，**全选里面的所有文件和文件夹**（包括 `.github`、`lib`、`docs`、`build.bat`、`pubspec.yaml` 等），一起拖进网页的上传区域。
   - ⚠️ 一定要把 **`.github` 文件夹**也传上去（它是自动编译的关键）。
3. 等上传完成后，点 **Commit changes**。

---

## 第 4 步：自动开始编译

1. 上传完成即触发了自动编译。点仓库顶部 **Actions** 标签页，能看到一个正在运行的 “构建 APK” 任务（黄色圆点在转）。
2. 等待约 5~15 分钟，直到它变成**绿色对勾**。

---

## 第 5 步：下载 APK

1. 点进那个绿色对勾的构建记录。
2. 页面底部 **Artifacts** 区域，有一个 **photo-cleaner-apk**，点它下载（是个 zip）。
3. 解压 zip，里面就是 **app-release.apk**。

---

## 第 6 步：安装到手机

1. 把 `app-release.apk` 传到手机（微信/QQ/网盘/数据线都行）。
2. 点击安装；若提示“禁止安装未知来源”，在弹窗里允许即可。

---

## 常见问题

| 现象 | 解决 |
| --- | --- |
| Actions 里没有运行的任务 | 确认上传时包含了 `.github` 文件夹；或在 Actions 页点 “Run workflow” 手动触发 |
| 编译失败（红色叉） | 点进构建记录，把红色报错截图发给我 |
| 下载的 Artifact 是 zip | 正常，解压后就是 apk |
| 想在手机上长期用 | GitHub 免费版 Artifact 保存约 90 天，建议及时下载到本地 |

---

> 说明：云端编出的 APK 用的是调试签名，可直接安装使用，但不能直接上架应用商店。若日后要上架，我再帮你配正式签名。
