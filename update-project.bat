@echo off
REM ================================================
REM ReLink - Update Firebase Project Script
REM ================================================

echo.
echo ================================================
echo ReLink - Firebase Project Update
echo ================================================
echo.
echo Current Project: relink-app-a96f3
echo Target Project: relink-f4647
echo.

REM Check if new google-services.json exists
if not exist "android\app\google-services.json.new" (
    echo ERROR: google-services.json.new not found!
    echo.
    echo Please download new google-services.json from Firebase Console
    echo and save it as: android\app\google-services.json.new
    echo.
    echo Steps:
    echo 1. Go to: https://console.firebase.google.com/project/relink-f4647
    echo 2. Project Settings -^> Your apps -^> Android app
    echo 3. Download google-services.json
    echo 4. Save as: android\app\google-services.json.new
    echo 5. Run this script again
    echo.
    pause
    exit /b 1
)

echo [1/7] Backing up old google-services.json...
copy android\app\google-services.json android\app\google-services.json.backup
echo ✓ Backup created
echo.

echo [2/7] Replacing google-services.json...
move /Y android\app\google-services.json.new android\app\google-services.json
echo ✓ File replaced
echo.

echo [3/7] Updating .firebaserc...
echo { > .firebaserc
echo   "projects": { >> .firebaserc
echo     "default": "relink-f4647" >> .firebaserc
echo   } >> .firebaserc
echo } >> .firebaserc
echo ✓ .firebaserc updated
echo.

echo [4/7] Switching Firebase CLI project...
call firebase use relink-f4647
echo ✓ Project switched
echo.

echo [5/7] Verifying new configuration...
echo.
echo Checking google-services.json:
findstr /C:"project_id" android\app\google-services.json
findstr /C:"project_number" android\app\google-services.json
findstr /C:"package_name" android\app\google-services.json
echo.

echo [6/7] Cleaning Flutter build...
call flutter clean
echo ✓ Clean completed
echo.

echo [7/7] Getting dependencies...
call flutter pub get
echo ✓ Dependencies installed
echo.

echo ================================================
echo ✓ PROJECT UPDATE COMPLETED!
echo ================================================
echo.
echo New Project: relink-f4647
echo.
echo NEXT STEPS:
echo 1. Update .env file with new project IDs
echo 2. Update web/index.html Firebase config (if using web)
echo 3. Test app: flutter run
echo 4. Verify all features work
echo.
echo To test: flutter run
echo.
pause
