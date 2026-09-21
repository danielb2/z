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

set -xg pth (mktemp -d)
mkdir -p "$pth/data dir"
set -xg Z_DATA "$pth/data dir/.z"
set -xg special '(){}#$%^<>?*"\'\\ &	'
set -xg pipe_path "$pth/pipe|path"
set -xg newline_path "$pth/new\nline"
set -xg unicode_path "$pth/日本語"
set -xg percent_path "$pth/literal%7Cpath"
set -xg common_a "$pth/common-a"
set -xg common_b "$pth/common-b"
mkdir -p "$pth/foo" "$pth/bar" "$pth/$special" "$pipe_path" "$unicode_path" "$percent_path" "$common_a" "$common_b"
touch "$Z_DATA"

function cd_some
    z --clean
    for path in "$pth/foo" "$pth/bar" "$pth/$special" "$pipe_path" "$unicode_path" "$percent_path" "$common_a" "$common_b"
        cd "$path"
    end
end

cd_some
printf "v1:%s/new%%0Aline|1|%s\n" "$pth" (date +%s) >> "$Z_DATA"
printf "%s|4|1501234567\n" "$percent_path" >>"$Z_DATA"
__z_add

@test "legacy rows merge into one encoded row" 1 -eq (grep -c 'v1:.*literal%257Cpath|' "$Z_DATA")

@test ".z is created" -f $Z_DATA
@test "Z_CMD is set" ! -z $Z_CMD
@test "has foo" 0 -eq (grep -q foo $Z_DATA; echo $status)
@test "help includes fuzzy option" 0 -eq (z -h | grep -q -- "--fuzzy"; echo $status)
@test "version prints command version" 0 -eq (z --version | grep -q '^z 3.0.0$'; echo $status)
@test "version does not change directory" "$PWD" = (z --version >/dev/null; echo $PWD)
@test "has bar" 0 -eq (grep -q bar $Z_DATA; echo $status)
@test "has special" "$pth/$special" = (z -e "$special")
@test "encoded pipe path" 0 -eq (grep -q '%7C' $Z_DATA; echo $status)
@test "encoded newline path" 0 -eq (grep -q '%0A' $Z_DATA; echo $status)
@test "encoded literal percent path" 0 -eq (grep -q 'literal%257Cpath' $Z_DATA; echo $status)
@test "literal percent path is searchable" "$percent_path" = (z -e 'literal%7Cpath')
@test "multiple matches parse safely" 0 -eq (z -e common >/dev/null; echo $status)
@test "! has kid" 1 -eq (grep -q kid $Z_DATA; echo $status)
@test "z --purge" -z (z --purge > /dev/null; cat $Z_DATA)
@test "z --clean" 1 -eq (
        echo '$pth/invalid_path|1|1501234567' >> $Z_DATA;
        z --clean > /dev/null;
        grep -q invalid_path $Z_DATA;
        echo $status
     )
cd_some
__z --clean >/dev/null
@test "clean preserves live entries" 0 -eq (grep -q 'foo' "$Z_DATA"; echo $status)
set live_dir "$pth/cleanup-live"
set stale_dir "$pth/cleanup-stale"
mkdir -p "$live_dir"
cd "$live_dir"
__z_add
printf "%s|1|%s\n" (__z_encode_path "$stale_dir") (date +%s) >> "$Z_DATA"
cd "$pth"
__z --clean >/dev/null
@test "clean keeps a live directory" 0 -eq (grep -q 'cleanup-live' "$Z_DATA"; echo $status)
@test "clean removes a deleted directory" 1 -eq (grep -q 'cleanup-stale' "$Z_DATA"; echo $status)

@test "z -e foo" $pth/foo = (z -e foo)
@test "! z -e kid" 1 = (z -e kid >/dev/null; echo $status)
@test "z -h" 0 -eq (z -h | grep -q Usage; echo $status)
@test "help includes directory" 0 -eq (z -h | grep -q -- "--dir"; echo $status)
@test "help includes purge" 0 -eq (z -h | grep -q -- "--purge"; echo $status)
@test "invalid option fails" 2 -eq (z --not-an-option >/dev/null 2>/dev/null; echo $status)
@test "multi-term query has no test error" 0 -eq (z -e f oo 2>/dev/null | string match -q -- "$pth/foo"; echo $status)
@test "z foo" $pth/foo = (z foo; and echo $PWD)
@test "fuzzy matching is disabled by default" 1 -eq (z -e fooo >/dev/null; echo $status)
@test "fuzzy switch finds one-edit match" $pth/foo = (z --fuzzy -e fooo)
set -gx Z_FUZZY true
@test "Z_FUZZY enables fuzzy matching" $pth/foo = (z -e fooo)
set -e Z_FUZZY
@test "z bar" $pth/bar = (z bar; and echo $PWD)
@test "rank mode" $pth/foo = (z --rank -e foo)
@test "recent mode" $pth/foo = (z --recent -e foo)
@test "f oo" $pth/foo = (z f oo; and echo $PWD)
@test "fo oo" $pth/foo = (z fo oo; and echo $PWD)
@test "z kid" 1 = (z kid >/dev/null; echo $status)
@test "special path encoding round trips" "$pth/$special" = (__z_decode_path (__z_encode_path "$pth/$special"))
@test "z --list foo succeeds" 0 -eq (z --list foo >/dev/null 2>/dev/null; echo $status)
cd "$pth/foo"
z -x >/dev/null
@test "z -x removes current directory" 1 -eq (grep -qF -- "$pth/foo" "$Z_DATA"; echo $status)
set mode (stat -c '%a' $Z_DATA 2>/dev/null)
if test $status -ne 0
    set mode (stat -f '%Lp' $Z_DATA)
end
@test "data file is private" 600 -eq $mode
