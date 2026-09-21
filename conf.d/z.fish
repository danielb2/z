if test -z "$Z_DATA"
    if test -z "$XDG_DATA_HOME"
        set -U Z_DATA_DIR "$HOME/.local/share/z"
    else
        set -U Z_DATA_DIR "$XDG_DATA_HOME/z"
    end
    set -U Z_DATA "$Z_DATA_DIR/data"
end
set -U Z_DATA_DIR (path dirname -- "$Z_DATA")

if test ! -e "$Z_DATA"
    if test ! -e "$Z_DATA_DIR"
        mkdir -p -m 700 "$Z_DATA_DIR"; or begin
            printf "Unable to create z data directory: %s\n" "$Z_DATA_DIR" >&2
            return 1
        end
    end
    touch "$Z_DATA"; or begin
        printf "Unable to create z data file: %s\n" "$Z_DATA" >&2
        return 1
    end
end
chmod 600 "$Z_DATA"; or begin
    printf "Unable to protect z data file: %s\n" "$Z_DATA" >&2
    return 1
end

function __z_encode_path
    set -l value "$argv[1]"
    set value (string replace --all -- '%' '%25' "$value")
    set -l slash (printf '\\')
    set value (string replace --all -- "$slash" '%5C' "$value")
    set value (string replace --all -- '|' '%7C' "$value")
    set -l newline (printf '\n' | string collect --no-trim)
    set value (string replace --all -- "$newline" '%0A' "$value")
    printf 'v1:%s\n' "$value"
end

function __z_decode_path
    set -l value "$argv[1]"
    if not string match -q 'v1:*' -- "$value"
        printf '%s\n' "$value"
        return
    end
    set value (string sub -s 4 -- "$value")
    if not string match -q '*%*' -- "$value"
        printf '%s\n' "$value"
        return
    end
    set -l newline (printf '\n' | string collect --no-trim)
    set -l slash (printf '\\')
    set value (string replace --all -- '%0A' "$newline" "$value" | string collect)
    set value (string replace --all -- '%7C' '|' "$value" | string collect)
    set value (string replace --all -- '%5C' "$slash" "$value" | string collect)
    string replace --all -- %25 % "$value" | string collect
end

if test -z "$Z_CMD"
    set -U Z_CMD z
end

set -g Z_VERSION 3.0.0

set -U ZO_CMD "$Z_CMD"o

if test ! -z $Z_CMD
    function $Z_CMD -d "jump around"
        __z $argv
    end
end

if test ! -z $ZO_CMD
    function $ZO_CMD -d "open target dir"
        __z -d $argv
    end
end

if not set -q Z_EXCLUDE
    set -U Z_EXCLUDE "^$HOME\$"
else if contains $HOME $Z_EXCLUDE
    # Workaround: migrate old default values to a regex (see #90).
    set Z_EXCLUDE (string replace -r -- "^$HOME\$" '^'$HOME'$$' $Z_EXCLUDE)
end


function __z_on_variable_pwd --on-variable PWD
    __z_add
end

function __z_uninstall --on-event z_uninstall
    functions -e __z_on_variable_pwd
    functions -e $Z_CMD
    functions -e $ZO_CMD

    if test ! -z "$Z_DATA"
        printf "To completely erase z's data, remove:\n" >/dev/stderr
        printf "%s\n" "$Z_DATA" >/dev/stderr
    end

    set -e Z_CMD
    set -e ZO_CMD
    set -e Z_DATA
    set -e Z_EXCLUDE
end
