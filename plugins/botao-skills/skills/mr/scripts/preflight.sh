#!/usr/bin/env bash
# Collect every fact needed to open a GitLab MR, in one shot.
# Usage: preflight.sh [target-branch]
# Prints KEY=VALUE lines on stdout. FATAL=... means nothing else could be
# determined; BLOCKER=... means the caller must resolve something first.

set -uo pipefail

emit() { printf '%s=%s\n' "$1" "$2"; }
fatal() { emit FATAL "$1"; exit 1; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fatal not_a_git_repo
command -v glab >/dev/null 2>&1 || fatal glab_not_installed

SOURCE=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || fatal detached_head

REMOTE=$(git config --get "branch.$SOURCE.remote" 2>/dev/null || true)
if [ -z "$REMOTE" ]; then
  if git remote | grep -qx origin; then REMOTE=origin; else REMOTE=$(git remote | head -n1); fi
fi
[ -n "$REMOTE" ] || fatal no_git_remote
URL=$(git remote get-url "$REMOTE" 2>/dev/null) || fatal no_git_remote

# git@host:group/repo.git | ssh://git@host:22/group/repo.git | https://host/group/repo.git
strip_scheme() { printf '%s' "$1" | sed -E -e 's#^[a-z]+://##' -e 's#^[^@/]+@##'; }
HOST=$(strip_scheme "$URL" | sed -E 's#[:/].*$##')
PROJECT=$(strip_scheme "$URL" | sed -E -e 's#^[^:/]+[:/]##' -e 's#^[0-9]+/##' -e 's#\.git$##')

git fetch --quiet "$REMOTE" 2>/dev/null || emit WARN fetch_failed

# Check auth before anything that talks to GitLab. `glab mr list` fails silently
# into an empty list when unauthenticated, which reads as "no MR exists" instead
# of "could not look" — so stop here rather than emit facts that are all lies.
if ! glab auth status --hostname "$HOST" >/dev/null 2>&1; then
  emit HOST "$HOST"
  emit BLOCKER glab_not_authenticated
  exit 0
fi

emit HOST "$HOST"
emit PROJECT "$PROJECT"
emit REMOTE "$REMOTE"
emit SOURCE_BRANCH "$SOURCE"

# The target branch is a required argument. Resolving one on the caller's behalf
# means guessing which branch a team merges into, and a wrong guess produces a
# real MR pointed at the wrong place. So when it is missing, stop — but stop with
# the candidates and the evidence for each, because "which branch?" on its own
# just hands the question back to someone who would have typed it if they knew.
if [ -z "${1:-}" ]; then
  DEF=$(git ls-remote --symref "$REMOTE" HEAD 2>/dev/null \
    | sed -n 's#^ref: refs/heads/\([^[:space:]]*\).*#\1#p' | head -n1)
  # Falls back to the local origin/HEAD, which is written at clone time and never
  # refreshed by git fetch — fine as a hint, not to be trusted as the answer.
  [ -z "$DEF" ] && DEF=$(git symbolic-ref --quiet --short "refs/remotes/$REMOTE/HEAD" 2>/dev/null | sed "s#^$REMOTE/##")
  [ -n "$DEF" ] && emit DEFAULT_BRANCH "$DEF"

  HIST=$(glab mr list --source-branch "$SOURCE" --all -F json 2>/dev/null || printf '[]')
  HIST_TARGETS=$(printf '%s' "$HIST" | grep -o '"target_branch":"[^"]*"' | cut -d'"' -f4 | sort | uniq -c | sort -rn)
  [ -n "$HIST_TARGETS" ] && emit RECENT_MR_TARGETS "$(echo "$HIST_TARGETS" | awk '{printf "%s:%s,", $2, $1}' | sed 's/,$//')"

  # How the current branch stands against each candidate. ahead=0 means an MR
  # into it would be empty — worth saying before the user picks that one.
  SEEN=" "
  for c in $DEF $(echo "$HIST_TARGETS" | awk '{print $2}'); do
    case "$SEEN" in *" $c "*) continue ;; esac
    SEEN="$SEEN$c "
    git show-ref --verify --quiet "refs/remotes/$REMOTE/$c" || continue
    emit CANDIDATE "$c ahead=$(git rev-list --count "$REMOTE/$c..HEAD" 2>/dev/null || echo 0) behind=$(git rev-list --count "HEAD..$REMOTE/$c" 2>/dev/null || echo 0)"
  done

  emit BLOCKER target_required
  exit 0
fi

TARGET=${1#"$REMOTE/"}
emit TARGET_BRANCH "$TARGET"

[ "$SOURCE" = "$TARGET" ] && emit BLOCKER same_source_and_target

if git show-ref --verify --quiet "refs/remotes/$REMOTE/$TARGET"; then
  BASE="$REMOTE/$TARGET"
  emit AHEAD "$(git rev-list --count "$BASE..HEAD" 2>/dev/null || echo 0)"
  emit BEHIND "$(git rev-list --count "HEAD..$BASE" 2>/dev/null || echo 0)"
  emit MERGE_BASE "$(git merge-base "$BASE" HEAD 2>/dev/null || echo '')"
  [ "$(git rev-list --count "$BASE..HEAD" 2>/dev/null || echo 0)" = "0" ] && emit BLOCKER no_commits_ahead
else
  emit BLOCKER target_branch_missing_on_remote
fi

if git show-ref --verify --quiet "refs/remotes/$REMOTE/$SOURCE"; then
  emit REMOTE_BRANCH exists
  emit UNPUSHED "$(git rev-list --count "$REMOTE/$SOURCE..HEAD" 2>/dev/null || echo 0)"
else
  emit REMOTE_BRANCH missing
  emit UNPUSHED all
fi

emit UNCOMMITTED "$(git status --porcelain 2>/dev/null | grep -c . | tr -d ' ')"

MR_JSON=$(glab mr list --source-branch "$SOURCE" --target-branch "$TARGET" -F json 2>/dev/null || printf '[]')
EXISTING=$(printf '%s' "$MR_JSON" | grep -o '"web_url":"[^"]*"' | head -n1 | cut -d'"' -f4)
if [ -n "$EXISTING" ]; then
  emit EXISTING_MR "$EXISTING"
  emit BLOCKER mr_already_open
fi

ROOT=$(git rev-parse --show-toplevel)
if [ -d "$ROOT/.gitlab/merge_request_templates" ]; then
  emit MR_TEMPLATES "$(ls "$ROOT/.gitlab/merge_request_templates" 2>/dev/null | paste -sd, - | tr -d ' ')"
fi

exit 0
