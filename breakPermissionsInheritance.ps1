# this script breaks the inheritance for the SharePoint list, saves the current permissions 
# and adds to the default visitors group Contribute permissions. Actual for SharePoint online

$url = 'https://url/sites/subsite/something'

$listTitle = 'The List'
$imageLibTitle = 'The Images'
Connect-PnPOnline -Url $url -Interactive


$visitorGroup = Get-PnPGroup -AssociatedVisitorGroup

Set-PnPList -Identity $listTitle  -BreakRoleInheritance  #Only 1 user has permissions
Set-PnPList -Identity $listTitle  -BreakRoleInheritance -CopyRoleAssignments #Permissions are copied from the parent site

Set-PnPListPermission -Identity $listTitle -Group $visitorGroup -AddRole 'Contribute'  #visitors group has Contribute permissions
