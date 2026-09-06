# git-prompt.zsh — zsh port of https://github.com/ezorita/git-prompt
#
# MIT License
# Copyright (c) 2018 eduard valera i zorita
# Zsh / macOS port: Copyright (c) 2026 Carles Javierre Petit
#
# Same behaviour as the bash script: branch, ahead/behind, repo-relative
# path, autofetch on cd / branch change / interval. Differences:
# - precmd hook instead of PROMPT_COMMAND
# - %{...%} color wraps instead of \[...\]
# - BSD and GNU stat (macOS + Linux)
# - tab-split for rev-list counts (no BASH_REMATCH)
#
# Source from ~/.zshrc:
#   source /path/to/git-prompt/git-prompt.zsh

[[ -n ${ZSH_VERSION:-} ]] || return 0

# zsh does not expand \033 in "...". Use $'\e' so the terminal gets ESC,
# then %{ %} so the width math ignores the codes.
setopt prompt_percent
typeset -g _gp_e=$'\e'
Color_Off="%{${_gp_e}[0m%}"
Black="%{${_gp_e}[0;35m%}"
Red="%{${_gp_e}[0;31m%}"
Green="%{${_gp_e}[0;32m%}"
Yellow="%{${_gp_e}[0;33m%}"
Blue="%{${_gp_e}[0;34m%}"
Purple="%{${_gp_e}[0;35m%}"
Cyan="%{${_gp_e}[0;36m%}"
White="%{${_gp_e}[0;37m%}"
BBlack="%{${_gp_e}[1;35m%}"
BRed="%{${_gp_e}[1;31m%}"
BGreen="%{${_gp_e}[1;32m%}"
BYellow="%{${_gp_e}[1;33m%}"
BBlue="%{${_gp_e}[1;34m%}"
BPurple="%{${_gp_e}[1;35m%}"
BCyan="%{${_gp_e}[1;36m%}"
BWhite="%{${_gp_e}[1;37m%}"

# Re-source must replace a first load that stored literal '\033'.
[[ ${User_color:-} == *$'\e'* ]] || User_color=$BGreen
[[ ${At_color:-} == *$'\e'* ]] || At_color=$Purple
[[ ${Host_color:-} == *$'\e'* ]] || Host_color=$BBlue
[[ ${Path_color:-} == *$'\e'* ]] || Path_color=$BPurple
[[ ${Branch_color:-} == *$'\e'* ]] || Branch_color=$Green
[[ ${Ahead_color:-} == *$'\e'* ]] || Ahead_color=$Green
[[ ${Behind_color:-} == *$'\e'* ]] || Behind_color=$Red
[[ ${NoSync_color:-} == *$'\e'* ]] || NoSync_color=$Red
[[ ${Fetch_color:-} == *$'\e'* ]] || Fetch_color=$'\e[0;32m'
[[ ${Git_color:-} == *$'\e'* ]] || Git_color=$White
[[ ${Prompt_color:-} == *$'\e'* ]] || Prompt_color=$White
[[ ${Prompt_error_color:-} == *$'\e'* ]] || Prompt_error_color=$BRed

Force_Default_Prompt=${Force_Default_Prompt:-1}

# Original README misspells AUTOFECTH. Accept both.
GIT_PROMPT=${GIT_PROMPT:-1}
GIT_AUTOFETCH=${GIT_AUTOFETCH:-${GIT_AUTOFECTH:-1}}
GIT_AUTOFETCH_INTERVAL=${GIT_AUTOFETCH_INTERVAL:-${GIT_AUTOFECTH_INTERVAL:-600}}
GIT_BRANCH_MAX_LENGTH=${GIT_BRANCH_MAX_LENGTH:-30}
GIT_BRANCH_TAIL_LENGTH=${GIT_BRANCH_TAIL_LENGTH:-5}

typeset -g GIT_ONLINE=1
typeset -g GIT_SSH_AGENT_STORED=0
typeset -g GIT_LAST_ROOT=""
typeset -g GIT_LAST_BRANCH=""
typeset -g GIT_LAST_FETCH
GIT_LAST_FETCH=$(date '+%s')
typeset -g LAST_EXIT_CODE=0
typeset -g GIT_PROMPT_SAVED_PROMPT="$PROMPT"

__git_prompt_escape() {
    # Percent signs in branch / path would be prompt-expanded.
    print -r -- "${1//\%/%%}"
}

