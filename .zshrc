#--------------------------------------------------------------------------------
# zsh settings
#--------------------------------------------------------------------------------
autoload -Uz compinit
compinit
#cdを付けなくてもディレクトリ名で移動
setopt auto_cd
#移動したディレクトリを記録
setopt auto_pushd
#タブキーで補完候補を順に表示
setopt auto_menu
#補完候補一覧でファイルの種別を識別マーク表示
setopt list_types
#コマンド訂正
setopt correct
#補完候補を詰めて表示
setopt list_packed
#ビープ音をならないように
setopt nolistbeep
setopt no_beep
# コマンドラインの引数で --prefix=/usr などの = 以降でも補完できる
setopt magic_equal_subst
# グロブ機能を拡張する
setopt extended_glob
# ファイルグロブで大文字小文字を区別しない
unsetopt caseglob
# グロブを数値順にソート
setopt numeric_glob_sort
# カーソル位置で補完
setopt complete_in_word

#EDITOR=vimの場合zshもvimバインドになるので明示指定
bindkey -e
#処理に時間がかかった場合に自動的に処理時間を表示する
# REPORTTIME=1
#moshでもsshと同じ補完がでるように
compdef mosh=ssh
#ターミナルでCtrl+sを押してしまった時にロックされるのを防ぐ
stty stop undef

#zmvコマンドを使用
autoload -Uz zmv

## Ctrl+G send-breakを無効化
bindkey -r '^G'
## Ctrl+S fwd-i-searchを無効化
bindkey -r '^S'

#----------------------------------------
# chpwd_recent_dirs & cdr
#----------------------------------------

if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
    autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':completion:*:*:cdr:*:*' menu selection
    zstyle ':completion:*' recent-dirs-insert both
    zstyle ':chpwd:*' recent-dirs-max 500
    zstyle ':chpwd:*' recent-dirs-default true
fi

#----------------------------------------
# completion style
#----------------------------------------

# 補完時に大文字小文字を区別しない
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
# 補完の種類
zstyle ':completion:*' completer _oldlist _complete _match _expand _prefix
# 補完一覧をカーソルで選択できるように
zstyle ':completion:*' menu select
# 補完の色
zstyle ':completion:*' format '%F{blue}%d%f'
# 補完候補をグループ分け
zstyle ':completion:*' group-name ''
# 補完候補に色を付ける
zstyle ':completion:*:default' list-colors ''
# 補完候補をキャッシュする。
zstyle ':completion:*' use-cache yes

#----------------------------------------
# prompt settings
#----------------------------------------

#branch名を表示する
autoload -Uz add-zsh-hook
autoload -Uz colors
colors
autoload -Uz vcs_info

zstyle ':vcs_info:*' enable git svn hg bzr
zstyle ':vcs_info:*' formats '[%b]'
zstyle ':vcs_info:*' actionformats '[%b|%a]'
zstyle ':vcs_info:(svn|bzr):*' branchformat '%b:r%r'
zstyle ':vcs_info:bzr:*' use-simple true
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "+" # 追加の変更点があったときの文字
zstyle ':vcs_info:git:*' unstagedstr "-"  # 削除の変更点が会った時の文字
zstyle ':vcs_info:git:*' formats '[%b] %c%u'
zstyle ':vcs_info:git:*' actionformats '[%b|%a] %c%u'

function git_prompt_stash_count {
    local COUNT=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
    if [ "$COUNT" -gt 0 ]; then
        echo " stash($COUNT)"
    fi
}

function _update_vcs_info_msg() {
    psvar=()
    LANG=en_US.UTF-8 vcs_info
    [[ -n "$vcs_info_msg_0_" ]] && psvar[1]="$vcs_info_msg_0_"
    psvar[2]=`git_prompt_stash_count`
}
add-zsh-hook precmd _update_vcs_info_msg

# プロンプト
PROMPT="%F{cyan}[%D{%m/%d %T}] %1(v|%F{green}%1v%f%F{yellow}%2v%f|) [%~]
%{[31m%}%n%%%{[m%} "

# 複数行でのプロンプトの左側
PROMPT2="%{[31m%}%_%%%{[m%} "

# 入力ミスの確認
SPROMPT="%{[31m%}%r is correct? [n,y,a,e]:%{[m%} "

# ssh接続時はホスト名を表示
[ -n "${REMOTEHOST}${SSH_CONNECTION}" ] &&
    PROMPT="%{[37m%}${HOST%%.*} ${PROMPT}"


#ターミナルのタイトルの設定
case "${TERM}" in
kterm*|xterm)
    precmd() {
        echo -ne "\033]0;${USER}@${HOST%%.*}:${PWD}\007"
    }
    ;;
esac
#----------------------------------------
# history settings
#----------------------------------------

HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
# 履歴が重複していたら最新のもののみ保存
setopt hist_ignore_all_dups
setopt hist_ignore_dups     # ignore duplication command history list
setopt share_history        # share command history data
# スペースで始まるコマンドは履歴に保存しない
setopt hist_ignore_space
#履歴にタイムスタンプや実行時間を含める
setopt extended_history
#履歴検索
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end

bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

#--------------------------------------------------------------------------------
# alias and function settings
alias relogin='exec $SHELL -l'
#--------------------------------------------------------------------------------


#----------------------------------------
# functions
#----------------------------------------

# lsした時にファイル数が多かったら省略する
ls_abbrev() {
    # -C : Force multi-column output.
    # -F : Append indicator (one of */=>@|) to entries.
    local cmd_ls='ls'
    local -a opt_ls
    opt_ls=('-CF' '--color=always')
    case "${OSTYPE}" in
        freebsd*|darwin*)
            if type gls > /dev/null 2>&1; then
                cmd_ls='gls'
            else
                # -G : Enable colorized output.
                opt_ls=('-CFG')
            fi
            ;;
    esac

    local ls_result
    ls_result=$(CLICOLOR_FORCE=1 COLUMNS=$COLUMNS command $cmd_ls ${opt_ls[@]} | sed $'/^\e\[[0-9;]*m$/d')

    local ls_lines=$(echo "$ls_result" | wc -l | tr -d ' ')

    if [ $ls_lines -gt 10 ]; then
        echo "$ls_result" | head -n 5
        echo '...'
        echo "$ls_result" | tail -n 5
        echo "$(command ls -1 -A | wc -l | tr -d ' ') files exist"
    else
        echo "$ls_result"
    fi
}

