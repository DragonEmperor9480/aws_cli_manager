@echo off
REM Build Windows desktop app with Go backend

echo ==========================================
echo Building AWS Manager for Windows
echo ==========================================

echo.
echo Step 1: Building Go backend executable...
cd ..\backend
set GOOS=windows
set GOARCH=amd64
go build -o awsmgr_backend.exe main.go
cd ..\scripts

if %errorlevel% neq 0 (
    echo Failed to build Go backend
    exit /b 1
)

echo Done: Go backend compiled: backend\awsmgr_backend.exe

echo.
echo Step 2: Building Flutter Windows app...
cd ..\awsmgr_ui

call flutter clean
call flutter pub get
call flutter build windows --release

if %errorlevel% neq 0 (
    echo Failed to build Flutter app
    exit /b 1
)

echo.
echo Step 3: Copying backend to Flutter build...
copy ..\backend\awsmgr_backend.exe build\windows\x64\runner\Release\
echo Done: Backend copied to bundle

cd ..

echo.
echo ==========================================
echo Build Complete!
echo ==========================================
echo App location: awsmgr_ui\build\windows\x64\runner\Release\
echo.
echo To run:
echo   cd awsmgr_ui\build\windows\x64\runner\Release\
echo   awsmgr.exe
pause
