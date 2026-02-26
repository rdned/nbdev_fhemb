# Scripts

>This folder contains operational scripts for CI release downloads and NAS mounts.

## 1) CI release asset download

### `download_release_asset_ci.sh`

A CI‑safe helper script for downloading a specific asset (typically a wheel) from a GitHub release identified by tag. Works with both public and private repositories and supports integrity verification when the release metadata includes a `SHA‑256` digest.

The script provides defaults for all positional parameters, but **a valid authentication token is always required**.

#### Tokens (mandatory)

The script cannot run without a token. You must provide either:

1. `FHEMB_TOKEN` — a fine‑grained Personal Access Token (`PAT`)
Use this for private repositories or cross‑repository access.
Required permission: Repository → Contents → Read.

2. `GITHUB_TOKEN` — the token automatically provided by GitHub Actions
Works only for the current repository and only if it has contents: read permission.
Often insufficient for private or cross‑repo downloads.

>##### Who can create and distribute tokens
>
>- Repository owner / organization admin
>
>   - Can create a fine‑grained `PAT` with the required permissions.
>   - Can store it as a CI secret (`FHEMB_TOKEN`) so all contributors and workflows can use it without seeing the raw token.
>   - Can optionally share such a `PAT` directly with trusted contributors for local use.
>- Contributors
>   - Cannot create a `PAT` for someone else’s private repository.
>   - Use the token provided by the owner:
>     - via CI secrets (`FHEB_TOKEN`), or
>     - via the built‑in `GITHUB_TOKEN` when running inside the same repository’s GitHub Actions.

Set one of:

```bash
# provided by the repo owner (directly or via CI)
export FHEMB_TOKEN="<your-token>"

# or available automatically in GitHub Actions
export GITHUB_TOKEN="<token-provided-by-github-actions>"
```

#### Usage

```bash
scripts/download_release_asset_ci.sh <OWNER>/<REPO> <TAG> <ASSET_NAME> [<OUT_PATH>]
 ```

Angle brackets indicate placeholders, not literal syntax.
All parameters have script defaults, so they are optional, but in real use you normally override them.

- `OWNER/REPO` — GitHub repository (default: `rdned/fhemb`)
- `TAG` — release tag (default: `0.1.0`)
- `ASSET_NAME` — asset filename (default: `fhemb-0.1.0-py3-none-anywhl`)
- `OUT_PATH` — output path (default: same as `ASSET_NAME`)

##### Example

```bash
export FHEMB_TOKEN="<personal-access-token>"
scripts/download_release_asset_ci.sh rdned/fhemb v0.1.0 fhemb-0.1.0-py3-none-any.whl dist/fhemb.whl
```

#### GitHub Actions

1. Add a secret FHEMB_TOKEN (fine‑grained PAT with contents:read for the target repo).
2. Call the script from your workflow, for example:

```yaml
- name: Download wheel
  run: scripts/download_release_asset_ci.sh rdned/fhemb v0.1.0 fhemb-0.1.0-py3-none-any.whl dist/fhemb.whl
```

The script automatically picks up:

- `FHEMB_TOKEN` (preferred for cross‑repo/private access)
- or `GITHUB_TOKEN` (may not work for private repos or cross‑repo downloads)

#### Behavior

- Fetches release metadata via the GitHub API.
- Locates the asset by exact name and prints available assets if not found.
- Downloads the asset using the authenticated binary endpoint.
- Verifies file size when metadata includes `.size` (warnings only).
- Verifies `SHA‑256` when metadata includes `.digest` (fatal on mismatch).
- Exits with stable, meaningful codes:
  - 1 — missing token
  - 2 — missing `jq` or `shasum`
  - 3 — release not found
  - 4 — asset not found
  - 5 — digest mismatch

#### Requirements

- `jq` for `JSON` parsing
- shasum for `SHA‑256` verification

#### Security

- Tokens are never printed.
- Keep `FHEMB_TOKEN` or `GITHUB_TOKEN` in CI secrets.
- Use fine‑grained PATs with minimal required permissions.

