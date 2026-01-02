@echo off
REM Wrapper script to run the Python deployment script
python3 "%~dp0deploy_to_phone.py" %*
if errorlevel 1 (
    python "%~dp0deploy_to_phone.py" %*
)
