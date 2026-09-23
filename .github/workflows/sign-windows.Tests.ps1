# Pester tests for sign-windows.ps1, the custom sign command craft runs
# for Windows packages. signtool is replaced by a recording stub so the
# tests exercise the script's own logic: file list handling, batching,
# argument construction and failure propagation.
#
# Run: pwsh -NoProfile -Command "Invoke-Pester .github/workflows/sign-windows.Tests.ps1"

BeforeAll {
    $script:signScript = Join-Path $PSScriptRoot "sign-windows.ps1"
    $script:work = Join-Path ([IO.Path]::GetTempPath()) ("sign-windows-tests-" + [Guid]::NewGuid())
    New-Item -ItemType Directory $script:work | Out-Null

    # every invocation of the stub appends one line per argument, with a
    # blank line separating invocations
    $script:calls = Join-Path $script:work "signtool-calls.txt"
    $script:stub = Join-Path $script:work "signtool"
    @'
#!/bin/sh
for a in "$@"; do printf '%s\n' "$a" >> "$FAKE_SIGNTOOL_CALLS"; done
printf '\n' >> "$FAKE_SIGNTOOL_CALLS"
exit "${FAKE_SIGNTOOL_EXIT:-0}"
'@ | Set-Content -Path $script:stub -NoNewline
    chmod +x $script:stub

    $script:dlib = Join-Path $script:work "Azure.CodeSigning.Dlib.dll"
    $script:metadata = Join-Path $script:work "metadata.json"
    Set-Content $script:dlib ""
    Set-Content $script:metadata "{}"

    function Invoke-SignScript {
        param([string[]]$Files, [hashtable]$Env = @{}, [string[]]$ExtraArgs = @())
        $list = Join-Path $script:work ("filelist-" + [Guid]::NewGuid() + ".txt")
        Set-Content -Path $list -Value ($Files -join "`n")
        $env:FAKE_SIGNTOOL_CALLS = $script:calls
        $env:WINDOWS_SIGNTOOL = $script:stub
        $env:WINDOWS_SIGN_DLIB = $script:dlib
        $env:WINDOWS_SIGN_METADATA = $script:metadata
        $env:WINDOWS_SIGN_LOG = Join-Path $script:work "signed.log"
        foreach ($k in $Env.Keys) { Set-Item "env:$k" $Env[$k] }
        $output = & pwsh -NoProfile -File $script:signScript $list @ExtraArgs 2>&1
        return @{ ExitCode = $LASTEXITCODE; Output = ($output | Out-String) }
    }

    function Get-SigntoolCalls {
        if (-not (Test-Path $script:calls)) { return @() }
        $text = Get-Content $script:calls -Raw
        $calls = [System.Collections.Generic.List[object]]::new()
        foreach ($chunk in ($text -split "`n`n")) {
            if ($chunk.Trim()) {
                $calls.Add([string[]]@($chunk -split "`n" | Where-Object { $_ -ne "" }))
            }
        }
        return ,$calls
    }
}

AfterAll {
    Remove-Item $script:work -Recurse -Force -ErrorAction SilentlyContinue
}

Describe "sign-windows.ps1" {
    BeforeEach {
        Remove-Item $script:calls -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $script:work "signed.log") -ErrorAction SilentlyContinue
        Remove-Item env:FAKE_SIGNTOOL_EXIT -ErrorAction SilentlyContinue
    }

    It "signs every listed file with the Artifact Signing dlib in one signtool call" {
        $files = @("/pkg/bin/PlanioStorage.exe", "/pkg/bin/Qt6Core.dll")
        $result = Invoke-SignScript -Files $files

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $calls = Get-SigntoolCalls
        $calls.Count | Should -Be 1
        $args = $calls[0]
        $args[0] | Should -Be "sign"
        $args | Should -Contain "/fd"
        $args | Should -Contain "SHA256"
        $args | Should -Contain "/tr"
        $args | Should -Contain "http://timestamp.acs.microsoft.com"
        $args | Should -Contain "/td"
        $args | Should -Contain "/dlib"
        $args | Should -Contain $script:dlib
        $args | Should -Contain "/dmdf"
        $args | Should -Contain $script:metadata
        # files come last, after all options, in list order
        $args[-2] | Should -Be $files[0]
        $args[-1] | Should -Be $files[1]
    }

    It "ignores blank lines in the file list" {
        $result = Invoke-SignScript -Files @("/pkg/bin/a.exe", "", "   ", "/pkg/bin/b.dll", "")

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $args = (Get-SigntoolCalls)[0]
        $args | Should -Contain "/pkg/bin/a.exe"
        $args | Should -Contain "/pkg/bin/b.dll"
        ($args | Where-Object { $_ -match '^\s*$' }).Count | Should -Be 0
    }

    It "splits the files into several signtool calls when the command line would get too long" {
        $files = 1..10 | ForEach-Object { "/pkg/bin/library-number-$_.dll" }
        # each path is ~30 chars; a 100 char budget forces multiple batches
        $result = Invoke-SignScript -Files $files -ExtraArgs @("-MaxFileArgsLength", "100")

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $calls = Get-SigntoolCalls
        $calls.Count | Should -BeGreaterThan 1
        foreach ($call in $calls) {
            $call[0] | Should -Be "sign"
            $call | Should -Contain "/dmdf"
            $batch = $call | Where-Object { $_ -like "/pkg/bin/*" }
            ($batch -join " ").Length | Should -BeLessOrEqual 100
        }
        $signed = $calls | ForEach-Object { $_ | Where-Object { $_ -like "/pkg/bin/*" } }
        $signed | Should -Be $files
    }

    It "fails when signtool fails" {
        $result = Invoke-SignScript -Files @("/pkg/bin/a.exe") -Env @{ FAKE_SIGNTOOL_EXIT = "3" }

        $result.ExitCode | Should -Not -Be 0
    }

    It "fails when the signing tools are not configured" {
        $result = Invoke-SignScript -Files @("/pkg/bin/a.exe") -Env @{ WINDOWS_SIGN_DLIB = "/nonexistent/dlib.dll" }

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match "WINDOWS_SIGN_DLIB"
        (Get-SigntoolCalls).Count | Should -Be 0
    }

    It "records every signed file in the sign log" {
        $files = @("/pkg/bin/a.exe", "/pkg/bin/b.dll")
        $result = Invoke-SignScript -Files $files

        $result.ExitCode | Should -Be 0 -Because $result.Output
        Get-Content (Join-Path $script:work "signed.log") | Should -Be $files
    }
}
