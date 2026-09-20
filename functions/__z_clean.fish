function __z_clean -d "Clean up .z file to remove paths no longer valid"
    set -l tmpfile (mktemp $Z_DATA.XXXXXX); or return 1

    if test -f $tmpfile
        while read -l line
            set -l fields (string split -m 2 '|' -- "$line")
            set -l path (__z_decode_path "$fields[1]")
            if test (count $fields) -eq 3; and test -d "$path"
                printf "%s|%s|%s\n" (__z_encode_path "$path") "$fields[2]" "$fields[3]"
            end
        end < "$Z_DATA" > "$tmpfile"; or begin
            rm -f "$tmpfile"
            return 1
        end
        chmod 600 "$tmpfile"; or begin
            rm -f "$tmpfile"
            return 1
        end
        if test ! -z "$Z_OWNER"
            chown $Z_OWNER:(id -ng $Z_OWNER) "$tmpfile"; or begin
                rm -f "$tmpfile"
                return 1
            end
        end
        command mv -f "$tmpfile" "$Z_DATA"; or begin
            rm -f "$tmpfile"
            return 1
        end
    end
end
