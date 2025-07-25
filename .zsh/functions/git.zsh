worktree(){
  local cmd=$1

  if [[ -z $cmd ]]; then
    echo "Usage: worktree <command>"
    echo "Commands:"
    echo "  new <worktree_name> - Create a new worktree"
    return 0
  fi

  shift

  # Check if inside a git repo
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Not inside a git repository"
    return 1
  fi

  local repo_root=$(git rev-parse --show-toplevel)
  local repo_name=$(basename "$repo_root")
  local worktrees_dir="$HOME/projects/worktrees/$repo_name"
  mkdir -p "$worktrees_dir"

  case "$cmd" in
    new)
      local worktree_name="$1"
      if [[ -z $worktree_name ]]; then
        echo "Please provide a worktree name:"
        read -r worktree_name
        if [[ -z $worktree_name ]]; then
          echo "Worktree name is required."
          return 1
        fi
      fi
      local branch_name="$worktree_name"
      local worktree_path="$worktrees_dir/$worktree_name"
      # Create new branch from current HEAD
      git branch "$branch_name"
      # Create the worktree for the new branch
      git worktree add "$worktree_path" "$branch_name"
      cursor "$worktree_path"
      ;;
    "")
      echo "Please provide a subcommand (e.g., 'new')."
      return 1
      ;;
    *)
      echo "unknown command '$cmd'"
      return 1
      ;;
  esac
}
