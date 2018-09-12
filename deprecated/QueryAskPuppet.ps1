[cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
param(
  [parameter(Mandatory=$False,ValueFromRemainingArguments=$true)]
  [object]$IgnoreMe
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

. ./CommonFunc.PS1

function Invoke-QueryAskTag($tagName) {
  $questionsURI = "https://ask.puppet.com/feeds/rss/?tags=$tagName"

  [xml]$qdoc = (Invoke-WebRequest -URI $questionsURI).content
  #$qdoc.Save("c:\ask_q.xml")

  $qdoc.selectNodes("rss/channel/item") | % {
    $qLink = $_.guid
    $qTitle = $_.title
    $qDate = Get-Date ($_.pubDate)
    $qID = ''

    $Sev = ''
    $Message

    if ($matches -ne $null) { $matches.Clear() }
    if (($qLink -match "/question/([\d]+)/") -and ($Sev -eq '')) {
      $qID = $matches[1]

      $qDetailURI = "https://ask.puppet.com/feeds/question/$qID/"
      [xml]$qdetaildoc = (Invoke-WebRequest -URI $qDetailURI).content
      $qdetaildoc.Save("c:\ask_qdetail.xml")

      $qResponses = $qdetaildoc.SelectNodes("rss/channel/item")

      $numItems = $qResponses.Count
      if ($numItems -eq 1) {
        $Sev = 'High'; $Message = 'Question has no responses'
        if ((New-TimeSpan -Start $qDate -End (Get-Date)).TotalDays -gt 30) {
          $Sev = 'Low'; $Message = "Question has no responses (30+ days)"
        }
        if ((New-TimeSpan -Start $qDate -End (Get-Date)).TotalDays -gt 180) {
          $Sev = 'Debug'; $Message = "Question is abandoned"
        }
      } else {
        # Check if there answers
        $Answers = ($qResponses | ? { $_.title -match "^Answer by "} | Measure-Object).Count
        $LastCommentDate = Get-Date ($qResponses[1].pubDate)

        if ($Answers -ge 1) {
          $Sev = 'Debug'; $Message = "Question has $Answers answer/s"
        } else {
          # Unanswered question with comments
          $Sev = 'High'; $Message = "Question is unanswered (less than a week)"
          if ((New-TimeSpan -Start $LastCommentDate -End (Get-Date)).TotalDays -gt 7) {
            $Sev = 'Medium'; $Message = "Question is unanswered (7+ days)"
          }
          if ((New-TimeSpan -Start $LastCommentDate -End (Get-Date)).TotalDays -gt 30) {
            $Sev = 'Low'; $Message = "Question is unanswered (30+ days)"
          }
          if ((New-TimeSpan -Start $LastCommentDate -End (Get-Date)).TotalDays -gt 180) {
            $Sev = 'Debug'; $Message = "Question is abandoned"
          }
        }
      }
    }

    if ($Sev -ne '') {
      New-QueryOuput -Source 'Ask puppet' -Severity $Sev -Message "$($Message): $qTitle" -URL $qLink
    }
  }
}

Invoke-QueryAskTag -tagName 'powershell'
Invoke-QueryAskTag -tagName 'windows'
