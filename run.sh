#!/bin/sh

# Color definitions
PURPLE='\033[0;35m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Configuration
HOSTNAME="vps"
HISTORY_FILE="${HOME}/.custom_shell_history"
MAX_HISTORY=1000

# Check if not installed
if [ ! -e "/.installed" ]; then
    # Check if rootfs.tar.xz or rootfs.tar.gz exists and remove them if they do
    if [ -f "/rootfs.tar.xz" ]; then
        rm -f "/rootfs.tar.xz"
    fi
    
    if [ -f "/rootfs.tar.gz" ]; then
        rm -f "/rootfs.tar.gz"
    fi
    
    # Wipe the files we downloaded into /tmp previously
    rm -rf /tmp/sbin
    
    # Mark as installed.
    touch "/.installed"
fi

# Check if the autorun script exists
if [ ! -e "/autorun.sh" ]; then
    touch /autorun.sh
    chmod +x /autorun.sh
fi

printf "\033c"
printf "${GREEN}Starting..${NC}\n"
sleep 1
printf "\033c"

# Logger function
log() {
    local level=$1
    local message=$2
    local color=$3
    
    if [ -z "$color" ]; then
        color=${NC}
    fi
    
    printf "${color}[$level] $message${NC}\n"
}

# Function to handle cleanup on exit
cleanup() {
    log "INFO" "Session ended. Goodbye!" "$GREEN"
    exit 0
}

# Function to get formatted directory
get_formatted_dir() {
    current_dir="$PWD"
    case "$current_dir" in
        "$HOME"*)
            printf "~${current_dir#$HOME}"
        ;;
        *)
            printf "$current_dir"
        ;;
    esac
}

# Function to print the banner
print_banner() {
    printf "\033c"
    printf "${GREEN}╭────────────────────────────────────────────────────────────────────────────────╮${NC}\n"
    printf "${GREEN}│                                                                                │${NC}\n"
    printf "${GREEN}│                             LINUX - VPS                                        │${NC}\n"
    printf "${GREEN}│                                                                                │${NC}\n"
    printf "${GREEN}│                           ${RED}© 2024 - 2025 ${PURPLE}@lipey1  ${GREEN}                              │${NC}\n"
    printf "${GREEN}│                                                                                │${NC}\n"
    printf "${GREEN}╰────────────────────────────────────────────────────────────────────────────────╯${NC}\n"
    printf "                                                                                               \n"
}

print_instructions() {
    log "INFO" "Type 'help' to view a list of available custom commands." "$YELLOW"
}

# Function to print prompt
print_prompt() {
    printf "\n${GREEN}root@${HOSTNAME}${NC}:${RED}$(get_formatted_dir)${NC}# "
}

# Function to save command to history
save_to_history() {
    cmd="$1"
    if [ -n "$cmd" ] && [ "$cmd" != "exit" ]; then
        printf "$cmd\n" >> "$HISTORY_FILE"
        # Keep only last MAX_HISTORY lines
        if [ -f "$HISTORY_FILE" ]; then
            tail -n "$MAX_HISTORY" "$HISTORY_FILE" > "$HISTORY_FILE.tmp"
            mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
        fi
    fi
}

# Function reinstall the OS
reinstall() {
    # Source the /etc/os-release file to get OS information
    . /etc/os-release
    
    if [ "$ID" = "alpine" ] || [ "$ID" = "chimera" ]; then
        rm -rf / > /dev/null 2>&1
    else
        rm -rf --no-preserve-root / > /dev/null 2>&1
    fi
}

