function __z_complete -d "add completions"
    complete -e $Z_CMD
    function __z_complete_options
        set -l zdata ($Z_CMD -l | cut -d' ' -f2- | awk -F / '{print $NF}' )
        if not set -q comp[1]
            set comp (commandline -ct | string replace -r -- '^-[^=]*=' '' $comp)
        end
        set -l dirs (complete -C"'' $comp" | string match -r '.*/$')

        printf "%s\n" $dirs\t./
        printf "%s\n" $zdata\t
    end

    complete -c $Z_CMD -s c -l clean -d "Cleans out $Z_DATA"
    complete -c $Z_CMD -s e -l echo -d "Prints best match, no cd"
    complete -c $Z_CMD -s l -l list -d "List matches, no cd"
    complete -c $Z_CMD -s p -l purge -d "Purges $Z_DATA"
    complete -c $Z_CMD -s r -l rank -d "Searches by rank, cd"
    complete -c $Z_CMD -s t -l recent -d "Searches by recency, cd"
    complete -c $Z_CMD -s h -l help -d "Print help"
    complete -c $Z_CMD -s x -l delete -d "Removes the current directory from $Z_DATA"
    complete -c $Z_CMD -d dir -f -a "(__z_complete_options)"
    complete -c $ZO_CMD -d dir -f -a "(__z_complete_options)"
end
