# Auditable Windows Opus encoder build

Builds Windows x64 portable `opusenc.exe` and `opusinfo.exe` from unmodified Xiph release sources. This is an independently maintained build, not an official Xiph binary distribution and not a guarantee of vulnerability-free software.

## Sources

- libopus 1.6.1
- libopusenc 0.3
- opus-tools 0.2 (the command-line utility version, distinct from libopus)
- libogg 1.3.6
- opusfile 0.12 (configure dependency; HTTP disabled)

Sources come from https://downloads.xiph.org/releases/ and are checked against pinned SHA-256 hashes before extraction. Hash references: https://opus-codec.org/downloads/, https://downloads.xiph.org/releases/opus/SHA256SUMS.txt and https://downloads.xiph.org/releases/ogg/SHA256SUMS.

## Build and validation

Run the manually triggered **Build portable Windows encoder** workflow. Ubuntu 24.04 cross-compiles using distribution-provided MinGW-w64. Windows 2022 validates the resulting executables and exercises mono 24 kbps VBR encoding with `--speech --set-ctl-int 4000=2048` (SIGNAL_VOICE + APPLICATION_VOIP).

Only official GitHub Actions are used, pinned to commit SHAs. No repository secrets are needed; jobs have minimal permissions. The final artifact contains binaries, upstream licenses, source hashes, toolchain versions, smoke-test logs and output SHA-256 hashes, with GitHub build provenance attestation. Artifacts expire after 30 days.

No Debate source, audio, configuration, credentials or match data is included. No automatic deployment or Release publication occurs.

Trust boundaries remain: upstream sources, distribution compiler packages, GitHub runner images, GitHub Actions and the repository account. Toolchain packages and runner images are not bit-for-bit pinned; this workflow is auditable but does not promise byte-reproducibility.
