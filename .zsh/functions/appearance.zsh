# Ghostty and Zed both follow the macOS appearance, so flipping it switches both.
theme-toggle() {
  command theme-toggle "$@"
}

# ZLE widget to allow binding to a hotkey in zsh (e.g. bindkey '^X^T' _theme_toggle_widget)
_theme_toggle_widget() {
  theme-toggle >/dev/null 2>&1
  zle reset-prompt
}
zle -N _theme_toggle_widget

