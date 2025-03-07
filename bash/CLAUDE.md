# Development Environment Setup Guidelines

## Commands
- `./bootstrap.sh` - Install prerequisites 
- `./manage-secrets.sh init` - Initialize secrets configuration
- `./dev-env-setup.sh` - Run full environment setup
- `./manage-secrets.sh decrypt` - Decrypt private configuration
- `./manage-secrets.sh encrypt` - Encrypt private configuration

## Code Style Guidelines
- **Naming**: Use `snake_case` for variables and functions
- **Comments**: Include header blocks with descriptions for all scripts
- **Error Handling**: Use `set -e` and `set -o pipefail` for fail-fast behavior
- **Logging**: Use `log_info/log_warn/log_error/log_fatal` functions from logging.sh
- **Testing**: Test commands with `set -x` for verbose debugging
- **Structure**: Organize features into separate script files in /scripts directory
- **Functions**: Create modular functions with clear single responsibilities
- **Config**: Store settings in YAML files (public.yml and private.yml)
- **Security**: Never hard-code credentials; use private.yml with SOPS encryption