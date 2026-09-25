# Backstage teardown - what is left

The Mac side is done, as of 2026-09-25. This is the remainder: the Pi containers
and the Cloudflare configuration in front of them. None of it is urgent - it
costs nothing to leave running, and the library is still reachable over SSH,
which is the point of keeping it.

This file lives here because the runbook it was distilled from lives *inside*
the library it describes, and that becomes unreachable the moment the last of
this is done.

## What is still standing

| | |
|---|---|
| Canonical library | `block.local:/home/kubgus/Claude` - **keep this**, it is the real copy |
| Stack | `/home/kubgus/Containers/backstage` on the Pi |
| Containers | `backstage` (MCP server), `backstage-smb` (Samba), `backstage-backup` (restic) |
| Backup state | `/home/kubgus/Containers/backstage-backup-state`, outside the library |
| Source repo | `git@gitlab.com:kubgus/backstage.git`, working copy `~/Documents/Code/backstage` |
| Mac replica | `~/Documents/Claude` - 43 MB, now stale and no longer synced |

`ssh` needs `-4` on this network: `block.local` also resolves to an IPv6
link-local address, and ssh tries that first and fails with "No route to host".

## Do this first, before anything is stopped

**Copy the restic repository password into the password manager.** A restic
repository whose password is lost is not recoverable by any means, and this is
the only copy:

```sh
ssh -4 block.local 'cat ~/Containers/backstage-backup-state/repo.password'
```

Then take a final snapshot and prove it restores:

```sh
ssh -4 block.local 'cd ~/Containers/backstage && docker compose run --rm backup restic snapshots'
ssh -4 block.local 'cd ~/Containers/backstage && docker compose run --rm backup restore-test'
```

Repository is `01b50d2b7e` at `rclone:gdrive:Backups/backstage` - Google Drive,
not R2. Done means the restore test passed, not that the snapshot ran.

## Order of operations

1. **Stop the two serving containers**, leave `backstage-backup` running so the
   library keeps its history:

   ```sh
   ssh -4 block.local 'cd ~/Containers/backstage && docker compose stop backstage backstage-smb'
   ```

   Verify the backup container is still up before moving on. If you want the
   backups gone too, that is a separate decision - the library is still on the
   Pi either way, and hourly snapshots are the only rollback for `.pii.` files,
   which are git-ignored.

2. **Remove the claude.ai connector** at claude.ai -> Settings -> Connectors,
   entry "Backstage". Until this is gone it injects its instructions and 20 tool
   definitions into every session that has it enabled, including Claude Code,
   which picks it up automatically.

3. **Cloudflare tunnel routes** - Zero Trust -> Networks -> Tunnels -> "Block":

   - route to `backstage.reynach.com` -> `http://localhost:7259`
   - route to `smb.reynach.com` -> the Samba container

   Delete both, and their DNS records in the `reynach.com` zone.

4. **Cloudflare Access applications** - Zero Trust -> Access -> Applications:

   - "Backstage", id `10c35b9c-a735-4f09-943f-dd43904eee95`, with the policy
     "Kubo only" (Emails include `gustafik@reynach.com`)
   - "Backstage SMB", with the policy "SMB tunnel token" (Service Auth)

   Save one tab at a time. The application editor spans two tabs behind a single
   Save, and staging changes on both before saving loses them silently - no
   error, and nothing in the audit log. Check the audit log filtered to the
   application afterwards: a save that does not appear there did not happen.

5. **Revoke the service token** `backstage-smb` - Zero Trust -> Access ->
   Service credentials. It does not expire until 2027-09-21.

   **Do this even if you stop here.** `cloudflared access tcp` ignores the
   documented `TUNNEL_SERVICE_TOKEN_ID` and `_SECRET` environment variables, so
   the wrapper passed them as flags, which put the secret in `ps` output on this
   machine. Treat it as disclosed. The local copy of the token file is deleted;
   the token itself is still valid until revoked here.

6. **Three orphan OAuth clients** registered while debugging Managed OAuth are
   still on the account. They grant nothing on their own - a token still has to
   pass a policy - and removing them needs registration access tokens that were
   not kept. Deleting the Access application above is what actually retires them.

7. **Teable** - `Central -> Services`, row "Library MCP". Delete or mark retired.

## If you ever want the mount back

Do not. It was an SMB share over a Cloudflare Access TCP tunnel, and the
measured cost was 9.6s for a recursive listing of `Projects/` against 0.12s to
read a 250 KB file. Browsing or working out of it was painful, git across it was
forbidden because `.git/index.lock` is unsafe over SMB, and it dropped on every
deep sleep because an SMB session cannot survive one. The watchdog that put it
back was 6 KB of bash guarding against a failure mode macOS created.

SSH is the way in:

```sh
ssh -4 block.local
cd ~/Claude
```

## One trap worth keeping

macOS stores filenames decomposed (NFD), Linux keeps whatever bytes it receives.
A Slovak filename created on the Mac arrives on the Pi as a *different* file, so
git reports the tracked name deleted with an untracked one beside it, and an
rsync pull proposes a delete with no matching send - which is silent data loss.
`core.precomposeunicode=true` hides this locally, which is why it stays
invisible until two machines are involved. Normalise with
`unicodedata.normalize("NFC", name)` on both sides before trusting a sync.

This bit during this migration too: the writing examples came off the share
NFD-normalised, and every search-and-replace containing an accented character
silently matched nothing until they were normalised first.
