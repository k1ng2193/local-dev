#!/bin/bash

boldinfo() {
  tput bold
  tput setaf 45
  echo -e "INFO:$(tput sgr0) $1\n"
}

boldwarn() {
  tput bold
  tput setaf 11
  echo -e "WARNING:$(tput sgr0) $1\n"
}

bolderr() {
  tput bold
  tput setaf 1
  echo -e "Error:$(tput sgr0) $1\n"
}

create_symlinks() {
  boldinfo "Creating ZSH Env Startup Files Symlinks"
  ln -s ~/local-dev/.zprofile ~/.zprofile
  ln -s ~/local-dev/.zshrc ~/.zshrc

  boldinfo "Creating Config Directory Symlink"
  ln -s ~/local-dev/.config ~/.config
}

install_tmux_plugins() {
  boldinfo "Installing tmux plugins"
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  ~/.tmux/plugins/tpm/bin/install_plugins
}

setup_bat() {
  boldinfo "Building bat CLI cache"
  bat cache --build
}

# Function to list existing SSH keys
list_ssh_keys() {
  boldinfo "Existing SSH keys in ~/.ssh:"
  ls -1 ~/.ssh/*.pub 2>/dev/null || boldwarn "No public SSH keys found."
}

# Function to generate SSH key
generate_ssh_key() {
  local key_path="$1"
  local email="$2"

  # Ensure directory exists
  mkdir -p ~/.ssh

  # Generate SSH key
  ssh-keygen -t ed25519 -C "$email" -f "$key_path"

  # Return the path to the public key
  echo "${key_path}.pub"
}

# Prompt for email address
prompt_email() {
  local email

  while true; do
      read -rp "Enter your email address: " email
      
      if [[ -z "$email" ]]; then
          boldwarn "Email cannot be empty. Please try again."
      elif [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$ ]]; then
          echo "$email"
          break
      else
          boldwarn "Invalid email format. Please try again."
      fi
  done
}

# Prompt for SSH key path
prompt_ssh_key() {
  local default_key=~/.ssh/id_github
  local key_path
  local email

  while true; do
      # Check if default key exists
      if [ -f "${default_key}.pub" ]; then
          read -rp "An SSH key already exists. Create a new one? (y/N): " create_new
          if [[ ! "$create_new" =~ ^[Yy]$ ]]; then
              echo "${default_key}.pub"
              break
          fi
      fi

      # Prompt for email and generate key
      email=$(prompt_email)
      key_path=$(generate_ssh_key "$default_key" "$email")
      
      echo "$key_path"
      break
  done
}

# Prompt user for key title
prompt_key_title() {
    local title

    read -rp "Enter a title for this SSH key: " title

    # Use a default if no title provided
    if [ -z "$title" ]; then
        title="$(hostname) - $(date +%Y-%m-%d)"
    fi

    echo "$title"
}

setup_gh_ssh() {
  boldinfo "Creating SSH key and Adding to Github Account"

  cp ~/local-dev/.ssh ~/

  # Ensure GitHub CLI is installed
  if ! command -v gh &>/dev/null; then
      bolderr "GitHub CLI (gh) is not installed. Please install it first."
      exit 1
  fi 

  # Prompt for SSH key
  SSH_KEY_PATH=$(prompt_ssh_key)

  # Prompt for key title
  KEY_TITLE=$(prompt_key_title)

  # Confirm before adding
  boldinfo -e "About to add SSH key:"
  boldinfo "Path: $SSH_KEY_PATH"
  boldinfo "Title: $KEY_TITLE"

  read -rp "Confirm? (y/N): " confirm
  if [[ $confirm =~ ^[Yy]$ ]]; then
      
      # Add SSH key to GitHub
      # Check if addition was successful
      if gh ssh-key add "$SSH_KEY_PATH" -t "$KEY_TITLE"; then
          boldinfo "SSH key successfully added to GitHub!"
      else
          bolderr "Failed to add SSH key to GitHub."
      fi
  else
      boldinfo "SSH key addition cancelled."
  fi
}

# Run the main function
boldinfo "Navigating to the home directory"
cd ~ || exit

create_symlinks
install_tmux_plugins
setup_bat
setup_gh_ssh
