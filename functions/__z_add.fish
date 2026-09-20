function __z_add -d "Add PATH to .z file"
    test -n "$fish_private_mode"; and return 0

    for i in $Z_EXCLUDE
        if string match -r $i $PWD >/dev/null
            return 0 #Path excluded
        end
    end

    set -l tmpfile (mktemp $Z_DATA.XXXXXX)

    if test -f $tmpfile
        set -l path (__z_encode_path "$PWD")
        command awk -v path="$path" -v now=(date +%s) -F "|" '
      BEGIN {
          rank[path] = 1
          time[path] = now
      }
      $2 >= 1 {
          if( $1 == path ) {
              rank[$1] = $2 + 1
              time[$1] = now
          }
          else {
              rank[$1] = $2
              time[$1] = $3
          }
          count += $2
      }
      END {
          if( count > 1000 ) {
              for( i in rank ) print i "|" 0.9*rank[i] "|" time[i] # aging
          }
          else for( i in rank ) print i "|" rank[i] "|" time[i]
      }
    ' $Z_DATA 2>/dev/null >$tmpfile

        if test $status -ne 0
            rm -f "$tmpfile"
            printf "Unable to update %s\n" "$Z_DATA" >&2
            return 1
        end

        chmod 600 "$tmpfile"; or begin
            rm -f "$tmpfile"
            printf "Unable to protect %s\n" "$Z_DATA" >&2
            return 1
        end
        if test ! -z "$Z_OWNER"
            chown $Z_OWNER:(id -ng $Z_OWNER) "$tmpfile"; or begin
                rm -f "$tmpfile"
                printf "Unable to set owner on %s\n" "$Z_DATA" >&2
                return 1
            end
        end
        command mv "$tmpfile" "$Z_DATA"; or begin
            rm -f "$tmpfile"
            printf "Unable to replace %s\n" "$Z_DATA" >&2
            return 1
        end
    end
end