## 2) NAS mount scripts

⚠️ **Network prerequisite:** All NAS mount scripts assume that the NAS hosts are reachable on your local network.
If you are off‑LAN, establish your VPN connection (e.g., Tunnelblick) before running any mount script.

### Shared helpers

- `mount.sh`: low-level mount/unmount/check functions.
- `config_env.sh`: cross-platform config-root detection and `.env` value parsing.

### `mount_nas_storage.sh`

Purpose:

- Orchestrates a NAS mount sequence by invoking two child scripts in order (NAS1 then NAS2).
- Continues to step 2 even if step 1 fails, and prints timestamped status logs.

Current behavior:

- Looks for scripts under `${HOME}/scripts`:
  - `${HOME}/scripts/mount_nas1_thdata.sh`
  - `${HOME}/scripts/mount_nas2.sh`
- Runs each only if it exists and is executable.

Usage:

```bash
chmod +x scripts/mount_nas_storage.sh
scripts/mount_nas_storage.sh
```

### Other mount entry points

- `mount_nas1.sh`: mounts NAS1 using `MOUNT` from the platform config directory (`.env.paths`).
- `mount_thdata.sh`: mounts thermal data using `AUDIOFILES` from `.env.paths` and builds remote host/user from `.env.db` (`SSH_USERNAME`, `REMOTE_HOST`).
- `mount_nas2.sh`: mounts NAS2 using optional keys `MOUNT_NAS2` and `REMOTE_PATH_NAS2` from `.env.paths` (falls back to defaults if unset).

### Configuration keys reference

Template source files are in `config/` at repository root:

- `config/.env.paths.template`
- `config/.env.db.template`

Configuration directory by platform (same convention as top-level README):

| Platform | Config directory | Example path |
|---|---|---|
| **macOS** | `~/.config/fhemb/` | `/Users/<user>/.config/fhemb/` |
| **Linux** | `~/.config/fhemb/` | `/home/<user>/.config/fhemb/` |
| **Windows** | `%APPDATA%\fhemb\` | `C:\Users\<user>\AppData\Roaming\fhemb\` |

Initialize local config files (macOS/Linux/WSL/Git Bash):

```bash
mkdir -p ~/.config/fhemb
cp config/.env.paths.template ~/.config/fhemb/.env.paths
cp config/.env.db.template ~/.config/fhemb/.env.db
```

Initialize local config files (PowerShell):

```powershell
$cfg = Join-Path $env:APPDATA "fhemb"
New-Item -ItemType Directory -Force -Path $cfg | Out-Null
Copy-Item config/.env.paths.template (Join-Path $cfg ".env.paths") -Force
Copy-Item config/.env.db.template (Join-Path $cfg ".env.db") -Force
```

#### `.env.paths` (in your platform config directory)

| Key | Used by | Required | Description |
|---|---|---|---|
| `MOUNT` | `mount_nas1.sh` | Yes | Local mount point for NAS1. |
| `AUDIOFILES` | `mount_thdata.sh` | Yes | Local mount point for thermal data share. |
| `MOUNT_NAS2` | `mount_nas2.sh` | No | Local mount point for NAS2 (default: `/Volumes/NAS2`). |
| `REMOTE_PATH_NAS2` | `mount_nas2.sh` | No | Remote NAS2 share path (default: `nas2:/share/CACHEDEV1_DATA/Data`). |

#### `.env.db` (in your platform config directory)

| Key | Used by | Required | Description |
|---|---|---|---|
| `SSH_USERNAME` | `mount_thdata.sh` | Yes | Username used to build thermal-data remote path. |
| `REMOTE_HOST` | `mount_thdata.sh` | Yes | Host used to build thermal-data remote path. |

Example `REMOTE_PATH` derived by `mount_thdata.sh`:

```text
${SSH_USERNAME}@${REMOTE_HOST}:/NASstorage/ricardoc/thermal_data
```
