function __z_clean -d "Clean up z data to remove paths no longer valid"
    set -l tmpfile (mktemp "$Z_DATA.XXXXXX"); or return 1

    while read -l line
        set -l fields (string split -m 2 '|' -- "$line")
        if test (count $fields) -ne 3
            continue
        end

        set -l path (__z_decode_path "$fields[1]")
        set -l stored_path "$fields[1]"
        if not string match -q 'v1:*' -- "$stored_path"
            set stored_path (__z_encode_path "$path")
        end
        if test -d "$path"
            printf "%s|%s|%s\n" "$stored_path" "$fields[2]" "$fields[3]"
        end
    end < "$Z_DATA" > "$tmpfile"; or return 1

    chmod 600 "$tmpfile"; or return 1
    if test ! -z "$Z_OWNER"
        chown $Z_OWNER:(id -ng $Z_OWNER) "$tmpfile"; or return 1
    end
    command mv "$tmpfile" "$Z_DATA"; or return 1
end
