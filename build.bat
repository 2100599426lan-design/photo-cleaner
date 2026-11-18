@echo off
cd /d "%~dp0"
echo ============================================
echo  Photo Cleaner - one-click build script
echo ============================================
echo.

echo [1/4] Generate platform folders (android/ios)...
call flutter create --org com.example --project-name photo_cleaner .
if errorlevel 1 goto :fail

echo [2/4] Restore dependencies...
call flutter pub add photo_manager image provider google_mlkit_image_labeling
if errorlevel 1 goto :fail
call flutter pub get
if errorlevel 1 goto :fail

echo [3/4] Build release APK (first time takes 5-15 minutes)...
call flutter build apk --release
if errorlevel 1 goto :fail

echo [4/4] Done!
echo.
echo APK is here:
echo   build\app\outputs\flutter-apk\app-release.apk
echo.
pause
exit /b 0

:fail
echo.
echo Build FAILED. Please send me the error messages above.
pause
exit /b 1
