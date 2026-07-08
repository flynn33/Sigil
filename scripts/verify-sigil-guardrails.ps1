$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Policy = Join-Path $Root "tools/sigil_guardrails/sigil_guardrail_policy.json"
$Verifier = Join-Path $Root "tools/sigil_guardrails/verify_sigil_guardrails.py"

python $Verifier --project-root $Root --policy $Policy --strict

$Solution = Get-ChildItem -Path $Root -Filter *.sln -Recurse | Select-Object -First 1
if ($null -ne $Solution) {
    Write-Host "Visual Studio solution detected: $($Solution.FullName)"
    if (Get-Command msbuild -ErrorAction SilentlyContinue) {
        msbuild $Solution.FullName /t:Restore,Build /p:Configuration=Debug
    } else {
        Write-Host "Open the solution in Visual Studio for Windows, run Restore, Build, and Test, then record evidence."
    }
} else {
    Write-Host "No Visual Studio solution detected. Open the Sigil project folder in Visual Studio for Windows, run this script in the integrated terminal, and record the non-applicable Apple-binary build limitation with the passing guardrail output."
}
