# Equivalent to set -e: Stop on any error
$ErrorActionPreference = "Stop"

# Store the original location
$originalLocation = Get-Location

# Define constants
$TEST_DIR = "bindgen-test-artifacts"

# Create directory if it doesn't exist
New-Item -ItemType Directory -Force -Path $TEST_DIR | Out-Null

# Get the first argument
$command = $args[0]

try {
    switch ($command) {
        "install" {
            # Get the latest release
            $RELEASE_URL = "https://api.github.com/repos/dylibso/xtp-bindgen-test/releases/latest"
            
            try {
                $response = Invoke-RestMethod -Uri $RELEASE_URL
                $ASSET_URL = $response.assets[0].browser_download_url
                
                if ([string]::IsNullOrEmpty($ASSET_URL)) {
                    Write-Error "Asset URL not found. Please check the asset name or the repository."
                    exit 1
                }

                Write-Host "changing into '$TEST_DIR'..."
                Set-Location $TEST_DIR

                Write-Host "downloading bundle.zip from '$ASSET_URL'..."
                Invoke-WebRequest -Uri $ASSET_URL -OutFile "bundle.zip"

                # Extract the zip file
                Expand-Archive -Path "bundle.zip" -DestinationPath "." -Force
            }
            catch {
                Write-Error "Error during installation: $_"
                throw
            }
        }
        
        "run" {
            try {
                Write-Host "changing into '$TEST_DIR/bundle/'..."
                Set-Location "$TEST_DIR/bundle"

                # Using ../../bundle so we test the bindgen template
                $PLUGIN_NAME = "exampleplugin"
                
                Write-Host "generating initial plugin code in '$(Get-Location)/$PLUGIN_NAME'..."
                xtp plugin init --schema-file schema.yaml --template ../../bundle --path $PLUGIN_NAME --name $PLUGIN_NAME --feature stub-with-code-samples --yes

                Write-Host "building '$PLUGIN_NAME'..."
                xtp plugin build --path $PLUGIN_NAME

                Write-Host "testing '$PLUGIN_NAME'..."
                xtp plugin test "$PLUGIN_NAME/dist/plugin.wasm" --with test.wasm --mock-host mock.wasm --log-level debug
            }
            catch {
                Write-Error "Error during run: $_"
                throw
            }
        }

        default {
            Write-Error "Invalid command. Use 'install' or 'run'"
            exit 1
        }
    }
}
finally {
    # Always return to the original location, even if there's an error
    Write-Host "Returning to original location: $originalLocation"
    Set-Location -Path $originalLocation
}