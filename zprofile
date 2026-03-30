# Nvim as default editor
export EDITOR="nvim"

# Essential aliases
alias ls="ls --color=auto"
alias grep="grep --color=auto"

# Edit zprofile
alias editzprofile="$EDITOR ~/.zprofile && source ~/.zprofile"

alias ll="ls -lh"
alias la="ls -lha"

alias ..="cd .."

# Local binaries
export PATH="$HOME/Bin:$PATH"

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Git aliases
alias gs="git status"
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
alias gx="git stash"
alias gxa="git stash apply"
alias gbb="git branch"
alias gbd="git branch -d"
alias gbD="git branch -D" # caps for safety
alias gbc="git checkout"
alias gbcn="git checkout -b" # git checkout new (branch)
alias gbs="git switch"
alias gbsn="git switch -c" # git switch new (branch)
alias gbm="git merge"
alias gl="git log"
alias glg="git log --oneline --graph --decorate" # git log graph
alias gla="git log --all --oneline --graph --decorate" # git log all
alias gt="git tag"

# Sanity reminders
isitlate() {
  hour=$(date +%H)
  if (( hour >= 22 || hour < 6 )); then
    return 0
  else
    return 1
  fi
}

sleepreminder() {
  echo ""
  echo "It's late. Go to sleep."
  echo "-Your past self"
  echo ""
  sleep 5
}

if isitlate; then
  sleepreminder
fi

go() {
  if isitlate; then
    sleepreminder
    return 1
  fi
  command go "$@"
}

nvim() {
  if isitlate; then
    sleepreminder
    return 1
  fi
  command nvim "$@"
}
