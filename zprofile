# -----------------------
# Nvim as default editor
# -----------------------
export EDITOR="nvim"

# -----------------------
# Homebrew
# -----------------------
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

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
# Secure npm, npx, pnpm, yarn
# -----------------------
alias npm="socket npm"
alias npx="socket npx"
alias pnpm="socket pnpm"
alias yarn="socket yarn"


# -----------------------
# Claude shortcuts
# -----------------------
alias clc="claudeswitch"

# -----------------------
# Git shortcuts
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
alias gbr="git branch -m" # git branch rename
alias gl="git log"
alias glg="git log --oneline --graph --decorate" # git log graph
alias gla="git log --all --oneline --graph --decorate" # git log all
alias gt="git tag"

# -----------------------
# Add user binaries to PATH
# -----------------------
export PATH="$HOME/Bin:$PATH"

# -----------------------
# Bun
# -----------------------
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# -----------------------
# Go
# -----------------------
export GOPATH=$HOME/.go
export PATH=$PATH:$GOPATH/bin

# -----------------------
# Dotnet
# -----------------------
export DOTNET_ROOT="/opt/homebrew/opt/dotnet/libexec"

# -----------------------
# Ffmpeg full
# -----------------------
export LDFLAGS="-L/opt/homebrew/opt/ffmpeg-full/lib"
export CPPFLAGS="-I/opt/homebrew/opt/ffmpeg-full/include"

# -----------------------
# Secrets (login keychain)
# -----------------------
_export_secret() {
  local value
  value="$(security find-generic-password -a "$USER" -s "$2" -w 2>/dev/null)" || return 0
  if [ -n "$value" ]; then
    export "$1=$value"
  fi
}

# to add a secret to the macOS keychain:
# security add-generic-password -a "$USER" -s <service> -w

# call, variable, service:
_export_secret TEABLE_API_KEY teable-mcp-api-key