#cdした後に自動的にls
typeset -ga chpwd_functions
chpwd_functions+=ls_abbrev


# 圧縮ファイルの解凍
function extract() {
    case $1 in
        *.tar.gz|*.tgz) tar xzvf $1;;
        *.tar.xz) tar Jxvf $1;;
        *.zip) unzip $1;;
        *.lzh) lha e $1;;
        *.tar.bz2|*.tbz) tar xjvf $1;;
        *.tar.Z) tar zxvf $1;;
        *.gz) gzip -dc $1;;
        *.bz2) bzip2 -dc $1;;
        *.Z) uncompress $1;;
        *.tar) tar xvf $1;;
        *.arj) unarj $1;;
    esac
}

# プロンプトで何も打たずにEnterキーを押すとlsとgit statusを表示する
# http://qiita.com/yuyuchu3333/items/e9af05670c95e2cc5b4d
function do_enter() {
    if [ -n "$BUFFER" ]; then
        zle accept-line
        return 0
    fi
    echo
    ls_abbrev
    if [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" = 'true' ]; then
        echo
        echo -e "\e[0;33m--- git status ---\e[0m"
        git status -sb
    fi
    echo
    zle reset-prompt
    return 0
}
zle -N do_enter
bindkey '^m' do_enter

#mkdirしてcd
function mkcd() {
    mkdir $1 && cd $_
}

#----------------------------------------
# alias
#----------------------------------------

#上書きを防ぐ
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

#圧縮ファイルを実行すると解凍するように
alias -s {gz,tgz,zip,lzh,bz2,tbz,Z,tar,arj,xz}=extract

#lsを色付き表示
case $(uname) in
    *BSD|Darwin)
    alias ls="ls -G"
    ;;
    *)
    alias ls="ls --color=auto"
    ;;
esac

#詳細表示
alias ll="ls -AlhFv"

# ^ で cd ..
# ^を入力したいときはCtrl-V
function cdup() {
    echo
    cd ..
    zle reset-prompt
}
zle -N cdup
bindkey '\^' cdup

#cdする前の場所に戻る
alias pd='popd'

# L でページャー起動
alias -g L="|& $PAGER"

#ブラックホール
alias -g NL=">/dev/null"
alias -g NLL=">/dev/null 2>&1"

#上の階層
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'
alias -g .......='../../../../../..'
alias -g ........='../../../../../../..'
alias -g .........='../../../../../../../..'
alias -g ..........='../../../../../../../../..'
alias -g ...........='../../../../../../../../../..'

#Ubuntuでもopenで開けるように
if type gnome-open > /dev/null 2>&1; then
    alias open="gnome-open"
fi

alias g='git'

alias zmv='noglob zmv -W'

#----------------------------------------
# encoding function
#----------------------------------------

function utf8(){
    nkf -w --overwrite $1
}
function sjis(){
    nkf -s --overwrite $1
}

#----------------------------------------
# git settings
#----------------------------------------

#git ルートディレクトリのパスを表示
alias git-root="git rev-parse --show-toplevel"

#git ルートディレクトリに移動
function cd-git-root() {
    cd `git-root`
}

#----------------------------------------
# tmux settings
#----------------------------------------

# #常に -2 オプションで起動するように (強制的に端末が256色だと認識させる)
# alias tmux='tmux -2'
#
# #tmuxの自動起動
# if [ -z "$PS1" ] ; then return ; fi
#
# if [ -z $TMUX ] ; then
#     tmuxls=`tmux ls`
#     if [ -z $tmuxls ] ; then
#             tmux
#     else
#             tmux attach
#     fi
# fi
#
# #tmuxのプレフィックスを任意のキーに変更
# function tmux-set-prefix(){
#     tmux set-option -g prefix $1
# }
#
# #tmuxのプレフィックスをC-bに変更
# function tmux-change-prefix(){
#     tmux-set-prefix C-b
# }
#
# #tmuxのプレフィックスをC-tに戻す
# function tmux-reset-prefix(){
#     tmux-set-prefix C-t
#  }

#----------------------------------------
# peco
#----------------------------------------

# source ~/.zsh/peco.zsh

#----------------------------------------
# fzf
#----------------------------------------

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh && source ~/.zsh/fzf.zsh

