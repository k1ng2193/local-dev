#!/bin/bash

boldinfo() {
  tput bold
  tput setaf 45
  echo -e "INFO:$(tput sgr0) $1\n"
}

bolderr() {
  tput bold
  tput setaf 1
  echo -e "Error:$(tput sgr0) $1\n"
}

boldinfo "Navigating to the home directory"
cd ~ || exit

# Homebrew package manager
if ! command -v brew &>/dev/null; then
  boldinfo "Installing Homebrew Package Manager"
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  boldinfo "Updating Homebrew Package Manager"
  brew update
fi

brew install --cask ghostty
brew install starship

brew install git
brew install gh
brew install jq
brew install yq
brew install awk
brew install ripgrep
brew install bat
brew install btop
brew install atuin
brew install fzf
git clone https://github.com/junegunn/fzf-git.sh
brew install tldr
brew install fd
brew install eza
brew install trash
brew install font-sauce-code-pro-nerd-font
brew install openssl
brew install openssh
brew install opensc
brew install tcptraceroute

# AWS CLI
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
brew install s4cmd

brew install neovim
brew install tmux
brew install postgresql
brew install uv
brew install node@18
brew install yarn
brew install nginx

boldinfo "Creating ZSH Env Startup Files Symlinks"
cd ~ || exit
ln -s ~/local-dev/.zprofile ~/.zprofile
ln -s ~/local-dev/.zshrc ~/.zshrc

boldinfo "Creating Config Directory Symlink"
ln -s ~/local-dev/.config ~/.config

boldinfo "Installing tmux plugins"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
~/.tmux/plugins/tpm/bin/install_plugins

boldinfo "Building bat CLI cache"
bat cache --build
