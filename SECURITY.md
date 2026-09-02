# Security

## Supported releases

Security fixes are applied to the latest Windows release. Reproduce an issue
against that release before reporting it when possible.

## Report a vulnerability

Use GitHub's [private vulnerability reporting
form](https://github.com/AbrarZShahriar/omawrite-windows/security/advisories/new).
Include the affected version, package type, observed impact, and minimal
reproduction steps. Do not disclose an unpatched vulnerability or personal
document contents in a public issue. If the form is unavailable, email
`a.zshahriar@gmail.com`.

Ordinary defects and feature requests belong in the public
[issue tracker](https://github.com/AbrarZShahriar/omawrite-windows/issues).

## Release integrity

Official Windows packages are attached to this repository's GitHub releases.
Each portable ZIP and Setup EXE has a companion SHA-256 file. Compare the hash
before running a downloaded package. The current binaries are unsigned; Windows
can therefore show a reputation warning even when the checksum is correct.

See [CODE_SIGNING_POLICY.md](CODE_SIGNING_POLICY.md) for the build and signing
boundary.
