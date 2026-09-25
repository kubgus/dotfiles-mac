# Backstage - retired 2026-09-25

The MCP server that exposed the personal project library, the Samba share that mounted
it at `/Volumes/backstage`, and everything in Cloudflare in front of them. All gone.
This is the record of what was removed and what survived, because the runbook it came
from lived inside the library it describes.

## What survived

| | |
|---|---|
| The library | `~/Documents/Claude` on the Mac, 82 MB, **canonical since 2026-09-25**, with its git history. An archive; see its own `CLAUDE.md` |
| Old snapshots | 28 restic snapshots at `rclone:gdrive:Backups/backstage`, repo `01b50d2b7e`, last 2026-09-25 01:34 UTC |
| The archived stack | `block.local:~/Archive/backstage/`, with its own README |
| Source | `git@gitlab.com:kubgus/backstage.git`, working copy `~/Documents/Code/backstage` |


**The library lives on one machine now.** `block.local:~/Claude` was deleted on
2026-09-25 after the Mac copy was verified strictly ahead: 229 of 230 files identical
by content hash, the remaining two recoverable from git at Block's own HEAD, and
Block's HEAD an ancestor of the Mac's. Only the archived stack remains on Block.

The 28 restic snapshots at `rclone:gdrive:Backups/backstage` are a frozen copy of the
old Block tree, not a running backup. Their password is in the password manager and in
`~/Archive/backstage/backup-state/repo.password`; lose it and they are unrecoverable by
any means. Day to day the Mac copy rides on iCloud, which is the backup story now.

## What was removed

**On the Mac**: the `com.reynach.backstagemount` launchd agent and its plist,
`~/Bin/backstagemount`, `~/Bin/claudelink`, `~/.config/backstage/smb-token.env`,
18 MB of non-rotating logs, two hangs caches, the SMB keychain entry, the mount
itself, and eight dangling `CLAUDE.local.md` symlinks across active repos.

**On Block**: containers `backstage`, `backstage-smb` and `backstage-backup`, plus the
`backstage_default` network. The stack and backup state moved to `~/Archive/backstage/`.

**In Cloudflare**, all verified against the API response rather than the UI:

- Access applications `Backstage` (`10c35b9c-...`) and `Backstage SMB` (`2634da24-...`)
- Policies `Kubo only` (`0cb89bea-...`) and `SMB tunnel token` (`f6254753-...`)
- Service token `backstage-smb` (`630cb5d0-...`), disabled first, then deleted
- Tunnel routes `backstage.reynach.com` and `smb.reynach.com` on the Block tunnel
- Both DNS records - now NXDOMAIN

**Elsewhere**: the claude.ai connector, and the Teable `Central -> Services` row, which
is marked Down rather than deleted because that table keeps retired services that way.

## Three things worth keeping

**The dashboard reports success for work it did not do.** Deleting the service token
showed no error and changed nothing; the API had returned
`400 service_token_in_use`, visible only in the network log. The application editor
has the same failure mode, recorded in the original runbook - a save spanning two
tabs silently loses one. Check the response, not the UI.

**Delete routes before Access applications, not after.** Removing the apps first left
both hostnames published with no authentication in front of them. Nothing was
reachable because the containers were already stopped, but a restart would have
exposed the MCP server - which can read and write the whole library - to the internet.

**macOS stores filenames decomposed (NFD), Linux keeps the bytes it receives.** A
Slovak filename made on the Mac arrives on Linux as a different file, so git reports
the tracked name deleted with an untracked one beside it, and an rsync pull proposes a
delete with no matching send, which is silent data loss. `core.precomposeunicode=true`
hides it locally, which is why it stays invisible until two machines are involved.
This bit again during the migration: the writing examples came off the share NFD, and
every search-and-replace containing an accented character matched nothing until they
were normalised with `unicodedata.normalize("NFC", name)`.

## Reclaimable on Block, if you want the space

Images `backstage:local` (1.17 GB) and `backstage-backup:local` (204 MB), and the
docker volume `backstage_backstage-index`. The Pi is at 12 percent of 229 GB, so
there is no pressure. Left in place deliberately.
