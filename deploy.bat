@echo off
REM ================================================
REM ReLink - Firebase Hosting Deployment Script
REM ================================================

echo.
echo ================================================
echo ReLink - Firebase Hosting Deployment
echo ================================================
echo.

REM Step 1: Clean build
echo [1/5] Cleaning Flutter build...
call flutter clean
if %errorlevel% neq 0 (
    echo ERROR: Flutter clean failed!
    pause
    exit /b 1
)
echo ✓ Clean completed
echo.

REM Step 2: Get dependencies
echo [2/5] Getting Flutter dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Flutter pub get failed!
    pause
    exit /b 1
)
echo ✓ Dependencies installed
echo.

REM Step 3: Build web app
echo [3/5] Building Flutter web app (release mode)...
call flutter build web --release
if %errorlevel% neq 0 (
    echo ERROR: Flutter build web failed!
    pause
    exit /b 1
)
echo ✓ Web build completed
echo.

REM Step 4: Deploy to Firebase Hosting
echo [4/5] Deploying to Firebase Hosting...
call firebase deploy --only hosting
if %errorlevel% neq 0 (
    echo ERROR: Firebase deployment failed!
    echo.
    echo Make sure you are logged in to Firebase:
    echo   firebase login
    pause
    exit /b 1
)
echo ✓ Deployment completed
echo.

REM Step 5: Show success message
echo ================================================
echo ✓ DEPLOYMENT SUCCESSFUL!
echo ================================================
echo.
echo Your app is now live at:
echo   - https://relink-app-a96f3.web.app
echo   - https://relink-app-a96f3.firebaseapp.com
echo.
echo To view deployment details:
echo   firebase hosting:sites:list
echo.
pause
