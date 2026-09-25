#!/bin/bash
# Claude Code status line: cwd + git branch (with a dirty marker), model and
# reasoning effort, a meters segment - context and the Claude.ai subscription
# limits, each with the time left until it resets - then the session cost and
# the initials of the account spending it. Every percentage is USED, not
# remaining, so the three read in the same direction.
set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
now="$(date +%s)"

get() {
    printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null || true
}

# --- colors (kept subtle; the status line already renders dimmed) ---
# Green, yellow and red mean severity and nothing else, so they stay reserved
# for the meters and the dirty marker. Everything else is identity: cyan for
# the directory, magenta for the model, orange for the account, plain white for
# the branch and the session cost. The branch is deliberately not yellow - that
# collided with the auto-mode indicator that sits directly under this line.
# Orange is the one colour reaching past the 8-colour set, because that set has
# no orange and borrowing yellow would read as a warning.
c_reset=$'\033[0m'
c_dir=$'\033[36m'
c_dirty=$'\033[31m'
c_model=$'\033[35m'
c_account=$'\033[38;5;208m'
c_text=$'\033[37m'
c_ok=$'\033[32m'
c_warn=$'\033[33m'
c_crit=$'\033[31m'
c_dim=$'\033[2m'

# How long until a rolling window resets, at one unit of useful precision:
# 3d4h, 2h11m, 47m, <1m. The input is a unix epoch in seconds; one that is
# missing, malformed or already elapsed prints nothing, so a stale snapshot
# degrades to a bare percentage instead of counting down past zero.
time_left() {
    local at="${1%%.*}" left d h m
    case "$at" in '' | *[!0-9]*) return 0 ;; esac
    left=$((at - now))
    [ "$left" -gt 0 ] || return 0
    d=$((left / 86400))
    h=$((left % 86400 / 3600))
    m=$((left % 3600 / 60))
    if [ "$d" -gt 0 ]; then
        printf '%dd%dh' "$d" "$h"
    elif [ "$h" -gt 0 ]; then
        printf '%dh%dm' "$h" "$m"
    elif [ "$m" -gt 0 ]; then
        printf '%dm' "$m"
    else
        printf '<1m'
    fi
}

# A meter is green until half spent, yellow past that, red near the limit. The
# reset countdown stays dim: it is context, not severity.
meter() {
    local label="$1" pct="$2" reset="${3:-}" int color left
    [ -n "$pct" ] || return 0
    int="${pct%%.*}"
    color="$c_ok"
    if [ "$int" -ge 80 ]; then
        color="$c_crit"
    elif [ "$int" -ge 50 ]; then
        color="$c_warn"
    fi
    printf '%s%s:%d%%%s' "$color" "$label" "$int" "$c_reset"
    left="$(time_left "$reset")"
    [ -n "$left" ] && printf ' %s(%s)%s' "$c_dim" "$left" "$c_reset"
    return 0
}

# --- 1. directory + git branch ---
cwd="$(get '.workspace.current_dir')"
[ -n "$cwd" ] || cwd="$(get '.cwd')"
dir_name="$(basename "$cwd")"

branch=""
dirty=""
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch="$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")"
    status_output="$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null || true)"
    [ -n "$status_output" ] && dirty="*"
fi

location="${c_dir}${dir_name}${c_reset}"
if [ -n "$branch" ]; then
    location="${location} ${c_dim}on${c_reset} ${c_text}${branch}${c_reset}${c_dirty}${dirty}${c_reset}"
fi

# --- 2. model + reasoning effort ---
# .effort is absent on models that do not support a reasoning effort level.
model="$(get '.model.display_name')"
effort="$(get '.effort.level')"
[ -n "$effort" ] && model="${model} ${c_dim}(${effort})${c_reset}"

# --- 3. meters: context and subscription limits, then session cost ---
# rate_limits is subscriber-only and cost can be absent, so each part is
# optional and its segment disappears if nothing is available. Only the two
# rolling windows reset on a clock, so only they carry a countdown.
meters=()
while read -r label pct_path reset_path; do
    m="$(meter "$label" "$(get "$pct_path")" "${reset_path:+$(get "$reset_path")}")"
    [ -n "$m" ] && meters+=("$m")
done <<'METERS'
ctx .context_window.used_percentage
5h .rate_limits.five_hour.used_percentage .rate_limits.five_hour.resets_at
7d .rate_limits.seven_day.used_percentage .rate_limits.seven_day.resets_at
METERS

cost="$(get '.cost.total_cost_usd')"
cost_part=""
[ -n "$cost" ] && cost_part="${c_text}$(printf '$%.2f' "$cost")${c_reset}"

# --- 4. account initials ---
# Which account this is, shortened to the initials of its display name: K,
# JG, JG2. The payload carries no identity at all, so it comes from the config
# directory the session was launched with - claudeswitch points
# CLAUDE_CONFIG_DIR at an account, and each one keeps its own .claude.json
# inside it, while the default account is the one that leaves the variable
# unset and keeps that file in $HOME. Signed out, or signed in under no name,
# yields nothing and the segment disappears rather than standing there empty.
account_json="${CLAUDE_CONFIG_DIR:-$HOME}/.claude.json"
initials=""
if [ -r "$account_json" ]; then
    initials="$(jq -r '[(.oauthAccount.displayName // "") | splits("[[:space:]]+")]
        | map(select(. != "") | .[0:1]) | add // "" | ascii_upcase' \
        "$account_json" 2>/dev/null || true)"
fi

# --- assemble ---
parts=("$location" "${c_model}${model}${c_reset}")
[ ${#meters[@]} -gt 0 ] && parts+=("${meters[*]}")
[ -n "$cost_part" ] && parts+=("$cost_part")
[ -n "$initials" ] && parts+=("${c_account}${initials}${c_reset}")

sep=" ${c_dim}|${c_reset} "
out=""
for p in "${parts[@]}"; do
    if [ -n "$out" ]; then
        out="${out}${sep}${p}"
    else
        out="$p"
    fi
done

printf '%s\n' "$out"
