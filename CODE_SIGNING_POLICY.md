# Code signing policy

OmaWrite for Windows does not currently publish signed binaries. This document
defines the boundary that a future signing integration must preserve.

- Release packages must be built from a public version tag by the repository's
  GitHub Actions workflow.
- A locally built executable must not be substituted into an official release.
- The portable ZIP and Setup EXE must use the same source revision and version.
- Every published package must retain its SHA-256 checksum.
- Signing must cover the OmaWrite executable and installer only. Bundled
  third-party binaries remain attributable to their original publishers.
- Each signing request must require explicit approval after the public build
  completes.

Project roles:

- Committer and reviewer: [AbrarZShahriar](https://github.com/AbrarZShahriar)
- Signing approver: [AbrarZShahriar](https://github.com/AbrarZShahriar)

The application's data-transfer behavior is specified in
[PRIVACY.md](PRIVACY.md).
