#!/bin/bash

# Homebrew package manager
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh

# AWS CLI
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

brew install s4cmd
brew install oh-my-zsh
brew install postgresql
brew install iterm2 --cask
brew install jq
brew install yq
brew install awk
brew install python@3.11
brew install nginx
brew install neovim@0.10.0
brew install ripgrep
brew install tmux
brew install pyenv-virtualenv
brew install bat
brew install btop
brew install atuin
brew install fzf
brew install tldr
brew install fd
brew install eza
brew install openssl@1.1
brew install node@18
brew install openssh
brew install opensc
brew install tcptraceroute
brew install watchman
