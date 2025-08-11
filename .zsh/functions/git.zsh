worktree(){
  local cmd=$1

  if [[ -z $cmd ]]; then
    echo "Usage: worktree <command>"
    echo "Commands:"
    echo "  new <worktree_name> - Create a new worktree"
    echo "  open - Open an existing worktree using fzf"
    echo "  branch - Create a worktree from an existing branch using fzf"
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

  # Helper to open a path with the user's configured editor
  _open_with_editor() {
    local target_path="$1"
    if [[ -n "$EDITOR" ]]; then
      # Support EDITOR values with flags (e.g., "code -n")
      local -a editor_cmd
      editor_cmd=("${(z)EDITOR}")
      echo "Opening $target_path with ${editor_cmd[1]}..."
      "${editor_cmd[@]}" "$target_path"
    else
      echo "EDITOR is not set. Please set $EDITOR to your preferred editor (e.g., 'export EDITOR=\"code -n\"') and rerun."
      return 1
    fi
  }

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
      _open_with_editor "$worktree_path"
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
      
      # Step 3: Open in editor
      if [[ -d "$worktree_path" ]]; then
        _open_with_editor "$worktree_path"
      else
        echo "Worktree path does not exist: $worktree_path"
        return 1
      fi
      ;;
    branch)
      # Check if fzf is available
      if ! command -v fzf > /dev/null 2>&1; then
        echo "fzf is required but not installed. Please install fzf first."
        return 1
      fi
      
      # Get all branches (local and remote)
      local all_branches=$(git branch -a --format='%(refname:short)' | sed 's|origin/||' | sort -u)
      
      # Filter out HEAD and current branch
      local current_branch=$(git branch --show-current)
      local available_branches=$(echo "$all_branches" | grep -v "HEAD" | grep -v "^$current_branch$" | fzf --prompt="Select branch: ")
      
      if [[ -z "$available_branches" ]]; then
        echo "No branch selected"
        return 1
      fi
      
      # Check if branch exists locally, if not fetch it
      if ! git show-ref --verify --quiet refs/heads/"$available_branches"; then
        echo "Branch '$available_branches' not found locally. Fetching from remote..."
        git fetch origin "$available_branches":"$available_branches" 2>/dev/null || {
          echo "Failed to fetch branch '$available_branches' from remote"
          return 1
        }
      fi
      
      # Create worktree name (use branch name, but handle special characters)
      local worktree_name=$(echo "$available_branches" | sed 's/[^a-zA-Z0-9._-]/-/g')
      local worktree_path="$worktrees_dir/$worktree_name"
      
      # Check if worktree already exists
      if [[ -d "$worktree_path" ]]; then
        echo "Worktree '$worktree_name' already exists at $worktree_path"
        echo "Opening existing worktree..."
        _open_with_editor "$worktree_path"
        return 0
      fi
      
      # Create the worktree for the selected branch
      echo "Creating worktree for branch '$available_branches'..."
      git worktree add "$worktree_path" "$available_branches"
      
      if [[ $? -eq 0 ]]; then
        echo "Worktree created successfully at $worktree_path"
        _open_with_editor "$worktree_path"
      else
        echo "Failed to create worktree for branch '$available_branches'"
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
