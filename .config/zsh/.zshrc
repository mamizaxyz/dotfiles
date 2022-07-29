# Mamiza's zsh config

# Enable colors and change prompt:
autoload -U colors && colors	# Load colors
PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "
setopt autocd		# Automatically cd into typed directory.
setopt interactivecomments
stty stop undef		# Disable ctrl-s to freeze terminal.

# History in cache directory:
HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE=~/.cache/zsh/history

# Load aliases and shortcuts if existent:
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliasrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/zshnameddirrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/zshnameddirrc"

# Basic auto/tab completion:
autoload -U compinit
zstyle ":completion:*" menu select
zstyle ":completion:*" matcher-list "m:{a-zA-Z}={A-Za-z}"
zmodload zsh/complist
compinit
_comp_options+=(globdots)	 # Include hidden files.

# vi mode
bindkey -v
export KEYTIMEOUT=1

# Use bash style word selection:
# WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'
autoload -U select-word-style
select-word-style bash

# Use vim keys in tab completion menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -v "^?" backward-delete-char

# Some more keybindings:
bindkey "^A" beginning-of-line
bindkey "^H" backward-kill-word
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# Changes cursor shape for different vi modes.
function
zle-keymap-select()
{
	case $KEYMAP in
		vicmd) echo -ne "\e[1 q";;	# Block
		viins|main) echo -ne "\e[5 q";;	# beam
	esac

}
zle -N zle-keymap-select
zle-line-init()
{
	zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
}
zle -N zle-line-init
echo -ne "\e[5 q"		# Use beam shaped cursor on startup.
preexec()
{
	echo -ne "\e[5 q"	# Use beam shaped cursor for each new prompt.
}

lfcd()
{
	tmp="$(mktemp)"
	lf -last-dir-path="$tmp" "$@"
	[ -f "$tmp" ] && {
		dir="$(cat "$tmp")"
		rm -f "$tmp" >/dev/null
		[ -d "$dir" ] && [ "$dir" != "$pwd" ] && cd "$dir"
	}
}

bindkey -s "^o" "lfcd\n"

autoload edit-command-line
zle -N edit-command-line
bindkey "^e" edit-command-line

# Load syntax highlighting; should be last; unless using autosuggestions.
source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh 2>/dev/null

# Load fish like autosuggestions; should be last.
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh 2>/dev/null

# Load command_not_found_handler.
source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/command-not-found.zsh" 2>/dev/null
