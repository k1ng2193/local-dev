ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

export STARSHIP_CONFIG=~/.config/starship/starship.toml
eval "$(starship init zsh)"

zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode

export GH_CONFIG_DIR=~/gh

alias ls="eza --color=always --long --git --icons=always --no-user"
alias profile="aws s3 ls --profile"

sso() {
    export AWS_PROFILE="$1"
    aws sso login
}

function rds_port_forwarding () {
if [ $1 = 'prod' ]
then
  host='host=prod-data-platform-api-aurora-1.c9pfra9e0ui4.us-west-2.rds.amazonaws.com'
elif [ $1 = 'release' ]
then
  host='host=release-data-platform-api-aurora-0-20221209214508265200000001.ceouhxsctaca.us-west-2.rds.amazonaws.com'
elif [ $1 = 'staging' ]
then
  host='host=staging-data-platform-api-aurora-0-20221209004954682000000001.cnz0vqmmh5lq.us-west-2.rds.amazonaws.com'
else return [Not a valid environment]
fi

# Get Bastion Instance ID
export BASTION_INSTANCE_ID=$(aws ec2 describe-instances \
  --filters 'Name=tag:application_role,Values=Bastion'  'Name=instance-state-name,Values=running' \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text)

aws ssm start-session --target ${BASTION_INSTANCE_ID} \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters \
  'portNumber=5432','localPortNumber=9090',${host}
}
function api_port_forwarding () {
if [ $1 = 'prod' ]
then
  host='host=data-api.prod.vareto.com'
elif [ $1 = 'release' ]
then
  host='host=data-api.release.vareto.com'
elif [ $1 = 'staging' ]
then
  host='host=data-api.staging.vareto.com'
else return [Not a valid environment]
fi

# Get Bastion Instance ID
export BASTION_INSTANCE_ID=$(aws ec2 describe-instances \
  --filters 'Name=tag:application_role,Values=Bastion'  'Name=instance-state-name,Values=running' \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text)

aws ssm start-session --target ${BASTION_INSTANCE_ID} \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters \
  'portNumber=80','localPortNumber=9090',${host}
}
function ssm_terminate () {
aws ssm terminate-session \
  --session-id $1
}
function artifact () {
export CODEARTIFACT_TOKEN=$(aws codeartifact get-authorization-token \
            --domain vareto \
            --domain-owner 544138963155 \
            --query authorizationToken \
            --output text)

export UV_INDEX_URL=https://aws:${CODEARTIFACT_TOKEN}@vareto-544138963155.d.codeartifact.us-west-2.amazonaws.com/pypi/vareto-python/simple
# pip3 config set global.index-url \
#   https://aws:${CODEARTIFACT_TOKEN}@vareto-544138963155.d.codeartifact.us-west-2.amazonaws.com/pypi/vareto-python/simple
}
function docker_artifact () {
export CODEARTIFACT_TOKEN=$(aws codeartifact get-authorization-token \
            --domain vareto \
            --domain-owner 544138963155 \
            --query authorizationToken \
            --output text)

pip3 config set global.extra-index-url \
  https://aws:${CODEARTIFACT_TOKEN}@vareto-544138963155.d.codeartifact.us-west-2.amazonaws.com/pypi/vareto-python/simple
cp ~/.config/pip/pip.conf pip.conf
}

function aws_docker_login () {
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 137149808471.dkr.ecr.us-west-2.amazonaws.com
}

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# export PATH="/Users/k1ng/.deno/bin:$PATH"
# source <(wmill completions zsh)
eval "$(atuin init zsh)"

eval "$(fzf --zsh)"

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

_fzf_compgen_path() {
    fd --hidden --exclude .git . "$1"
}

_fzf_compgen_dir() {
    fd --type=d --hidden --exclude .git . "$1"
}

autoload -U compinit && compinit
source ~/fzf-git.sh/fzf-git.sh

export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

_fzf_comprun() {
    local command=$1
    shift
    
    case "$command" in
        cd) fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
        export|unset) fzf --preview "eval 'echo \$' {}" "$@" ;;
        ssh) fzf --preview 'dig {}' "$@" ;;
        *) fzf --preview "--preview 'bat -n --color=always --line-range :500 {}'" "$@" ;;
    esac
}

export BAT_THEME="Catppuccin Mocha"

# eval "$(luarocks path --bin)"
export PATH="/opt/homebrew/opt/node@18/bin:$PATH"

export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
# export JAVA_HOME="/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home"
# export PATH="$JAVA_HOME/bin:$PATH"

export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
export PATH="$ANDROID_HOME/emulator:$PATH"
export PATH="$ANDROID_HOME/platform-tools:$PATH"

export SSH_SK_PROVIDER=pkcs11
