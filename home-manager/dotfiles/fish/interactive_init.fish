# Initialize Starship prompt
starship init fish | source

# Initialize pay-respects if available
if type -q pay-respects
  pay-respects --init fish | source
end

# Start Emacs daemon if available and not running
if test -f /usr/bin/emacs
  if not pgrep -x emacs > /dev/null
    /usr/bin/emacs --daemon
  end
end
