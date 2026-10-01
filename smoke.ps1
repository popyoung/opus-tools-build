$ErrorActionPreference = 'Stop'
Set-Location output
$version = (& ./opusenc.exe --version 2>&1 | Out-String)
if ($LASTEXITCODE -ne 0 -or $version -notmatch 'libopus 1\.6\.1') { throw "Unexpected encoder version: $version" }
$version | Set-Content version.txt -Encoding utf8
$help = (& ./opusenc.exe --help 2>&1 | Out-String)
if ($LASTEXITCODE -ne 0) { throw 'Encoder help command failed' }
$info = (& ./opusinfo.exe --version 2>&1 | Out-String)
if ($LASTEXITCODE -ne 0) { throw 'Stream inspection tool cannot run' }
$info | Set-Content opusinfo-version.txt -Encoding utf8
Get-ChildItem -File -Recurse | Sort-Object FullName | ForEach-Object {
  $relative = [IO.Path]::GetRelativePath($PWD.Path, $_.FullName).Replace('\','/')
  '{0}  {1}' -f (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant(), $relative
} | Set-Content SHA256SUMS.txt -Encoding utf8
