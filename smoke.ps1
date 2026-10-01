$ErrorActionPreference = 'Stop'
Set-Location output
$version = (& ./opusenc.exe --version 2>&1 | Out-String)
if ($LASTEXITCODE -ne 0 -or $version -notmatch 'libopus 1\.6\.1') { throw "Unexpected encoder version: $version" }
$version | Set-Content version.txt -Encoding utf8
$help = (& ./opusenc.exe --help 2>&1 | Out-String)
if ($help -notmatch '--speech' -or $help -notmatch '--set-ctl-int') { throw 'Required encoder controls unavailable' }
# Synthetic test signal only; no user or Debate audio is uploaded.
$rate = 48000
$frames = 4800
$stream = [IO.File]::Create((Join-Path $PWD 'smoke.wav'))
$writer = [IO.BinaryWriter]::new($stream)
try {
  $writer.Write([Text.Encoding]::ASCII.GetBytes('RIFF'))
  $writer.Write([int](36 + 2 * $frames))
  $writer.Write([Text.Encoding]::ASCII.GetBytes('WAVEfmt '))
  $writer.Write([int]16); $writer.Write([int16]1); $writer.Write([int16]1)
  $writer.Write([int]$rate); $writer.Write([int](2 * $rate))
  $writer.Write([int16]2); $writer.Write([int16]16)
  $writer.Write([Text.Encoding]::ASCII.GetBytes('data'))
  $writer.Write([int](2 * $frames))
  for ($i=0; $i -lt $frames; $i++) { $writer.Write([int16](8000 * [Math]::Sin(2 * [Math]::PI * 220 * $i / $rate))) }
} finally { $writer.Dispose() }
$encoded = (& ./opusenc.exe --bitrate 24 --vbr --speech --set-ctl-int 4000=2048 smoke.wav smoke.opus 2>&1 | Out-String)
if ($LASTEXITCODE -ne 0) { throw "Encoding failed: $encoded" }
$encoded | Set-Content encoding-test.txt -Encoding utf8
if ($encoded -notmatch 'VoIP') { throw "VOIP application not confirmed: $encoded" }
$info = (& ./opusinfo.exe smoke.opus 2>&1 | Out-String)
if ($LASTEXITCODE -ne 0 -or $info -notmatch 'Channels: 1') { throw "Invalid encoded output: $info" }
$info | Set-Content encoded-stream-info.txt -Encoding utf8
Remove-Item -LiteralPath smoke.wav,smoke.opus
Get-ChildItem -File -Recurse | Sort-Object FullName | ForEach-Object {
  $relative = [IO.Path]::GetRelativePath($PWD.Path, $_.FullName).Replace('\','/')
  '{0}  {1}' -f (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant(), $relative
} | Set-Content SHA256SUMS.txt -Encoding utf8
