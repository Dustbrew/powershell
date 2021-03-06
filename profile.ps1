
if ($HOME -eq "") {
  Remove-Item -Force variable:\home
  $home = (Get-Content env:\USERPROFILE)
  (Get-PSProvider 'FileSystem').Home = $home
}

New-PSDrive -Name proj -PSProvider FileSystem -Root (Resolve-Path "~/projects") | Out-Null

$scripts = Split-Path $profile
. $scripts\prepend-path.ps1 $scripts
. $scripts\prepend-path.ps1 .

if (Test-Path alias:\ri) { Remove-Item -Force alias:\ri }
if (Test-Path alias:\cd) { Remove-Item -Force alias:\cd }
if (Test-Path alias:\chdir) { Remove-Item -Force alias:\chdir }
if (Test-Path alias:\md) { Remove-Item -Force alias:\md }
if (Test-Path function:\md) { Remove-Item -Force function:\md }
if (Test-Path function:\mkdir) { Remove-Item -Force function:\mkdir }
if (Test-Path alias:\prompt) { Remove-Item -Force alias:\prompt }
if (Test-Path alias:\start) { Remove-Item -Force alias:\start }
if (Test-Path alias:\set) { Remove-Item -Force alias:\set }

Set-Alias grep Select-String
Set-Alias wide Format-Wide
Set-Alias whoami get-username
Set-Alias chdir cd
Set-Alias mkdir md
Set-Alias start explorer
Set-Alias v gvim
Set-Alias whence which
Set-Alias elevate elevate-process

$global:PWD = get-location;
$global:CDHIST = [System.Collections.Arraylist]::Repeat($PWD, 1);

function set {
  [string]$var=$args
  if ($var -eq "") {
    Get-ChildItem env: | Sort-Object name
  } else {
    if ($var -match "^(\S*?)\s*=\s*(.*)$") {
      Set-Item -Force -Path "env:$($matches[1])" -Value $matches[2];
    } else {
      Write-Error "ERROR Usage: VAR=VALUE"
    }
  }
}

function Get-AdminStatus {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object System.Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

set HOME=$home

# set cmd window color scheme
$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$windowsPrincipal = new-object 'System.Security.Principal.WindowsPrincipal' $windowsIdentity

if ($windowsPrincipal.IsInRole("Administrators") -eq 1)
{
	cmd.exe /c color 4f
	$role = "Admin";
}
else
{
	cmd.exe /c color 1f
	$role = "User";
}

# always set the location to the $home path
set-location $home

# override Prompt with prompt.ps1
if (test-path function:\prompt)       { remove-item -force function:\prompt }          # override with prompt.ps1

$ProgramFiles = ${env:ProgramFiles(x86)}
$ProgramFiles2 = ${env:ProgramFiles}
if (($ProgramFiles -eq $null) -or ($ProgramFiles.length -eq 0)) {
 $ProgramFiles = $ProgramFiles2
}

function Replace-String($find, $replace, $includes) {
  Get-ChildItem $includes | Select-String $find -List |% { (Get-Content $_.Path) | % { $_ -replace $find, $replace } | Set-Content $_.Path }
}

function dir-od {
 Get-ChildItem $args | Sort-Object -Property LastWriteTime
}

# Easily install new cmdlets
function InstallSnapIn([string]$dll, [string]$snapin) {
    $path = Get-Location;
    $assembly = $path.Path + "\" + $dll;
    elevate C:\Windows\Microsoft.NET\Framework\v2.0.50727\installutil.exe $assembly | Out-Null;
    Add-PSSnapin $snapin | Out-Null;
    Get-PSSnapin $snapin;
}


# I use the elevate command from the Script Elevation PowerToys to implement su
# if the user doesn't pass in any cmdline args, default to launching powershell
# Script Elevation PowerToys - http://technet.microsoft.com/en-us/magazine/cc162321.aspx
function su 
{ 
	if ($args.length -eq 0)
	{
		$args = ,'powershell'
	}
	elevate $args
}

function Get-Batchfile ($file) {
    $cmd = "`"$file`" & set"
    cmd /c $cmd | Foreach-Object {
        $p, $v = $_.split('=')
        Set-Item -path env:$p -value $v
    }
}

function temp { cd c:\temp }
function tools { cd "C:\utils" }
function vsl {cd c:\vsl}
function docs { cd "${env:HOMEPATH}\documents" }
function dt { cd "${env:HOMEPATH}\desktop" }
function home { cd $home}
function psd { cd "${env:HOMEPATH}\Documents\WindowsPowerShell" }
function mklink {cmd /C "mklink $args"}
function git-commit { git show | select-string commit | %{$_.ToString().Substring(7)}}
function rmd { rm -force -recurse $args}

function rubysync { 
  merlin
  merlin "C:\vsl\rubysync\Merlin\Main"
  set-title "rubysync"
}

${function:u} = { cd .. }
${function:...} = { cd ..\.. }
${function:....} = { cd ..\..\.. }
${function:.....} = { cd ..\..\..\.. }
${function:......} = { cd ..\..\..\..\.. }
${function:.......} = { cd ..\..\..\..\..\.. }

function pd { pushd "$args" }
function undo_and_delete {
  tf undo $args
  tf delete $args
}
function edit {
  if ($args[1] -eq $null) {
    gci -r | select-string $args[0] | % { gvim $_.Path}
  } else {
    gci -r -i $args[0] | select-string $args[1] | % { gvim $_.Path}
  }
}

