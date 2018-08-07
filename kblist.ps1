# created by Michael Goulart
# last updated : January 2010
# Function : to check for A LIST OF DEFINED kbxxxx patches on remote machines
# use optional powergadget charts

param($pclist,$kblist,$powergadget)
function Usage {
@'
Syntax:
powershell.exe .\kblist.ps1 pclist.txt kblistings.txt <Powergadget Filename>

-pclist.txt : Specifies a MANDATORY filename that contains machine names
-kblist.txt : Specifies a MANDATORY filename that contains patches names eg KBXXXXXX
-Powergadget Filename  : Specifies a OPTIONAL Powergadget filename.
'@
exit 1
}

if (!$pclist -or !$kblist)
{
	clear-host
	Usage
}

# $erroractionpreference = "SilentlyContinue"
clear-host

$filepath = "c:\temp\XAGLBADMINMG\KBCHECK_OUTPUT"
[system.io.file]::delete($filepath)


#check for existence of CORRECT filename
$pclist_exist = [System.IO.File]::Exists($pclist)
$kblist_exist = [System.IO.File]::Exists($kblist)
if (!$pclist_exist) {write-host "$pclist filename does not reside in current directory.";break}
if (!$kblist_exist) {write-host "$kblist filename does not reside in current directory.";break}

if ($powergadget)
{
	# check for powergadget file name
	$powergadget_exist = [System.IO.File]::Exists($powergadget)
	if (!$powergadget_exist) {write-host "$powergadget filename does not reside in current directory.";break}
}

$computernames = get-content $pclist
$patches = get-content $kblist
$hotfix = @{}

foreach ($kb in $patches)
{
	write-host -f green "Patch:" $kb.toupper() "`r"

	write `r | out-file -filepath $filepath -append
	"Patch: " + $kb.toupper() | out-file -filepath $filepath -append

	foreach ($computer in $computernames)
	{	
		$found=0
		$ping=0
	
		$strQuery = "select * from win32_pingstatus where address = '" + $computer + "'"
		$wmi = Get-WmiObject -query $strQuery

		if ($wmi.statuscode -eq 0)
		{
			$ping=1
			$checkkb = Get-WmiObject Win32_QuickFixEngineering -computer $computer | where-object {$_.hotfixid -eq $kb}
			if ($checkkb) 
			{
				 write-host $computer "(found) `r"
				"$computer (found)" | out-file -filepath $filepath -append
				$found=1
			}	
			else
			{
				write-host $computer "(Not found) `r"
				"$computer (Not found)" | out-file -filepath $filepath -append
			}
		}
		else
		{
			write-host "$computer Ping Failed. `r"
			"$computer Ping Failed" | out-file -filepath $filepath -append
		}		

	  $obj = 1 | select @{n="Computer";e={$computer}},@{n="Found";e={$found}},@{n="PingOK";e={$ping}}
	  $hotfix["$kb"] += @($obj) 
	}
}

write-host `n

if ($powergadget)
{
	# display using powergadget
	Add-PSSnapin PowerGadgets

	$hotfix.keys | select @{n="Patch";e={$_}}, 
	 @{n="Found";e={@($hotfix.$_ |where{$_.Found}).Count}}, 
 	 @{n="Not Found";e={@($hotfix.$_).count -  @($hotfix.$_ |where{$_.Found}).Count}} | out-chart -template $powergadget

}
else
{
	# display on screen
	$a = $hotfix.Keys | foreach  {
	 $found = @($hotfix.$_ | where {$_.Found}).Count 
	 $Pingsuccess = @($hotfix.$_ | where {$_.pingok}).Count 
	 $notfound = @($hotfix.$_).Count - $found
	 $pingfail = @($hotfix.$_).Count - $pingsuccess
	"$_ found in $found machines, Not Found: $notfound machines of which Ping Failed in $pingfail machines"}

	write `r | out-file -filepath $filepath -append
	$a | out-file -filepath $filepath -append
	$a
}

write-host "`nDetails written to $filepath"



