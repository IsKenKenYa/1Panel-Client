# arkts-check.ps1 — Launcher for arkts-check.js that works even when Node.js
# is NOT on PATH, by falling back to DevEco Studio's bundled node.exe.
#
# Usage:
#   .\arkts-check.ps1 -Project <abs-project-root> <file.ets...> [-Json] [-Studio <path>]
#
# All parameters are forwarded to arkts-check.js (kebab-case names also accepted
# by passing them through, e.g.: .\arkts-check.ps1 --project X f.ets --json)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Find-Node {
    # 1. Node on PATH
    $cmd = Get-Command node -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    # 2. DevEco Studio's bundled node (registry: HKLM\SOFTWARE\Huawei\DevEco Studio\<version> default value)
    foreach ($root in @('HKLM:\SOFTWARE\Huawei\DevEco Studio', 'HKLM:\SOFTWARE\WOW6432Node\Huawei\DevEco Studio')) {
        if (Test-Path $root) {
            foreach ($v in (Get-ChildItem $root -ErrorAction SilentlyContinue)) {
                $studio = (Get-ItemProperty $v.PSPath -ErrorAction SilentlyContinue).'(default)'
                if ($studio) {
                    $cand = Join-Path $studio 'tools\node\node.exe'
                    if (Test-Path $cand) { return $cand }
                }
            }
        }
    }

    # 3. Common install paths
    foreach ($p in @(
        'C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe',
        'C:\Program Files (x86)\Huawei\DevEco Studio\tools\node\node.exe',
        'D:\DevEco Studio\tools\node\node.exe'
    )) {
        if (Test-Path $p) { return $p }
    }

    return $null
}

$node = Find-Node
if (-not $node) {
    Write-Error 'Node.js not found: not on PATH and DevEco Studio bundled node not found. Install DevEco Studio or Node.js (>= 16).'
    exit 2
}

& $node (Join-Path $scriptDir 'arkts-check.js') @args
exit $LASTEXITCODE
