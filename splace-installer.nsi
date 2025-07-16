!ifndef EnvVarUpdate_INCLUDED
  MessageBox MB_OK "EnvVarUpdate.nsh not found. PATH will not be updated automatically."
!endif
; splace-installer.nsi - Minimal NSIS installer for splace CLI


Name "splace CLI"
OutFile "artifacts\\splace-windows-installer.exe"
InstallDir "$PROGRAMFILES\splace"
RequestExecutionLevel admin

!include "LogicLib.nsh"
!include "EnvVarUpdate.nsh"

Page directory
Page instfiles


Section "Install"
  SetOutPath "$INSTDIR"
  ; Always install splace.exe to $INSTDIR
  File "artifacts\\splace.exe"
  ; Create a shortcut on desktop
  CreateShortCut "$DESKTOP\\splace.lnk" "$INSTDIR\\splace.exe"
  ; Add splace to PATH using EnvVarUpdate
  !insertmacro AddToPath "$INSTDIR"
  MessageBox MB_OK "splace CLI installed to $INSTDIR. If PATH was updated, you can now use 'splace' from any terminal."
SectionEnd