# Function to install wget
install_wget() {
    distro=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    
    case "$distro" in
        "debian"|"ubuntu"|"devuan"|"linuxmint"|"kali")
            apt-get update -qq && apt-get install -y -qq wget > /dev/null 2>&1
        ;;
        "void")
            xbps-install -Syu -q wget > /dev/null 2>&1
        ;;
        "centos"|"fedora"|"rockylinux"|"almalinux"|"openEuler"|"amzn"|"ol")
            yum install -y -q wget > /dev/null 2>&1
        ;;
        "opensuse"|"opensuse-tumbleweed"|"opensuse-leap")
            zypper install -y -q wget > /dev/null 2>&1
        ;;
        "alpine"|"chimera")
            apk add --no-scripts -q wget > /dev/null 2>&1
        ;;
        "gentoo")
            emerge --sync -q && emerge -q wget > /dev/null 2>&1
        ;;
        "arch")
            pacman -Syu --noconfirm --quiet wget > /dev/null 2>&1
        ;;
        "slackware")
            yes | slackpkg install wget > /dev/null 2>&1
        ;;
        *)
            log "ERROR" "Unsupported distribution: $distro" "$RED"
            return 1
        ;;
    esac
}

# Function to install SSH from the repository
install_ssh() {
    distro=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    
    log "INFO" "Installing Dropbear SSH Server..." "$YELLOW"
    
    case "$distro" in
        "debian"|"ubuntu"|"devuan"|"linuxmint"|"kali")
            apt-get update -qq && apt-get install -y -qq dropbear > /dev/null 2>&1
        ;;
        "void")
            xbps-install -Syu -q dropbear > /dev/null 2>&1
        ;;
        "centos"|"fedora"|"rockylinux"|"almalinux"|"openEuler"|"amzn"|"ol")
            yum install -y -q dropbear > /dev/null 2>&1
        ;;
        "opensuse"|"opensuse-tumbleweed"|"opensuse-leap")
            zypper install -y -q dropbear > /dev/null 2>&1
        ;;
        "alpine"|"chimera")
            apk add --no-scripts -q dropbear > /dev/null 2>&1
        ;;
        "gentoo")
            emerge --sync -q && emerge -q dropbear > /dev/null 2>&1
        ;;
        "arch")
            pacman -Syu --noconfirm --quiet dropbear > /dev/null 2>&1
        ;;
        "slackware")
            yes | slackpkg install dropbear > /dev/null 2>&1
        ;;
        *)
            log "ERROR" "Unsupported distribution: $distro" "$RED"
            return 1
        ;;
    esac

    # Configurar grupos e usuários
    log "INFO" "Configuring users and groups..." "$YELLOW"
    
    # Criar grupos necessários
    cat >> /etc/group <<EOL
root:x:0:
daemon:x:1:
bin:x:2:
sys:x:3:
adm:x:4:
tty:x:5:
disk:x:6:
lp:x:7:
mail:x:8:
news:x:9:
uucp:x:10:
man:x:12:
proxy:x:13:
kmem:x:15:
dialout:x:20:
fax:x:21:
voice:x:22:
cdrom:x:24:
floppy:x:25:
tape:x:26:
sudo:x:27:
audio:x:29:
dip:x:30:
www-data:x:33:
backup:x:34:
operator:x:37:
list:x:38:
irc:x:39:
src:x:40:
gnats:x:41:
shadow:x:42:
utmp:x:43:
video:x:44:
sasl:x:45:
plugdev:x:46:
staff:x:50:
games:x:60:
users:x:100:
nogroup:x:65534:
ssh:x:988:
container:x:999:
EOL

    # Configurar senha root
    echo "root:vps123" | chpasswd

    # Criar diretório para as chaves
    mkdir -p /etc/dropbear
    
    # Gerar chaves do servidor
    dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
    dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key
    dropbearkey -t ed25519 -f /etc/dropbear/dropbear_ed25519_host_key

    # Matar qualquer processo SSH existente
    pkill dropbear
    pkill sshd

    # Iniciar Dropbear
    dropbear -E -F -p ${SSH_PORT:-22} &

    # Aguardar um momento para o serviço iniciar
    sleep 2

    # Verificar se o serviço está rodando
    if pgrep dropbear > /dev/null; then
        log "INFO" "SSH service is running" "$GREEN"
        
        # Mostrar processos SSH
        log "INFO" "SSH processes:" "$YELLOW"
        ps aux | grep dropbear
        
        # Mostrar portas abertas
        log "INFO" "Open ports:" "$YELLOW"
        ss -tuln
    else
        log "ERROR" "SSH service failed to start" "$RED"
    fi

    log "INFO" "SSH installed and configured successfully" "$GREEN"
    log "INFO" "Port: ${SSH_PORT:-22}" "$GREEN"
    log "INFO" "Username: root" "$GREEN"
    log "INFO" "Password: vps123" "$GREEN"

    # Atualizar /etc/passwd se necessário
    if ! grep -q "^container:" /etc/passwd; then
        echo "container:x:999:999:Container User:/home/container:/bin/bash" >> /etc/passwd
    fi
}

