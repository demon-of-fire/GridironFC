[CmdletBinding()]
param(
    [string]$Remote = "origin",
    [string]$Branch = "main",
    [string]$Repository = "demon-of-fire/GridironFC",
    [int]$TimeoutMinutes = 30
)

$ErrorActionPreference = "Stop"

git push $Remote $Branch
if ($LASTEXITCODE -ne 0) { throw "git push failed." }

$commit = (git rev-parse HEAD).Trim()
$deadline = (Get-Date).AddMinutes($TimeoutMinutes)
Write-Output "Waiting for the GitHub release workflow for $($commit.Substring(0, 7))..."

do {
    $runJson = gh run list --repo $Repository --workflow "Build iOS App" --commit $commit --limit 1 --json databaseId,status,conclusion,url
    $run = $runJson | ConvertFrom-Json | Select-Object -First 1
    if ($null -ne $run) {
        Write-Output "Workflow $($run.databaseId): $($run.status)"
        if ($run.status -eq "completed") {
            if ($run.conclusion -ne "success") {
                throw "Release workflow failed: $($run.url)"
            }
            & (Join-Path $PSScriptRoot "Fetch-LatestReleaseIPA.ps1") -Repository $Repository -Destination (Get-Location).Path
            exit $LASTEXITCODE
        }
    }
    Start-Sleep -Seconds 15
} while ((Get-Date) -lt $deadline)

throw "Timed out waiting for the release workflow."
