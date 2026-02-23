param(
    [string]$date  # 예: 2026-02-20
)

# 최신 work.md 파일 찾기
$workFile = Get-ChildItem -Name "work*.md" | Sort-Object | Select-Object -Last 1
if (-not $workFile) {
    Write-Host "work.md 파일을 찾을 수 없습니다." -ForegroundColor Red
    exit
}

# 파일 읽기
$lines = Get-Content $workFile -Encoding UTF8

# 프로젝트 자동 탐지
# 조건: "## " 로 시작하는 줄은 모두 프로젝트 블록
$projectHeaders = $lines | Where-Object { $_ -match "^## " }

# 보고서 최종 출력 버퍼
$out = @()
$out += "# 주간보고 — $date"
$out += ""
$out += "---"
$out += ""
$out += "# 1. 금주 실적"
$out += ""

# -------------------------------------------------------
# 각 프로젝트별로 Shipping/Active 내의 완료된 항목([x]) 추출
# -------------------------------------------------------
foreach ($projHeader in $projectHeaders) {

    $projName = $projHeader -replace "^## ", ""
    $out += "## $projName"

    $inProject = $false
    $inShipping = $false
    $inActive = $false
    $completed = @()

    foreach ($line in $lines) {

        if ($line -eq $projHeader) {
            $inProject = $true
            continue
        }

        if ($inProject -and $line -match "^## ") {
            break
        }

        if ($inProject -and $line -match "^### Shipping This Week") {
            $inShipping = $true
            $inActive = $false
            continue
        }

        if ($inProject -and $line -match "^### Active Work") {
            $inActive = $true
            $inShipping = $false
            continue
        }

        # Shipping 또는 Active 내부의 완료 작업만 찾기
        if (($inShipping -or $inActive) -and $line -match "- \[x\]") {
            $completed += $line
        }
    }

    if ($completed.Count -eq 0) {
        $out += "- (금주 실적 없음)"
    } else {
        $out += $completed
    }

    $out += ""
}

$out += "---"
$out += ""
$out += "# 2. 금주 미처리 업무"
$out += ""

# -------------------------------------------------------
# 각 프로젝트별로 Shipping/Active 내의 미완료 항목([ ]) 추출
# -------------------------------------------------------
foreach ($projHeader in $projectHeaders) {

    $projName = $projHeader -replace "^## ", ""
    $out += "## $projName"

    $inProject = $false
    $inShipping = $false
    $inActive = $false
    $incomplete = @()

    foreach ($line in $lines) {

        if ($line -eq $projHeader) {
            $inProject = $true
            continue
        }

        if ($inProject -and $line -match "^## ") {
            break
        }

        if ($inProject -and $line -match "^### Shipping This Week") {
            $inShipping = $true
            $inActive = $false
            continue
        }

        if ($inProject -and $line -match "^### Active Work") {
            $inActive = $true
            $inShipping = $false
            continue
        }

        # 미완료 작업만
        if (($inShipping -or $inActive) -and $line -match "- \[ \]") {
            $incomplete += $line
        }
    }

    if ($incomplete.Count -eq 0) {
        $out += "- (미처리 업무 없음)"
    } else {
        $out += $incomplete
    }

    $out += ""
}

$out += "---"
$out += ""
$out += "# 3. 차주 계획"
$out += ""

# -------------------------------------------------------
# 각 프로젝트별 Next Up 섹션 추출
# -------------------------------------------------------
foreach ($projHeader in $projectHeaders) {

    $projName = $projHeader -replace "^## ", ""
    $out += "## $projName"

    $inProject = $false
    $inNext = $false
    $nextup = @()

    foreach ($line in $lines) {

        if ($line -eq $projHeader) {
            $inProject = $true
            continue
        }

        if ($inProject -and $line -match "^## ") {
            break
        }

        if ($inProject -and $line -match "^### Next Up") {
            $inNext = $true
            continue
        }

        if ($inNext -and $line -match "^### ") {
            break
        }

        if ($inNext) {
            $nextup += $line
        }
    }

    if ($nextup.Count -eq 0) {
        $out += "- (차주 계획 없음)"
    } else {
        $out += $nextup
    }

    $out += ""
}

# -------------------------------------------------------
# 저장 (UTF8 with BOM)
# -------------------------------------------------------
$reportFile = "report-$date.md"
$Utf8 = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllLines($reportFile, $out, $Utf8)

Write-Host "report 생성 완료 → $reportFile" -ForegroundColor Green