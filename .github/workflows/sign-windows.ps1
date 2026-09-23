# Signs Windows binaries with Azure Artifact Signing.
#
# Craft runs this as its CodeSigning/WindowsCustomSignCommand for every
# binary that goes into the package, the bundled 7-Zip helper and the final
# installer. Craft passes one argument: a file with one path per line.
#
# Tool locations come from the environment, set up by the workflow before
# packaging:
#   WINDOWS_SIGNTOOL      signtool.exe from the Windows SDK build tools
#   WINDOWS_SIGN_DLIB     Azure.CodeSigning.Dlib.dll (Artifact Signing client)
#   WINDOWS_SIGN_METADATA metadata.json naming account, profile and endpoint
#   WINDOWS_SIGN_LOG      every signed path is appended here for verification
#
# Authentication happens inside the dlib via DefaultAzureCredential; the
# workflow logs in with azure/login (OIDC) right before packaging.

param(
    [Parameter(Mandatory = $true)]
    [string]$FileList,
    # signtool takes many files per call, but the command line must stay well
    # below the Windows limit of 32767 characters
    [int]$MaxFileArgsLength = 20000
)

$ErrorActionPreference = "Stop"

foreach ($name in "WINDOWS_SIGNTOOL", "WINDOWS_SIGN_DLIB", "WINDOWS_SIGN_METADATA") {
    $value = [Environment]::GetEnvironmentVariable($name)
    if (-not $value -or -not (Test-Path $value)) {
        Write-Error "$name is not set or does not exist: '$value'"
        exit 1
    }
}
if (-not $env:WINDOWS_SIGN_LOG) {
    Write-Error "WINDOWS_SIGN_LOG is not set"
    exit 1
}

$files = @(Get-Content $FileList | Where-Object { $_.Trim() })
if ($files.Count -eq 0) {
    Write-Error "No files to sign in $FileList"
    exit 1
}

$signArgs = @(
    "sign", "/v",
    "/fd", "SHA256",
    "/tr", "http://timestamp.acs.microsoft.com",
    "/td", "SHA256",
    "/dlib", $env:WINDOWS_SIGN_DLIB,
    "/dmdf", $env:WINDOWS_SIGN_METADATA
)

function Invoke-Signtool([string[]]$batch) {
    Write-Host "Signing $($batch.Count) file(s)"
    & $env:WINDOWS_SIGNTOOL @signArgs @batch
    if ($LASTEXITCODE -ne 0) {
        Write-Error "signtool failed with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
    Add-Content -Path $env:WINDOWS_SIGN_LOG -Value $batch
}

$batch = @()
$batchLength = 0
foreach ($file in $files) {
    # +1 for the separating space
    if ($batch.Count -gt 0 -and ($batchLength + $file.Length + 1) -gt $MaxFileArgsLength) {
        Invoke-Signtool $batch
        $batch = @()
        $batchLength = 0
    }
    $batch += $file
    $batchLength += $file.Length + 1
}
Invoke-Signtool $batch