# Function to print a beautiful help message
print_help_message() {
    printf "${PURPLE}╭────────────────────────────────────────────────────────────────────────────────╮${NC}\n"
    printf "${PURPLE}│                                                                                │${NC}\n"
    printf "${PURPLE}│                             Available Commands                                 │${NC}\n"
    printf "${PURPLE}│                                                                                │${NC}\n"
    printf "${PURPLE}│                      ${YELLOW}clear, cls${GREEN}         - Clear the screen.                    ${PURPLE}│${NC}\n"
    printf "${PURPLE}│                      ${YELLOW}exit${GREEN}               - Shutdown the server.                 ${PURPLE}│${NC}\n"
    printf "${PURPLE}│                      ${YELLOW}history${GREEN}            - Show command history.                ${PURPLE}│${NC}\n"
    printf "${PURPLE}│                      ${YELLOW}reinstall${GREEN}          - Reinstall the server.                ${PURPLE}│${NC}\n"
    printf "${PURPLE}│                      ${YELLOW}install-ssh${GREEN}        - Install our custom SSH server.       ${PURPLE}│${NC}\n"
    printf "${PURPLE}│                      ${YELLOW}help${GREEN}               - Display this help message.           ${PURPLE}│${NC}\n"
    printf "${PURPLE}│                                                                                │${NC}\n"
    printf "${PURPLE}╰────────────────────────────────────────────────────────────────────────────────╯${NC}\n"
}

# Function to handle command execution
execute_command() {
    cmd="$1"
    user="$2"
    
    # Save command to history
    save_to_history "$cmd"
    
    # Handle special commands
    case "$cmd" in
        "clear"|"cls")
            print_banner
            print_prompt "$user"
            return 0
        ;;
        "exit")
            cleanup
        ;;
        "history")
            if [ -f "$HISTORY_FILE" ]; then
                cat "$HISTORY_FILE"
            fi
            print_prompt "$user"
            return 0
        ;;
        "reinstall")
            log "INFO" "Reinstalling...." "$GREEN"
            reinstall
            exit 2
        ;;
        "sudo"*|"su"*)
            log "ERROR" "You are already running as root." "$RED"
            print_prompt "$user"
            return 0
        ;;
        "install-ssh")
            install_ssh
            print_prompt "$user"
            return 0
        ;;
        "help")
            print_help_message
            print_prompt "$user"
            return 0
        ;;
        *)
            eval "$cmd"
            print_prompt "$user"
            return 0
        ;;
    esac
}

# Function to run command prompt for a specific user
run_prompt() {
    user="$1"
    read -r cmd
    
    execute_command "$cmd" "$user"
    print_prompt "$user"
}

# Create history file if it doesn't exist
touch "$HISTORY_FILE"

# Set up trap for clean exit
trap cleanup INT TERM

# Print initial banner
print_banner

# Print the initial instructions
print_instructions

# Print initial command
printf "${GREEN}root@${HOSTNAME}${NC}:${RED}$(get_formatted_dir)${NC}#\n"

# Execute autorun.sh
sh "/autorun.sh"

# Main command loop
while true; do
    run_prompt "user"
done