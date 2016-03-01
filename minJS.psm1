<#
Minify JavaScript and PS1

Create by Ingo Karstein // http://ikarstein.wordpress.com

#>  

function minify {
	param(	[psobject]$inputData = $null,
			[string]$inputDataType = $null,
			[string]$xmlOutputFile = $null, [switch]$verbose ) 
			
	if( [string]::IsNullOrEmpty($inputData) ) {
		throw "InputData argument cannot be null"
		return
	}
			
	if( [string]::IsNullOrEmpty($inputDataType) ) {
		throw "InputDataType argument cannot be null"
		return
	}
	
	if( $inputDataType -ine "js"  -and $inputDataType -ine "ps1" ) {
		throw "InputDataType unknown"
		return
	}

	###################################################
	
	try {
		$limiters = @();
		
		#######################################
		#in the following section we define the language dependent limiters

		switch($inputDataType) {
		  #javascript module
		  "js"  {
				$limiters = @(
					@{open='"'; close='"'; type="DQString"; escapeChar='\'; canBeEscaped=$true; ignoreInOutput=$false},
					@{open="'"; close="'"; type="SQString"; escapeChar='\'; canBeEscaped=$true; ignoreInOutput=$false},
					@{open="/*"; close="*/"; type="MLComment"; canBeEscaped=$false; ignoreInOutput=$true},
					@{open="//"; close="`n"; type="EOLComment"; canBeEscaped=$false; ignoreInOutput=$true},
					@{open="<%"; close="%>"; type="ASPNet"; canBeEscaped=$false; ignoreInOutput=$false},
					@{open="/"; needCharsBefore="[\%\?\=\s\(\&\!]"; ignoreCharactersBefore="[\s\n\r\t]"; close=@(
						@{close="/"; type="RegEx"; escapeChar='\'; canBeEscaped=$true; ignoreInOutput=$false; followdByCharacters="[gi]"})},
					@{type="Code"; regex = @(
							@{search=[regex]'([^;])([\t\s\r\n]*)(\n)([\t\s\r]*)(break)'; replace='$1;$5'; priority=10},
							@{search=[regex]'([^\w\d])\s*'; replace='$1'; priority=1000},
							@{search=[regex]'\s*([^\w\d])'; replace='$1'; priority=1000},
							@{search=[regex]'\s*(\n)'; replace='$1'; priority=1000},
							@{search=[regex]'\n*(\n)'; replace='$1'; priority=1000},
							@{search=[regex]'(\n)\s*'; replace='$1'; priority=1000},
							@{search=[regex]'(\x20)\x20*'; replace='$1'; priority=1000},
							@{search=[regex]'\x20*([\:\;\,\(\)\{\}\[\]])\x20*'; replace='$1'; priority=1000},
							@{search=[regex]'([\{]);*'; replace='$1'; priority=1000},
							@{search=[regex]';*([\}])'; replace='$1'; priority=1000},
							@{search=[regex]'([;])[;]*'; replace='$1'; priority=1000},
							@{search=[regex]'\r'; replace='\n'; priority=1000},
							@{search=[regex]'\t'; replace=' '; priority=1000},
							@{search=[regex]'\n'; replace=''; priority=1000}
						)}
				)
		  }
		  #PowerShell module
		  "ps1" {
				$limiters = @(
					@{open='@"'; close='"@'; type="DQMLString"; canBeEscaped=$false; ignoreInOutput=$false},
					@{open="@'"; close="'@"; type="SQMLString"; canBeEscaped=$false; ignoreInOutput=$false},
					@{open="<#"; close="#>"; type="MLComment"; canBeEscaped=$false; ignoreInOutput=$true},
					@{open="#"; close="`n"; type="EOLComment"; canBeEscaped=$false; ignoreInOutput=$true; moveEnd=-1},
					@{open='"'; close='"'; type="DQString"; escapeChar="``"; canBeEscaped=$true; ignoreInOutput=$false},
					@{open="'"; close="'"; type="SQString"; escapeChar="``"; canBeEscaped=$true; ignoreInOutput=$false},
					@{type="Code"; regex = @( 
							@{search=[regex]'\n'; replace=";"; priority=1000},
							@{search=[regex]'([^\w\d])\x20{1}'; replace='$1'; priority=1000},
							@{search=[regex]'\x20+([^\w\d\-\$\@])'; replace='$1'; priority=1000},
							@{search=[regex]'\x20*(\n)'; replace='$1'; priority=1000},
							@{search=[regex]'(\x20)\x20+'; replace='$1'; priority=1000},
							@{search=[regex]'(\,)\;'; replace='$1'; priority=1000},
							@{search=[regex]'\x20*([\;\,\(\)\{\}\[\]])\x20*'; replace='$1'; priority=1000},
							@{search=[regex]'([\{]);*'; replace='$1'; priority=1000},
							@{search=[regex]';*([\}])'; replace='$1'; priority=1000},
							@{search=[regex]'([;])[;]*'; replace='$1'; priority=1000},
							@{search=[regex]'\x20*$'; replace=''; priority=1000},
							@{search=[regex]'\r'; replace="`n"; priority=1000},
							@{search=[regex]'\t'; replace=" "; priority=1000},
							@{search=[regex]'([\w\d])$'; replace='$1 '; priority=1000},
							@{search=[regex]'\n{2,}'; replace="`n"; priority=1000},
							@{search=[regex]'([\}\{])[;\s\t\n]*([\{\}])'; replace='$1$2'; priority=1000}
						)}
				)

				
		  }
		}
		
		###################################################

		#we need a single string not a array of strings...
		if( $inputData -is [Array] ) { $inputData = [string]::Join("`n", $inputData) }
		
		#the following two lines of code do some basic replacements. 
		# in each step the string should become shorter and shorter. 
		# it ends if there is no further optimization
		$l = 0
		do { $l = $inputData.Length; $inputData = $inputData -replace "`r`n","`n" -replace "`r", "x" } while( $inputData.Length -ne $l)

		#add line break at the end of the input string
		$inputData += "`n"

		#retrieve the first characters of all separators
		$limOpen = ($limiters | ? {![string]::IsNullOrEmpty($_.open)} | % { ($_.open)[0]} | select -Unique)

		#initializing of some variables
		$p = 0; $p1 = 0; $lp = 0; $nStr = "";
		$result1 = @()

		#$p = the position inside the input string for the next operation

		while( $true ) {
			
			#get position of next limiter char in the string starting at the next operation
			$n = $inputData.IndexOfAny($limOpen, $p1)
			
			if( $n -ge 0 ) {
				#if $n > 0 then there's a occurance of a limiter char	
				
				$limiter = $null; $closer = $null 

				#we iterate through each limiter definition
				$limiters | ? { $limiter -eq $null -and $_.open -ne $null } | % {
					$lim = $_	
					$n2 = 0
					if( ( ([string]$lim.Open).ToCharArray() | % {  if( $inputData[$n+$n2] -ne $_) {$false}; $n2++ }) -eq $null ) {
						$limiter = $lim
					}
				}
				
				#in JavaScript there is the "/" char that can be used as division operator or as limiter for regular expressions
				#  therefore we need to check to "context" of the limiter character. the limiter is only valid if the context
				#  is as expected
				
				if($limiter -ne $null -and $limiter.needCharsBefore -ne $null ) {
					$n4 = $n - 1
					while($n4 -ge 0){
						$c = $inputData[$n4]
						if( $c -notmatch $limiter.ignoreCharactersBefore) {
							if( $c -notmatch $limiter.needCharsBefore ) {
								$limiter = $null
								break
							} else  {
								break
							}
						}
						$n4--
					}
				}
				
				if( $limiter -ne $null ) {
					#...if we have found a valid limiter...
					
					if( $p -lt $n ) {
						#if there's a diffrence between the curren operation position and the next occurance of a limiter char
						#  the string portion of between is "Code".
						$s = $inputData.Substring($p, $n-$p)
						
						#This is registered as result object of type "Code"
						$r = New-Object PSObject
						$r | Add-Member -Name "Type" -Value "Code" -Force -MemberType NoteProperty 
						$r | Add-Member -Name "Text" -Value $s -Force -MemberType NoteProperty 
						$r | Add-Member -Name "Pos" -Value $p -Force -MemberType NoteProperty 
						$r | Add-Member -Name "Length" -Value ($n-$p) -Force -MemberType NoteProperty 
						$r | Add-Member -Name "IgnoreInOutput" -Value $false -Force -MemberType NoteProperty 
						if($verbose) {  $r | Out-String | Write-Host -ForegroundColor DarkBlue}
						$result1 += $r
					}
				
					#Now we need to find the closing limiter
					#we start behind the opening limiter
					$n1 = $n + $limiter.open.length
					do {
						$closer = $null

						#we look for the closing limiter
						if( $limiter.close -is [array] ) {
							$n3 = $inputData.Length
							$limiter.close | % { 
								$tmpN3 = $inputData.IndexOf($_.close, $n1)
								if($tmpN3 -lt $n3 ){
									$n3 = $tmpN3
									$closer = $_
								}
							}
							$n1 = $n3
						} else {
							$n1 = $inputData.IndexOf($limiter.close, $n1)
							$closer = $limiter
						}
						
						if( $n1 -lt 0 ) {
							#if it's position is -1 than the closing limiter is not in the string => Error!
							break
						} else {
							#something found!
							
							if($closer.canBeEscaped) {
								#The closing limiter could be an escaped character. Some notation like \" is C#/javascript or `" in PowerShell.  

								if( $n1 -lt ($closer.close.Length+($closer.escapeChar.Length*2)) ) {
									break
								} else {
									if( $inputData.Substring($n1-($closer.escapeChar.Length), $closer.escapeChar.Length) -ne $closer.escapeChar ) {
										break
									} else {
										if( $inputData.Substring($n1-($closer.escapeChar.Length*2), $closer.escapeChar.Length*2) -eq "$($closer.escapeChar)$($closer.escapeChar)" ) {
											break
										}
									}
								}
							} else {
								break
							}
						}
						$n1 += $closer.close.length
					} while( $true ) 
					
					if( $n1 -lt 0 ) {
						throw "input data not valid at position $($n)"
						return
					}
					
					if($closer.followdByCharacters -ne $null ) {
						while( $inputData[$n1 + $closer.close.Length] -match $closer.followdByCharacters ) { $n1++ }
					}
					
					$s = $inputData.Substring( $n, $n1 - $n + $closer.close.Length)
					
					$r = New-Object PSObject
					$r | Add-Member -Name "Type" -Value $closer.type -Force -MemberType NoteProperty 
					$r | Add-Member -Name "Text" -Value $s -Force -MemberType NoteProperty 
					$r | Add-Member -Name "Pos" -Value $n -Force -MemberType NoteProperty 
					$r | Add-Member -Name "Length" -Value ($n1 - $n + $closer.close.Length) -Force -MemberType NoteProperty 
					$r | Add-Member -Name "IgnoreInOutput" -Value $closer.IgnoreInOutput -Force -MemberType NoteProperty 
					if($verbose) {  $r | Out-String | Write-Host -ForegroundColor DarkBlue}
					$result1 += $r

					$p = $p1 = $n1 + $closer.close.length
					if($closer.moveEnd -ne $null ) {$p += $closer.moveEnd}
				} else {
					$p1 = $n + 1;
				}
			} else {
				#no more limiter characters found. the rest of the input string is "Code"
				$s = $inputData.Substring( $p)		
				$r = New-Object PSObject
				$r | Add-Member -Name "Type" -Value "Code" -Force -MemberType NoteProperty 
				$r | Add-Member -Name "Text" -Value $s -Force -MemberType NoteProperty 
				$r | Add-Member -Name "Pos" -Value $p -Force -MemberType NoteProperty 
				$r | Add-Member -Name "Length" -Value ($inputData.Length-$p) -Force -MemberType NoteProperty 
				$r | Add-Member -Name "IgnoreInOutput" -Value $false -Force -MemberType NoteProperty 
				if($verbose) {  $r | Out-String | Write-Host -ForegroundColor DarkBlue}
				$result1 += $r
				break
			}
		}
		
		#The following command removes all unwanted content from the result.
		$result2 = $result1 | ? { !$_.IgnoreInOutput} 
		
		#Now we merge adjacent "Code" blocks 
		#>>>
		$prev = $null
		$result3 = $result2 | % {
			if($_.Type -ieq "code" ) {
				if( $prev -ne $null ) {
			   		$prev.Text += $_.Text
					$prev.Length = -1
				} else {
					$prev = $_
				}
			} else {
				if($prev -ne $null ) { $prev; $prev = $null}
				$_
			}
		} 
		
		if($prev -ne $null ) { $result3 += $prev}
		#<<<<
		
		
		#Now we process all blocks
		$result4 = $result3 | % {
			$entity = $_
			
			#All parts are processed for reduction...
			
			$lim=$null
			$lim = ($limiters | ? { $_.Type -eq $entity.Type })	
			
			$s = $entity.Text
			$l = 0 
			do {
				$l = $s.Length
				if(![string]::IsNullOrEmpty($lim.replace)) {
					$s = $lim.Replace
				} else {
					#this will apply replacements based on regular expressions
					$lim.regex | ? { $_ -ne $null } | select @{Name="Obj"; Expression={$_}}, @{Name="Priority"; Expression={$_.priority}} | sort priority | % {
						$processor = $_.Obj
						if( $processor.Search.IsMatch($s) ) {
							$s = $processor.Search.Replace($s, $processor.Replace)
						}
					}
				}
			} while( $l -ne $s.Length)
			
			#returns the result string
			$entity | Add-Member -Name "TextAfterProcessing" -Value $s -Force -MemberType NoteProperty

			$entity
		}
		
		if( !([string]::IsNullOrEmpty($xmlOutputFile)) ) {
			$result4 | Export-Clixml $xmlOutputFile -Force -ErrorAction:$ErrorActionPreference
		}
		
		#building result string...
		$sb = New-Object system.text.StringBuilder
		$result4 | % { 
			if(![string]::IsNullOrEmpty($_.TextAfterProcessing)) {
				$sb.append($_.TextAfterProcessing)
			}
		} | Out-Null
		
		#that's it!
		return $sb.ToString().Trim()
	} catch {
		throw
	}
}
