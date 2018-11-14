<#
.SYNOPSIS
  Just a simple script to ensure the FileMaker Server 
  Web Publishing Engine (WPE) is running.

.SYNTAX
  Start-WPE.ps1

.DESCRIPTION
  The client was having issues, due to the introduction of what
  seemed to be a client-side bug, keeping the FileMaker Pro 17 WPE
  running on the host.  WPE's intermitten failure was causing issues
  for the client so this script was created to, first, check to see 
  if the fmscwpc service is running and, if it isn't, starting it.

.INPUTS
  None

.OUTPUTS
  Maybe write to a file for log purposes...

.NOTES
  Version:          1.0
  Author:           Ray Crawford
  Creation Date:    11/13/2018

.EXAMPLE
  ./Start-WPE.ps1

#>

# Create a Windows task (the first time, only)
$taskName = "startWPE"
$taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -like $taskName}
if ($taskExists) {
  # Do nothing
} else {
  # Create task
  $action = New-ScheduledTaskAction -Execute 'PowerShell.exe' `
    -Argument '-NoProfile -WindowStyle Hidden -command "& {C:\Start-WPE.ps1}"'
  $trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Minutes 1) `
    -RepetitionDuration ([System.TimeSpan]::MaxValue)
  $settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew
  $principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" `
    -LogonType ServiceAccount -RunLevel Highest

  Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "startWPE" `
    -Principal $principal `
    -Description "Ensuring FM WPE is running"
}

$time = Get-Date -Format o
$cwpc = Get-Process fmscwpc -ErrorAction SilentlyContinue

if ($cwpc) {
  $time + " - Running" | Out-File C:\Windows\Temp\Start-WPE.log -Append
} else {
  $time + " - Failed; restarting" | Out-File C:\Windows\Temp\Start-WPE.log -Append
  iex 'fmsadmin restart wpe -y'
  $(Get-Date -Format o) + " - Restarted" | Out-File C:\Windows\Temp\Start-WPE.log -Append
}
