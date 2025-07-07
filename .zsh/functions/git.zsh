function gw() {
  local worktree_name=$1
  local branch_name=$2

  # Check if inside a git repo
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Not inside a git repository"
    return 1
  fi

  local repo_root=$(git rev-parse --show-toplevel)
  local repo_name=$(basename "$repo_root")
  local worktrees_dir="$HOME/projects/worktrees/$repo_name"

  # Create .worktrees directory if it doesn't exist
  mkdir -p "$worktrees_dir"

  # If no worktree name given, prompt for one
  if [[ -z $worktree_name ]]; then
    echo "Please provide a worktree name:"
    read -r worktree_name
    if [[ -z $worktree_name ]]; then
      echo "Worktree name is required."
      return 1
    fi
  fi

  # If no branch name given, select from existing branches using fzf
  if [[ -z $branch_name ]]; then
    branch_name=$(git branch --format='%(refname:short)' | fzf --prompt="Select branch for worktree: ")
    if [[ -z $branch_name ]]; then
      echo "No branch selected."
      return 1
    fi
    if [[ $branch_name == "main" ]]; then
      git branch "$worktree_name" main
      branch_name="$worktree_name"
    fi
  fi

  local worktree_path="$worktrees_dir/$worktree_name"

  # Create the worktree
  git worktree add "$worktree_path" "$branch_name"
  cursor "$worktree_path"
}
