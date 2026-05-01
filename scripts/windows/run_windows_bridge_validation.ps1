param(
  [string]$Device = "windows"
)

$ErrorActionPreference = "Stop"

Write-Host "[Windows Bridge Validation] Running integration assertions on device: $Device"

$testPath = "integration_test/windows/windows_bridge_integration_test.dart"

flutter test $testPath -d $Device --reporter expanded
if ($LASTEXITCODE -ne 0) {
  throw "Windows bridge validation failed with exit code $LASTEXITCODE"
}

Write-Host "[Windows Bridge Validation] Passed"
