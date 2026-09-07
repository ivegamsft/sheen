#!/usr/bin/env pwsh
param()
$ErrorActionPreference = 'Stop'
$python = if ($IsWindows) { 'python' } else { 'python3' }
& $python -B (Join-Path $PSScriptRoot 'test-release-reliability.py')
if ($LASTEXITCODE -ne 0) { throw 'Release reliability regressions failed' }
