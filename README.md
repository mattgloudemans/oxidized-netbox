# oxidized-netbox

Project scaffolding for running [Oxidized](https://github.com/ytti/oxidized) with the built-in web UI and automatic GitLab synchronization of device configuration backups.

## What you get
- Docker Compose stack for the official `oxidized/oxidized` image with the web interface exposed on port 8888
- Opinionated Oxidized configuration that reads devices from `router.db` and pushes backups into a git repository
- Post-commit hook that syncs the repository to GitLab using a personal access token
- `.env`-style variables file to keep credentials out of version control

## Repository layout
- `docker-compose.yml` – orchestrates the Oxidized container and mounts configuration volumes
- `config/oxidized/config` – main Oxidized configuration (ERB-enabled to consume environment variables)
- `config/oxidized/router.db` – sample device inventory in `name:ip:ssh_port` format
- `config/secrets.env.example` – template for secrets that must be copied to `config/secrets.env`
- `scripts/git-sync.sh` – hook executed after every successful device backup to commit and push to GitLab
- `data/repo/` – working tree for the git repository maintained by Oxidized (ignored from git)

## Prerequisites
1. Docker Engine and Docker Compose plugin installed on the host
2. GitLab Personal Access Token (PAT) with `write_repository` scope for the target project
3. Device credentials that Oxidized will use for SSH connections

## Configuration
1. Copy the secrets template and edit it with your values:
   ```bash
   cp config/secrets.env.example config/secrets.env
   $EDITOR config/secrets.env
   ```
   Required entries:
   - `OXIDIZED_SSH_USERNAME` / `OXIDIZED_SSH_PASSWORD` (and optionally `OXIDIZED_ENABLE_PASSWORD`)
   - `GITLAB_REMOTE_URL` (HTTPS clone URL to your GitLab project)
   - `GITLAB_TOKEN` (PAT or Deploy Token with push access)

2. Populate `config/oxidized/router.db` with your devices (`name:ip:ssh_port`). Example:
   ```
   core-sw1:192.0.2.10:22
   edge-rtr1:198.51.100.5:2222
   ```

## Running Oxidized
Start the stack in the background:
```bash
docker compose up -d
```
The web interface and REST API are served on port 8888 by default. Override the published port by changing `OXIDIZED_WEB_PORT` in `config/secrets.env` before (re)starting the service.

Logs can be tailed with:
```bash
docker compose logs -f oxidized
```

## GitLab synchronization
- Oxidized writes device configurations to the git repository mounted at `data/repo`
- After every backup (`post_store` event), the `scripts/git-sync.sh` hook commits changes and pushes them to the GitLab project defined by `GITLAB_REMOTE_URL`
- The push is skipped automatically when the GitLab variables are missing, letting you validate locally without publishing

To rotate credentials, update `config/secrets.env` and recreate the container:
```bash
docker compose up -d --force-recreate
```

## Customization
- Adjust global Oxidized settings such as polling `interval`, threading, and per-device options inside `config/oxidized/config`
- Extend the repository with additional hooks or sources (e.g., NetBox API integration) by mounting extra scripts into `/opt/oxidized-hooks`
- For advanced secrets management, replace `config/secrets.env` with injections from Docker/Compose secrets or your preferred vault solution
