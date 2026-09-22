param(
  [ValidateSet('Inspect', 'Check', 'Restore')]
  [string]$Mode = 'Inspect',
  [string]$BackupPath = 'D:\06_App\00_Backups\bike-setup-tracker-backups-main\bike-setup-tracker-backups-main\latest',
  [string]$CertificatePath
)
$ErrorActionPreference = 'Stop'
$restoreTool = Join-Path $PSScriptRoot 'restore-dev'
$restoreScript = Join-Path $restoreTool 'restore.mjs'
if (-not (Test-Path -LiteralPath (Join-Path $BackupPath 'data.sql'))) { throw 'data.sql nicht gefunden.' }
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw 'Node.js 22 oder neuer installieren.' }
if ($CertificatePath -and -not (Test-Path -LiteralPath $CertificatePath -PathType Leaf)) { throw 'CA-Zertifikat nicht gefunden.' }

function Read-LocalSecret([string]$Prompt) {
  $secretValue = Read-Host $Prompt -AsSecureString
  $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secretValue)
  try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer); $secretValue.Dispose() }
}

try {
  if ($CertificatePath) { $env:DEV_RESTORE_CA_FILE = (Resolve-Path -LiteralPath $CertificatePath).Path }
  if ($Mode -ne 'Inspect') {
    if (-not (Test-Path -LiteralPath (Join-Path $restoreTool 'node_modules/pg/package.json'))) {
      & npm.cmd ci --prefix $restoreTool --ignore-scripts --no-audit --no-fund
      if ($LASTEXITCODE -ne 0) { throw 'Installation der Restore-Abhaengigkeiten fehlgeschlagen.' }
    }
    Write-Host 'Ziel ist ausschliesslich Dev: dcrkfiooddkbzljibomo'
    if ($Mode -eq 'Restore') { Write-Host 'Dev-Nutzer und App-Daten werden ersetzt. Bitte Dev-App vorher schliessen.' }
    $env:DEV_RESTORE_DB_PASSWORD = Read-LocalSecret 'Datenbankpasswort des Dev-Projekts (verdeckt)'
    $env:DEV_RESTORE_SERVICE_KEY = Read-LocalSecret 'Dev service_role JWT aus Settings > API Keys > Legacy keys (verdeckt)'
  }
  $restoreOutput = [System.Collections.Generic.List[string]]::new()
  $previousErrorPreference = $ErrorActionPreference
  try {
    # Windows PowerShell 5.1 treats redirected native stderr as ErrorRecord.
    # Keep streaming it, then report the actual tool failure in the exception.
    $ErrorActionPreference = 'Continue'
    & node $restoreScript "--$($Mode.ToLowerInvariant())" $BackupPath 2>&1 | ForEach-Object {
      $line = $_.ToString()
      $restoreOutput.Add($line)
      Write-Host $line
    }
    $restoreExitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorPreference
  }
  if ($restoreExitCode -ne 0) {
    $reason = $restoreOutput | Where-Object { $_ -match '^Abbruch:' } | Select-Object -Last 1
    if (-not $reason) { $reason = $restoreOutput | Where-Object { $_.Trim() } | Select-Object -Last 1 }
    if (-not $reason) { $reason = 'Keine Fehlermeldung vom Restore-Werkzeug erhalten.' }
    throw "Restore fehlgeschlagen (Exit $restoreExitCode): $reason"
  }
} finally {
  Remove-Item Env:DEV_RESTORE_DB_PASSWORD -ErrorAction SilentlyContinue
  Remove-Item Env:DEV_RESTORE_SERVICE_KEY -ErrorAction SilentlyContinue
  Remove-Item Env:DEV_RESTORE_CA_FILE -ErrorAction SilentlyContinue
}
