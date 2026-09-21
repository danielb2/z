set -e Z_CMD ZO_CMD Z_DATA Z_DATA_DIR Z_EXCLUDE Z_OWNER Z_FUZZY
set -e fish_private_mode
set -gx Z_CMD z
set -gx ZO_CMD zo
set -gx Z_EXCLUDE
set -gx Z_OWNER
functions -e z
function z
    __z $argv
end

set -xg adjust_test_root (mktemp -d)
set -xg Z_DATA "$adjust_test_root/data"
set -xg adjust_dir "$adjust_test_root/target"
mkdir -p "$adjust_dir"

touch "$Z_DATA"

function reset_adjust_store
    printf '' > "$Z_DATA"
    cd "$adjust_dir"
    if test (count (stored_rank)) -eq 0
        __z_add
    end
end

function stored_rank
    set -l path (__z_encode_path "$adjust_dir")
    awk -F '|' -v p="$path" '$1 == p {print $2; exit}' "$Z_DATA"
end

@test "increase adds an explicit ten to an isolated row" 0 -eq (
    reset_adjust_store
    set before (stored_rank)
    z --increase 10
    set after (stored_rank)
    awk -v before="$before" -v after="$after" 'BEGIN {exit (before == 1 && after - before == 10) ? 0 : 1}'
    echo $status
)

@test "increase defaults to ten on an isolated row" 0 -eq (
    reset_adjust_store
    set before (stored_rank)
    z --increase
    set after (stored_rank)
    awk -v before="$before" -v after="$after" 'BEGIN {exit (before == 1 && after - before == 10) ? 0 : 1}'
    echo $status
)

@test "decrease subtracts an explicit amount from an isolated row" 0 -eq (
    reset_adjust_store
    z --increase 20
    set before (stored_rank)
    z --decrease 5
    set after (stored_rank)
    awk -v before="$before" -v after="$after" 'BEGIN {exit (before == 21 && before - after == 5) ? 0 : 1}'
    echo $status
)

@test "decrease defaults to fifteen and removes zero weight" 0 -eq (
    reset_adjust_store
    z --increase 14
    z --decrease
    set after (stored_rank)
    test (count $after) -eq 0
    echo $status
)

@test "weight adjustment does not change directory" "$adjust_dir" = (
    reset_adjust_store
    set before $PWD
    z --increase
    echo $PWD
)
