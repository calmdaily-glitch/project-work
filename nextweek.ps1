param(
    [string]$newDate   # 생성될 work.md 날짜 예: 2026-02-26
)

# 최신 work.md 찾기
$workFile = Get-ChildItem -Name "work*.md" | Sort-Object | Select-Object -Last 1
if (-not $workFile) {
    Write-Host "work.md 파일을 찾을 수 없습니다." -ForegroundColor Red
    exit
}

$lines = Get-Content $workFile -Encoding UTF8

# 프로젝트 자동 인식 (## 로 시작하는 줄)
$projectHeaders = $lines | Where-Object { $_ -match "^## " }

$new = @()
$new += "# work.md — Week of $newDate"
$new += ""
$new += "---"
$new += ""

# -------------------------
# 프로젝트 단위로 반복
# -------------------------
foreach ($projHeader in $projectHeaders) {

    $projName = $projHeader -replace "^## ", ""
    $new += "## $projName"
    $new += ""

    $inProject = $false
    $inSection = ""
    
    # 섹션별 버퍼
    $shipNew = @()
    $activeNew = @()
    $blockedNew = @()
    $nextNew = @()

    foreach ($line in $lines) {

        # 프로젝트 시작
        if ($line -eq $projHeader) {
            $inProject = $true
            continue
        }

        # 프로젝트 종료
        if ($inProject -and $line -match "^## " -and $line -ne $projHeader) {
            break
        }

        # Shipping 섹션 시작
        if ($inProject -and $line -match "^### Shipping This Week") {
            $inSection = "Shipping"
            continue
        }

        # Active Work 섹션
        if ($inProject -and $line -match "^### Active Work") {
            $inSection = "Active"
            continue
        }

        # Blocked 섹션
        if ($inProject -and $line -match "^### Blocked") {
            $inSection = "Blocked"
            continue
        }

        # Next Up 섹션
        if ($inProject -and $line -match "^### Next Up") {
            $inSection = "Next"
            continue
        }

        # Shipping
        if ($inProject -and $inSection -eq "Shipping") {
            if ($line -match "- \[ \]") { $shipNew += $line }
            continue
        }

        # Active
        if ($inProject -and $inSection -eq "Active") {
            if ($line -match "- \[ \]") { $activeNew += $line }
            continue
        }

        # Blocked (그대로 유지)
        if ($inProject -and $inSection -eq "Blocked") {
            if ($line.Trim() -ne "") { $blockedNew += $line }
            continue
        }

        # Next Up (그대로 유지)
        if ($inProject -and $inSection -eq "Next") {
            if ($line.Trim() -ne "") { $nextNew += $line }
            continue
        }
    }

    # ----------------------
    # 다음 주 work.md 구성
    # ----------------------
    $new += "### Shipping This Week"
    if ($shipNew.Count -eq 0) { $new += "- [ ]" } else { $new += $shipNew }
    $new += ""

    $new += "### Active Work"
    if ($activeNew.Count -eq 0) { $new += "- [ ]" } else { $new += $activeNew }
    $new += ""

    $new += "### Blocked"
    if ($blockedNew.Count -eq 0) { $new += "- (Block 없음)" } else { $new += $blockedNew }
    $new += ""

    $new += "### Next Up"
    if ($nextNew.Count -eq 0) { $new += "- [ ]" } else { $new += $nextNew }
    $new += ""
    $new += "---"
    $new += ""
}

# 파일 저장 (UTF-8 BOM)
$outFile = "work-$newDate.md"
$Utf8 = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllLines($outFile, $new, $Utf8)

Write-Host "다음주 work.md 생성 완료 → $outFile" -ForegroundColor Green