__git_prompt_stat_mtime_size() {
    # Darwin: stat -f. Linux: stat -c. Do not use -f on Linux.
    local path="$1"
    case "$(uname -s)" in
        Darwin)
            stat -f '%m %z' "${path}" 2>/dev/null
            ;;
        *)
            stat -c '%Y %s' "${path}" 2>/dev/null
            ;;
    esac
}

__git_prompt_char() {
    if [[ ${LAST_EXIT_CODE} -ne 0 ]]; then
        print -r -- "${Prompt_error_color}\$${Color_Off} "
    else
        print -r -- "${Prompt_color}\$${Color_Off} "
    fi
}

__git_prompt_default() {
    local host_short="${HOST%%.*}"
    PROMPT="${User_color}$(__git_prompt_escape "${USER}")"
    PROMPT+="${At_color}@${Host_color}"
    PROMPT+="$(__git_prompt_escape "${host_short}")"
    PROMPT+=":${Path_color}$(__git_prompt_escape "${PWD}")"
    PROMPT+="${Color_Off}$(__git_prompt_char)"
    PS1="${PROMPT}"
}

__git_prompt_maybe_ssh_agent() {
    if [[ ${GIT_SSH_AGENT_STORED} -eq 0 && -n ${SSH_CONNECTION:-} ]]
    then
        print "Unlock ssh key to automatically fetch changes:"
        eval "$(ssh-agent)" >/dev/null
        if [[ -n ${GIT_SSH_PRIVATE_KEY:-} ]]; then
            ssh-add -q "${GIT_SSH_PRIVATE_KEY}"
        else
            ssh-add -q
        fi
        GIT_SSH_AGENT_STORED=1
    fi
}

