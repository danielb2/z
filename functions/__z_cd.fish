function __z_cd -d "Change directory and track the previous directory"
    set -l cur (pwd)
    builtin cd -- $argv[1]; or return
    set -gx __z_dirprev $cur
end
