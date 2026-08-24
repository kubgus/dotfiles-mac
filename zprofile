# -----------------------
# Nvim as default editor
# -----------------------
export EDITOR="nvim"

# -----------------------
# Essential aliases (QoL)
# -----------------------
alias ls="ls --color=auto"
alias ll="ls -lh"
alias la="ls -lha"

alias ..="cd .."

alias grep="grep --color=auto"

# -----------------------
# Automatically apply zprofile changes
# -----------------------
alias editzprofile="$EDITOR ~/.zprofile && source ~/.zprofile"

# -----------------------
# Add user binaries to PATH
# -----------------------
export PATH="$HOME/Bin:$PATH"

# -----------------------
# Homebrew
# -----------------------
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# -----------------------
# Bun
# -----------------------
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# -----------------------
# Dotnet
# -----------------------
export DOTNET_ROOT="/opt/homebrew/opt/dotnet/libexec"

# -----------------------
# Go
# -----------------------
export GOPATH=$HOME/.go
export PATH=$PATH:$GOPATH/bin

# -----------------------
# Ffmpeg full
# -----------------------
export LDFLAGS="-L/opt/homebrew/opt/ffmpeg-full/lib"
export CPPFLAGS="-I/opt/homebrew/opt/ffmpeg-full/include"

# -----------------------
# Secure node aliases
# -----------------------
alias npm="socket npm"
alias npx="socket npx"
alias pnpm="socket pnpm"
alias yarn="socket yarn"

# -----------------------
# Claude hands-free mode
# -----------------------
alias claudeagain="~/.claude/say-again.sh"
alias claudeskip="killall say"

# -----------------------
# Git aliases
# -----------------------
alias gs="git status"
alias gw="git show"
alias gwc="git show HEAD" # git show current (HEAD)
alias gwp="git show HEAD^" # git show previous (HEAD^)
alias ga="git add"
alias gaa="git add ." # git add all
alias gr="git reset"
alias gra="git reset ." # git reset all
alias grU="git reset HEAD^" # git reset undo (last commit)
alias grH="git reset --hard" # caps for safety
alias gc="git commit"
alias gcm="git commit -m"
alias gca="git commit --amend --no-edit" # git commit amend (add to last commit without changing message)
alias gcam="git commit --amend -m" # git commit amend message
alias gp="git push"
alias gpo="git push origin"
alias gpc="git push origin HEAD" # git push current (branch)
alias gpu="git push -u"
alias gpuo="git push -u origin"
alias gpuc="git push -u origin HEAD" # git push upstream current (branch)
alias gpd="git push origin --delete"
alias gpF="git push --force" # caps for safety
alias gu="git pull" # git pull
alias guc="git pull origin HEAD"
alias gx="git stash"
alias gxa="git stash apply"
alias gbb="git branch"
alias gba="git branch --all"
alias gbd="git branch -d"
alias gbD="git branch -D" # caps for safety
alias gbc="git checkout"
alias gbcn="git checkout -b" # git checkout new (branch)
alias gbs="git switch"
alias gbsn="git switch -c" # git switch new (branch)
alias gbm="git merge"
alias gbuc="git branch --set-upstream-to=origin/main main"
alias gl="git log"
alias glg="git log --oneline --graph --decorate" # git log graph
alias gla="git log --all --oneline --graph --decorate" # git log all
alias gt="git tag"

# -----------------------
# Sanity reminders
# -----------------------
_is_it_late() {
  return 1
  local hour
  hour=$(date +%H)
  if (( hour >= 22 || hour < 6 )); then
    return 0
  else
    return 1
  fi
}

_sleep_reminder() {
  echo ""
  echo "It's late. Go to sleep."
  echo "-Your past self"
  echo ""
  sleep 5
}

_run_sanity_check() {
  if _is_it_late; then
    _sleep_reminder
    return 1
  fi
  return 0
}

# Initial check on terminal startup
if _is_it_late; then
  _sleep_reminder
fi

LATE_COMMANDS=(
  "nvim"
  "go"
  "npm" "npx" "bun" "bunx"
)

# Wrap each command with alias
for cmd in "${LATE_COMMANDS[@]}"; do
  existing_val=""

  # Safely extract the existing alias if one exists
  if [[ -n "$ZSH_VERSION" ]]; then
    existing_val="${aliases[$cmd]}"
  elif [[ -n "$BASH_VERSION" ]]; then
    existing_val=$(alias "$cmd" 2>/dev/null | sed "s/^alias $cmd='\(.*\)'$/\1/")
  fi

  # Build the composite alias
  if [[ -n "$existing_val" ]]; then
    # Preserves your existing alias and prepends the check
    alias "$cmd"="_run_sanity_check && $existing_val"
  else
    # Creates a fresh check
    alias "$cmd"="_run_sanity_check && $cmd"
  fi
done
