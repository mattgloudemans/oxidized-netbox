#!/usr/bin/env bash
set -euo pipefail

repo_path="${OXIDIZED_REPO_PATH:-/var/lib/oxidized/repo}"
git_user="${OXIDIZED_GIT_USER:-oxidized}"
git_email="${OXIDIZED_GIT_EMAIL:-oxidized@example.com}"
remote_url="${GITLAB_REMOTE_URL:-}"
token="${GITLAB_TOKEN:-}"

default_branch="${OXIDIZED_GIT_BRANCH:-main}"

if [[ ! -d "$repo_path" ]]; then
  echo "[git-sync] repository path $repo_path does not exist" >&2
  exit 0
fi

if [[ ! -d "$repo_path/.git" ]]; then
  echo "[git-sync] initializing new git repository" >&2
  git -C "$repo_path" init
  git -C "$repo_path" config user.name "$git_user"
  git -C "$repo_path" config user.email "$git_email"
  git -C "$repo_path" checkout -b "$default_branch"
fi

# Ensure the branch exists (handles rebase scenarios)
if ! git -C "$repo_path" rev-parse --verify "$default_branch" >/dev/null 2>&1; then
  git -C "$repo_path" checkout -b "$default_branch"
else
  git -C "$repo_path" checkout "$default_branch"
fi

# Stage new and changed files
if ! git -C "$repo_path" add -A; then
  echo "[git-sync] failed to stage changes" >&2
  exit 1
fi

# Commit only when changes exist
if git -C "$repo_path" diff --cached --quiet; then
  echo "[git-sync] no configuration changes to commit" >&2
  exit 0
fi

timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
git -C "$repo_path" commit -m "Automated backup $timestamp"

# Push if remote credentials are available
if [[ -z "$remote_url" || -z "$token" ]]; then
  echo "[git-sync] remote URL or token not configured; skipping push" >&2
  exit 0
fi

case "$remote_url" in
  https://*)
    remote_no_proto="${remote_url#https://}"
    remote_with_token="https://oauth2:${token}@${remote_no_proto}"
    ;;
  http://*)
    remote_no_proto="${remote_url#http://}"
    remote_with_token="http://oauth2:${token}@${remote_no_proto}"
    ;;
  git@*)
    echo "[git-sync] skipping push because remote is SSH but only token provided" >&2
    exit 0
    ;;
  *)
    remote_with_token="$remote_url"
    ;;
esac

echo "[git-sync] pushing configuration updates to ${remote_url}" >&2
git -C "$repo_path" push "$remote_with_token" "HEAD:${default_branch}"
