function __z -d "Jump to a recent directory."
    function __print_help -d "Print z help."
        printf "Usage: $Z_CMD  [-cdefhlprtvx] string1 string2...\n\n"
        printf "         -c --clean    Removes directories that no longer exist from $Z_DATA\n"
        printf "         -d --dir      Opens matching directory using system file manager.\n"
        printf "         -e --echo     Prints best match, no cd\n"
        printf "         -l --list     List matches and scores, no cd\n"
        printf "         -p --purge    Delete all entries from $Z_DATA\n"
        printf "         -r --rank     Search by rank\n"
        printf "         -t --recent   Search by recency\n"
        printf "         -f --fuzzy    Enable fuzzy fallback matching\n"
        printf "         -x --delete   Removes the current directory from $Z_DATA\n"
        printf "            --increase [N] Increase current directory weight (default: 10)\n"
        printf "            --decrease [N] Decrease current directory weight (default: 15)\n"
        printf "         -h --help     Print this help\n\n"
        printf "         -v --version  Print the z version\n"
    end
    function __z_legacy_escape_regex
        # taken from escape_string_pcre2 in fish
        # used to provide compatibility with fish 2
        for c in (string split -- '' $argv)
            if contains $c (string split '' '.^$*+()?[{}\\|-]')
                printf \\
            end
            printf '%s' $c
        end
    end

    function __z_pushd
        set -l cur (pwd)
        builtin cd $argv[1]; or return
        set -a dirstack (pwd)
        set -gx __z_dirprev $cur
    end

    set -l options h/help v/version c/clean e/echo l/list p/purge r/rank t/recent f/fuzzy d/directory x/delete increase= decrease=

    if test (count $argv) -eq 0
        __z_pushd
        return $status
    end

    if test (count $argv) -eq 1; and test -d "$argv[1]"
        __z_pushd "$argv[1]"
        return $status
    end

    if test (count $argv) -eq 1; and test "$argv[1]" = -
        __z_pushd $__z_dirprev
        return $status
    end

    if test (count $argv) -eq 1; and test "$argv[1]" = ".."
        __z_pushd ..
        return $status
    end

    if test (count $argv) -eq 1
        switch $argv[1]
            case --increase
                set argv --increase 10
            case --decrease
                set argv --decrease 15
        end
    end

    argparse $options -- $argv
    or begin
        __print_help >&2
        return 2
    end

    set -l fuzzy_enabled 0
    if set -q _flag_fuzzy; or string match -q -i -- true 1 yes "$Z_FUZZY"
        set fuzzy_enabled 1
    end

    if set -q _flag_help
        __print_help
        return 0
    else if set -q _flag_version
        printf "z %s\n" "$Z_VERSION"
        return 0
    else if set -q _flag_increase; or set -q _flag_decrease
        if set -q _flag_increase; and set -q _flag_decrease
            printf "Choose only --increase or --decrease\n" >&2
            return 2
        end
        set -l amount 10
        set -l direction 1
        if set -q _flag_decrease
            set amount 15
            set direction -1
        end
        set -l value
        if set -q _flag_increase
            set value $_flag_increase[1]
        else
            set value $_flag_decrease[1]
        end
        if test -n "$value"
            if not string match -rq '^[0-9]+$' -- "$value"
                printf "Weight adjustment must be a non-negative integer\n" >&2
                return 2
            end
            set amount $value
        end
        __z_adjust (math "$direction * $amount")
        return $status
    else if set -q _flag_clean
        __z_clean; or return $status
        printf "%s cleaned!\n" $Z_DATA
        return 0
    else if set -q _flag_purge
        command chmod 600 "$Z_DATA"; or return 1
        printf '' > "$Z_DATA"; or begin
            printf "Unable to purge %s\n" "$Z_DATA" >&2
            return 1
        end
        if test ! -z "$Z_OWNER"
            command chown $Z_OWNER:(id -ng $Z_OWNER) "$Z_DATA"; or return 1
        end
        printf "%s purged!\n" $Z_DATA
        return 0
    else if set -q _flag_delete
        set -l tmpfile (mktemp "$Z_DATA.XXXXXX"); or return 1
        set -l encoded_pwd (__z_encode_path "$PWD")
        awk -F "|" -v encoded_pwd="$encoded_pwd" '
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
            canonical($1) != encoded_pwd { print }
        ' "$Z_DATA" >"$tmpfile"
        or begin
            return 1
        end
        chmod 600 "$tmpfile"; or begin
            return 1
        end
        if test ! -z "$Z_OWNER"
            command chown $Z_OWNER:(id -ng $Z_OWNER) "$tmpfile"; or begin
                return 1
            end
        end
        mv "$tmpfile" "$Z_DATA"; or begin
            return 1
        end
        return 0
    end

    set -l typ

    if set -q _flag_rank
        set typ rank
    else if set -q _flag_recent
        set typ recent
    end

    set -l z_script '
        function frecent(rank, time) {
            dx = t-time
            if( dx < 0 ) dx = 0
            # Preserve the original time-band weights while interpolating.
            if( dx < 3600 ) return rank * 4 * exp(log(0.5) * dx / 3600)
            if( dx < 86400 ) return rank * 2 * exp(log(0.25) * (dx-3600) / (86400-3600))
            if( dx < 604800 ) return rank * 0.5 * exp(log(0.5) * (dx-86400) / (604800-86400))
            return rank * 0.25 * exp(-(dx-604800) / 604800)
        }

        function encode(path, out, i, c, slash) {
            out = ""
            slash = sprintf("%c", 92)
            for( i = 1; i <= length(path); i++ ) {
                c = substr(path, i, 1)
                if( c == "%" ) out = out "%25"
                else if( c == slash ) out = out "%5C"
                else if( c == "|" ) out = out "%7C"
                else if( c == "\n" ) out = out "%0A"
                else out = out c
            }
            return "v1:" out
        }

        function canonical(path) {
            if( substr(path, 1, 3) == "v1:" ) return path
            return encode(path)
        }

        function decode(path) {
            if( substr(path, 1, 3) != "v1:" ) return path
            path = substr(path, 4)
            gsub("%0A", "\n", path)
            gsub("%7C", "|", path)
            gsub("%5C", sprintf("%c", 92), path)
            gsub("%25", "%", path)
            return path
        }

        function better(score, path, current_score, current_path) {
            if( score > current_score ) return 1
            if( score < current_score ) return 0
            return current_path == "" || path < current_path
        }

        function edit_distance(a, b, i, j, la, lb, cost, value) {
            la = length(a)
            lb = length(b)
            for( i in ed_previous ) delete ed_previous[i]
            for( i in ed_current ) delete ed_current[i]
            for( j = 0; j <= lb; j++ ) ed_previous[j] = j
            for( i = 1; i <= la; i++ ) {
                ed_current[0] = i
                for( j = 1; j <= lb; j++ ) {
                    cost = substr(a, i, 1) != substr(b, j, 1)
                    value = ed_previous[j] + 1
                    if( ed_current[j-1] + 1 < value ) value = ed_current[j-1] + 1
                    if( ed_previous[j-1] + cost < value ) value = ed_previous[j-1] + cost
                    ed_current[j] = value
                }
                for( j = 0; j <= lb; j++ ) {
                    ed_previous[j] = ed_current[j]
                    delete ed_current[j]
                }
            }
            return ed_previous[lb]
        }

        function fuzzy_limit(term) {
            if( length(term) < 3 ) return 0
            if( length(term) <= 5 ) return 1
            return 2
        }

        function fuzzy_score(path, query, i, j, n, m, term, limit, best, distance, total) {
            for( i in fuzzy_terms ) delete fuzzy_terms[i]
            for( i in fuzzy_parts ) delete fuzzy_parts[i]
            n = split(query, fuzzy_terms, /[[:space:]]+/)
            m = split(path, fuzzy_parts, "/")
            total = 0
            for( i = 1; i <= n; i++ ) {
                term = tolower(fuzzy_terms[i])
                if( term == "" ) continue
                limit = fuzzy_limit(term)
                best = 999999
                for( j = 1; j <= m; j++ ) {
                    distance = edit_distance(term, tolower(fuzzy_parts[j]))
                    if( distance < best ) best = distance
                }
                if( best > limit ) return -1
                total += best
            }
            return total
        }

        function output(matches, best_match, common) {
            # list or return the desired directory
            if( list ) {
                while( 1 ) {
                    found = 0
                    for( x in matches ) if( matches[x] != "" &&
                        (!found || matches[x] > best_score ||
                        (matches[x] == best_score && x < best_path)) ) {
                        found = 1
                        best_score = matches[x]
                        best_path = x
                    }
                    if( !found ) break
                    printf "%s\t%s\t%s\n", weights[best_path], best_score, best_path
                    matches[best_path] = ""
                }
            } else {
                if( common ) best_match = common
                print best_match
            }
        }

        function common(matches, short, x, slash) {
            # find the common root of a list of matches, if it exists
            short = ""
            slash = sprintf("%c", 92)
            for( x in matches ) {
                if( matches[x] && (!short || length(x) < length(short)) ) {
                    short = x
                }
            }
            if( short == "/" ) return
            for( x in matches ) if( matches[x] && index(x, short) != 1 ) {
                    return
                }
            for( x in matches ) if( matches[x] && x != short &&
                    substr(x, length(short) + 1, 1) != "/" &&
                    substr(x, length(short) + 1, 1) != slash ) {
                    return
                }
            return short
        }

        BEGIN {
            hi_rank = ihi_rank = fuzzy_hi_rank = -9999999999
        }
        {
            if( typ == "rank" ) {
                rank = $2
            } else if( typ == "recent" ) {
                rank = $3 - t
            } else rank = frecent($2, $3)
            path = decode($1)
            weights[path] = $2
            if( path ~ q ) {
                if( !(path in matches) || rank > matches[path] ) matches[path] = rank
            } else if( tolower(path) ~ tolower(q) ) {
                if( !(path in imatches) || rank > imatches[path] ) imatches[path] = rank
            }
            if( fuzzy_enabled ) {
                fuzzy_distance = fuzzy_score(path, fuzzy_query)
                if( fuzzy_distance >= 0 ) {
                    fuzzy_rank = rank - fuzzy_distance
                    if( !(path in fuzzy_matches) || fuzzy_rank > fuzzy_matches[path] ) fuzzy_matches[path] = fuzzy_rank
                    if( better(fuzzy_matches[path], path, fuzzy_hi_rank, fuzzy_best_match) ) {
                        fuzzy_best_match = path
                        fuzzy_hi_rank = fuzzy_matches[path]
                    }
                }
            }
            if( path in matches && better(matches[path], path, hi_rank, best_match) ) {
                best_match = path
                hi_rank = matches[path]
            } else if( path in imatches && better(imatches[path], path, ihi_rank, ibest_match) ) {
                ibest_match = path
                ihi_rank = imatches[path]
            }
        }

        END {
        # prefer case sensitive
            if( best_match ) {
                output(matches, best_match, common(matches))
            } else if( ibest_match ) {
                output(imatches, ibest_match, common(imatches))
            } else if( fuzzy_best_match ) {
                output(fuzzy_matches, fuzzy_best_match, common(fuzzy_matches))
            }
        }
    '
    set -l fuzzy_query (string join ' ' -- $argv)

    set -l qs
    for arg in $argv
        set -l escaped $arg
        if string escape --style=regex '' >/dev/null 2>&1 # use builtin escape if available
            set escaped (string escape --style=regex -- $escaped)
        else
            set escaped (__z_legacy_escape_regex $escaped)
        end
        # Need to escape twice, see https://www.math.utah.edu/docs/info/gawk_5.html#SEC32
        set escaped (string replace --all -- \\ \\\\ $escaped)
        set qs $qs $escaped
    end
    set -l q (string join -- '.*' $qs)

    if set -q _flag_list
        # Handle list separately as it can print common path information to stderr
        # which cannot be captured from a subcommand.
        command awk -v t=(date +%s) -v list="list" -v typ="$typ" -v q="$q" -v fuzzy_enabled="$fuzzy_enabled" -v fuzzy_query="$fuzzy_query" -F "|" $z_script "$Z_DATA"
        return
    end

    set target (command awk -v t=(date +%s) -v typ="$typ" -v q="$q" -v fuzzy_enabled="$fuzzy_enabled" -v fuzzy_query="$fuzzy_query" -F "|" $z_script "$Z_DATA")

    if test "$status" -gt 0
        return
    end

    if test -z "$target"
        printf "'%s' did not match any results\n" "$argv"
        return 1
    end

    if set -q _flag_echo
        printf "%s\n" "$target"
    else if set -q _flag_directory
        if test -n "$ZO_METHOD"
            type -q "$ZO_METHOD"; and "$ZO_METHOD" "$target"; and return $status
            echo "Cannot open with ZO_METHOD set to $ZO_METHOD"; and return 1
        else if test "$OS" = Windows_NT
            if type -q explorer
                explorer "$target"
                return $status
            end
            echo "Cannot open file explorer"
            return 1
        else
            type -q xdg-open; and xdg-open "$target"; and return $status
            type -q open; and open "$target"; and return $status
            echo "Not sure how to open file manager"; and return 1
        end
    else
        __z_pushd "$target"
    end
end
