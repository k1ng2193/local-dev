check_and_add_ssh_key() {
    local KEY_PATH="$HOME/.ssh/id_github"

    # Start SSH agent if not already running
    if [ -z "$SSH_AUTH_SOCK" ]; then
        eval "$(ssh-agent -s)" > /dev/null
    fi

    # Check if key is already added
    if ! ssh-add -l | grep -q "$(ssh-keygen -lf "${KEY_PATH}" | awk '{print $2}')"; then
        ssh-add -q "${KEY_PATH}"
        if [ $? -eq 0 ]; then
            echo "SSH key added: ${KEY_PATH}"
        else
            echo "Failed to add SSH key: ${KEY_PATH}"
        fi
    fi
}

check_and_add_ssh_key

# Ensure user-installed binaries take precedence
# export PATH="/usr/local/bin/python3.12:$PATH"
export PATH=/usr/local/bin:$PATH
# export PATH=/usr/local/opt/openssh/bin:$PATH
# export PATH="/Users/k1ng/.pyenv/versions/3.10.4/bin:${PATH}"

# export PYENV_ROOT="$HOME/.pyenv"
# command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"
# eval "$(pyenv virtualenv-init -)"

# Load .zshrc if it exists
# test -f ~/.zshrc && source ~/.zshrc

eval "$(/opt/homebrew/bin/brew shellenv)"
