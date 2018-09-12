[cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
param(
  [string]$GITHUB_TOKEN = '',

  [parameter(Mandatory=$False,ValueFromRemainingArguments=$true)]
  [object]$IgnoreMe
)
$ErrorActionPreference = 'Stop'

if ($GITHUB_TOKEN -eq '') { Throw "Requires a GITHUB_TOKEN parameter" }

. ./CommonFunc.PS1
$OUTPUT_SOURCE = 'GitHub'

$ENV:GITHUB_OAUTH_TOKEN = $GITHUB_TOKEN

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Import-Module "$($PSScriptRoot)\VendoredModules\Github\Posh-Github.psm1" -Force

$PublicRepoList = @(
  "puppetlabs-acl",
  "puppetlabs-chocolatey",
  "puppetlabs-dism",
  "puppetlabs-dsc",
  "puppetlabs-dsc_lite",
  "puppetlabs-iis",
  "puppetlabs-powershell",
  "puppetlabs-reboot",
  "puppetlabs-registry",
  "puppetlabs-scheduled_task",
  "puppetlabs-sqlserver",
  "puppetlabs-wsus_client",
  "puppetlabs-windows"
)

$PrivateRepoList = @(
)

$WindowsTeam = @('glennsarti', 'iristyle', 'jpogran', 'randomnoun7', 'thoughtcrhyme', 'michaeltlombardi', 'clairecadman')

$PrivateRepoList | % {
  $RepoName = $_
  $Message = 'Unable to check private repositories'
  $Sev = 'Medium'

  New-QueryOuput -Source $OUTPUT_SOURCE -Severity $Sev -Message "($RepoName) $($Message)" -URL "https://github.com/puppetlabs/$Reponame"
}

$PublicRepoList | % {
  $RepoName = $_

  Write-Verbose "Querying repo $RepoName for issues ..."
  Get-GitHubIssues -Repository $RepoName -Owner 'puppetlabs' -State open | % {
    $thisIssue = $_
    $Message = ''
    $Sev = ''
    if ($thisIssue.pull_request -eq $null) {
      # Some Issues are PRs.  Ignore the PRs
      if ($thisIssue.comments -eq 0) {
        $Sev = 'High'; $message = 'Windows Team needs to comment'
      } else {
        Write-Verbose "Querying comments for issue $($thisIssue.ID) ..."
        $lastComment = Get-GitHubIssueComments -GitHubIssue $thisIssue | Sort-Object updated_at | Select -Last 1

        $isLastCommentWindows = ($WindowsTeam -contains $lastComment.user.login)
        $LastCommentDate = Get-Date "$($lastComment.updated_at)"

        if (!$isLastCommentWindows) {
         $Sev = 'High'; $message = 'Windows Team needs to comment'
        } else {
          if ((New-TimeSpan -Start $LastCommentDate -End (Get-Date)).TotalDays -gt 7) {
            $Sev = 'Medium'; $message = 'Requires followup'
          } else {
            $Sev = 'Debug'; $message = 'No need for followup'
          }
        }

      }
      New-QueryOuput -Source $OUTPUT_SOURCE -Severity $Sev -Message "($RepoName Issue) $($Message): `"$($thisIssue.title)`"" -URL $thisIssue.html_url
    } else {
      # PRs
      $Message = ''
      $Sev = ''
      if ($thisIssue.title -match 'WIP') {
        $Sev = 'Debug'; $message = 'Work In Progress only'
      } else {
        if ($thisIssue.comments -eq 0) {
          $Sev = 'High'; $message = 'Windows Team needs to comment'
        } else {
          Write-Verbose "Querying comments for PR $($thisIssue.ID) ..."
          $lastComment = Get-GitHubIssueComments -GitHubIssue $thisIssue | Sort-Object updated_at | Select -Last 1

          $isLastCommentWindows = ($WindowsTeam -contains $lastComment.user.login)
          $LastCommentDate = Get-Date "$($lastComment.updated_at)"

          if (!$isLastCommentWindows) {
          $Sev = 'High'; $message = 'Windows Team needs to comment'
          } else {
            if ((New-TimeSpan -Start $LastCommentDate -End (Get-Date)).TotalDays -gt 7) {
              $Sev = 'Medium'; $message = 'Requires followup'
            } else {
              $Sev = 'Debug'; $message = 'No need for followup'
            }
          }
        }
      }
      New-QueryOuput -Source $OUTPUT_SOURCE -Severity $Sev -Message "($RepoName PR) $($Message): `"$($thisIssue.title)`"" -URL $thisIssue.pull_request.html_url
    }
    Start-Sleep -Milliseconds 100 # Throttle our connections to stop API rate limiting
  }
}
