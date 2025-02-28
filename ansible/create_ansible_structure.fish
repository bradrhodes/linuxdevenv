#!/usr/bin/env fish

# Script to create only the roles directory structure
# Run this from the Ansible project root directory

echo "Creating roles directory structure..."

# Create roles base directory
mkdir -p roles

# Define role structure with their specific subdirectories
set -l roles_structure "
common:tasks,defaults
git:tasks,defaults
ssh:tasks,defaults
nix:tasks,defaults
shell:tasks,defaults,handlers
editors:tasks,defaults
tmux:tasks,defaults
fonts:tasks,defaults,handlers
dotfiles:tasks,defaults
"

# Create all role directories and files
for role_line in (string split \n $roles_structure)
    # Skip empty lines
    if test -z "$role_line"
        continue
    end
    
    set -l role_parts (string split : $role_line)
    set -l role_name $role_parts[1]
    set -l role_dirs (string split , $role_parts[2])
    
    # Create role base directory
    mkdir -p roles/$role_name
    
    # Create subdirectories with main.yml files
    for subdir in $role_dirs
        mkdir -p roles/$role_name/$subdir
        echo "---" > roles/$role_name/$subdir/main.yml
    end
end

# Create special files for SSH role
echo "---" > roles/ssh/tasks/ssh_keys.yml
echo "---" > roles/ssh/tasks/github_ssh.yml

echo "Roles directory structure creation complete!"
echo "Created the following structure:"
find roles -type d | sort
echo "Created empty YAML files in each directory."