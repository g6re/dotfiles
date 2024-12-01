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

# Install and configure tmux
if ! command_exists tmux; then
    echo "Tmux is not installed."
    if confirm "Do you want to install Tmux?" "n"; then
        sudo pacman -S --noconfirm tmux || { echo "Failed to install Tmux. Exiting..."; exit 1; }
        if confirm "Do you want to install the Tmux configuration?" "n"; then
            if [ -f ~/.tmux.conf ]; then
                if confirm "The file ~/.tmux.conf already exists. Do you want to delete it?" "n"; then
                    rm ~/.tmux.conf
                else
                    echo "The file ~/.tmux.conf was not deleted. Configuration will not be installed."
                fi
            fi
            cp ~/.dotfiles/.tmux/.tmux.conf ~/
        fi
    else
        echo "Tmux is needed for its configuration. Continuing..."
    fi
else
    if confirm "Do you want to install the Tmux configuration?" "n"; then
        if [ -f ~/.tmux.conf ]; then
            if confirm "The file ~/.tmux.conf already exists. Do you want to delete it?" "n"; then
                rm ~/.tmux.conf
            else
                echo "The file ~/.tmux.conf was not deleted. Configuration will not be installed."
            fi
        fi
        cp ~/.dotfiles/.tmux/.tmux.conf ~/
    fi
fi

# Download, compile, and install Neovim
if ! command_exists nvim; then
    echo "Neovim is not installed."
    if confirm "Do you want to download and compile Neovim from source?" "n"; then
        # Install necessary dependencies including 'make' and 'gcc'
        echo "Installing dependencies..."
        sudo pacman -S --noconfirm cmake unzip ninja gettext make gcc || { echo "Failed to install dependencies. Exiting..."; exit 1; }

        # Download Neovim source code
        echo "Downloading Neovim source code..."
        git clone https://github.com/neovim/neovim.git ~/neovim || { echo "Failed to download Neovim source code. Exiting..."; exit 1; }

        # Compile and install Neovim
        echo "Compiling and installing Neovim..."
        cd ~/neovim || { echo "Failed to change directory to ~/neovim. Exiting..."; exit 1; }
        make CMAKE_BUILD_TYPE=Release || { echo "Failed to compile Neovim. Exiting..."; exit 1; }
        sudo make CMAKE_BUILD_TYPE=Release install || { echo "Failed to install Neovim. Exiting..."; exit 1; }
        cd - || exit

        # Clean up
        rm -rf ~/neovim

        if confirm "Do you want to install Neovim configuration?" "n"; then
            mkdir -p ~/.config/nvim
            cp -r ~/.dotfiles/.nvim/* ~/.config/nvim/
        fi
    else
        echo "Neovim is needed for its configuration. Continuing..."
    fi
else
    if confirm "Do you want to install Neovim configuration?" "n"; then
        mkdir -p ~/.config/nvim
        cp -r ~/.dotfiles/.nvim/* ~/.config/nvim/
    fi
fi

# Install xclip if necessary
if ! command_exists xclip; then
    echo "xclip is not installed."
    if confirm "Do you want to install xclip?" "n"; then
        sudo pacman -S --noconfirm xclip || { echo "Failed to install xclip. Exiting..."; exit 1; }
    fi
else
    echo "xclip is already installed."
fi

echo "Setup completed successfully."

