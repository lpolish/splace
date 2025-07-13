; splace-installer.nsi - Minimal NSIS installer for splace CLI
Name "splace CLI"
OutFile "splace-installer.exe"
InstallDir "$PROGRAMFILES\splace"
RequestExecutionLevel admin

Page directory
Page instfiles

Section "Install"
  SetOutPath "$INSTDIR"
  File "splace-windows.exe"
  ; Create a shortcut
  CreateShortCut "$DESKTOP\splace.lnk" "$INSTDIR\splace-windows.exe"
  MessageBox MB_OK "Add $INSTDIR to your PATH manually to use 'splace' from any terminal."
SectionEnd
