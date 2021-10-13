# script parameters ---------------------------------------------------------------------------------------------------
## python related parameters
$python_vers = "3.9.7"
$python_digest = "cc3eabc1f9d6c703d1d2a4e7c041bc1d"
$python_scripts_dir = "$env:localappdata\Programs\Python\Python39\Scripts"
## datashark related parameters
$repo_url = "https://github.com/koromodako"
$cli_vers = "0.1.0"
$core_vers = "0.1.1"
$dev_vers = "0.1.0"
# computed variables --------------------------------------------------------------------------------------------------
$tmpdir = "$env:localappdata\Temp"
## python related variables
$python_installer = "python-$python_vers-amd64.exe"
$python_installer_url = "https://www.python.org/ftp/python/$python_vers/$python_installer"
$python_installer_path = "$tmpdir\$python_installer"
## datashark related variables
$core = "datashark_core-$core_vers-py3-none-any.whl"
$core_url = "$repo_url/datashark-core/releases/download/$core_vers/$core"
$core_path = "$tmpdir\$core"
$cli = "datashark_cli-$agent_vers-py3-none-any.whl"
$cli_url = "$repo_url/datashark-cli/releases/download/$cli_vers/$cli"
$cli_path = "$tmpdir\$cli"
$config_url = "$repo_url/datashark-dev/releases/download/$dev_vers/datashark.dist.yml"
$config_path = "$env:appdata\Datashark\datashark.yml"
# main script procedure -----------------------------------------------------------------------------------------------
## download the installer from www.python.org
Write-Output "[INFO] downloading Python $python_vers installer..."
$webclient = New-Object System.Net.WebClient
$webclient.DownloadFile("$python_installer_url", "$python_installer_path")
## check installer hexdigest after download and just before run (warning: vulnerable to race condition on the file system)
Write-Output "[INFO] checking Python $python_vers installer MD5 digest..."
$digest = Get-FileHash "$python_installer_path" -Algorithm MD5
if(-Not $python_digest.Equals($digest.Hash.ToLower())){
    Write-Error "Hash digest mismatch!"
    Exit
}
## execute Python installer
Write-Output "[INFO] running Python $python_vers installer..."
$arguments = @(
    "/passive"
    "CompileAll=1"
    "PrependPath=1"
    "Shortcuts=0"
    "Include_doc=0"
    "Include_launcher=0"
    "InstallLauncherAllUsers=0"
    "Include_tcltk=0"
    "Include_test=0"
)
$params = @{
    FilePath = "$python_installer_path"
    ArgumentList = $arguments
    NoNewWindow = $true
    Wait = $true
}
Start-Process @params
## remove Python installer
Write-Output "[INFO] removing Python $python_vers installer..."
Remove-Item "$python_installer_path"
## refresh env
Write-Output "[INFO] refreshing environment..."
$env:path = (
    [System.Environment]::GetEnvironmentVariable("Path", "Machine") +
    ';' +
    [System.Environment]::GetEnvironmentVariable("Path", "User")
)
## check python and pip
Write-Output "[INFO] checking python and pip..."
python.exe -V
pip.exe -V
## download Datashark packages
Write-Output "[INFO] downloading Datashark packages..."
$webclient.DownloadFile("$core_url", "$core_path")
$webclient.DownloadFile("$cli_url", "$cli_path")
## ensure pip is up-to-date
Write-Output "[INFO] ensuring pip is up-to-date..."
python.exe -m pip install -U pip
## setup Datashark packages
Write-Output "[INFO] installing Datashark packages..."
pip.exe install "$core_path"
pip.exe install "$cli_path"
## remove Datashark packages
Write-Output "[INFO] removing Datashark packages..."
Remove-Item "$core_path"
Remove-Item "$cli_path"
## create configuration and logs folders
Write-Output "[INFO] creating Datashark directories..."
mkdir -Force "$env:appdata\Datashark"
mkdir -Force "$env:appdata\Datashark\Logs"
## download template configuration file
Write-Output "[INFO] downloading configuration file template..."
$webclient.DownloadFile("$config_url", "$config_path")
## setup is complete
Write-Output "[INFO] setup complete!"
Write-Output "[INFO] 1. you should customize $config_path"
Write-Output "[INFO] 2. then start datashark cli using: datashark.exe -c $config_path -h"
