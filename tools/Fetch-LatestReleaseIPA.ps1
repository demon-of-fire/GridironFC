[CmdletBinding()]
param(
    [string]$Repository = "demon-of-fire/GridironFC",
    [string]$Destination = (Get-Location).Path
)

$ErrorActionPreference = "Stop"
$destinationPath = (Resolve-Path -LiteralPath $Destination).Path
$temporaryPath = Join-Path ([System.IO.Path]::GetTempPath()) ("gridironfc-release-" + [guid]::NewGuid().ToString("N"))

try {
    New-Item -ItemType Directory -Path $temporaryPath | Out-Null
    gh release download --repo $Repository --pattern "GridironFC.ipa" --pattern "release-manifest.json" --dir $temporaryPath --clobber

    $manifestPath = Join-Path $temporaryPath "release-manifest.json"
    $ipaPath = Join-Path $temporaryPath "GridironFC.ipa"
    if (-not (Test-Path -LiteralPath $manifestPath) -or -not (Test-Path -LiteralPath $ipaPath)) {
        throw "The latest release is missing GridironFC.ipa or release-manifest.json."
    }

    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $actualHash = (Get-FileHash -LiteralPath $ipaPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne $manifest.sha256.ToLowerInvariant()) {
        throw "Downloaded IPA checksum does not match release manifest for version $($manifest.version)."
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($ipaPath)
    try {
        if (-not ($archive.Entries.FullName -contains "Payload/GridironFC.app/Info.plist")) {
            throw "Downloaded file is not a valid GridironFC IPA payload."
        }
    } finally {
        $archive.Dispose()
    }

    $targetPath = Join-Path $destinationPath "GridironFC.ipa"
    Copy-Item -LiteralPath $ipaPath -Destination $targetPath -Force
    Write-Output "Verified GridironFC $($manifest.version) from $($manifest.commit.Substring(0, 7)) and saved it to $targetPath"
} finally {
    if (Test-Path -LiteralPath $temporaryPath) {
        Remove-Item -LiteralPath $temporaryPath -Recurse -Force
    }
}
