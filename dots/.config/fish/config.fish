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
    else
        set -l h (hostname | string lower)
        if test -f ~/.config/terminal/$h-sequences.txt
            cat ~/.config/terminal/$h-sequences.txt
        end
    end

    function ssh
        command ssh $argv
        if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
            cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        else
            set -l h (hostname | string lower)
            if test -f ~/.config/terminal/$h-sequences.txt
                cat ~/.config/terminal/$h-sequences.txt
            end
        end
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

    # Helper command to generate and apply full 16-color shell themes from hex code, image path, or web URL
    function settheme --description "Set shell theme from hex color, image file, or web URL"
        if test (count $argv) -eq 0
            echo "Usage: settheme <hex-color | image-path | image-url> [options...]"
            return 1
        end

        set -l target $argv[1]
        set -l extra_args $argv[2..-1]
        set -l script_dir ~/.config/quickshell/ii/scripts/colors
        set -l state_dir ~/.local/state/quickshell/user/generated

        mkdir -p $state_dir/terminal

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
                set target "$cache_img"
            else
                echo "Error: Failed to download image from URL."
                return 1
            end
        end

        set -l py_cmd python3
        for py in ~/.local/state/quickshell/.venv/bin/python3 $ILLOGICAL_IMPULSE_VIRTUAL_ENV/bin/python3 python3
            if test -x "$py"; and "$py" -c "import PIL, materialyoucolor" >/dev/null 2>&1
                set py_cmd "$py"
                break
            end
        end

        set -l planet_name (string lower "$target")
        if test -f ~/.config/terminal/$planet_name-sequences.txt
            set target ~/.config/terminal/$planet_name-sequences.txt
        else if test -f /home/nicho/Documents/GitHub/iiClone/mine/dots-hyprland/dots/.config/terminal/$planet_name-sequences.txt
            set target /home/nicho/Documents/GitHub/iiClone/mine/dots-hyprland/dots/.config/terminal/$planet_name-sequences.txt
        end

        if string match -r '\.txt$' -i -- "$target" >/dev/null; and test -f "$target"
            cp "$target" $state_dir/terminal/sequences.txt
            cat $state_dir/terminal/sequences.txt
            return 0
        else if test -f "$target"
            matugen image "$target" $extra_args
            $py_cmd $script_dir/generate_colors_material.py --path "$target" --termscheme $script_dir/terminal/scheme-base.json --blend_bg_fg --cache $state_dir/color.txt > $state_dir/material_colors.scss
        else if string match -r '\.(jpe?g|png|webp|gif|bmp|tiff?)$' -i -- $target >/dev/null
            echo "Error: Image file '$target' not found."
            return 1
        else if string match -r '^#?[0-9a-fA-F]{3,8}$' -- $target >/dev/null
            matugen color hex "$target" $extra_args
            $py_cmd $script_dir/generate_colors_material.py --color "$target" --termscheme $script_dir/terminal/scheme-base.json --blend_bg_fg --cache $state_dir/color.txt > $state_dir/material_colors.scss
        else
            echo "Error: '$target' is not a valid file path, web URL, planet name, or hex color."
            return 1
        end

        bash $script_dir/applycolor.sh
        if test -f $state_dir/terminal/sequences.txt
            cat $state_dir/terminal/sequences.txt
        end
    end
end

