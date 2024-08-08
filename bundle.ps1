# Enable strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Run the build command
npm run build

# Remove the bundle directory if it exists and create a new one
if (Test-Path -Path "bundle") {
    Remove-Item -Recurse -Force "bundle"
}
New-Item -ItemType Directory -Path "bundle"
New-Item -ItemType Directory -Path "bundle/template"

# Copy files to the bundle directory
Copy-Item -Recurse -Force "template/*" "bundle/template"
Copy-Item -Force "dist/plugin.wasm" "bundle"
Copy-Item -Force "config.yaml" "bundle"

# Create a zip file of the bundle directory
if (Test-Path -Path "bundle.zip") {
    Remove-Item -Force "bundle.zip"
}
Compress-Archive -Path "bundle/*" -DestinationPath "bundle.zip"
