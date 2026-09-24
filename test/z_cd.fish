set -l root (mktemp -d)
mkdir -p "$root/from" "$root/to"
cd "$root/from"
__z_cd "$root/to"
@test "z cd changes to target" "$root/to" = "$PWD"
@test "z cd tracks previous directory" "$root/from" = "$__z_dirprev"
__z_cd "$__z_dirprev"
@test "z cd can return to previous directory" "$root/from" = "$PWD"
