if status is-interactive
    set -g fish_greeting
    fish_add_path --path ~/.npm-global/bin
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    if test "$TERM" = xterm-kitty; and type -q fastfetch
        fastfetch
    end
end
