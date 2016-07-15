[cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
param(
  [parameter(Mandatory=$True)]
  [string]$PuppetPassUsername,

  [parameter(Mandatory=$True)]
  [string]$PuppetPassPassword,

  [parameter(Mandatory=$False,ValueFromRemainingArguments=$true)]
  [object]$IgnoreMe
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

. ./CommonFunc.PS1

Import-Module "$PSScriptRoot\Modules\Jira\PSJira\PSJira.psd1" -Force -Verbose:$false

$jiraServer = 'https://tickets.puppetlabs.com'
Write-Verbose "Using Jira URL $jiraServer"
Set-JiraConfigServer $jiraServer

# Setup Credential
$SecPassword = ConvertTo-SecureString -String $PuppetPassPassword -AsPlainText -Force
$JiraCred = New-Object System.Management.Automation.PSCredential ($PuppetPassUsername, $SecPassword)

# Check for issues in Triage
Get-JiraIssue -Query 'project = "MODULES" and Sprint = "Windows Triage"' -Credential $JiraCred | % { 
  $thisIssue = $_

  $Sev = ''
  $Message = ''
  $URL = "$($jiraServer)/browse/$($thisIssue.Key)"
  switch ($thisIssue.Status) {
    'Open' {
      $Sev = 'High'
      $Message = 'Issue has not been accepted'
    }
    'Closed' {
      $Sev = 'Low'
      $Message = 'Issue should not be in Triage'
    }
    default {
      $Sev = 'Debug'
      $Message = 'Triaged'
    }
  }
  if ($Sev -ne '') {
    New-QueryOuput -Source 'Jira' -Severity $Sev -Message "$($thisIssue.Key) $($Message): $($thisIssue.Summary)" -URL $URL
  }
}
