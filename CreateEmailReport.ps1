param([string]$GITHUB_TOKEN = '', [string]$EmailAddress = '', [string]$Queryfilter = '.+')
$ErrorActionPreference = 'Stop'
$ProgressPreference='SilentlyContinue'

. ./CommonFunc.PS1

$Settings = Join-Path -Path $PSScriptRoot -ChildPath 'Settings.ps1'
if (Test-Path -Path $Settings) { . $Settings }
# Use global settings if script settings are specific
if ($GITHUB_TOKEN -eq '') { $GITHUB_TOKEN = $global:GITHUB_TOKEN }
if ($EmailAddress -eq '') { $EmailAddress = $global:EmailAddress }

$results = @()

# DEBUG
# $Queryfilter = 'Ask'

Get-ChildItem -Path "$($PSScriptRoot)\Query*.ps1" | ? { $_ -match $Queryfilter} | % {
  Write-Host "Running $_ ..."

  $props = @{
    'GITHUB_TOKEN' = $GITHUB_TOKEN 
  }

  try {
    $results += (. $_ @props -Verbose) 
  }
  catch [System.Exception] {
    throw $_    
  }
}


$html = @"
<html>
<head>
<style>
body { font-family: tahoma, sans serif; }

div.sevtitle { font-size:20pt; font-weight:bold; }

table tr td { padding:5px; }
table { border-collapse: collapse; }
thead, thead td {
  font-weight:bold;
  color:white;
  background-color:black;
}

# High Sev
.hightable { }
.hightable tr:nth-child(odd) { background-color: #efe0e0 }
.hightable tr:nth-child(even) { background-color: #fff0f0 }
div.highdiv { color: red; }

# Medium Sev
.mediumtable { }
.mediumtable tr:nth-child(odd) { background-color: #ece4d9 }
.mediumtable tr:nth-child(even) { background-color: #fcf4e9 }
div.mediumdiv { color: #ff9800; }

# Low Sev
.lowtable { }
.lowtable tr:nth-child(odd) { background-color: #e8eada }
.lowtable tr:nth-child(even) { background-color: #f8faea }
div.lowdiv { color: #bac734; }

# Debug Sev
.debugtable { }
.debugtable tr:nth-child(odd) { background-color: #e0e0e0 }
.debugtable tr:nth-child(even) { background-color: #f0f0f0 }
div.debugdiv { color: black; }

  #style='color:black;font-size:20pt; font-weight:bold;'

</style>
</head>
<body>
<center>
<h1>Windows Triage Report</h1>
<h3>$( (Get-Date).ToString('dd MMMM yyyy HH:mm'))</h3>
<hr />
"@


'High','Medium','Low','Debug' | % {
  $SevLevel = $_
  # Debug Sev
  $html += "<div class='sevtitle $($SevLevel.ToLower())div'>$SevLevel Severity Items</div><table class='$($SevLevel.ToLower())table'>`n`r"
  $html += "<thead><td>Source</td><td>Link</td><td>Message</td></thead>`n`r"
  $results | ? { $_.Severity -eq $SevLevel} | Sort-Object -Property Source,Message | % {
    $html += "<tr><td>$($_.Source)</td>"
    if ($_.URL -ne '') {
      $html += "<td><a href='$($_.URL)'>Link</a></td>"
    } else {
      $html += '<td>&nbsp;</td>'
    }
    $html += "<td>$($_.Message)</td></tr>`n`r"
  }
  $html += "</table>`n`r<br /><br />"
}


$html += "</center></body></html>"

Send-MailMessage -To $EmailAddress -Subject "Windows Triage Report - $((Get-Date).ToString('dd MMMM yyyy HH:mm'))" `
  -From $EmailAddress -Body $html -BodyAsHtml -SmtpServer "ASPMX.L.GOOGLE.COM"

# $html | Out-File 'C:\Temp\test.html'

Write-Host "Email sent to $EmailAddress"