function __z_add -d "Add PATH to .z file"
    test -n "$fish_private_mode"; and return 0

    for i in $Z_EXCLUDE
        if string match -r $i $PWD >/dev/null
            return 0 #Path excluded
        end
    end

    set -l tmpfile (mktemp "$Z_DATA.XXXXXX"); or return 1

    if test -f "$tmpfile"
        set -l path (__z_encode_path "$PWD")
        command awk -v path="$path" -v now=(date +%s) -F "|" '
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
          }
          else {
              rank[stored] = $2
              time[stored] = $3
          }
          count += $2
      }
      END {
          rank[path] += 1
          time[path] = now
          if( count > 1000 ) {
              for( i in rank ) print i "|" 0.9*rank[i] "|" time[i]
          }
          else for( i in rank ) print i "|" rank[i] "|" time[i]
      }
    ' "$Z_DATA" 2>/dev/null >"$tmpfile"

        if test $status -ne 0
            printf "Unable to update %s\n" "$Z_DATA" >&2
            return 1
        end

        chmod 600 "$tmpfile"; or begin
            printf "Unable to protect %s\n" "$Z_DATA" >&2
            return 1
        end
        if test ! -z "$Z_OWNER"
            chown $Z_OWNER:(id -ng $Z_OWNER) "$tmpfile"; or begin
                printf "Unable to set owner on %s\n" "$Z_DATA" >&2
                return 1
            end
        end
        command mv "$tmpfile" "$Z_DATA"; or begin
            printf "Unable to replace %s\n" "$Z_DATA" >&2
            return 1
        end
    end
end
