$ErrorActionPreference = 'Stop'

$rootDir = if ($args.Count -gt 0) { $args[0] } else { (Get-Location).Path }
Set-Location $rootDir

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'git is required'
}

git config core.hooksPath .githooks

Write-Host 'Configured git hooks path to .githooks'