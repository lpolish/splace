; splace-installer.nsi - Minimal NSIS installer for splace CLI

Name "splace CLI"
OutFile "artifacts/splace-windows-installer.exe"
InstallDir "$PROGRAMFILES\splace"
RequestExecutionLevel admin

Page directory
Page instfiles


Section "Install"
  SetOutPath "$INSTDIR"
  File "splace.exe"
  ; Create a shortcut
  CreateShortCut "$DESKTOP\splace.lnk" "$INSTDIR\splace.exe"
  ; Add install dir to user PATH automatically
  ReadEnvStr $0 "PATH"
  StrCpy $1 "$INSTDIR"
  ${If} $0 != ""
    ${If} ${EnvVarContains} $0 $1 0
      ; Already in PATH
    ${Else}
      ; Add to PATH
      WriteEnvStr "PATH" "$0;$1"
      MessageBox MB_OK "$INSTDIR has been added to your PATH. You can now use 'splace' from any terminal."
    ${EndIf}
  ${Else}
    WriteEnvStr "PATH" "$1"
    MessageBox MB_OK "$INSTDIR has been set as your PATH. You can now use 'splace' from any terminal."
  ${EndIf}
SectionEnd
