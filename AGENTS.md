# Repository Guidelines

## Project Structure & Module Organization
- `docker-compose.yml` orchestrates the Oxidized container and mounts configuration, data, and hook directories.
- `config/oxidized/` stores the ERB-enabled Oxidized config (`config`) and device inventory (`router.db`).
- `config/secrets.env.example` documents required environment variables; copy it to `config/secrets.env` for local secrets.
- `scripts/` contains operational helpers such as `git-sync.sh`, executed after device backups.
- `data/repo/` is the working tree for captured device configs; it is ignored by git except for the placeholder `.gitkeep`.

## Build, Test, and Development Commands
- `docker compose up -d` boots the Oxidized stack in the background.
- `docker compose logs -f oxidized` tails runtime logs for troubleshooting pollers and hooks.
- `docker compose down` stops the stack and releases bound ports.
- `docker compose exec oxidized bash` opens an interactive shell inside the container for advanced debugging.

## Coding Style & Naming Conventions
- YAML files (Compose, Oxidized config) use two-space indentation and lowercase keys.
- Shell scripts follow `bash` strict mode (`set -euo pipefail`); prefer double quotes around parameter expansions.
- Environment variable names are uppercase with `OXIDIZED_` or `GITLAB_` prefixes; back up corresponding documentation in `secrets.env.example` when adding new values.

## Testing Guidelines
- No automated tests are defined; validate changes by running `docker compose up -d` and confirming successful polls via the web UI and logs.
- When modifying `git-sync.sh`, dry-run by entering the container (`docker compose exec oxidized bash`) and running the script against a staged repo snapshot.
- Record manual verification steps in PR descriptions when the change cannot be trivially tested.

## Commit & Pull Request Guidelines
- Write commit subjects in the imperative mood (e.g., `Add GitLab sync hook`), keeping the summary under 65 characters.
- Group related configuration updates into single commits to simplify rollback.
- Pull requests should describe the motivation, highlight config or secret changes, and include reproduction or validation notes.
- If the change alters container behavior (ports, volumes, credentials), call it out in bold in the PR body and alert reviewers to update their local `config/secrets.env`.

## Security & Configuration Tips
- Never commit `config/secrets.env`; the template plus `.gitignore` guard against accidental publication—verify before pushing.
- Rotate GitLab tokens and device credentials periodically; update the environment file and restart with `docker compose up -d --force-recreate`.
- Audit the `data/repo/` directory for configuration artifacts prior to sharing archives or troubleshooting bundles.
