#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
remote="${REMOTE:-origin}"
deploy_branch="${DEPLOY_BRANCH:-gh-pages}"
remote_url="$(git -C "$repo_root" remote get-url "$remote")"
source_sha="$(git -C "$repo_root" rev-parse --short HEAD)"
workdir="$(mktemp -d "${TMPDIR:-/tmp}/tact-pages.XXXXXX")"

cleanup() {
  rm -rf "$workdir"
}
trap cleanup EXIT

mkdir -p "$workdir/assets/brand" "$workdir/assets/screenshots"
cp "$repo_root/index.html" "$repo_root/styles.css" "$repo_root/.nojekyll" "$workdir/"
cp -R "$repo_root/privacy" "$workdir/"
cp "$repo_root/assets/brand/tact-tools-icon.png" "$workdir/assets/brand/"
cp "$repo_root"/assets/screenshots/*.webp "$workdir/assets/screenshots/"

git -C "$workdir" init -b "$deploy_branch"
git -C "$workdir" remote add origin "$remote_url"
git -C "$workdir" add .
git -C "$workdir" commit \
  -m "deploy: Publish static staging site" \
  -m "Publish the static website files generated from source commit $source_sha." \
  -m "The main branch includes Android and mock app submodules for the screenshot harness, so GitHub Pages is served from this static-only branch."
git -C "$workdir" push -f origin "$deploy_branch"
