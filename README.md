# OmaWrite for Windows

[![Windows build](https://github.com/AbrarZShahriar/omawrite-windows/actions/workflows/windows.yml/badge.svg)](https://github.com/AbrarZShahriar/omawrite-windows/actions/workflows/windows.yml)
[![Latest release](https://img.shields.io/github/v/release/AbrarZShahriar/omawrite-windows?label=Windows%20release)](https://github.com/AbrarZShahriar/omawrite-windows/releases/latest)

The low-friction native Windows build of
[Omawrite](https://github.com/omacom/omawrite), a focused Markdown writing
app built with Qt Quick and C++. This is an unofficial Windows fork. It keeps
the upstream Linux build working and follows the Windows light or dark theme.

<img width="2948" height="3227" alt="screenshot-2026-06-23_15-24-08" src="https://github.com/user-attachments/assets/4e930c0d-edda-4046-b444-a59eff523329" />
<img width="2948" height="3227" alt="screenshot-2026-06-23_15-23-23" src="https://github.com/user-attachments/assets/8ced7c26-961b-4ded-b263-84403001a951" />


## Start on Windows

The fastest option is to download and run the x64 Setup EXE from the
[latest release](https://github.com/AbrarZShahriar/omawrite-windows/releases/latest).
It contains the complete app and does not download files during installation.

Prefer no installer? Download the x64 portable ZIP, extract it, and run
`omawrite.exe`. The ZIP contains the compiled app and every required Qt file.

You can also clone this repository or use **Code > Download ZIP**, then
double-click `install-windows.cmd`. If Windows Settings opens, select OmaWrite
for `.md` files.

The repository installer downloads the latest release, verifies its SHA-256
checksum, and installs it for the current user. It does not require
administrator access unless the Microsoft Visual C++ runtime is missing.

To remove the app, double-click `uninstall-windows.cmd` or use the Windows
Installed apps page.

Releases are built in public GitHub Actions runs and include SHA-256 checksums.
The executable is not currently code-signed, so Windows can show a reputation
warning on first launch.

The current build targets Intel and AMD x86-64 computers running Windows 11.
Windows 11 does not have a 32-bit x86 edition. ARM64 is not currently a native
build target.

## Build on Windows

Install Visual Studio Build Tools 2022 with the C++ workload, then double-click
`build-windows.cmd`. The build script downloads a verified Qt 6.8.3 toolchain,
runs the test suite, deploys the runtime, and creates a portable ZIP plus a
Setup EXE in `dist`.

## Install on Omarchy

Install the `omawrite` package from the Omarchy Package Repository. Omawrite is
installed by default in new Omarchy installations from Quattro forward.

## Shortcuts

- `Ctrl+S` saves. Unsaved documents use the system file picker.
- `Ctrl+Shift+S` saves as.
- `Ctrl+O` opens a Markdown file through the system file picker.
- `Ctrl+P` opens the system print dialog.
- `Ctrl+N` opens a new Omawrite window.
- `Ctrl+Z`, `Ctrl+Shift+Z`, and `Ctrl+Y` handle undo and redo.
- `F11` or `Super+F` toggles fullscreen.
- `Ctrl+F` searches the document. Use `Enter` or `Ctrl+G` for the next match and `Shift+Enter` for the previous match.
- `Ctrl+H` opens find and replace.
- `Ctrl+B`, `Ctrl+I`, and `Ctrl+K` insert bold, italic, and link Markdown.
- `Ctrl+?` shows the keyboard shortcut reference.

Unsaved drafts are recovered after an abnormal exit. Omawrite also watches open files
and warns before an external change can replace local work.

On Linux, text follows `omarchy display text size` or GNOME's
`text-scaling-factor` and re-flows without a restart. On Windows, OmaWrite uses
the system color scheme and the app's default text size.

## Linux requirements

- Qt 6: `qt6-base`, `qt6-declarative`, `qt6-quickcontrols2`
- `xdg-desktop-portal` and a portal backend

The iA Writer Mono font is bundled under the SIL Open Font License 1.1; see
`fonts/OFL.txt`. The font is copyright Information Architects Inc. and based on
IBM Plex, copyright IBM Corp.

The Windows package dynamically links to Qt 6 under the GNU Lesser General
Public License v3. See `THIRD-PARTY-NOTICES.md` for distribution details.
