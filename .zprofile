# Ensure user-installed binaries take precedence
export PATH=/usr/local/bin:$PATH

export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Load .zshrc if it exists
test -f ~/.zshrc && source ~/.zshrc
