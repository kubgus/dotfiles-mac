# Backstage - retired 2026-09-25

The MCP server that exposed the personal project library, the Samba share that mounted
it at `/Volumes/backstage`, and everything in Cloudflare in front of them. All gone.
This is the record of what was removed and what survived, because the runbook it came
from lived inside the library it describes.

## What survived

| | |
|---|---|
| The library | `block.local:~/Claude`, 103 MB, still canonical. Reach it over SSH: `ssh -4 block.local` |
| Old snapshots | 28 restic snapshots at `rclone:gdrive:Backups/backstage`, repo `01b50d2b7e`, last 2026-09-25 01:34 UTC |
| The archived stack | `block.local:~/Archive/backstage/`, with its own README |
| Source | `git@gitlab.com:kubgus/backstage.git`, working copy `~/Documents/Code/backstage` |
| Mac replica | `~/Documents/Claude`, 43 MB, now stale and no longer synced |

**Nothing backs up `~/Claude` any more.** The backup container is gone with the rest.
The 28 snapshots are a point-in-time copy, not a running backup. The repository
password is in the password manager and in `~/Archive/backstage/backup-state/repo.password`;
lose it and the snapshots are unrecoverable by any means.

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
