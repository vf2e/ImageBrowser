#Requires -Version 5.1
param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$BuildDir = "",
    [switch]$GenerateOnly,
    [switch]$OpenReport
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not $BuildDir) {
    $BuildDir = Join-Path $ProjectRoot "build-release"
}

$TestDir = Join-Path $BuildDir "tests"
$ReportDir = Join-Path $TestDir "reports"
$OutputDir = Join-Path $BuildDir "test-report"
$OutputFile = Join-Path $OutputDir "index.html"
$TemplateFile = Join-Path $PSScriptRoot "test_report_template.html"

$Suites = @(
    @{ Id = "backend"; Exe = "tst_imagebrowserbackend.exe"; XmlFile = "backend.xml"; TxtFile = "test-result-backend.txt"; Title = "C++ backend"; Subtitle = "ImageBrowserBackend"; Platform = "offscreen" },
    @{ Id = "qml"; Exe = "tst_qml.exe"; XmlFile = "qml.xml"; TxtFile = "test-result-qml.txt"; Title = "QML components"; Subtitle = "UI + controller"; Platform = "offscreen" },
    @{ Id = "keyboard"; Exe = "tst_keyboard_integration.exe"; XmlFile = "keyboard.xml"; TxtFile = "test-result-keyboard.txt"; Title = "Keyboard integration"; Subtitle = "main.qml shortcuts"; Platform = "windows" }
)

function Escape-Html([string]$Text) {
    if ($null -eq $Text) { return "" }
    return [System.Net.WebUtility]::HtmlEncode($Text)
}

function Parse-QtTestSuite([string]$XmlPath) {
    if (-not (Test-Path $XmlPath)) {
        throw "JUnit XML not found: $XmlPath"
    }

    [xml]$doc = Get-Content -Path $XmlPath -Encoding UTF8
    $suite = $doc.testsuite
    if (-not $suite) {
        throw "Invalid Qt Test XML: $XmlPath"
    }

    $properties = @{}
    if ($suite.properties -and $suite.properties.property) {
        foreach ($prop in $suite.properties.property) {
            $properties[$prop.name] = $prop.value
        }
    }

    $cases = @()
    if ($suite.testcase) {
        foreach ($tc in $suite.testcase) {
            $result = $tc.result
            if (-not $result) {
                if ($tc.failure) { $result = "fail" } else { $result = "pass" }
            }
            $message = ""
            if ($tc.failure) {
                $message = $tc.failure.'#text'
                if (-not $message) { $message = $tc.failure.message }
            }
            $isHarness = ($tc.name -eq "initTestCase" -or $tc.name -eq "cleanupTestCase")
            $cases += [PSCustomObject]@{
                Name = $tc.name
                Result = $result
                Message = $message
                IsHarness = $isHarness
            }
        }
    }

    $businessCases = $cases | Where-Object { -not $_.IsHarness }
    $failedCases = $businessCases | Where-Object { $_.Result -ne "pass" }

    [PSCustomObject]@{
        Name = $suite.name
        Properties = $properties
        Cases = $cases
        BusinessCount = @($businessCases).Count
        PassedCount = @($businessCases | Where-Object { $_.Result -eq "pass" }).Count
        FailedCount = @($failedCases).Count
        FailedCases = $failedCases
        DurationMs = 0
        ExitCode = 0
    }
}

function Build-FailedBlocks([array]$SuiteResults) {
    $parts = New-Object System.Collections.Generic.List[string]
    foreach ($suite in $SuiteResults) {
        foreach ($fc in $suite.FailedCases) {
            $line1 = "    <div class=""fail-card"">"
            $line2 = "      <div class=""fail-card-head"">"
            $line3 = "        <span class=""badge badge-fail"">FAIL</span>"
            $line4 = "        <strong>" + (Escape-Html $suite.Meta.Title) + "</strong>"
            $line5 = "        <code>" + (Escape-Html $fc.Name) + "</code>"
            $line6 = "      </div>"
            $line7 = "      <pre>" + (Escape-Html $fc.Message) + "</pre>"
            $line8 = "    </div>"
            $parts.Add(($line1, $line2, $line3, $line4, $line5, $line6, $line7, $line8) -join "`n")
        }
    }
    if ($parts.Count -eq 0) {
        return '<p class="muted">No failures.</p>'
    }
    return $parts -join "`n"
}

