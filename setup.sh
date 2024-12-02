#!/bin/sh

# Function to prompt user
confirm() {
    local prompt="$1"
    local default_answer="$2"
    read -p "$prompt [y/N]: " answer
    answer=${answer:-$default_answer}
    [ "$answer" = "y" ] || [ "$answer" = "Y" ]
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update the system
echo "Updating the system..."
sudo pacman -Syu --noconfirm || { echo "System update failed. Exiting..."; exit 1; }

# Check and/or install git
if ! command_exists git; then
    echo "Git is not installed."
    if confirm "Do you want to install Git?" "n"; then
        sudo pacman -S --noconfirm git || { echo "Failed to install Git. Exiting..."; exit 1; }
    else
        echo "Git is required to continue. Exiting..."
        exit 1
    fi
fi

# Verify git installation
if ! command_exists git; then
    echo "Git could not be installed correctly. Exiting..."
    exit 1
fi

# Verify git version
echo "Git version:"
git --version || { echo "Failed to get Git version. Exiting..."; exit 1; }

# Ask for the GitHub PAT
read -sp "Enter your GitHub PAT: " pat
echo

# Configure Git credentials
git config --global credential.helper store

# Create a credentials file for git
echo "https://g6re:$pat@github.com" > ~/.git-credentials

# Clone the .dotfiles repository
echo "Cloning the .dotfiles repository..."
git clone --recurse-submodules https://github.com/g6re/.dotfiles.git ~/.dotfiles || { echo "Failed to clone the repository. Exiting..."; exit 1; }

# Clean up the credentials file
rm -f ~/.git-credentials

# SSH Setup
if ! command_exists sshd; then
    echo "SSH is not installed."
    if confirm "Do you want to install SSH?" "n"; then
        sudo pacman -S --noconfirm openssh || { echo "Failed to install SSH. Exiting..."; exit 1; }
    fi
fi

if command_exists sshd; then
    echo "SSH is installed."
    if confirm "Do you want to configure SSH?" "n"; then
        # Clone .ssh sub-repository if not already present
        if [ ! -d ~/.dotfiles/.ssh ]; then
            echo "Cloning .ssh repository..."
            git clone https://github.com/g6re/.ssh.git ~/.dotfiles/.ssh || { echo "Failed to clone the SSH repository. Exiting..."; exit 1; }
        fi

        # Move sshd_config to /etc/ssh/
        if [ -f ~/.dotfiles/.ssh/sshd_config ]; then
            echo "Moving sshd_config to /etc/ssh/..."
            sudo cp ~/.dotfiles/.ssh/sshd_config /etc/ssh/ || { echo "Failed to move sshd_config. Exiting..."; exit 1; }
        else
            echo "sshd_config file not found in ~/.dotfiles/.ssh/"
        fi

        # Start and enable SSH service
        echo "Starting and enabling SSH service..."
        sudo systemctl start sshd
        sudo systemctl enable sshd
    fi
else
    echo "SSH was not installed. Skipping configuration."
fi

# Continue with tmux setup as in the original script
# (same for Neovim and other components)
# ...

echo "Setup completed successfully."
