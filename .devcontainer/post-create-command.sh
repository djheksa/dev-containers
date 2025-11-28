#!/bin/bash
set -e

echo "Running post-create setup as user: $(whoami)..."

# --- 0. Start SSH Server (for Remote Development) ---
echo "Starting SSH server..."
sudo service ssh start

# --- 1. Install Shell Tools (Oh My Zsh & plugins) ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

if [ "$INSTALL_ZSH_PLUGINS" = "true" ]; then
    ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        echo "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
    fi
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        echo "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
    fi
fi

# --- 2. Fix Runtime Permissions for Mounted Volumes ---
# Directories created by volume mounts are owned by root.
    # Change ownership to the dev-user to allow writing to them.
    echo "Fixing permissions for mounted volumes..."
if [ -d "$HOME/.zsh" ]; then
    sudo chown -R dev-user:dev-user $HOME/.zsh
fi
if [ -d "/opt/nvm" ]; then
    sudo chown -R dev-user:dev-user /opt/nvm
fi
if [ -d "$HOME/.config" ]; then
    sudo chown -R dev-user:dev-user $HOME/.config
fi
if [ -d "$HOME/.gemini" ]; then
    sudo chown -R dev-user:dev-user $HOME/.gemini
fi

# --- Fix Git Config Persistence (Symlink Strategy) ---
# Remove the directory if Docker created it incorrectly
if [ -d "$HOME/.gitconfig" ]; then
    echo "Removing .gitconfig directory created by Docker..."
    rm -rf "$HOME/.gitconfig"
fi

# Ensure the persistence directory exists and has correct permissions
if [ -d "$HOME/.git-state" ]; then
    sudo chown -R dev-user:dev-user "$HOME/.git-state"
    
    # Create the actual config file if it doesn't exist
    if [ ! -f "$HOME/.git-state/.gitconfig" ]; then
        touch "$HOME/.git-state/.gitconfig"
    fi
    
    # Link ~/.gitconfig -> ~/.git-state/.gitconfig
    if [ ! -L "$HOME/.gitconfig" ]; then
        ln -s "$HOME/.git-state/.gitconfig" "$HOME/.gitconfig"
    fi
fi

if [ -d "$HOME/.ssh" ]; then
    sudo chown -R dev-user:dev-user $HOME/.ssh
    sudo chmod 700 $HOME/.ssh
fi


