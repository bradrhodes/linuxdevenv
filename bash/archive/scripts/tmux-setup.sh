#!/usr/bin/env bash
# TMUX setup and plugin installation

setup_tmux() {
  log_section "Setting up TMUX"
  if [ "$INSTALL_TMUX_PLUGINS" = true ]; then
    if [ ! -d ~/.tmux/plugins/tpm ]; then
      mkdir -p ~/.tmux/plugins
      git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
      
      # Create a basic tmux config if none exists
      if [ ! -f ~/.tmux.conf ]; then
        PREFIX="${TMUX_PREFIX:-C-a}"
        cat > ~/.tmux.conf << EOF
# Set prefix to $PREFIX
unbind C-b
set -g prefix $PREFIX
bind $PREFIX send-prefix

# Enable mouse mode
set -g mouse on

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# TPM (Tmux Plugin Manager)
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# Initialize TMUX plugin manager
run '~/.tmux/plugins/tpm/tpm'
EOF
      fi
      log_info "TMUX Plugin Manager installed"
    else
      log_info "TMUX Plugin Manager already installed"
    fi
  else
    log_info "Skipping TMUX plugin setup as configured"
  fi
}