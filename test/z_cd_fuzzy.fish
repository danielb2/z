set -e Z_CMD ZO_CMD Z_DATA Z_DATA_DIR Z_EXCLUDE Z_OPTS Z_OWNER
set -gx Z_CMD cd
set -gx Z_DATA (mktemp)
source (path dirname (status filename))/../conf.d/z.fish

set -l root (mktemp -d)
mkdir -p "$root/books"
printf "%s|1|%s\n" (__z_encode_path "$root/books") (date +%s) >> "$Z_DATA"
builtin cd "$root"

@test "cd -f finds a one-edit fuzzy match" "$root/books" = (cd -f book; and echo $PWD)
builtin cd "$root"
set -l before $PWD
cd -f booq >/dev/null 2>&1
set -l booq_status $status
@test "cd -f finds booq as a two-edit fuzzy match" 0 = $booq_status
@test "cd -f changes directory for booq" "$root/books" = "$PWD"
builtin cd "$root"
cd -f boop >/dev/null 2>&1
set -l boop_status $status
@test "cd -f finds boop as a two-edit fuzzy match" 0 = $boop_status
@test "cd -f changes directory for boop" "$root/books" = "$PWD"
