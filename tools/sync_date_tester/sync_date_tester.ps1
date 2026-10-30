param(
    [string]$OfflineDb = $null,
    [string]$General = $null,
    [string]$Both = $null,
    [switch]$Status = $false,
    [switch]$NoRestart = $false,
    [string]$Serial = $null
)

$PackageName = "it.emanueleciotola.gscanner"
$SettingsKey = "flutter.celiac_settings"
$LastSyncKey = "flutter.celiac_app_last_sync_time"

function Get-AdbDevice {
    $lines = & adb devices
    foreach ($line in $lines) {
        if ($line -match "^([^\s]+)\s+device$") {
            if ($Serial) { return $Serial }
            return $Matches[1]
        }
    }
    Write-Host "Nessun dispositivo ADB connesso. Verifica che il debug USB sia attivo." -ForegroundColor Red
    exit 1
}

function Read-SharedPrefs([string]$dev) {
    $xml = & adb -s $dev shell "run-as $PackageName cat shared_prefs/FlutterSharedPreferences.xml"
    return ($xml -join "`n")
}

function Write-SharedPrefs([string]$dev, [string]$xmlContent) {
    $tempFile = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tempFile, $xmlContent, [System.Text.Encoding]::UTF8)

    try {
        & adb -s $dev push $tempFile /data/local/tmp/FlutterSharedPreferences.xml | Out-Null
        & adb -s $dev shell "run-as $PackageName cp /data/local/tmp/FlutterSharedPreferences.xml shared_prefs/FlutterSharedPreferences.xml" | Out-Null
        & adb -s $dev shell "rm /data/local/tmp/FlutterSharedPreferences.xml" | Out-Null
    } finally {
        if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
    }
}

function Restart-App([string]$dev) {
    Write-Host "Riavvio dell'app $PackageName..." -ForegroundColor Cyan
    & adb -s $dev shell "am force-stop $PackageName" | Out-Null
    & adb -s $dev shell "am start -n $PackageName/.MainActivity" | Out-Null
    Write-Host "App riavviata con successo." -ForegroundColor Green
}

function Show-Status([string]$xmlContent) {
    [xml]$xml = $xmlContent
    $nowEpoch = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

    Write-Host "`n=== STATO ATTUALE SINCRONIZZAZIONE (DEVICE) ===" -ForegroundColor Cyan

    # 1. Offline DB
    $settingsNode = $xml.map.string | Where-Object { $_.name -eq $SettingsKey }
    $offlineDbText = "Nessuna data / null [Hard Stale]"
    $offColor = "Red"

    if ($settingsNode -and $settingsNode.InnerText) {
        try {
            $json = $settingsNode.InnerText | ConvertFrom-Json
            if ($json.offlineDbLastSyncedAt -and $json.offlineDbLastSyncedAt -gt 0) {
                $epoch = [int64]$json.offlineDbLastSyncedAt
                $dt = [DateTimeOffset]::FromUnixTimeSeconds($epoch).LocalDateTime
                $diffDays = [math]::Floor(($nowEpoch - $epoch) / 86400)
                $tag = ""
                if ($diffDays -le 7) { $tag = "[Sincronizzato]"; $offColor = "Green" }
                elseif ($diffDays -le 30) { $tag = "[Soft Stale -> Pillola Gialla]"; $offColor = "Yellow" }
                else { $tag = "[Hard Stale -> Pillola Rossa]"; $offColor = "Red" }
                $offlineDbText = "$($dt.ToString('dd/MM/yyyy HH:mm')) ($diffDays giorni fa) $tag"
            }
        } catch {}
    }

    Write-Host "Database Offline (offlineDbLastSyncedAt):"
    Write-Host "  -> $offlineDbText" -ForegroundColor $offColor

    # 2. General Sync
    $genNode = $xml.map.string | Where-Object { $_.name -eq $LastSyncKey }
    $genText = "Nessuna data / null"
    $genColor = "Red"

    if ($genNode -and $genNode.InnerText) {
        try {
            $dt = [DateTime]::Parse($genNode.InnerText)
            $diffDays = [math]::Floor(((Get-Date) - $dt).TotalDays)
            $genText = "$($genNode.InnerText) ($diffDays giorni fa)"
            $genColor = "Gray"
        } catch {
            $genText = $genNode.InnerText
        }
    }

    Write-Host "Sync Generale ($LastSyncKey):"
    Write-Host "  -> $genText" -ForegroundColor $genColor
    Write-Host "================================================" -ForegroundColor Cyan
}

function Update-Dates([string]$xmlContent, $offDays, $genDays, [bool]$offNull = $false, [bool]$genNull = $false) {
    [xml]$xml = $xmlContent
    $nowEpoch = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

    if ($offNull -or ($null -ne $offDays)) {
        $node = $xml.map.string | Where-Object { $_.name -eq $SettingsKey }
        if ($node) {
            $json = $node.InnerText | ConvertFrom-Json
            if ($offNull) {
                $json.offlineDbLastSyncedAt = $null
            } else {
                $targetSec = $nowEpoch - ($offDays * 86400)
                $json.offlineDbLastSyncedAt = $targetSec
            }
            $node.InnerText = ($json | ConvertTo-Json -Compress)
        }
    }

    if ($genNull -or ($null -ne $genDays)) {
        $genNode = $xml.map.string | Where-Object { $_.name -eq $LastSyncKey }
        if ($genNull) {
            if ($genNode) { $xml.map.RemoveChild($genNode) | Out-Null }
        } else {
            $targetIso = (Get-Date).ToUniversalTime().AddDays(-$genDays).ToString("o")
            if ($genNode) {
                $genNode.InnerText = $targetIso
            } else {
                $newElem = $xml.CreateElement("string")
                $newElem.SetAttribute("name", $LastSyncKey)
                $newElem.InnerText = $targetIso
                $xml.map.AppendChild($newElem) | Out-Null
            }
        }
    }

    $sw = New-Object System.IO.StringWriter
    $xml.Save($sw)
    return $sw.ToString()
}

