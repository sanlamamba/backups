#!/usr/bin/env bash
# ~/.claude/statusline.sh — compact Claude Code status line.
#
# Claude Code pipes session JSON on stdin; we parse it with python3 (no jq needed)
# and print one line:
#   <model>  <dir> ⎇ <branch>*(<dirty>) [wt:<worktree>]  $<cost>  ◔<ctx>%  5h:<rate>%
#
# Wired via settings.json:
#   "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
# Field reference: https://code.claude.com/docs/en/statusline
set -uo pipefail

IN="$(cat)"

# Python prints tab-separated fields with "-" for anything missing. Tabs keep paths
# with spaces intact, and the "-" placeholders stop `read` collapsing empty fields.
IFS=$'\t' read -r MODEL CWD COST CTX RATE WT < <(
  IN="$IN" python3 - <<'PY' 2>/dev/null
import json, os

try:
    d = json.loads(os.environ.get("IN") or "{}")
except ValueError:
    d = {}


def get(*path):
    cur = d
    for key in path:
        if not isinstance(cur, dict):
            return None
        cur = cur.get(key)
    return cur


def is_num(x):
    return isinstance(x, (int, float)) and not isinstance(x, bool)


model = get("model", "display_name") or get("model", "id") or "?"
cwd = get("workspace", "current_dir") or d.get("cwd") or "-"

cost = get("cost", "total_cost_usd")
cost = f"{cost:.2f}" if is_num(cost) else "-"

# Context %: the pre-computed field, else input tokens / window size. Null early in
# a session and right after /compact, so show "-" rather than a wrong number.
pct = get("context_window", "used_percentage")
if not is_num(pct):
    used = get("context_window", "total_input_tokens")
    size = get("context_window", "context_window_size")
    pct = 100 * used / size if is_num(used) and is_num(size) and size else None
ctx = str(round(pct)) if is_num(pct) else "-"

# 5-hour rate limit: only present for Pro/Max after the first response.
rate = get("rate_limits", "five_hour", "used_percentage")
rate = str(round(rate)) if is_num(rate) else "-"

worktree = get("workspace", "git_worktree") or get("worktree", "name") or "-"

fields = [model, cwd, cost, ctx, rate, worktree]
print("\t".join(str(f).replace("\t", " ") or "-" for f in fields))
PY
)
MODEL="${MODEL:-?}"; CWD="${CWD:--}"; COST="${COST:--}"; CTX="${CTX:--}"; RATE="${RATE:--}"; WT="${WT:--}"
[ "$CWD" = "-" ] && CWD="$(pwd)"

# Git segment, cached for 5s per directory: the status line re-runs on every update,
# and `git status` is slow in large repos. --no-optional-locks avoids fighting
# Claude's own git commands for the index lock.
git_segment() {
  local dir="$1" key cache now mtime branch dirty out
  git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  key="$(printf '%s' "$dir" | cksum | cut -d' ' -f1)"
  cache="${TMPDIR:-/tmp}/claude-statusline-git-${key}"
  now="$(date +%s)"
  mtime="$(stat -c %Y "$cache" 2>/dev/null || stat -f %m "$cache" 2>/dev/null || echo 0)"
  if [ -s "$cache" ] && [ $((now - mtime)) -lt 5 ]; then
    cat "$cache"
    return 0
  fi
  # Branch name, or the short SHA when HEAD is detached.
  branch="$(git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null \
    || git -C "$dir" rev-parse --short HEAD 2>/dev/null)"
  dirty="$(git --no-optional-locks -C "$dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  out=" ⎇ ${branch}"
  [ "${dirty:-0}" -gt 0 ] && out="${out}*(${dirty})"
  printf '%s' "$out" > "$cache" 2>/dev/null
  printf '%s' "$out"
}

DIRNAME="$(basename "$CWD")"
GIT="$(git_segment "$CWD")"
WTDISP=""
[ "$WT" != "-" ] && WTDISP=" [wt:${WT}]"

# Color a percentage by pressure: >=80 red, >=60 yellow, else dim green.
pressure_color() {
  if   [ "$1" -ge 80 ]; then echo 31
  elif [ "$1" -ge 60 ]; then echo 33
  else echo 2; fi
}

CTXDISP=""
if [ "$CTX" != "-" ] && [ "$CTX" -ge 0 ] 2>/dev/null; then
  CTXDISP="$(printf '  \033[%sm◔%s%%\033[0m' "$(pressure_color "$CTX")" "$CTX")"
fi

COSTDISP=""
[ "$COST" != "-" ] && COSTDISP="$(printf '  \033[33m$%s\033[0m' "$COST")"

RATEDISP=""
if [ "$RATE" != "-" ] && [ "$RATE" -ge 0 ] 2>/dev/null; then
  RATEDISP="$(printf '  \033[%sm5h:%s%%\033[0m' "$(pressure_color "$RATE")" "$RATE")"
fi

# ANSI: cyan model, dim dir, green git, magenta worktree, yellow cost, pressure-colored gauges.
printf '\033[36m%s\033[0m  \033[2m%s\033[0m\033[32m%s\033[0m\033[35m%s\033[0m%s%s%s\n' \
  "$MODEL" "$DIRNAME" "$GIT" "$WTDISP" "$COSTDISP" "$CTXDISP" "$RATEDISP"
