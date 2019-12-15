@echo off
cls
setlocal EnableExtensions

:: Check necessary data
if not "%XVHM_APP_STARTED%"=="true" goto missing
if "%XVHM_APP_DIR%"=="" goto missing
if "%XVHM_TMP_DIR%"=="" goto missing
if "%XVHM_CACERT_DIR%"=="" goto missing
if "%XVHM_VHOST_CERT_DIR%"=="" goto missing
if "%XVHM_VHOST_CERT_KEY_DIR%"=="" goto missing
if "%XVHM_OPENSSL_BIN%"=="" goto missing

if "%~1"=="" goto missing
goto startGenerate

:missing
echo.
echo Missing environment variables or input parameters.
echo Please run application from command "xvhosts"
exit /B

:startGenerate
set XVHM_HOSTNAME=%~1

if not exist "%XVHM_TMP_DIR%" mkdir "%XVHM_TMP_DIR%"
if not exist "%XVHM_VHOST_CERT_DIR%" mkdir "%XVHM_VHOST_CERT_DIR%"
if not exist "%XVHM_VHOST_CERT_KEY_DIR%" mkdir "%XVHM_VHOST_CERT_KEY_DIR%"

echo.
echo ============================================================
echo Generate the certificate request and security key for virtual host "%XVHM_HOSTNAME%".

set OPENSSL_CONF=%XVHM_VHOST_CERT_GENERATE_CONFIG%
%XVHM_OPENSSL_BIN% req -newkey rsa:2048 -sha256 -subj "/CN=%XVHM_HOSTNAME%" -nodes -keyout "%XVHM_TMP_DIR%\%XVHM_HOSTNAME%.key" -out "%XVHM_TMP_DIR%\%XVHM_HOSTNAME%.csr"

echo.
echo ============================================================
echo Authenticate the certificate request and issue an SSL certificate for virtual host "%XVHM_HOSTNAME%" (include its SANs).

if not exist "%XVHM_TMP_DIR%\index.txt" type nul > "%XVHM_TMP_DIR%\index.txt"
if not exist "%XVHM_TMP_DIR%\index.txt.attr" type nul > "%XVHM_TMP_DIR%\index.txt.attr"
if not exist "%XVHM_TMP_DIR%\serial.txt" type nul > "%XVHM_TMP_DIR%\serial.txt"
if not exist "%XVHM_TMP_DIR%\serial.txt.attr" type nul > "%XVHM_TMP_DIR%\serial.txt.attr"
for /F "tokens=* USEBACKQ" %%a in (`php -r "echo md5('%XVHM_HOSTNAME%');"`) do (echo %%a> "%XVHM_TMP_DIR%\serial.txt")

set OPENSSL_CONF=%XVHM_CACERT_GENERATE_CONFIG%
%XVHM_OPENSSL_BIN% ca -batch -policy signing_policy -extensions signing_req -days 3650 -out "%XVHM_TMP_DIR%\%XVHM_HOSTNAME%.cert" -infiles "%XVHM_TMP_DIR%\%XVHM_HOSTNAME%.csr"

echo.
echo ============================================================
echo The SSL certificate has been generated. Relocating the certificate and private key to the storage location.

move /y "%XVHM_TMP_DIR%\%XVHM_HOSTNAME%.cert" "%XVHM_VHOST_CERT_DIR%"
move /y "%XVHM_TMP_DIR%\%XVHM_HOSTNAME%.key" "%XVHM_VHOST_CERT_KEY_DIR%"

echo.
echo ========================================
echo Clear temporary data

set OPENSSL_CONF=
set XVHM_HOSTNAME=
del /Q "%XVHM_TMP_DIR%\."

echo.
echo ============================================================
echo Finish job.

endlocal