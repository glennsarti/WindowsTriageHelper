
Function New-QueryOuput {
[CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$True)]
    [ValidateSet('Debug','Info','Warning','Error','Low','Medium','High')]
    [String]$Severity

    ,[Parameter(Mandatory=$True)]
    [String]$Message

    ,[Parameter(Mandatory=$True)]
    [String]$Source

    ,[Parameter(Mandatory=$False)]
    [String]$URL = ''
  )

  Process {
    if ($Severity -eq 'Info') { $Severity = 'Low' }
    if ($Severity -eq 'Warning') { $Severity = 'Medium' }
    if ($Severity -eq 'Error') { $Severity = 'High' }

    $props = @{
      'Severity' = $Severity
      'Message' = $Message
      'Source' = $Source
      'URL' = $URL
    }

    return (New-Object -TypeName PSCustomObject -Property $props)
  }
}