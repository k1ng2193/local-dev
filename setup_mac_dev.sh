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

boldinfo "Copying ZSH Env Startup Files"
cp ./.zprofile ~/.zprofile
cp ./.zshrc ~/.zshrc

boldinfo "Navigating to the home directory"
cd ~ || exit

# Homebrew package manager
if ! command -v brew &>/dev/null; then
  boldinfo "Installing Homebrew Package Manager"
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
else
  boldinfo "Updating Homebrew Package Manager"
  brew update
fi

brew install iterm2 --cask
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

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
brew install python@3.11
brew install pyenv-virtualenv
brew install node@18
brew install nginx
brew install watchman
