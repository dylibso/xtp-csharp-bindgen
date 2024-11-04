$exe = ""
if ($PSVersionTable.Platform -eq "Win32NT" -or ($PSVersionTable.PSEdition -eq "Desktop")) {
    $exe = ".exe"
}

# Function to check if a command exists
function Test-CommandExists {
    param ($Command)
    
    try {
        if (Get-Command $Command -ErrorAction Stop) {
            return $true
        }
    }
    catch {
        return $false
    }
    return $false
}

# Function to parse dotnet workload list output
function Get-DotnetWorkloads {
    $output = dotnet workload list | Out-String
    $lines = $output -split "`n" | ForEach-Object { $_.Trim() }
    
    $workloads = @{}
    $inWorkloadSection = $false
    $updateAvailable = $false
    
    foreach ($line in $lines) {
        if ($line -match "^Installed Workload Id") {
            $inWorkloadSection = $true
            continue
        }
        if ($line -match "^-+$") {
            continue
        }
        if ($line -match "Updates are available for") {
            $updateAvailable = $true
            break
        }
        if ($inWorkloadSection -and $line -match "^(\S+)\s+(\S+)\s+(.*)$") {
            $workloads[$matches[1]] = @{
                Version = $matches[2]
                Source = $matches[3]
            }
        }
    }
    
    return @{
        Workloads = $workloads
        UpdateAvailable = $updateAvailable
    }
}

# Initialize missing dependencies flag
$missingDeps = $false

# Check for .NET SDK
if (-not (Test-CommandExists "dotnet")) {
    $missingDeps = $true
    Write-Host ".NET SDK is not installed." -ForegroundColor Red
    Write-Host ""
    Write-Host "To install .NET SDK 8:"
    Write-Host "    winget install Microsoft.DotNet.SDK.8" -ForegroundColor Yellow
    Write-Host ""
}
else {
    # Check .NET SDK versions
    $sdks = dotnet --list-sdks
    $hasNet8 = $false
    
    foreach ($sdk in $sdks) {
        if ($sdk -match "^8\.") {
            $hasNet8 = $true
            Write-Host ".NET SDK $($sdk.Split()[0]) is installed." -ForegroundColor Green
            break
        }
    }
    
    if (-not $hasNet8) {
        $missingDeps = $true
        Write-Host ".NET SDK 8.x is not installed." -ForegroundColor Red
        Write-Host ""
        Write-Host "To install .NET SDK 8:"
        Write-Host "    winget install Microsoft.DotNet.SDK.8" -ForegroundColor Yellow
        Write-Host ""
    }

    # Check for WASI workload
    $workloadInfo = Get-DotnetWorkloads
    if (-not $workloadInfo.Workloads.ContainsKey("wasi-experimental")) {
        $missingDeps = $true
        Write-Host ".NET WASI experimental workload is not installed." -ForegroundColor Red
        Write-Host ""
        Write-Host "To install WASI workload:"
        Write-Host "    dotnet workload install wasi-experimental" -ForegroundColor Yellow
        Write-Host ""
    }
    else {
        $version = $workloadInfo.Workloads["wasi-experimental"].Version
        Write-Host ".NET WASI experimental workload $version is installed." -ForegroundColor Green
    }
}

# Check for WASI SDK
if (-not $env:WASI_SDK_PATH) {
    $missingDeps = $true
    Write-Host "WASI_SDK_PATH environment variable is not set." -ForegroundColor Red
    Write-Host ""
    Write-Host "1. Download WASI SDK from https://github.com/WebAssembly/wasi-sdk/releases" -ForegroundColor Yellow
    Write-Host "2. Extract to a directory (e.g., /usr/local/wasi-sdk or D:\tools\wasi_sdk)" -ForegroundColor Yellow
    Write-Host "3. Set WASI_SDK_PATH environment variable" -ForegroundColor Yellow
    Write-Host ""
}
elseif (-not (Test-Path (Join-Path $env:WASI_SDK_PATH "bin\clang$exe"))) {
    $missingDeps = $true
    Write-Host "WASI SDK installation appears incomplete or incorrect." -ForegroundColor Red
    Write-Host "   Could not find clang$exe in $env:WASI_SDK_PATH/bin" -ForegroundColor Red
    Write-Host ""
    Write-Host "1. Download WASI SDK from https://github.com/WebAssembly/wasi-sdk/releases" -ForegroundColor Yellow
    Write-Host "2. Extract to a directory (e.g., /usr/local/wasi-sdk or D:\tools\wasi_sdk)" -ForegroundColor Yellow
    Write-Host "3. Ensure WASI_SDK_PATH points to the correct directory" -ForegroundColor Yellow
    Write-Host ""
}
else {
    Write-Host "WASI SDK found at $env:WASI_SDK_PATH" -ForegroundColor Green
}

# Exit with error if required dependencies are missing
if ($missingDeps) {
    Write-Host ""
    Write-Host "Please install the missing required dependencies and ensure they are on your path. Then run this script again." -ForegroundColor Red
    Start-Sleep -Seconds 2
    exit 1
}