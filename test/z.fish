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
mkdir -p "$pth/foo" "$pth/bar" "$pth/$special" "$pipe_path" "$newline_path" "$unicode_path" "$percent_path" "$common_a" "$common_b"
touch "$Z_DATA"

function cd_some
    z --clean
    for path in "$pth/foo" "$pth/bar" "$pth/$special" "$pipe_path" "$newline_path" "$unicode_path" "$percent_path" "$common_a" "$common_b"
        cd "$path"
    end
end

cd_some
printf "%s|4|1501234567\n" "$percent_path" >> "$Z_DATA"
__z_add

@test "legacy rows merge into one encoded row" 1 -eq (grep -c 'v1:.*literal%257Cpath|' "$Z_DATA")

@test ".z is created" -f $Z_DATA
@test "Z_CMD is set" ! -z $Z_CMD
@test "has foo" 0 -eq (grep -q foo $Z_DATA; echo $status)
@test "has bar" 0 -eq (grep -q bar $Z_DATA; echo $status)
@test "has special" 0 -eq (grep -qF $special $Z_DATA; echo $status)
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

@test "z -e foo" $pth/foo = (z -e foo)
@test "! z -e kid" 1 = (z -e kid >/dev/null; echo $status)
@test "z -h" 0 -eq (z -h | grep -q Usage; echo $status)
@test "help includes directory" 0 -eq (z -h | grep -q -- "--dir"; echo $status)
@test "help includes purge" 0 -eq (z -h | grep -q -- "--purge"; echo $status)
@test "invalid option fails" 2 -eq (z --not-an-option >/dev/null 2>/dev/null; echo $status)
@test "multi-term query has no test error" 0 -eq (z -e f oo 2>/dev/null | string match -q "$pth/foo"; echo $status)
@test "z foo" $pth/foo = (z foo; and echo $PWD)
@test "z bar" $pth/bar = (z bar; and echo $PWD)
@test "rank mode" $pth/foo = (z --rank -e foo)
@test "recent mode" $pth/foo = (z --recent -e foo)
@test "f oo" $pth/foo = (z f oo; and echo $PWD)
@test "fo oo" $pth/foo != (z fo oo; and echo $PWD)
@test "z kid" 1 = (z kid >/dev/null; echo $status)
@test "z special" 0 -eq (fish -c 'grep -qF $special $Z_DATA'; echo $status)
@test "z --list foo" $pth/foo = (z --list foo 2>/dev/null | awk '{ print $2} ')
@test "z -x works" 1 = (begin; z foo; and z -x; and cd ..; and z foo; end >/dev/null; echo $status)
set mode (stat -c '%a' $Z_DATA 2>/dev/null)
if test $status -ne 0
    set mode (stat -f '%Lp' $Z_DATA)
end
@test "data file is private" 600 -eq $mode

rm -rf $pth
