# Commands to run in interactive sessions can go here
if status is-interactive
    # No greeting
    set fish_greeting

    # Use starship
    function starship_transient_prompt_func
        starship module character
    end
    if test "$TERM" != "linux"
        starship init fish | source
        enable_transience
    end
    
    # Colors
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    # Aliases
    # kitty doesn't clear properly so we need to do this weird printing
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"
    alias pamcan pacman
    alias q 'qs -c ii'
    if test "$TERM" != "linux"
        alias ls 'eza --icons'
    end
    function restore_host_colors
        if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
            cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        end
    end

    if test "$TERM" = "xterm-kitty"
        function ssh
            kitten ssh $argv
            restore_host_colors
        end
    else
        function ssh
            command ssh $argv
            restore_host_colors
        end
    end

    # nix-shell wrapper to keep Fish shell and Starship config active
    function nix-shell
        if not contains -- --run $argv; and not contains -- --command $argv
            command nix-shell $argv --run fish
        else
            command nix-shell $argv
        end
    end
end
