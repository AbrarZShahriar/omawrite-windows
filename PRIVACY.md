# Privacy

OmaWrite is a local Markdown editor. The installed application does not include
telemetry, analytics, advertising, account sign-in, or a network client. It
does not transfer information to another system unless the user explicitly
opens a link in a document. Link activation passes the URL to the operating
system's default application.

Documents are read from and written to locations selected by the user. The
application stores the last save directory in the operating system's local
settings store. While a document has unsaved changes, a recovery copy is kept
in the application's local data directory. The recovery copy is removed after
the document is saved or discarded normally.

The optional `install-windows.cmd` and `windows/install.ps1` scripts contact the
GitHub API and GitHub release storage only when the user runs them. They obtain
the latest installer and its checksum, verify the download, and then start the
installer. The packaged editor and Setup EXE do not download application files
during installation or normal use.

OmaWrite uses Qt and the bundled iA Writer Mono font. Their license information
is listed in [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md); these local
components do not add an OmaWrite-operated data service.
