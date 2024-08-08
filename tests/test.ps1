# Enable strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Get all YAML files in the schemas directory
$files = Get-ChildItem -Path .\tests\schemas\*.yaml

foreach ($file in $files) {
    Write-Host "Generating and testing $($file.FullName)..."

    xtp plugin init --schema-file $file.FullName --template .\bundle --path .\tests\output -y --feature stub-with-code-samples --name output

    # cd .\tests\output
    # xtp plugin build
    # cd ..\..
}
