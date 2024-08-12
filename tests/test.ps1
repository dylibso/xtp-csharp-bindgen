# Enable strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Get all YAML files in the schemas directory
$files = Get-ChildItem -Path .\tests\schemas\*.yaml

foreach ($file in $files) {
    Write-Host "Generating and testing $($file.FullName)..."

    $outputFolder = ".\tests\output\$($file.BaseName)"

    xtp plugin init --schema-file $file.FullName --template .\bundle --path $outputFolder -y --feature stub-with-code-samples --name output
}
