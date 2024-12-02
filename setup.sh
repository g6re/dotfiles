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

# Initial pacman-key setup
if confirm "Do you want to initialize and populate pacman keys before updating the system?" "n"; then
    echo "Initializing pacman keys..."
    sudo pacman-key --init || { echo "Failed to initialize pacman keys. Exiting..."; exit 1; }
    sudo pacman-key --populate archlinux || { echo "Failed to populate pacman keys. Exiting..."; exit 1; }
fi

# Update the system
echo "=== Updating the system ==="
sudo pacman -Syu --noconfirm || { echo "System update failed. Exiting..."; exit 1; }

# Check and install git
if ! command_exists git; then
    echo "Git is not installed."
    if confirm "Do you want to install Git?" "n"; then
        sudo pacman -S --noconfirm git || { echo "Failed to install Git. Exiting..."; exit 1; }
    else
        echo "Git is required to continue. Exiting..."
        exit 1
    fi
fi

# Clone the .dotfiles repository
echo "=== Cloning the .dotfiles repository ==="
read -sp "Enter your GitHub PAT: " pat
echo

git config --global credential.helper store
echo "https://g6re:$pat@github.com" > ~/.git-credentials
git clone --recurse-submodules https://github.com/g6re/.dotfiles.git ~/.dotfiles || { echo "Failed to clone the repository. Exiting..."; exit 1; }
rm -f ~/.git-credentials

# Tmux setup
echo "=== Configuring Tmux ==="
if ! command_exists tmux; then
    if confirm "Do you want to install Tmux?" "n"; then
        sudo pacman -S --noconfirm tmux || { echo "Failed to install Tmux. Exiting..."; exit 1; }
    fi
fi

if command_exists tmux && confirm "Do you want to install the Tmux configuration?" "n"; then
    if [ -f ~/.tmux.conf ]; then
        if confirm "The file ~/.tmux.conf already exists. Do you want to overwrite it?" "n"; then
            rm ~/.tmux.conf
        fi
    fi
    cp ~/.dotfiles/.tmux/.tmux.conf ~/
fi

# Neovim setup
echo "=== Configuring Neovim ==="
if ! command_exists nvim; then
    if confirm "Do you want to install Neovim from source?" "n"; then
        sudo pacman -S --noconfirm cmake unzip ninja gettext make gcc || { echo "Failed to install dependencies. Exiting..."; exit 1; }

        echo "Downloading and compiling Neovim..."
        git clone https://github.com/neovim/neovim.git ~/neovim || { echo "Failed to clone Neovim. Exiting..."; exit 1; }
        cd ~/neovim || exit
        make CMAKE_BUILD_TYPE=Release || { echo "Failed to compile Neovim. Exiting..."; exit 1; }
        sudo make install || { echo "Failed to install Neovim. Exiting..."; exit 1; }
        cd - || exit
        rm -rf ~/neovim
    fi
fi

if command_exists nvim && confirm "Do you want to install Neovim configuration?" "n"; then
    mkdir -p ~/.config/nvim
    cp -r ~/.dotfiles/.nvim/* ~/.config/nvim/
fi

# SSH setup
echo "=== Configuring SSH ==="
if ! command_exists sshd; then
    if confirm "Do you want to install SSH?" "n"; then
        sudo pacman -S --noconfirm openssh || { echo "Failed to install SSH. Exiting..."; exit 1; }
    fi
fi

if command_exists sshd; then
    if confirm "Do you want to configure SSH?" "n"; then
        if [ ! -d ~/.dotfiles/.ssh ]; then
            git submodule update --init --recursive || { echo "Failed to update SSH submodule. Exiting..."; exit 1; }
        fi

        if [ -f ~/.dotfiles/.ssh/sshd_config ]; then
            echo "Copying sshd_config to /etc/ssh/..."
            sudo cp ~/.dotfiles/.ssh/sshd_config /etc/ssh/ || { echo "Failed to copy sshd_config. Exiting..."; exit 1; }
            sudo systemctl restart sshd
            sudo systemctl enable sshd
        else
            echo "sshd_config not found in ~/.dotfiles/.ssh/"
        fi
    fi
fi

# Install xclip if necessary
echo "=== Configuring xclip ==="
if ! command_exists xclip; then
    if confirm "Do you want to install xclip? (Good for WSL)" "n"; then
        sudo pacman -S --noconfirm xclip || { echo "Failed to install xclip. Exiting..."; exit 1; }
    fi
fi

echo "=== Setup completed successfully! ==="