$device = Get-AdbDevice
$currentXml = Read-SharedPrefs $device

if ($Status) {
    Show-Status $currentXml
    exit 0
}

if ($Both -or ($null -ne $OfflineDb) -or ($null -ne $General)) {
    $offD = $null; $genD = $null; $offN = $false; $genN = $false

    if ($Both) {
        if ($Both -match "^(null|reset)$") { $offN = $true; $genN = $true }
        elseif ($Both -match "^(now|today|0)$") { $offD = 0; $genD = 0 }
        else { $d = [math]::Abs([int]$Both); $offD = $d; $genD = $d }
    } else {
        if ($OfflineDb) {
            if ($OfflineDb -match "^(null|reset)$") { $offN = $true }
            elseif ($OfflineDb -match "^(now|today|0)$") { $offD = 0 }
            else { $offD = [math]::Abs([int]$OfflineDb) }
        }
        if ($General) {
            if ($General -match "^(null|reset)$") { $genN = $true }
            elseif ($General -match "^(now|today|0)$") { $genD = 0 }
            else { $genD = [math]::Abs([int]$General) }
        }
    }

    $newXml = Update-Dates -xmlContent $currentXml -offDays $offD -genDays $genD -offNull $offN -genNull $genN
    Write-SharedPrefs -dev $device -xmlContent $newXml
    Write-Host "SharedPreferences aggiornate con successo!" -ForegroundColor Green

    if (-not $NoRestart) {
        Restart-App -dev $device
    }

    $updatedXml = Read-SharedPrefs -dev $device
    Show-Status $updatedXml
    exit 0
}

while ($true) {
    $currentXml = Read-SharedPrefs -dev $device
    Show-Status $currentXml

    Write-Host "`nSeleziona un'operazione:" -ForegroundColor Cyan
    Write-Host " [1] Database Offline: -10 giorni (Soft Stale -> Pillola Gialla)" -ForegroundColor Yellow
    Write-Host " [2] Database Offline: -40 giorni (Hard Stale -> Pillola Rossa)" -ForegroundColor Red
    Write-Host " [3] Database Offline: Oggi / Now (Sincronizzato)" -ForegroundColor Green
    Write-Host " [4] Database Offline: Reset / Null (Mai sincronizzato)" -ForegroundColor Red
    Write-Host " -----------------------------------------------" -ForegroundColor DarkGray
    Write-Host " [5] Sync Generale SharedPreferences: -10 giorni" -ForegroundColor Yellow
    Write-Host " [6] Sync Generale SharedPreferences: -40 giorni" -ForegroundColor Red
    Write-Host " [7] Sync Generale SharedPreferences: Oggi / Now" -ForegroundColor Green
    Write-Host " [8] Sync Generale SharedPreferences: Reset / Null" -ForegroundColor Red
    Write-Host " -----------------------------------------------" -ForegroundColor DarkGray
    Write-Host " [9] ENTRAMBI: -10 giorni (Soft Stale)" -ForegroundColor Yellow
    Write-Host " [10] ENTRAMBI: -40 giorni (Hard Stale)" -ForegroundColor Red
    Write-Host " -----------------------------------------------" -ForegroundColor DarkGray
    Write-Host " [r] Riavvia solo l'applicazione" -ForegroundColor Cyan
    Write-Host " [q] Esci" -ForegroundColor Gray

    $choice = (Read-Host "`nScelta").Trim().ToLower()

    if ($choice -in @("q", "quit", "exit")) {
        Write-Host "Arrivederci!" -ForegroundColor Cyan
        break
    }
    if ($choice -eq "r") {
        Restart-App -dev $device
        continue
    }

    $offD = $null; $genD = $null; $offN = $false; $genN = $false

    switch ($choice) {
        "1" { $offD = 10 }
        "2" { $offD = 40 }
        "3" { $offD = 0 }
        "4" { $offN = $true }
        "5" { $genD = 10 }
        "6" { $genD = 40 }
        "7" { $genD = 0 }
        "8" { $genN = $true }
        "9" { $offD = 10; $genD = 10 }
        "10" { $offD = 40; $genD = 40 }
        default {
            Write-Host "Scelta non valida." -ForegroundColor Red
            continue
        }
    }

    $newXml = Update-Dates -xmlContent $currentXml -offDays $offD -genDays $genD -offNull $offN -genNull $genN
    Write-SharedPrefs -dev $device -xmlContent $newXml
    Write-Host "SharedPreferences aggiornate con successo!" -ForegroundColor Green
    Restart-App -dev $device
    Start-Sleep -Seconds 1
}