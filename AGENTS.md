# AGENTS.md

## Cursor Cloud specific instructions

### What this repo is

Bounty-Bot-v1 is a **CLI-only** bug bounty recon pipeline (no web server, database, or Docker). The main entry point is `scripts/hunter.sh`, which chains ProjectDiscovery tools and optionally calls `scripts/reporter.py` when Nuclei finds critical/high issues.

### One-time path layout (required)

Scripts hardcode `/home/crex/bounty-bot` and `/home/crex/cyber-tools/bin/nuclei`. The workspace is symlinked there:

```bash
sudo mkdir -p /home/crex/cyber-tools/bin
sudo ln -sfn /workspace /home/crex/bounty-bot
sudo ln -sf "$HOME/go/bin/nuclei" /home/crex/cyber-tools/bin/nuclei
```

### External CLI dependencies

These must be on `PATH` (installed via `go install` in the VM update script):

| Tool | Role |
|------|------|
| `subfinder` | Subdomain enumeration (Phase 1) |
| `httpx` | Live host probing (Phase 2) |
| `katana` | Endpoint crawling (Phase 3; output not consumed downstream) |
| `nuclei` | Vulnerability scanning (Phase 4) |
| `dolphin` | Local LLM for report synthesis (only when Nuclei has hits) |

`dolphin` is not bundled in this repo. For local dev without a real Dolphin install, a stub at `~/.local/bin/dolphin` is sufficient to exercise `reporter.py`.

### Running the pipeline

1. Add authorized domains (one per line) to `authorized_targets.txt`.
2. Ensure `PATH` includes `$HOME/go/bin` and `$HOME/.local/bin`.
3. Run:

```bash
bash scripts/hunter.sh
```

Artifacts land in `recon/<domain>/` (subs, live hosts, nuclei hits) and `reports/<domain>/` (Markdown reports when findings exist).

### Lint / syntax checks

There is no project linter. Validate scripts with:

```bash
bash -n scripts/hunter.sh
python3 -m py_compile scripts/reporter.py
```

### Gotchas

- An **empty** `authorized_targets.txt` causes `hunter.sh` to exit immediately with a clear error — add at least one domain before running.
- First `nuclei` run downloads templates; allow extra time on cold start.
- Only scan domains you are **authorized** to test. `example.com` is useful for smoke tests but still performs live network recon.
- `katana` output (`urls.txt`) is written but not used by later phases in the current script.
