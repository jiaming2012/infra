@echo off
:: =============================================================================
:: Temporal Stack — Windows Firewall Rule for gRPC Port 7233
:: =============================================================================
:: Creates an inbound firewall rule allowing TCP traffic on port 7233 so
:: remote Temporal workers (Digital Ocean, LAN hosts) can reach the server.
::
:: IMPORTANT: Right-click this file and select "Run as Administrator"
:: =============================================================================

:: Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script must be run as Administrator.
    echo Right-click firewall.bat and select "Run as Administrator".
    pause
    exit /b 1
)

echo.
echo =============================================
echo  Temporal — Firewall Rule Setup
echo =============================================
echo.

:: Delete existing rule (idempotent — no error if rule does not exist)
echo Removing existing rule (if any)...
netsh advfirewall firewall delete rule name="Temporal gRPC 7233" >nul 2>&1

:: Add inbound rule — no remoteip restriction (Digital Ocean workers use public IPs)
echo Creating inbound rule for TCP 7233...
netsh advfirewall firewall add rule ^
  name="Temporal gRPC 7233" ^
  dir=in ^
  action=allow ^
  protocol=TCP ^
  localport=7233 ^
  description="Temporal gRPC API for remote workers (yumyums, slack-trading)"

if %errorlevel% equ 0 (
    echo.
    echo [PASS] Firewall rule created successfully.
) else (
    echo.
    echo [FAIL] Failed to create firewall rule.
    pause
    exit /b 1
)

:: Show the rule for verification
echo.
echo --- Verifying rule ---
netsh advfirewall firewall show rule name="Temporal gRPC 7233"

:: Print manual router step (per D-02)
echo.
echo =============================================
echo  MANUAL STEP REQUIRED: Router Port Forward
echo =============================================
echo  For Digital Ocean workers to reach this server:
echo    1. Open your router admin UI
echo    2. Add a port forward: external 7233 -^> 192.168.8.164:7233 (TCP)
echo    3. Verify with: grpc_health_probe -addr ^<public-ip^>:7233
echo.
echo  This is environment-specific and cannot be automated.
echo =============================================
echo.
pause
