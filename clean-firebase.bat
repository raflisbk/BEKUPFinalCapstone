@echo off
REM ================================================
REM ReLink - Clean Firebase Configuration Script
REM ================================================

echo.
echo ================================================
echo ReLink - Clean Firebase Configuration
echo ================================================
echo.
echo This will REMOVE all Firebase configuration files.
echo A backup will be created in backup_configs/
echo.

set /p confirm="Are you sure you want to continue? (yes/no): "
if /i not "%confirm%"=="yes" (
    echo.
    echo Operation cancelled.
    pause
    exit /b 0
)

echo.
echo [1/6] Creating backup...
if not exist backup_configs mkdir backup_configs
copy android\app\google-services.json backup_configs\ >nul 2>&1
copy .firebaserc backup_configs\ >nul 2>&1
copy firebase.json backup_configs\firebase.json.bak >nul 2>&1
echo ✓ Backup created in backup_configs/
echo.

echo [2/6] Removing Android Firebase config...
del android\app\google-services.json >nul 2>&1
del android\app\google-services.json.backup >nul 2>&1
del android\app\google-services.json.new >nul 2>&1
echo ✓ Android config removed
echo.

echo [3/6] Removing Firebase CLI config...
del .firebaserc >nul 2>&1
echo ✓ Firebase CLI config removed
echo.

echo [4/6] Creating template .firebaserc...
(
echo {
echo   "projects": {
echo     "default": "YOUR_PROJECT_ID_HERE"
echo   }
echo }
) > .firebaserc
echo ✓ Template .firebaserc created
echo.

echo [5/6] Cleaning Flutter build...
call flutter clean >nul 2>&1
echo ✓ Flutter build cleaned
echo.

echo [6/6] Removing build caches...
rmdir /s /q build >nul 2>&1
rmdir /s /q android\.gradle >nul 2>&1
rmdir /s /q android\app\build >nul 2>&1
echo ✓ Build caches removed
echo.

echo ================================================
echo ✓ FIREBASE CONFIGURATION CLEANED!
echo ================================================
echo.
echo Backup location: backup_configs/
echo.
echo NEXT STEPS:
echo 1. Read FRESH_START_GUIDE.md
echo 2. Create new Firebase project
echo 3. Download new google-services.json
echo 4. Place in android/app/
echo 5. Update .firebaserc with new project ID
echo 6. Run: flutter pub get
echo 7. Run: flutter run
echo.
echo For FREE storage alternative, check:
echo - Cloudinary (25 GB free)
echo - See FRESH_START_GUIDE.md Part 4
echo.
pause
