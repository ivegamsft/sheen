#!/usr/bin/env pwsh
param()
$ErrorActionPreference = 'Stop'
$python = if ($IsWindows) { 'python' } else { 'python3' }
& $python -B (Join-Path $PSScriptRoot 'test-downstream-token-hygiene.py')
if ($LASTEXITCODE -ne 0) { throw 'Downstream token hygiene regressions failed' }
