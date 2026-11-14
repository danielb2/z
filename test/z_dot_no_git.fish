set -l root (mktemp -d)
mkdir -p "$root/child"
cd "$root/child"
set -l before $PWD
functions -e __jump_add __z_on_variable_pwd __zoxide_hook
set -lx PATH "$root/no-git"
__z .
@test "__z dot stays put without git" "$before" = "$PWD"
