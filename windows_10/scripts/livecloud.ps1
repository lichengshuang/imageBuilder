Write-Host "Delete livecloud User"
$UserExist = [ADSI]::Exists("WinNT://livecloud-10/livecloud")
if ($UserExist) {
    [ADSI]$server="WinNT://livecloud-10"
    $server.delete("user", "livecloud")
}

function xzFile($src, $dest) {
    $sevenZip = "C:\Windows\System32\7za.exe"
    & cmd "/c $sevenZip x `"$src`" -so | $sevenZip x -aoa -si -ttar -o`"$dest`""
}

function download($url, $dest) {
    Write-Host "Downloading $url"
    ( New-Object System.Net.WebClient).DownloadFile( $url, $dest)
}

$url = "http://172.16.2.254/Packer/"
$bin_dir = "C:\Windows\System32\"
$tmp_dir = "C:\Windows\Temp\"

download $url"tools/7za.exe" $bin_dir"7za.exe"
download $url"tools/curl.exe" $bin_dir"curl.exe"
download $url"qga/vm_init.bat" $bin_dir"vm_init.bat"
download $url"tools/python.tar.gz" $tmp_dir"python.tar.gz"
download $url"tools/virtiodriver2012R2.tar.gz" $tmp_dir"virtiodriver.tar.gz"
download $url"tools/vagent.tar.gz" $tmp_dir"vagent.tar.gz"
download $url"qga/qemu-ga-x86_64.msi" $tmp_dir"qemu-ga-x86_64.msi"

xzFile "C:\Windows\Temp\python.tar.gz" "C:\Windows\Temp"

if (!(Test-Path "C:\Program Files\python" )) {
    $msiFile = "C:\Windows\Temp\python-2.7.8.amd64.msi"
    $python_home = "C:\Program Files\python"
    $arguments = @(
        "/i"
        "`"$msiFile`""
        "/qn"
        "/norestart"
        "ALLUSERS=1"
        "TARGETDIR=`"$python_home`""
    )
    Write-Host "Installing $msiFile....."
    $process = Start-Process -FilePath msiexec.exe -ArgumentList $arguments -Wait -PassThru
    if ($process.ExitCode -eq 0){
        Write-Host "$msiFile has been successfully installed"
    } else {
        Write-Host "installer exit code  $($process.ExitCode) for file  $($msifile)"
    }
    $pip = "C:\Windows\Temp\pip-7.1.2-py2.py3-none-any.whl"
    $setuptools = "C:\Windows\Temp\setuptools-18.5-py2.py3-none-any.whl"
    $pywin32 = "C:\Windows\Temp\pywin32-219.win-amd64-py2.7.exe"
    & $python_home\python.exe $pip/pip install $pip
    & $python_home\Scripts\pip.exe install $setuptools
    & $python_home\Scripts\easy_install.exe $pywin32
}
[Environment]::SetEnvironmentVariable("Path", "$env:Path;C:\Program Files\python\;C:\Program Files\python\Scripts\", "User")

if (!(Test-Path "C:\Windows\virtiodriver" )) {
    Write-Host "Install VirtIO Driver...."
    xzFile "C:\Windows\Temp\virtiodriver.tar.gz" "C:\Windows"
    $Host.UI.RawUI.WindowTitle = "Installing VirtIO certificate..."
    $virtioCertPath = "C:\Windows\virtiodriver\VirtIO.cer"
    $virtioDriversPath = "C:\Windows\virtiodriver"
    $cacert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($virtioCertPath)
    $castore = New-Object System.Security.Cryptography.X509Certificates.X509Store([System.Security.Cryptography.X509Certificates.StoreName]::TrustedPublisher,`
           [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine)
    $castore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    $castore.Add($cacert)
    Write-Host "Installing VirtIO drivers from: $virtioDriversPath"
    $process = Start-process -Wait -PassThru pnputil "-i -a C:\Windows\virtiodriver\*.inf"
    if ($process.ExitCode -eq 0){
        Write-Host "VirtIO has been successfully installed"
    } else {
        Write-Host "InstallVirtIO failed"
    }
}

if (!(Test-Path "C:\Windows\vagent" )) {
    Write-Host "Config Vagent...."
    xzFile "C:\Windows\Temp\vagent.tar.gz" "C:\Windows"
    $python = "C:\Program Files\python\python.exe"
    & $python C:\Windows\vagent\vagent_service.py install
    & $python C:\Windows\vagent\vagent_service.py start
    Set-Service -Name "vagent" -StartupType Automatic -description "LiveCloud Agent for VM"
    
    # configure firewall
    Write-Host "Configuring firewall"
    netsh advfirewall firewall add rule name="vagent" dir=in action=allow service=vagent enable=yes
    netsh advfirewall firewall add rule name="vagent" dir=in action=allow program="C:\Windows\vagent\vagent.py" enable=yes
    netsh advfirewall firewall add rule name="vagent" dir=in action=allow protocol=TCP localport=12345
}

if (!(Test-Path "C:\Program Files\qemu-ga" )) {
    $msiFile = "C:\Windows\Temp\qemu-ga-x86_64.msi"
    $targetdit = "C:\Program Files\qemu-ga"
    $arguments = @(
        "/i"
        "`"$msiFile`""
        "/qn"
        "/norestart"
        "ALLUSERS=1"
        "TARGETDIR=`"$targetdit`""
    )
    Write-Host "Installing $msiFile....."
    $process = Start-Process -FilePath msiexec.exe -ArgumentList $arguments -Wait -PassThru
    if ($process.ExitCode -eq 0){
        Write-Host "$msiFile has been successfully installed"
        Start-Service "QEMU Guest Agent VSS Provider"
        Start-Service "QEMU-GA"
    } else {
        Write-Host "installer exit code $($process.ExitCode) for file $($msifile)"
    }   
}