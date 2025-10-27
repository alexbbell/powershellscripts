# the script finds the files larger than 20Mb at the local drive
Get-ChildItem -Path "C:\" -Recurse -File |
>>     Where-Object { $_.Length -gt 20MB } |
>>     Sort-Object Length -Descending |
>>     Select-Object @{Name="SizeMB";Expression={[math]::Round($_.Length / 1MB, 2)}}, FullName
