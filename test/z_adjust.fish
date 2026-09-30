set -e Z_CMD ZO_CMD Z_DATA Z_DATA_DIR Z_EXCLUDE Z_OPTS Z_OWNER
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

function listed_score
    z -l | awk -F '\t' -v p="$adjust_dir" '$2 == p {print $1; exit}'
end

@test "increase adds an explicit ten to an isolated score" 0 -eq (
    reset_adjust_store
    set before (listed_score)
    z --increase 10
    set after (listed_score)
    awk -v before="$before" -v after="$after" 'BEGIN {exit (after - before >= 9.99 && after - before <= 10.01) ? 0 : 1}'
    echo $status
)

@test "increase defaults to ten on an isolated score" 0 -eq (
    reset_adjust_store
    set before (listed_score)
    z --increase
    set after (listed_score)
    awk -v before="$before" -v after="$after" 'BEGIN {exit (after - before >= 9.99 && after - before <= 10.01) ? 0 : 1}'
    echo $status
)

@test "decrease subtracts an explicit amount from an isolated score" 0 -eq (
    reset_adjust_store
    z --increase 20
    set before (listed_score)
    z --decrease 5
    set after (listed_score)
    awk -v before="$before" -v after="$after" 'BEGIN {exit (before - after >= 4.99 && before - after <= 5.01) ? 0 : 1}'
    echo $status
)

@test "decrease defaults to fifteen on an isolated score" 0 -eq (
    reset_adjust_store
    z --increase 20
    set before (listed_score)
    z --decrease
    set after (listed_score)
    awk -v before="$before" -v after="$after" 'BEGIN {exit (before - after >= 14.99 && before - after <= 15.01) ? 0 : 1}'
    echo $status
)

@test "weight adjustment does not change directory" "$adjust_dir" = (
    reset_adjust_store
    set before $PWD
    z --increase
    echo $PWD
)
