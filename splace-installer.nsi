; splace-installer.nsi - Minimal NSIS installer for splace CLI

Name "splace CLI"
OutFile "artifacts\\splace-windows-installer.exe"
!include "LogicLib.nsh"
!include "EnvVarUpdate.nsh"
InstallDir "$PROGRAMFILES\splace"
RequestExecutionLevel admin

Page directory
Page instfiles


Section "Install"
  SetOutPath "$INSTDIR"
  ; Include the built binary from artifacts
  File "artifacts\\splace.exe"
  ; Create a shortcut on desktop
  CreateShortCut "$DESKTOP\\splace.lnk" "$INSTDIR\\splace.exe"
  ; Add splace to PATH using EnvVarUpdate
  !insertmacro AddToPath "$INSTDIR"
SectionEnd