__git_prompt_trim_branch() {
    local branch="$1"
    local max_len=${GIT_BRANCH_MAX_LENGTH}
    local tail_len=${GIT_BRANCH_TAIL_LENGTH}
    local max_tail start_len
    if (( ${#branch} <= max_len )); then
        print -r -- "${branch}"
        return
    fi
    max_tail=$((max_len - 2))
    (( tail_len > max_tail )) && tail_len=${max_tail}
    start_len=$((max_len - 1 - tail_len))
    print -r -- "${branch[1,start_len]}…${branch[-tail_len,-1]}"
}

__git_prompt_maybe_autofetch() {
    local git_branch="$1"
    local git_root="$2"
    local autofetch=0
    local last_fetch_out cur_time mtime size

    if [[ ${GIT_LAST_ROOT} != "${git_root}" ]]; then
        autofetch=1
        GIT_LAST_ROOT="${git_root}"
    fi
    if [[ ${GIT_LAST_BRANCH} != "${git_branch}" ]]; then
        autofetch=1
        GIT_LAST_BRANCH="${git_branch}"
    fi

    if [[ ${GIT_AUTOFETCH} -ne 1 ]]; then
        return
    fi

    if [[ ${autofetch} -eq 0 ]]; then
        last_fetch_out="$(
            __git_prompt_stat_mtime_size "${git_root}/.git/FETCH_HEAD"
        )"
        if [[ ${last_fetch_out} == [0-9]*' '[0-9]* ]]; then
            mtime="${last_fetch_out%% *}"
            size="${last_fetch_out##* }"
            if [[ ${size} != 0 ]]; then
                GIT_LAST_FETCH="${mtime}"
                GIT_ONLINE=1
            else
                GIT_ONLINE=0
            fi
        fi
        cur_time=$(date '+%s')
        if [[ -z ${GIT_LAST_FETCH} ]] \
            || (( cur_time - GIT_LAST_FETCH > GIT_AUTOFETCH_INTERVAL ))
        then
            autofetch=1
        fi
    fi

    if [[ ${autofetch} -eq 1 ]]; then
        printf '%s%s:fetch...\033[0m' "${Fetch_color}" "${git_branch}"
        if git fetch origin "${git_branch}" 2>&1 | grep -q fatal; then
            GIT_ONLINE=0
        else
            GIT_ONLINE=1
        fi
        GIT_LAST_FETCH=$(date '+%s')
        printf '\r\033[K'
    fi
}

__git_prompt_status() {
    local git_branch="$1"
    local git_upstream="$2"
    local counts ahead_n behind_n
    local status_string=""
    local sync_ok=1
    local ahead_s="" behind_s=""

    counts=$(
        git rev-list --left-right --count \
            "${git_branch}...${git_upstream}" 2>&1
    )
    if [[ ${counts} == *fatal* ]]; then
        sync_ok=0
    fi
    if [[ ${sync_ok} -eq 0 || ${GIT_ONLINE} -eq 0 ]]; then
        status_string+="${At_color}(${Color_Off}${NoSync_color}҂"
        status_string+="${Color_Off}${At_color})${Color_Off}"
    fi
    if [[ ${sync_ok} -eq 1 ]]; then
        ahead_n="${counts%%$'\t'*}"
        behind_n="${counts##*$'\t'}"
        if [[ ${ahead_n} != 0 ]]; then
            ahead_s="${Ahead_color}${ahead_n}↑${Color_Off}"
        fi
        if [[ ${behind_n} != 0 ]]; then
            behind_s="${Behind_color}${behind_n}↓${Color_Off}"
        fi
        if [[ -n ${ahead_s} && -n ${behind_s} ]]; then
            status_string+="${At_color}(${Color_Off}${ahead_s} ${behind_s}"
            status_string+="${At_color})${Color_Off}"
        elif [[ -n ${ahead_s} ]]; then
            status_string+="${At_color}(${Color_Off}${ahead_s}"
            status_string+="${At_color})${Color_Off}"
        elif [[ -n ${behind_s} ]]; then
            status_string+="${At_color}(${Color_Off}${behind_s}"
            status_string+="${At_color})${Color_Off}"
        fi
    fi
    print -r -- "${status_string}"
}

__git_prompt_draw() {
    local git_branch git_upstream git_root git_path display_branch
    local host_short="${HOST%%.*}"
    local repo_name suffix

    git_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @ 2>&1)
    if [[ ${git_branch} == *"ot a git repository"* ]]; then
        if [[ ${Force_Default_Prompt} -eq 1 ]]; then
            __git_prompt_default
        else
            PROMPT="${GIT_PROMPT_SAVED_PROMPT}"
            PS1="${PROMPT}"
        fi
        return
    fi

    __git_prompt_maybe_ssh_agent

    if [[ ${git_branch} == *"unknown revision"* ]]; then
        git_branch="init"
        git_upstream=""
    else
        git_upstream=$(
            git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>&1
        )
        if [[ ${git_upstream} == *"upstream configured"* ]]; then
            git_upstream=""
        fi
    fi

    git_root=$(git rev-parse --show-toplevel)
    if [[ -n ${git_upstream} ]]; then
        __git_prompt_maybe_autofetch "${git_branch}" "${git_root}"
    fi

    repo_name="${git_root:t}"
    suffix="${$(pwd -P)#${git_root}}"
    git_path="${repo_name}${suffix}"
    display_branch="$(__git_prompt_trim_branch "${git_branch}")"

    PROMPT="${Branch_color}$(__git_prompt_escape "${display_branch}")"
    PROMPT+="${Color_Off}"
    if [[ -n ${git_upstream} ]]; then
        PROMPT+="$(__git_prompt_status "${git_branch}" "${git_upstream}")"
    else
        PROMPT+="${At_color}(local)${Color_Off}"
    fi
    PROMPT+="${At_color}@${Color_Off}${Host_color}"
    PROMPT+="$(__git_prompt_escape "${host_short}")"
    PROMPT+="${Color_Off}${Git_color}:g~${Color_Off}${Path_color}"
    PROMPT+="$(__git_prompt_escape "${git_path}")"
    PROMPT+="${Color_Off}$(__git_prompt_char)"
    PS1="${PROMPT}"
}

__git_prompt_precmd() {
    LAST_EXIT_CODE=$?
    if [[ ${GIT_PROMPT} -eq 0 ]]; then
        PROMPT="${GIT_PROMPT_SAVED_PROMPT}"
        PS1="${PROMPT}"
        return
    fi
    if ! command -v git >/dev/null 2>&1; then
        if [[ ${Force_Default_Prompt} -eq 1 ]]; then
            __git_prompt_default
        fi
        return
    fi
    __git_prompt_draw
}

gitpr() {
    if [[ ${GIT_PROMPT} -eq 1 ]]; then
        GIT_PROMPT=0
    else
        GIT_PROMPT=1
    fi
}

autoload -Uz add-zsh-hook
if [[ -z ${GIT_PROMPT_HOOKED:-} ]]; then
    add-zsh-hook precmd __git_prompt_precmd
    typeset -g GIT_PROMPT_HOOKED=1
fi
