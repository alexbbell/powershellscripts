#there are a lot of directories, some of them have only 1 subdirectory, other have more than 1
#if there's a subfolder 'Source', the value is True, otherwise False
#the solution is in old-school style with ArrayList of objects

$city = "TA"
$path = "D:\Dest\" + $city + "\Files\"
$root_folders = Get-ChildItem $path -Directory
$sub_root_folders = New-Object System.Collections.ArrayList

foreach($root_folder in $root_folders) {
$fpath = $path + $root_folder + "\Source\"

$tp = Test-Path $fpath -PathType Any
$fldr = New-Object System.Object
$fldr | Add-Member -MemberType NoteProperty -Name "docId" -Value $root_folder
$fldr | Add-Member -MemberType NoteProperty -Name "hasSource" -Value $tp
$sub_root_folders.Add($fldr ) | Out-Null
}

$dest_file = "D:\Dest\report_" + $city + "_sources.txt"
$sub_root_folders | Out-File $dest_file