# --- 3. Source SDK scripts to make them available in this script ---
export SDKMAN_DIR="/usr/local/sdkman"
[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

if [ "$INSTALL_NODE" = "true" ]; then
    export NVM_DIR="/opt/nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# --- 4. Install SDKs and set defaults (non-interactively) ---
if [ "$INSTALL_EXTRA_JDKS" = "true" ]; then
    echo "Installing Java versions..."
    (echo n | sdk install java 17.0.11-tem || echo "WARNING: Failed to install Java 17, but continuing...")
    echo "Setting default Java version to 17, as required by IntelliJ..."
    (sdk default java 17.0.11-tem || echo "WARNING: Failed to set default Java, but continuing...")

    (echo n | sdk install java 8.0.392-zulu || echo "WARNING: Failed to install Java 8, but continuing...")
    (echo n | sdk install java 11.0.21-zulu || echo "WARNING: Failed to install Java 11, but continuing...")
    (echo n | sdk install java 21.0.1-zulu || echo "WARNING: Failed to install Java 21, but continuing...")
fi
if [ "$INSTALL_NODE" = "true" ]; then
    echo "Installing Node.js LTS..."
    nvm install --lts || echo "WARNING: Failed to install Node LTS, but continuing..."
    nvm alias default lts/* || echo "WARNING: Failed to set default Node, but continuing..."
    nvm use default

    echo "Installing Google Gemini CLI..."
    npm install -g @google/gemini-cli || echo "WARNING: Failed to install Google Gemini CLI"
fi


# --- 5. Atomically Configure Final .zshrc for the User ---
echo "Configuring final .zshrc..."
ZSHRC_TMP="/tmp/.zshrc.tmp"
> $ZSHRC_TMP

# --- Basic Zsh and Oh My Zsh Config ---
cat <<'EOF' >> $ZSHRC_TMP
export ZSH="$HOME/.oh-my-zsh"
export HISTFILE="$HOME/.zsh/history"
ZSH_THEME="robbyrussell"
EOF

# Conditionally add plugins
if [ "$INSTALL_ZSH_PLUGINS" = "true" ]; then
    echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' >> $ZSHRC_TMP
else
    echo 'plugins=(git)' >> $ZSHRC_TMP
fi

# Add Oh My Zsh source and SDKMAN/NVM sourcing
cat <<'EOF' >> $ZSHRC_TMP

source $ZSH/oh-my-zsh.sh

# --- Dev Container Sourcing ---
export SDKMAN_DIR="/usr/local/sdkman"
[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
EOF

# Conditionally add nvm sourcing
if [ "$INSTALL_NODE" = "true" ]; then
cat <<'EOF' >> $ZSHRC_TMP
export NVM_DIR="/opt/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
fi

# Add Aliases and the new MOTD
cat <<'EOF' >> $ZSHRC_TMP

# --- Aliases ---
alias l='ls -CF'; alias la='ls -A'; alias ll='ls -alF'; alias l.='ls -d .* --color=auto'
alias ..='cd ..'; alias ...='cd ../..'; alias ....='cd ../../..'
alias h='history'; alias grep='grep --color=auto'; alias ports='sudo netstat -tulpn'
alias mc='mvn clean'; alias mci='mvn clean install'; alias mcp='mvn clean package'; alias mcd='mvn deploy'
alias gw='./gradlew'; alias gwc='gw clean'; alias gwb='gw build'; alias gwbs='gw build -x test'
alias update='sudo apt-get update && sudo apt-get upgrade -y'

# --- Aliases for Key Commands ---
alias lij='ls $SDKMAN_DIR/candidates/java'
alias sdj='sdk default java'
alias lnv='nvm ls'
alias sdn='nvm alias default'
alias sp='cd /workspace && git clone'

# --- Welcome Message (MOTD) ---
# Define Colors for MOTD
RESET='\e[0m'
BOLD='\e[1m'
CYAN='\e[36m'
GREEN='\e[32m'
MAGENTA='\e[35m'
WHITE='\e[37m'
GRAY='\e[90m'

# Get System Info
JAVA_INFO=$(java -version 2>&1 | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/' || echo "n/a")
NODE_INFO=$(node -v || echo "n/a")
GEMINI_INFO=$(gemini --version 2>/dev/null || echo "Not Found")
DISK_INFO=$(df -h /workspace | awk 'END{print $4 " free"}' || echo "n/a")
USER_INFO=$(whoami)

# MOTD using printf for alignment
printf "\n"
printf "${BOLD}${CYAN}🚀 Welcome to the All-in-One Dev Container${RESET}\n\n"

printf "${BOLD}${MAGENTA}💻 SYSTEM${RESET}\n"
printf "   ${GRAY}- Java      :${RESET} %s\n" "$JAVA_INFO"
if [ "$INSTALL_NODE" = "true" ]; then
printf "   ${GRAY}- Node.js   :${RESET} %s\n" "$NODE_INFO"
fi
printf "   ${GRAY}- Gemini CLI:${RESET} %s\n" "$GEMINI_INFO"
printf "   ${GRAY}- User      :${RESET} %s\n" "$USER_INFO"
printf "   ${GRAY}- Workspace :${RESET} %s (projects)\n" "/workspace ($DISK_INFO)"
printf "   ${GRAY}- Config    :${RESET} /opt/dev_container_root\n"
printf "   ${GRAY}- SSH Access:${RESET} Host: localhost, Port: 2222, User: dev-user, Pass: devpass\n"

printf "\n${BOLD}${MAGENTA}💡 ALIASES${RESET}\n"

printf "   ${GREEN}- lij      ${RESET} : List installed Java versions\n"
printf "   ${GREEN}- sdj <ver>${RESET} : Set default Java version\n"
if [ "$INSTALL_NODE" = "true" ]; then
printf "   ${GREEN}- lnv      ${RESET} : List installed Node.js versions\n"
printf "   ${GREEN}- sdn <ver>${RESET} : Set default Node.js version\n"
fi
printf "   ${GREEN}- sp <url> ${RESET} : Start a new project (git clone)\n"
printf "\n"

if [ "$GEMINI_INFO" != "Not Found" ]; then
    printf "${BOLD}${MAGENTA}⚠️  NOTE${RESET}\n"
    printf "   To use Gemini, run: ${BOLD}gemini chat${RESET} or simply ${BOLD}gemini${RESET}\n"
    printf "   It will prompt you to login with Google.\n\n"
fi
EOF

# Atomically move the new .zshrc into place
mv $ZSHRC_TMP $HOME/.zshrc

echo "✅ Dev Container setup complete!"