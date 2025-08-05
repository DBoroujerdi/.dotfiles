worktree(){
  local cmd=$1

  if [[ -z $cmd ]]; then
    echo "Usage: worktree <command>"
    echo "Commands:"
    echo "  new <worktree_name> - Create a new worktree"
    echo "  open - Open an existing worktree using fzf"
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
    open)
      # Check if fzf is available
      if ! command -v fzf > /dev/null 2>&1; then
        echo "fzf is required but not installed. Please install fzf first."
        return 1
      fi
      
      local worktrees_base="$HOME/projects/worktrees"
      
      # Check if worktrees directory exists
      if [[ ! -d "$worktrees_base" ]]; then
        echo "No worktrees found at $worktrees_base"
        return 1
      fi
      
      # Step 1: Pick the project using fzf
      local selected_project=$(find "$worktrees_base" -maxdepth 1 -type d -name "*" | grep -v "^$worktrees_base$" | sed "s|$worktrees_base/||" | fzf --prompt="Select project: ")
      
      if [[ -z "$selected_project" ]]; then
        echo "No project selected"
        return 1
      fi
      
      local project_path="$worktrees_base/$selected_project"
      
      # Step 2: Pick the worktree within the selected project
      local selected_worktree=$(find "$project_path" -maxdepth 1 -type d -name "*" | grep -v "^$project_path$" | sed "s|$project_path/||" | fzf --prompt="Select worktree: ")
      
      if [[ -z "$selected_worktree" ]]; then
        echo "No worktree selected"
        return 1
      fi
      
      local worktree_path="$project_path/$selected_worktree"
      
      # Step 3: Open in cursor
      if [[ -d "$worktree_path" ]]; then
        echo "Opening $worktree_path in Cursor..."
        cursor "$worktree_path"
      else
        echo "Worktree path does not exist: $worktree_path"
        return 1
      fi
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
