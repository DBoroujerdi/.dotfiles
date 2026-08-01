#!/bin/sh
# Launch bootstrap.py with the first python3 that has tomllib (3.11+).
# macOS ships /usr/bin/python3 3.9, which does not, so a bare `python3` on the
# server's PATH is not enough. Override with WT_PYTHON if needed.
set -eu

dir=$(dirname "$0")

for candidate in \
  "${WT_PYTHON:-}" \
  python3 \
  python3.14 python3.13 python3.12 python3.11 \
  /opt/homebrew/bin/python3 \
  /usr/local/bin/python3; do
  [ -n "$candidate" ] || continue
  command -v "$candidate" >/dev/null 2>&1 || continue
  "$candidate" -c 'import tomllib' >/dev/null 2>&1 || continue
  exec "$candidate" "$dir/bootstrap.py" "$@"
done

echo "[wt] error: no python3 with tomllib (3.11+) found on PATH" >&2
exit 1
