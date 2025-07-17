#Get users profile location
$Userprofile = $env:USERPROFILE
$Acl = Get-Acl $Userprofile
#Apply Permissions to User Folder
$UserACL = Get-ACL $Userprofile
$Acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("View Profile Admins", "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")))
(Get-Item $Userprofile).SetAccessControl($Acl)