set -l empty_path (mktemp -d)
set -lx PATH "$empty_path"
functions -e __z_on_variable_pwd __zoxide_hook __jump_add
set output (__z --interactive 2>&1)
set result_status $status
@test "interactive warns when fzf is unavailable" 127 = $result_status
@test "interactive warning names fzf" 0 -eq (string match -q '*fzf*' -- "$output"; echo $status)
