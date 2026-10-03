[CmdletBinding()]
param(
  [ValidateSet('Install','Uninstall','Verify')]
  [string]$Action = 'Verify',
  [string]$GameRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$PackageRoot = Split-Path -Parent $PSScriptRoot
$ManifestPath = Join-Path $PackageRoot 'payload\release-manifest.json'
$Manifest = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json

function Get-Sha256([string]$Path) {
  return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Resolve-GameRoot([string]$Requested) {
  $candidates = @()
  if ($Requested) { $candidates += $Requested }
  $candidates += $PackageRoot
  $candidates += (Get-Location).Path
  foreach ($candidate in $candidates) {
    if (-not $candidate) { continue }
    $full = [IO.Path]::GetFullPath($candidate.Trim('"'))
    if (Test-Path -LiteralPath (Join-Path $full 'www\data\System.json')) { return $full }
  }
  $typed = Read-Host 'Cole o caminho da pasta principal de Treasure of Nadia'
  $full = [IO.Path]::GetFullPath($typed.Trim('"'))
  if (-not (Test-Path -LiteralPath (Join-Path $full 'www\data\System.json'))) {
    throw 'Pasta inválida: www\data\System.json não foi encontrado.'
  }
  return $full
}

function Resolve-SafeTarget([string]$Root, [string]$Relative) {
  if ([IO.Path]::IsPathRooted($Relative)) { throw "Rota absoluta bloqueada: $Relative" }
  $normalized = $Relative.Replace('/', [IO.Path]::DirectorySeparatorChar)
  $target = [IO.Path]::GetFullPath((Join-Path $Root $normalized))
  $prefix = [IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
  if (-not $target.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Rota fora do jogo bloqueada: $Relative"
  }
  return $target
}

function Get-ReleaseState([string]$Root) {
  $items = @()
  foreach ($entry in $Manifest.files) {
    $target = Resolve-SafeTarget $Root $entry.file
    if (-not (Test-Path -LiteralPath $target)) {
      $items += [pscustomobject]@{ Entry=$entry; Path=$target; State='MISSING'; Hash=$null }
      continue
    }
    $hash = Get-Sha256 $target
    $state = if ($hash -eq $entry.source_sha256) { 'SOURCE' } elseif ($hash -eq $entry.target_sha256) { 'TARGET' } else { 'UNKNOWN' }
    $items += [pscustomobject]@{ Entry=$entry; Path=$target; State=$state; Hash=$hash }
  }
  return $items
}

function Read-Patch($Entry) {
  $patchPath = Join-Path (Join-Path $PackageRoot 'payload') $Entry.patch
  if (-not (Test-Path -LiteralPath $patchPath)) { throw "Patch ausente: $($Entry.patch)" }
  if ((Get-Sha256 $patchPath) -ne $Entry.patch_sha256) { throw "Hash inválido do patch: $($Entry.patch)" }
  $file = [IO.File]::OpenRead($patchPath)
  try {
    $gzip = New-Object IO.Compression.GzipStream($file, [IO.Compression.CompressionMode]::Decompress)
    try {
      $reader = New-Object IO.StreamReader($gzip, [Text.Encoding]::UTF8)
      try { return ($reader.ReadToEnd() | ConvertFrom-Json) }
      finally { $reader.Dispose() }
    } finally { $gzip.Dispose() }
  } finally { $file.Dispose() }
}

function Build-TargetBytes([byte[]]$Source, $Patch, [string]$Relative) {
  if ($Patch.format -ne 'COPY_INSERT_V1') { throw "Formato de patch não suportado em $Relative" }
  $output = New-Object IO.MemoryStream
  try {
    foreach ($op in $Patch.operations) {
      if ($op[0] -eq 'c') {
        $offset = [int64]$op[1]
        $length = [int]$op[2]
        if ($offset -lt 0 -or $length -lt 0 -or ($offset + $length) -gt $Source.LongLength) {
          throw "Operação COPY inválida em $Relative"
        }
        $output.Write($Source, [int]$offset, $length)
      } elseif ($op[0] -eq 'i') {
        $bytes = [Convert]::FromBase64String([string]$op[1])
        $output.Write($bytes, 0, $bytes.Length)
      } else { throw "Operação desconhecida em $Relative" }
    }
    $result = $output.ToArray()
    if ($result.LongLength -ne [int64]$Patch.target_size) { throw "Tamanho reconstruído inválido em $Relative" }
    return $result
  } finally { $output.Dispose() }
}

function Get-BytesHash([byte[]]$Bytes) {
  $algorithm = [Security.Cryptography.SHA256]::Create()
  try { return ([BitConverter]::ToString($algorithm.ComputeHash($Bytes))).Replace('-','').ToLowerInvariant() }
  finally { $algorithm.Dispose() }
}

function Replace-File([string]$Destination, [byte[]]$Bytes) {
  $id = [Guid]::NewGuid().ToString('N')
  $temp = "$Destination.ptbr-temp-$id"
  $replaceBackup = "$Destination.ptbr-replaced-$id"
  [IO.File]::WriteAllBytes($temp, $Bytes)
  try { [IO.File]::Replace($temp, $Destination, $replaceBackup) }
  finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force }
    if (Test-Path -LiteralPath $replaceBackup) { Remove-Item -LiteralPath $replaceBackup -Force }
  }
}

$ResolvedRoot = Resolve-GameRoot $GameRoot
Write-Host "Jogo: $ResolvedRoot"
Write-Host "Mod: $($Manifest.mod_name) v$($Manifest.mod_version)"
$state = @(Get-ReleaseState $ResolvedRoot)
$sourceCount = @($state | Where-Object State -eq 'SOURCE').Count
$targetCount = @($state | Where-Object State -eq 'TARGET').Count
$unknown = @($state | Where-Object { $_.State -eq 'UNKNOWN' -or $_.State -eq 'MISSING' })
Write-Host "Originais compatíveis: $sourceCount | Traduzidos: $targetCount | Incompatíveis/ausentes: $($unknown.Count)"

if ($Action -eq 'Verify') {
  if ($unknown.Count) {
    $unknown | Select-Object @{n='Arquivo';e={$_.Entry.file}},State,Hash | Format-Table -AutoSize
    throw 'VERIFICAÇÃO FALHOU: instalação diferente da build suportada ou arquivos alterados.'
  }
  if ($sourceCount -eq $Manifest.file_count) { Write-Host 'VERIFICAÇÃO PASS: jogo original compatível e pronto para instalar.'; exit 0 }
  if ($targetCount -eq $Manifest.file_count) { Write-Host 'VERIFICAÇÃO PASS: tradução já está instalada e íntegra.'; exit 0 }
  throw 'VERIFICAÇÃO FALHOU: estado misto entre original e traduzido.'
}

$BackupRoot = Join-Path $ResolvedRoot ".ptbr-nadia-backup\$($Manifest.mod_version)"
$BackupManifestPath = Join-Path $BackupRoot 'backup-manifest.json'

if ($Action -eq 'Install') {
  if ($unknown.Count) { throw 'INSTALAÇÃO BLOQUEADA: há arquivos incompatíveis ou ausentes.' }
  if ($targetCount -eq $Manifest.file_count) { Write-Host 'A tradução já está instalada e íntegra.'; exit 0 }
  if ($sourceCount -ne $Manifest.file_count) { throw 'INSTALAÇÃO BLOQUEADA: estado misto; restaure a instalação original primeiro.' }
  if (-not (Test-Path -LiteralPath $BackupRoot)) {
    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
    foreach ($item in $state) {
      $backup = Resolve-SafeTarget $BackupRoot $item.Entry.file
      New-Item -ItemType Directory -Path (Split-Path -Parent $backup) -Force | Out-Null
      Copy-Item -LiteralPath $item.Path -Destination $backup
      if ((Get-Sha256 $backup) -ne $item.Entry.source_sha256) { throw "Backup inválido: $($item.Entry.file)" }
    }
    [ordered]@{ mod=$Manifest.mod_name; version=$Manifest.mod_version; build_fingerprint=$Manifest.build_fingerprint; created_at=(Get-Date).ToString('o'); files=@($Manifest.files | ForEach-Object {[ordered]@{file=$_.file;source_sha256=$_.source_sha256;target_sha256=$_.target_sha256}}) } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $BackupManifestPath -Encoding UTF8
  } else {
    if (-not (Test-Path -LiteralPath $BackupManifestPath)) { throw 'Backup existente sem manifesto; instalação bloqueada.' }
    foreach ($entry in $Manifest.files) {
      $backup = Resolve-SafeTarget $BackupRoot $entry.file
      if (-not (Test-Path -LiteralPath $backup) -or (Get-Sha256 $backup) -ne $entry.source_sha256) { throw "Backup existente inválido: $($entry.file)" }
    }
  }
  $changed = New-Object Collections.Generic.List[string]
  try {
    foreach ($item in $state) {
      $source = [IO.File]::ReadAllBytes($item.Path)
      $patch = Read-Patch $item.Entry
      $targetBytes = Build-TargetBytes $source $patch $item.Entry.file
      if ((Get-BytesHash $targetBytes) -ne $item.Entry.target_sha256) { throw "Target hash inválido: $($item.Entry.file)" }
      Replace-File $item.Path $targetBytes
      if ((Get-Sha256 $item.Path) -ne $item.Entry.target_sha256) { throw "Falha pós-escrita: $($item.Entry.file)" }
      $changed.Add($item.Entry.file)
    }
  } catch {
    Write-Warning 'Falha durante instalação. Restaurando backups...'
    foreach ($entry in $Manifest.files) {
      $backup = Resolve-SafeTarget $BackupRoot $entry.file
      $destination = Resolve-SafeTarget $ResolvedRoot $entry.file
      if (Test-Path -LiteralPath $backup) { Copy-Item -LiteralPath $backup -Destination $destination -Force }
    }
    throw
  }
  Write-Host "INSTALAÇÃO PASS: $($changed.Count) arquivos aplicados e verificados."
  Write-Host 'Abra o jogo manualmente e valide menus, diálogos e acentos.'
  exit 0
}

if ($Action -eq 'Uninstall') {
  if (-not (Test-Path -LiteralPath $BackupManifestPath)) { throw 'DESINSTALAÇÃO BLOQUEADA: backup verificável não encontrado.' }
  if ($unknown.Count) { throw 'DESINSTALAÇÃO BLOQUEADA: arquivos traduzidos foram alterados depois da instalação.' }
  if ($sourceCount -eq $Manifest.file_count) { Write-Host 'Os arquivos originais já estão restaurados.'; exit 0 }
  if ($targetCount -ne $Manifest.file_count) { throw 'DESINSTALAÇÃO BLOQUEADA: estado misto.' }
  foreach ($entry in $Manifest.files) {
    $backup = Resolve-SafeTarget $BackupRoot $entry.file
    if (-not (Test-Path -LiteralPath $backup) -or (Get-Sha256 $backup) -ne $entry.source_sha256) { throw "Backup inválido: $($entry.file)" }
  }
  foreach ($entry in $Manifest.files) {
    $backup = Resolve-SafeTarget $BackupRoot $entry.file
    $destination = Resolve-SafeTarget $ResolvedRoot $entry.file
    Copy-Item -LiteralPath $backup -Destination $destination -Force
    if ((Get-Sha256 $destination) -ne $entry.source_sha256) { throw "Falha ao restaurar: $($entry.file)" }
  }
  Write-Host "DESINSTALAÇÃO PASS: $($Manifest.file_count) arquivos originais restaurados e verificados."
  Write-Host "O backup foi preservado em: $BackupRoot"
}
