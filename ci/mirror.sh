#!/usr/bin/env bash
# Match pi-nix's source-only default-branch mirrors, without token-bearing Git argv.
set +x
set -euo pipefail

if [[ ${CI_PIPELINE_SOURCE:-} != push || -z ${CI_DEFAULT_BRANCH:-} || ${CI_COMMIT_BRANCH:-} != "$CI_DEFAULT_BRANCH" ]]; then
  echo 'Skipping mirrors outside a default-branch push.'
  exit 0
fi

# Do not let inherited Git HTTP tracing disclose credentials.
unset GIT_TRACE GIT_TRACE_CURL GIT_CURL_VERBOSE
export GIT_TERMINAL_PROMPT=0
askpass_dir=$(mktemp -d)
trap 'rm -rf "$askpass_dir"' EXIT
cat > "$askpass_dir/askpass" <<'ASKPASS'
#!/usr/bin/env bash
set +x
case "$1" in
  *Username*) printf '%s\n' "$MIRROR_USERNAME" ;;
  *Password*) printf '%s\n' "$MIRROR_PASSWORD" ;;
  *) exit 1 ;;
esac
ASKPASS
chmod 700 "$askpass_dir/askpass"
export LC_ALL=C GIT_ASKPASS="$askpass_dir/askpass"

git checkout -B "$CI_DEFAULT_BRANCH" "origin/$CI_DEFAULT_BRANCH"

mirror_push() {
  local name="$1" host="$2" repo="$3" username="$4" token="$5" url="$6"

  if [[ -z "$url" ]]; then
    if [[ -z "$token" ]]; then
      echo "Skipping $name mirror; URL/token variable is not configured."
      return 0
    fi
    url="https://$host/$repo.git"
  fi

  # URL overrides select a destination, not an inline secret. SSH uses runner keys.
  case "$url" in
    "https://$host/"*) ;;
    "git@$host:"*) ;;
    *)
      echo "Invalid $name mirror URL; use its expected host and a separate token variable." >&2
      return 1
      ;;
  esac

  echo "Pushing $CI_DEFAULT_BRANCH to $name mirror"
  MIRROR_USERNAME="$username" MIRROR_PASSWORD="$token" \
    git -c credential.helper= push --force "$url" "$CI_DEFAULT_BRANCH:$CI_DEFAULT_BRANCH"
}

mirror_push github github.com "${GITHUB_MIRROR_REPO:-bovf/artcraft-nix}" x-access-token \
  "${GITHUB_TOKEN:-}" "${GITHUB_MIRROR_URL:-}"
mirror_push codeberg codeberg.org "${CODEBERG_MIRROR_REPO:-bovfbovf/artcraft-nix}" bovfbovf \
  "${CODEBERG_TOKEN:-}" "${CODEBERG_MIRROR_URL:-}"
