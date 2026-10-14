@echo off
wslc.exe start wslc-dev >nul 2>&1
wslc.exe exec -it -u wtcttn -w /workspace wslc-dev zsh