function Build-SummaryCards([array]$SuiteResults) {
    $parts = New-Object System.Collections.Generic.List[string]
    foreach ($suite in $SuiteResults) {
        $cardClass = if ($suite.FailedCount -eq 0) { "ok" } else { "bad" }
        $parts.Add("      <div class=""card $cardClass"">")
        $parts.Add("        <h3>" + (Escape-Html $suite.Meta.Title) + "</h3>")
        $parts.Add("        <p class=""big"">$($suite.PassedCount)<span>/$($suite.BusinessCount)</span></p>")
        $parts.Add("        <p class=""muted"">passed / business cases</p>")
        $parts.Add("      </div>")
    }
    return $parts -join "`n"
}

function Build-SuiteSections([array]$SuiteResults) {
    $parts = New-Object System.Collections.Generic.List[string]
    foreach ($suite in $SuiteResults) {
        $suitePassRate = 0
        if ($suite.BusinessCount -gt 0) {
            $suitePassRate = [math]::Round(100.0 * $suite.PassedCount / $suite.BusinessCount, 1)
        }
        $durationText = "n/a"
        if ($suite.DurationMs -gt 0) {
            $durationText = "{0:N2} s" -f ($suite.DurationMs / 1000.0)
        }

        $suiteId = Escape-Html $suite.Meta.Id
        $parts.Add("    <section class=""suite"" id=""suite-$suiteId"">")
        $parts.Add("      <header class=""suite-head"" onclick=""toggleSuite('$suiteId')"">")
        $parts.Add("        <div>")
        $parts.Add("          <h2>" + (Escape-Html $suite.Meta.Title) + "</h2>")
        $parts.Add("          <p class=""muted"">" + (Escape-Html $suite.Meta.Subtitle) + "</p>")
        $parts.Add("        </div>")
        $parts.Add("        <div class=""suite-stats"">")
        $parts.Add("          <span class=""pill"">$($suite.PassedCount)/$($suite.BusinessCount) passed</span>")
        $parts.Add("          <span class=""pill"">$durationText</span>")
        $parts.Add("          <span class=""chevron"" id=""chev-$suiteId"">&#9660;</span>")
        $parts.Add("        </div>")
        $parts.Add("      </header>")
        $parts.Add("      <div class=""suite-body"" id=""body-$suiteId"">")
        $parts.Add("        <div class=""progress""><div class=""progress-bar"" style=""width:$suitePassRate%""></div></div>")
        $qtVer = Escape-Html $suite.Properties.QtVersion
        $parts.Add("        <p class=""suite-meta muted"">suite <code>" + (Escape-Html $suite.Name) + "</code> / Qt $qtVer</p>")
        $parts.Add("        <table class=""case-table"">")
        $parts.Add("          <thead><tr><th>Status</th><th>Case</th><th>Detail</th></tr></thead>")
        $parts.Add("          <tbody>")

        foreach ($case in ($suite.Cases | Where-Object { -not $_.IsHarness })) {
            $statusClass = if ($case.Result -eq "pass") { "pass" } else { "fail" }
            $statusLabel = if ($case.Result -eq "pass") { "PASS" } else { "FAIL" }
            $detail = ""
            if ($case.Message) {
                $detail = "<details><summary>details</summary><pre>" + (Escape-Html $case.Message) + "</pre></details>"
            }
            $parts.Add("        <tr class=""case-row"" data-name=""" + (Escape-Html $case.Name.ToLower()) + """>")
            $parts.Add("          <td><span class=""badge badge-$statusClass"">$statusLabel</span></td>")
            $parts.Add("          <td><code>" + (Escape-Html $case.Name) + "</code></td>")
            $parts.Add("          <td>$detail</td>")
            $parts.Add("        </tr>")
        }

        $parts.Add("          </tbody>")
        $parts.Add("        </table>")
        $parts.Add("      </div>")
        $parts.Add("    </section>")
    }
    return $parts -join "`n"
}

function Write-HtmlReport {
    param(
        [array]$SuiteResults,
        [string]$OutPath,
        [hashtable]$Meta
    )

    $totalBusiness = ($SuiteResults | Measure-Object -Property BusinessCount -Sum).Sum
    $totalPassed = ($SuiteResults | Measure-Object -Property PassedCount -Sum).Sum
    $totalFailed = ($SuiteResults | Measure-Object -Property FailedCount -Sum).Sum
    $passRate = 0
    if ($totalBusiness -gt 0) {
        $passRate = [math]::Round(100.0 * $totalPassed / $totalBusiness, 1)
    }
    $overallStatus = if ($totalFailed -eq 0) { "pass" } else { "fail" }
    $overallLabel = if ($totalFailed -eq 0) { "ALL PASSED" } else { "$totalFailed FAILED" }

    $template = Get-Content -Path $TemplateFile -Raw -Encoding UTF8
    $html = $template
    $html = $html.Replace("{{GENERATED_AT}}", (Escape-Html $Meta.GeneratedAt))
    $html = $html.Replace("{{BUILD_DIR}}", (Escape-Html $Meta.BuildDir))
    $html = $html.Replace("{{OVERALL_STATUS}}", $overallStatus)
    $html = $html.Replace("{{OVERALL_LABEL}}", (Escape-Html $overallLabel))
    $html = $html.Replace("{{PASS_RATE}}", "$passRate")
    $html = $html.Replace("{{TOTAL_PASSED}}", "$totalPassed")
    $html = $html.Replace("{{TOTAL_BUSINESS}}", "$totalBusiness")
    $html = $html.Replace("{{TOTAL_FAILED}}", "$totalFailed")
    $html = $html.Replace("{{SUMMARY_CARDS}}", (Build-SummaryCards $SuiteResults))
    $html = $html.Replace("{{FAILED_BLOCKS}}", (Build-FailedBlocks $SuiteResults))
    $html = $html.Replace("{{SUITE_SECTIONS}}", (Build-SuiteSections $SuiteResults))

    $null = New-Item -ItemType Directory -Path (Split-Path $OutPath -Parent) -Force
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($OutPath, $html, $utf8NoBom)
}

function Run-TestSuites {
    if (-not (Test-Path $TestDir)) {
        throw "Test directory not found: $TestDir"
    }

    $null = New-Item -ItemType Directory -Path $ReportDir -Force
    $results = @()

    foreach ($suite in $Suites) {
        $exePath = Join-Path $TestDir $suite.Exe
        if (-not (Test-Path $exePath)) {
            throw "Test executable not found: $exePath"
        }

        $xmlPath = Join-Path $ReportDir $suite.XmlFile
        $txtPath = Join-Path $TestDir $suite.TxtFile
        $savedPlatform = $env:QT_QPA_PLATFORM
        $env:QT_QPA_PLATFORM = $suite.Platform

        Push-Location $TestDir
        try {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            & $exePath "-o" "${xmlPath},junitxml" "-o" "${txtPath},txt"
            $exitCode = $LASTEXITCODE
            $sw.Stop()

            $parsed = Parse-QtTestSuite -XmlPath $xmlPath
            $parsed | Add-Member -NotePropertyName Meta -NotePropertyValue $suite -Force
            $parsed.ExitCode = $exitCode
            $parsed.DurationMs = $sw.ElapsedMilliseconds
            $results += $parsed

            $secs = [math]::Round($sw.Elapsed.TotalSeconds, 2)
            Write-Host "[INFO] $($suite.Title): $($parsed.PassedCount)/$($parsed.BusinessCount) passed (${secs}s)"
        }
        finally {
            Pop-Location
            if ($null -ne $savedPlatform) { $env:QT_QPA_PLATFORM = $savedPlatform }
            else { Remove-Item Env:QT_QPA_PLATFORM -ErrorAction SilentlyContinue }
        }
    }

    return $results
}

if (-not $GenerateOnly) {
    $suiteResults = Run-TestSuites
}
else {
    $suiteResults = @()
    foreach ($suite in $Suites) {
        $xmlPath = Join-Path $ReportDir $suite.XmlFile
        $parsed = Parse-QtTestSuite -XmlPath $xmlPath
        $parsed | Add-Member -NotePropertyName Meta -NotePropertyValue $suite -Force
        $suiteResults += $parsed
    }
}

$meta = @{
    GeneratedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    BuildDir = $BuildDir
}

Write-HtmlReport -SuiteResults $suiteResults -OutPath $OutputFile -Meta $meta

$anyFailed = @($suiteResults | Where-Object { $_.FailedCount -gt 0 -or $_.ExitCode -ne 0 }).Count -gt 0
Write-Host ""
Write-Host "[OK] HTML report: $OutputFile"
if ($anyFailed) {
    Write-Host "[WARN] Some tests failed."
}

if ($OpenReport) {
    Start-Process $OutputFile
}

if (-not $GenerateOnly) {
    $worstExit = ($suiteResults | ForEach-Object { $_.ExitCode } | Measure-Object -Maximum).Maximum
    if ($null -eq $worstExit) { $worstExit = 0 }
    exit $worstExit
}

exit 0
