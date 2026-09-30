set -l repo (realpath (mktemp -d))
mkdir -p "$repo/child"
command git init -q "$repo"
cd "$repo/child"
__z .
@test "__z dot enters the git root" "$repo" = "$PWD"
