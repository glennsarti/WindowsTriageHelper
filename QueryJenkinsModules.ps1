[cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
param(
  [parameter(Mandatory=$False,ValueFromRemainingArguments=$true)]
  [object]$IgnoreMe
)
$ErrorActionPreference = 'Stop'
$ProgressPreference='SilentlyContinue'

. ./CommonFunc.PS1

$rootURL = 'https://jenkins-modules.puppetlabs.com'

Function Invoke-Request($url) {
  $webProps = @{
    'Method' = 'GET'
  }

  if ($url -match '^http') {
    $webProps.URI = $url
  } else {
    $webProps.URI = "$($rootURL)/$url"
  }

  $response = Invoke-WebRequest @webProps
  $response | ConvertFrom-JSON
}




(Invoke-Request "view/3.%20windows%20only/api/json").views | ? { $_.name -ne 'ad hoc' } | % {
  $projectView = $_
  Write-Verbose "Checking $($projectView.name)"

  (Invoke-Request "$($projectView.URL)/api/json").views | % {
     $branchView = $_
     Write-Verbose "Checking branch $($branchView.name) of $($projectView.name)"

    (Invoke-Request "$($branchView.URL)/api/json").jobs | % {
      $jobObject = $_
      Write-Verbose "Checking job $($jobObject.name) on branch $($branchView.name) of $($projectView.name)"

      $Message = ''
      $Sev = ''
      switch ($jobObject.color) {
        'blue'           { $Message = "Job is ok"; $Sev = 'Debug' } # No Problem
        'blue_anime'     { $Message = "Job is in progress"; $Sev = 'Info' }
        'aborted_anime'  { $Message = "Job is in progress"; $Sev = 'Info' }
        'red_anime'      { $Message = "Job is in progress"; $Sev = 'Info' }
        'notbuilt_anime' { $Message = "Job is in progress"; $Sev = 'Info' }
        'aborted'        { $Message = "Job was aborted"; $Sev = 'Info' }
        'notbuilt'       { $Message = "Job has not been run"; $Sev = 'Warn' }
        'red'            { $Message = "Job has failed"; $Sev = 'Error' }
        default { $Message = "Unknown job color of $($jobObject.color)"; $Sev = 'Error' }
      }
      New-QueryOuput -Source 'Jenkins' -Severity $Sev -Message "$($Message): $($projectView.name)/$($branchView.name)/$($jobObject.name)" -URL $branchView.URL

    }
  }
}