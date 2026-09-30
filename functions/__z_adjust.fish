function __z_adjust -d "Adjust the current directory weight"
    set -l delta $argv[1]
    set -l encoded_pwd (__z_encode_path "$PWD")
    set -l now (date +%s)
    set -l tmpfile (mktemp "$Z_DATA.XXXXXX"); or return 1

    command awk -v path="$encoded_pwd" -v delta="$delta" -v now="$now" -F "|" '
        function encode(value, out, i, c, slash) {
            out = ""
            slash = sprintf("%c", 92)
            for( i = 1; i <= length(value); i++ ) {
                c = substr(value, i, 1)
                if( c == "%" ) out = out "%25"
                else if( c == slash ) out = out "%5C"
                else if( c == "|" ) out = out "%7C"
                else if( c == "\n" ) out = out "%0A"
                else out = out c
            }
            return "v1:" out
        }
        function canonical(value) {
            if( substr(value, 1, 3) == "v1:" ) return value
            return encode(value)
        }
        $2 >= 1 {
            stored = canonical($1)
            if( stored in rank ) {
                rank[stored] += $2
                if( $3 > time[stored] ) time[stored] = $3
            } else {
                rank[stored] = $2
                time[stored] = $3
            }
        }
        function factor(timestamp, dx) {
            dx = now - timestamp
            if( dx < 0 ) dx = 0
            if( dx < 3600 ) return 4 * exp(log(0.5) * dx / 3600)
            if( dx < 86400 ) return 2 * exp(log(0.25) * (dx-3600) / (86400-3600))
            if( dx < 604800 ) return 0.5 * exp(log(0.5) * (dx-86400) / (604800-86400))
            return 0.25 * exp(-(dx-604800) / 604800)
        }
        END {
            if( path in rank ) {
                rank[path] += delta / factor(time[path])
                if( rank[path] < 0 ) rank[path] = 0
            } else if( delta > 0 ) {
                rank[path] = delta / 4
                time[path] = now
            }
            for( stored in rank ) if( rank[stored] >= 0.000001 )
                print stored "|" rank[stored] "|" time[stored]
        }
    ' "$Z_DATA" >"$tmpfile"; or begin
        printf "Unable to update %s\n" "$Z_DATA" >&2
        return 1
    end

    chmod 600 "$tmpfile"; or begin
        printf "Unable to protect %s\n" "$Z_DATA" >&2
        return 1
    end
    if test -n "$Z_OWNER"
        command chown $Z_OWNER:(id -ng $Z_OWNER) "$tmpfile"; or begin
            printf "Unable to set owner on %s\n" "$Z_DATA" >&2
            return 1
        end
    end
    command mv "$tmpfile" "$Z_DATA"; or begin
        printf "Unable to replace %s\n" "$Z_DATA" >&2
        return 1
    end
end
