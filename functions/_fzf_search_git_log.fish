function _fzf_search_git_log --description "Search the output of git log and preview commits. Replace the current token with the selected commit hash."
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo '_fzf_search_git_log: Not in a git repository.' >&2
    else
        # see documentation for git format placeholders at https://git-scm.com/docs/git-log#Documentation/git-log.txt-emnem
        # %h gives you the abbreviated commit hash, which is useful for saving screen space, but we will have to expand it later below
        set log_fmt_str '%C(bold blue)%h%C(reset) - %C(cyan)%ad%C(reset) %C(yellow)%d%C(reset) %C(normal)%s%C(reset)  %C(dim normal)[%an]%C(reset)'
        set token (commandline --current-token)
        set base_commit (git rev-parse --verify $token 2>/dev/null)
        if test $status -ne 0
            set query $token
        end
        set selected_log_lines (
            git log --color=always --format=format:$log_fmt_str --date=short $base_commit | \
            _fzf_wrapper --ansi \
                --multi \
                --tiebreak=index \
                --preview='git show --color=always {1}' \
                # --query=(commandline --current-token) \
                --query=$query \
                $fzf_git_log_opts
        )
        if test $status -eq 0
            for line in $selected_log_lines
                set abbreviated_commit_hash (string split --max 1 " " $line)[1]
                set commit_hash (git rev-parse $abbreviated_commit_hash)
                set commit_hashes $commit_hashes $commit_hash
            end
            commandline --current-token --replace (string join ' ' $commit_hashes)
        end
    end

    commandline --function repaint
end
