# Uygulamayı cihazda/emülatörde çalıştırır ve lib/ altındaki .dart dosyaları
# kaydedildikçe otomatik hot reload yapar (IDE dışından yapılan değişiklikler dahil).
#
# Kullanım:  powershell -ExecutionPolicy Bypass -File tool\dev_live.ps1 [-DeviceId emulator-5554]
# Hot restart: .dart_tool\live_restart dosyasını oluşturun (betik siler ve restart atar).
param(
  [string]$DeviceId = "emulator-5554"
)

$ErrorActionPreference = "Stop"
$projectDir = Split-Path -Parent $PSScriptRoot
$libDir = Join-Path $projectDir "lib"
$restartFlag = Join-Path $projectDir ".dart_tool\live_restart"

function Write-Log([string]$message) {
  Write-Host ("[{0:HH:mm:ss}] {1}" -f (Get-Date), $message)
}

# lib/ içindeki en son değişiklik zamanı + dosya sayısı (silme/ekleme de yakalanır)
function Get-LibStamp {
  $files = @(Get-ChildItem -Path $libDir -Recurse -Filter *.dart)
  $latest = $files | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
  "$($latest.LastWriteTimeUtc.Ticks):$($files.Count)"
}

# Proje yolunda Türkçe/ASCII olmayan karakter varsa Dart araçları (DDS, analyzer)
# bağlantıyı koparıyor. Bu durumda proje geçici bir sürücü harfine bağlanır (subst).
$workDir = $projectDir
$substDrive = $null
if ($projectDir -match '[^\x00-\x7F]') {
  $used = (Get-PSDrive -PSProvider FileSystem).Name
  $letter = @('X', 'Y', 'W', 'V', 'U', 'T') | Where-Object { $used -notcontains $_ } | Select-Object -First 1
  & subst "${letter}:" $projectDir
  $substDrive = "${letter}:"
  $workDir = "$substDrive\"
  Write-Log "Proje yolu ASCII degil -> $substDrive surucusu uzerinden calisiliyor"
}

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "cmd.exe"
# --no-dds: Dart Developer Service, kullanıcı klasöründeki Türkçe karakter yüzünden
# başlar başlamaz kapanıp bağlantıyı koparıyor; hot reload için DDS gerekmiyor.
$psi.Arguments = "/c flutter run --machine --no-dds -d $DeviceId"
$psi.WorkingDirectory = $workDir
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
$psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8

$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $psi
Register-ObjectEvent -InputObject $proc -EventName OutputDataReceived -SourceIdentifier FlutterOut | Out-Null
Register-ObjectEvent -InputObject $proc -EventName ErrorDataReceived -SourceIdentifier FlutterErr | Out-Null
[void]$proc.Start()
$proc.BeginOutputReadLine()
$proc.BeginErrorReadLine()

$script:appId = $null
$script:appReady = $false
$script:requestId = 0

function Send-Request([string]$method, [hashtable]$params) {
  $script:requestId++
  $request = @{ id = $script:requestId; method = $method; params = $params }
  $proc.StandardInput.WriteLine("[" + ($request | ConvertTo-Json -Compress -Depth 4) + "]")
  $proc.StandardInput.Flush()
}

function Send-Restart([bool]$full) {
  Send-Request "app.restart" @{ appId = $script:appId; fullRestart = $full; pause = $false; reason = "save" }
}

function Read-DaemonLine([string]$line) {
  if ([string]::IsNullOrWhiteSpace($line)) { return }
  if (-not $line.StartsWith("[{")) { Write-Log $line; return }
  try { $messages = $line | ConvertFrom-Json } catch { Write-Log $line; return }

  foreach ($m in $messages) {
    switch ($m.event) {
      "app.start" { $script:appId = $m.params.appId }
      "app.started" { $script:appReady = $true; Write-Log "UYGULAMA ACILDI - lib/ altindaki degisiklikler artik otomatik yansiyacak" }
      "app.progress" { if ($m.params.message) { Write-Log $m.params.message } }
      "app.log" { Write-Log ("app: " + $m.params.log) }
      "daemon.logMessage" { Write-Log ("" + $m.params.level + ": " + $m.params.message) }
      "app.stop" { Write-Log "Uygulama durdu" }
      default {
        if ($null -ne $m.id) {
          if ($m.error) { Write-Log ("HATA: " + ($m.error | ConvertTo-Json -Compress -Depth 4)) }
          elseif ($m.result -and $m.result.code -ne 0) { Write-Log ("Yeniden yukleme basarisiz: " + $m.result.message) }
          else { Write-Log "Yeniden yukleme tamam" }
        }
      }
    }
  }
}

function Read-PendingEvents([string]$source) {
  foreach ($e in @(Get-Event -SourceIdentifier $source -ErrorAction SilentlyContinue)) {
    Read-DaemonLine $e.SourceEventArgs.Data
    Remove-Event -EventIdentifier $e.EventIdentifier
  }
}

Write-Log "flutter run baslatildi ($DeviceId)"
$lastStamp = Get-LibStamp
$changedAt = $null

try {
  while (-not $proc.HasExited) {
    Read-PendingEvents "FlutterOut"
    Read-PendingEvents "FlutterErr"

    if ($script:appReady) {
      $stamp = Get-LibStamp
      if ($stamp -ne $lastStamp) {
        $lastStamp = $stamp
        $changedAt = Get-Date
      }
      # Arka arkaya kaydedilen dosyalar tek seferde yüklensin diye kısa bekleme
      if ($changedAt -and ((Get-Date) - $changedAt).TotalMilliseconds -ge 400) {
        $changedAt = $null
        Write-Log "Degisiklik algilandi -> hot reload"
        Send-Restart $false
      }
      if (Test-Path $restartFlag) {
        Remove-Item $restartFlag
        Write-Log "Hot restart"
        Send-Restart $true
      }
    }
    Start-Sleep -Milliseconds 300
  }
}
finally {
  if (-not $proc.HasExited) {
    if ($script:appId) { Send-Request "app.stop" @{ appId = $script:appId } }
    if (-not $proc.WaitForExit(5000)) { & taskkill /PID $proc.Id /T /F | Out-Null }
  }
  Unregister-Event -SourceIdentifier FlutterOut -ErrorAction SilentlyContinue
  Unregister-Event -SourceIdentifier FlutterErr -ErrorAction SilentlyContinue
  if ($substDrive) { & subst $substDrive /D }
}
Write-Log "flutter run sona erdi (cikis kodu $($proc.ExitCode))"
