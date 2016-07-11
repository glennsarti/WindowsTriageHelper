[cmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='Low')]
param(
  [parameter(Mandatory=$False,ValueFromRemainingArguments=$true)]
  [object]$IgnoreMe
)
. ./CommonFunc.PS1

'1','2','3' | % {
  New-QueryOuput -Source 'Test Source' -Severity 'High' -Message "High $_" -URL "http://high.com/$_"
  New-QueryOuput -Source 'Test Source' -Severity 'Medium' -Message "Medium $_" -URL "http://medium.com/$_"
  New-QueryOuput -Source 'Test Source' -Severity 'Low' -Message "Low $_" -URL "http://low.com/$_"
  New-QueryOuput -Source 'Test Source' -Severity 'Debug' -Message "Debug $_" -URL "http://debug.com/$_"
}


