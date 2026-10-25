param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9]+(?:-[a-z0-9]+)*$')]
    [string]$Restaurant,

    [string[]]$FlutterArgs = @('--profile', '--no-enable-impeller')
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Builder = Join-Path $ProjectRoot 'tool\hubdine_build.dart'

if (-not (Test-Path $Builder)) {
    throw "HubDine build tool not found: $Builder"
}

$RestaurantDir = Join-Path $ProjectRoot "config\restaurants\$Restaurant"
$RestaurantConfig = Join-Path $RestaurantDir 'restaurant.json'
$FirebaseConfig = Join-Path $RestaurantDir 'google-services.json'

if (-not (Test-Path $RestaurantConfig)) {
    throw "Missing restaurant config: $RestaurantConfig"
}
if (-not (Test-Path $FirebaseConfig)) {
    throw "Missing Firebase Android config: $FirebaseConfig"
}

Push-Location $ProjectRoot
try {
    & dart run $Builder $Restaurant run @FlutterArgs
    $ExitCode = $LASTEXITCODE
}
finally {
    Pop-Location
}

if ($null -eq $ExitCode) {
    throw 'Dart build process did not return an exit code.'
}
exit $ExitCode
