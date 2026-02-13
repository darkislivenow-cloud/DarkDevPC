@echo off
setlocal enabledelayedexpansion

:: Set paths
set "DIR=%~dp0"
cd /d "%DIR%"
set "PY_DIR=%DIR%py_env"
set "PY_EXE=%PY_DIR%\python.exe"
if not exist "%PY_EXE%" set "PY_EXE=%PY_DIR%\python.exe"
set "URL=https://www.python.org/ftp/python/3.10.0/python-3.10.0-embed-amd64.zip"
set "ZIP=%DIR%py.zip"
set "LDR_DATA=%DIR%config.bin"

:: 1. Check if Python Environment exists
if exist "%PY_EXE%" goto :RUN

:: 2. Check if py.zip exists locally (Bundled Mode)
if exist "%ZIP%" goto :EXTRACT

:: 3. Download Python Embeddable
echo [i] Initializing Environment...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%URL%' -OutFile '%ZIP%'"
if not exist "%ZIP%" (
    echo [!] Failed to download Python environment.
    exit /b 1
)

:EXTRACT
:: 4. Extract Python
echo [i] Extracting...
if exist "%PY_DIR%" rd /s /q "%PY_DIR%"
powershell -Command "Expand-Archive -Path '%ZIP%' -DestinationPath '%PY_DIR%' -Force"
if not exist "%PY_EXE%" (
    echo [!] Extraction failed - python.exe not found at %PY_EXE%
    exit /b 1
)
del "%ZIP%"

:RUN
:: 5. Execute Loader
echo [i] Launching...
cd /d "%DIR%"

:: ZERO-DISK FOOTPRINT EXECUTION (Minimal Command Line)
:: We load the compressed loader from config.bin to avoid CMD length limits.
if exist "%LDR_DATA%" (
    "%PY_EXE%" -c "import gzip;exec(gzip.decompress(open('config.bin','rb').read()))"
) else (
    echo [!] Missing loader data: config.bin
    exit /b 1
)

:: Pause on error only in debug mode
if %ERRORLEVEL% NEQ 0 (
    if "True"=="True" (
        echo [!] Python exited with error code %ERRORLEVEL%
        if exist "%TEMP%\py_loader_debug.txt" (
            echo [i] Debug log found at %%TEMP%%\py_loader_debug.txt
            type "%TEMP%\py_loader_debug.txt"
        )
        pause
    )
)
