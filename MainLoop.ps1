Write-Host "Run this to get logs: Get-EventLog -LogName Application -Newest 20 -ErrorAction Ignore | Where-Object { (`$_.Source -like '*Dynamics*' -or `$_.Source -eq '$SqlServiceName') -and (`$_.EntryType -eq `"Error`" -or `$_.EntryType -eq `"Warning`") -and `$_.EntryType -ne `"0`" } | Select-Object TimeGenerated, EntryType, Message | format-list"

while ($true) { start-sleep -seconds 10 }