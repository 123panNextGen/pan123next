@echo off
REM Build Go downloader backend for all platforms

echo === Windows (amd64) ===
set GOOS=windows
set GOARCH=amd64
go build -o ..\build\go\downloader_server.exe .\cmd\server
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
echo OK: build\go\downloader_server.exe

echo === macOS (amd64) ===
set GOOS=darwin
set GOARCH=amd64
go build -o ..\build\go\downloader_server_darwin_amd64 .\cmd\server
echo OK: build\go\downloader_server_darwin_amd64

echo === macOS (arm64, Apple Silicon) ===
set GOOS=darwin
set GOARCH=arm64
go build -o ..\build\go\downloader_server_darwin_arm64 .\cmd\server
echo OK: build\go\downloader_server_darwin_arm64

echo === Linux (amd64) ===
set GOOS=linux
set GOARCH=amd64
go build -o ..\build\go\downloader_server_linux_amd64 .\cmd\server
echo OK: build\go\downloader_server_linux_amd64

echo Done. Binaries are in build\go\
