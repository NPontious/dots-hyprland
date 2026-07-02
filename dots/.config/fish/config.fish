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
    else if test -f ~/.local/state/quickshell/user/generated/terminal/headless-sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/headless-sequences.txt
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
        else if test -f ~/.local/state/quickshell/user/generated/terminal/headless-sequences.txt
            cat ~/.local/state/quickshell/user/generated/terminal/headless-sequences.txt
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

    # Automatically fetch remote git changes in the background when entering a directory
    function __auto_git_fetch --on-variable PWD
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1
            command git fetch --quiet >/dev/null 2>&1 &
        end
    end
    __auto_git_fetch

    # Helper command to generate and apply Material You shell colors from hex code, image path, or web image URL on headless machines
    function settheme --description "Set headless shell theme from hex color, image file, or web URL"
        if test (count $argv) -eq 0
            echo "Usage: settheme <hex-color | image-path | image-url> [matugen-options...]"
            echo "Examples:"
            echo "  settheme '#8caaee'"
            echo "  settheme https://example.com/desolo.png --type scheme-expressive"
            echo "  settheme ~/Pictures/wallpaper.png"
            return 1
        end
        if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
            echo "Note: GUI environment detected. For best results on desktop, use 'switchwall.sh' instead."
            return 1
        end

        set -l target $argv[1]
        set -l extra_args $argv[2..-1]

        if string match -r '^https?://' -- $target >/dev/null
            echo "Downloading image from $target..."
            mkdir -p ~/.cache
            set -l cache_img ~/.cache/settheme_downloaded_image
            if command -v curl >/dev/null
                curl -sSL "$target" -o "$cache_img"
            else
                wget -q "$target" -O "$cache_img"
            end
            if test -s "$cache_img"
                matugen image "$cache_img" $extra_args
            else
                echo "Error: Failed to download image from URL."
                return 1
            end
        else if test -f "$target"
            matugen image "$target" $extra_args
        else if string match -r '\.(jpe?g|png|webp|gif|bmp|tiff?)$' -i -- $target >/dev/null
            echo "Error: Image file '$target' not found."
            return 1
        else if string match -r '^#?[0-9a-fA-F]{3,8}$' -- $target >/dev/null
            matugen color hex "$target" $extra_args
        else
            echo "Error: '$target' is not a valid file path, web URL, or hex color."
            return 1
        end

        if test -f ~/.local/state/quickshell/user/generated/terminal/headless-sequences.txt
            cat ~/.local/state/quickshell/user/generated/terminal/headless-sequences.txt
        end
    end
end

