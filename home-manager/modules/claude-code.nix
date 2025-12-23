{ config, pkgs, ... }:

{
  # ===== CLAUDE CODE =====
  # AI coding assistant CLI from Anthropic
  programs.claude-code = {
    enable = true;

    # Optional: Add project-specific context/memory
    # memory.text = "Context about your development environment";
  };
}
