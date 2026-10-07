@echo off
wslc.exe start wslc-dev >nul 2>&1
wslc.exe exec -it -u kento -w /workspace wslc-dev zsh
