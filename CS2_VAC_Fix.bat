@echo off
title CS2 VAC Signatur-Fix v1.01.1_01
color 0A
setlocal EnableDelayedExpansion

:: ============================================================
:: CS2 VAC Signatur-Fix  v1.01.1_01
:: Behebt: "Einige Ihrer Spieldateien weisen keine oder
:: ungueltige Signaturen auf" (z.B. nach Systemwiederherstellung)
::
:: Stufe 1: CS2 schliessen + Steam-Dateipruefung starten
:: Stufe 2 (optional): Programmordner von CS2 sichern und von
::                     Steam frisch laden lassen
:: Aendert KEINE Configs, Startoptionen oder Windows-Settings.
:: ============================================================

:: --- Auto-Admin ---
>nul 2>&1 net session
if %errorlevel% neq 0 (
    echo Fordere Administratorrechte an...
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /b
)

echo.
echo  === CS2 VAC Signatur-Fix v1.01.1_01 ===
echo.

:: --- Steam-Pfad finden ---
set "STEAM="
for /f "tokens=2,*" %%A in ('reg query "HKCU\Software\Valve\Steam" /v SteamPath 2^>nul ^| find /i "SteamPath"') do set "STEAM=%%B"
if not defined STEAM (
    for /f "tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /v InstallPath 2^>nul ^| find /i "InstallPath"') do set "STEAM=%%B"
)
if not defined STEAM (
    echo [FEHLER] Steam-Installation nicht gefunden.
    goto end
)
set "STEAM=%STEAM:/=\%"
if not exist "%STEAM%\steam.exe" (
    echo [FEHLER] steam.exe nicht gefunden in: "%STEAM%"
    goto end
)
echo [OK] Steam:  %STEAM%

:: --- Bibliothek mit CS2 (App 730) finden ---
set "LIB="
if exist "%STEAM%\steamapps\appmanifest_730.acf" set "LIB=%STEAM%"
if not defined LIB if exist "%STEAM%\steamapps\libraryfolders.vdf" (
    for /f tokens^=4^ delims^=^" %%P in ('findstr /c:"\"path\"" "%STEAM%\steamapps\libraryfolders.vdf"') do (
        set "P=%%P"
        set "P=!P:\\=\!"
        if not defined LIB if exist "!P!\steamapps\appmanifest_730.acf" set "LIB=!P!"
    )
)
if not defined LIB (
    echo [FEHLER] CS2 wurde in keiner Steam-Bibliothek gefunden.
    goto end
)
set "CS2=%LIB%\steamapps\common\Counter-Strike Global Offensive"
echo [OK] CS2:    %CS2%
echo.

:: --- CS2 beenden ---
tasklist /fi "imagename eq cs2.exe" 2>nul | find /i "cs2.exe" >nul
if %errorlevel% equ 0 (
    echo [..] Beende CS2...
    taskkill /f /im cs2.exe >nul 2>&1
    timeout /t 3 /nobreak >nul
)

:: --- Stufe 2 optional ---
echo Stufe 2 nur waehlen, wenn Stufe 1 den Fehler NICHT behoben hat.
echo Dabei werden die Programmordner von CS2 gesichert und neu geladen.
echo.
choice /c JN /n /t 15 /d N /m "Stufe 2 ausfuehren? [J/N] (automatisch N in 15s): "
if %errorlevel% equ 1 goto deep
goto validate

:deep
for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TS=%%T"
set "BAK=%LIB%\steamapps\cs2_vacfix_backup_%TS%"
mkdir "%BAK%" >nul 2>&1
if exist "%CS2%\game\bin\win64" (
    move "%CS2%\game\bin\win64" "%BAK%\game_bin_win64" >nul && echo [OK] gesichert: game\bin\win64
)
if exist "%CS2%\game\csgo\bin" (
    move "%CS2%\game\csgo\bin" "%BAK%\game_csgo_bin" >nul && echo [OK] gesichert: game\csgo\bin
)
if exist "%CS2%\game\csgo\gameinfo.gi" (
    move "%CS2%\game\csgo\gameinfo.gi" "%BAK%\gameinfo.gi" >nul && echo [OK] gesichert: game\csgo\gameinfo.gi
)
echo [i] Backup liegt in: %BAK%
echo     (kann geloescht werden, sobald Premier wieder laeuft)
echo.

:validate
echo [..] Starte Steam-Dateipruefung fuer CS2...
start "" "%STEAM%\steam.exe" steam://validate/730
echo.
echo  ------------------------------------------------------------
echo   Jetzt in Steam warten, bis die Ueberpruefung 100%% erreicht
echo   und der anschliessende Download fertig ist.
echo   Danach CS2 normal starten und Premier suchen.
echo  ------------------------------------------------------------

:end
echo.
pause
endlocal
