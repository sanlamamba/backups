#!/usr/bin/env bash
#
# install_dataiku.sh — Interactive Dataiku DSS installer for Ubuntu 22.04 on AWS EC2
# Run as: sudo bash install_dataiku.sh
#
set -euo pipefail

# ─────────────────────────────────────────────
# Colors & helpers
# ─────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()      { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()     { echo -e "${RED}[ERROR]${NC} $*"; }
header()  { echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${BOLD}  $*${NC}"; echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

ask() {
    local prompt="$1" default="$2" var_name="$3"
    if [[ -n "$default" ]]; then
        read -rp "$(echo -e "${CYAN}?${NC} ${prompt} [${default}]: ")" input
        printf -v "$var_name" '%s' "${input:-$default}"
    else
        while true; do
            read -rp "$(echo -e "${CYAN}?${NC} ${prompt}: ")" input
            if [[ -n "$input" ]]; then
                printf -v "$var_name" '%s' "$input"
                break
            fi
            warn "This field is required."
        done
    fi
}

ask_yn() {
    local prompt="$1" default="$2"
    while true; do
        read -rp "$(echo -e "${CYAN}?${NC} ${prompt} [${default}]: ")" yn
        yn="${yn:-$default}"
        case "$yn" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) warn "Please answer y or n." ;;
        esac
    done
}

# ─────────────────────────────────────────────
# Pre-flight checks
# ─────────────────────────────────────────────
header "Dataiku DSS Installer for Ubuntu 22.04 / AWS EC2"

# Must run as root
if [[ $EUID -ne 0 ]]; then
    err "This script must be run as root (use: sudo bash $0)"
    exit 1
fi

# OS check
if ! grep -q 'Ubuntu' /etc/os-release 2>/dev/null; then
    err "This script is designed for Ubuntu. Your OS does not appear to be Ubuntu."
    exit 1
fi

UBUNTU_VERSION=$(grep VERSION_ID /etc/os-release | cut -d'"' -f2)
if [[ "$UBUNTU_VERSION" != "22.04" && "$UBUNTU_VERSION" != "20.04" ]]; then
    warn "Detected Ubuntu ${UBUNTU_VERSION}. Dataiku DSS 14 officially supports 20.04 and 22.04."
    if ! ask_yn "Continue anyway?" "n"; then
        exit 1
    fi
else
    ok "Detected Ubuntu ${UBUNTU_VERSION} — supported by Dataiku DSS."
fi

# ─────────────────────────────────────────────
# System resource checks
# ─────────────────────────────────────────────
header "Step 1: System Resource Checks"

TOTAL_RAM_MB=$(free -m | awk '/Mem:/ {print $2}')
TOTAL_RAM_GB=$((TOTAL_RAM_MB / 1024))
info "Detected RAM: ${TOTAL_RAM_GB} GB (${TOTAL_RAM_MB} MB)"
if [[ $TOTAL_RAM_MB -lt 7500 ]]; then
    warn "Dataiku recommends at least 8 GB RAM (32 GB for production)."
    warn "You have ${TOTAL_RAM_GB} GB. DSS may be sluggish or fail."
    if ! ask_yn "Continue anyway?" "n"; then
        exit 1
    fi
elif [[ $TOTAL_RAM_MB -lt 31000 ]]; then
    warn "You have ${TOTAL_RAM_GB} GB RAM. This is fine for dev/testing."
    warn "Dataiku recommends 32 GB+ for production workloads."
fi

TOTAL_DISK_GB=$(df -BG / | awk 'NR==2 {gsub("G",""); print $4}')
info "Detected free disk space on /: ${TOTAL_DISK_GB} GB"
if [[ $TOTAL_DISK_GB -lt 20 ]]; then
    err "You have less than 20 GB free. Dataiku needs at least 20 GB, 100 GB+ recommended."
    if ! ask_yn "Continue anyway?" "n"; then
        exit 1
    fi
elif [[ $TOTAL_DISK_GB -lt 100 ]]; then
    warn "You have ${TOTAL_DISK_GB} GB free. Dataiku recommends 100 GB+ for the data directory."
fi

CPU_COUNT=$(nproc)
info "Detected CPUs: ${CPU_COUNT}"
ok "System resource check complete."

# ─────────────────────────────────────────────
# Gather configuration
# ─────────────────────────────────────────────
header "Step 2: Configuration"

echo -e "${BOLD}Let's configure your Dataiku DSS installation.${NC}\n"

# DSS version
DSS_LATEST="14.4.3"
ask "Dataiku DSS version to install" "$DSS_LATEST" DSS_VERSION
info "Will install Dataiku DSS ${DSS_VERSION}"

# Dedicated user
echo ""
ask "Unix username to run DSS as (will be created if missing)" "dataiku" DSS_USER
if id "$DSS_USER" &>/dev/null; then
    ok "User '${DSS_USER}' already exists."
else
    info "User '${DSS_USER}' will be created."
fi

# Install directory (where tarball is unpacked)
ask "Installation directory (where DSS code will live)" "/home/${DSS_USER}" INSTALL_BASE

# Data directory
ask "Data directory (DSS config, logs, datasets)" "/home/${DSS_USER}/dss_data" DATA_DIR

# Port
ask "Base TCP port for DSS (DSS uses PORT to PORT+10)" "11000" DSS_PORT
if [[ $DSS_PORT -lt 1024 ]]; then
    warn "Ports below 1024 require root. This is not recommended."
fi

# License
echo ""
HAS_LICENSE=false
if ask_yn "Do you have a Dataiku license file (.json)?" "n"; then
    ask "Path to your license file" "" LICENSE_PATH
    if [[ ! -f "$LICENSE_PATH" ]]; then
        warn "File not found at ${LICENSE_PATH}. Will continue without license (Free Edition)."
    else
        HAS_LICENSE=true
        ok "License file found: ${LICENSE_PATH}"
    fi
else
    info "No license — DSS will start as Free Edition. You can add a license later."
fi

# R support
echo ""
INSTALL_R=false
if ask_yn "Do you need R support?" "n"; then
    INSTALL_R=true
    info "R packages will be included in dependency installation."
fi

# Auto-start at boot
echo ""
ENABLE_BOOT=false
if ask_yn "Enable DSS auto-start at boot (systemd service)?" "y"; then
    ENABLE_BOOT=true
fi

# UFW firewall
echo ""
CONFIGURE_UFW=false
if command -v ufw &>/dev/null; then
    UFW_STATUS=$(ufw status | head -1)
    if echo "$UFW_STATUS" | grep -q "active"; then
        info "UFW firewall is active."
        if ask_yn "Open port ${DSS_PORT} in UFW?" "y"; then
            CONFIGURE_UFW=true
        fi
    fi
fi

# ─────────────────────────────────────────────
# Summary & confirmation
# ─────────────────────────────────────────────
header "Step 3: Review Your Configuration"

echo -e "  ${BOLD}DSS Version:${NC}       ${DSS_VERSION}"
echo -e "  ${BOLD}Unix User:${NC}         ${DSS_USER}"
echo -e "  ${BOLD}Install Dir:${NC}       ${INSTALL_BASE}/dataiku-dss-${DSS_VERSION}"
echo -e "  ${BOLD}Data Dir:${NC}          ${DATA_DIR}"
echo -e "  ${BOLD}Base Port:${NC}         ${DSS_PORT}"
echo -e "  ${BOLD}License:${NC}           $(${HAS_LICENSE} && echo "$LICENSE_PATH" || echo "Free Edition")"
echo -e "  ${BOLD}R Support:${NC}         $(${INSTALL_R} && echo "Yes" || echo "No")"
echo -e "  ${BOLD}Auto-start:${NC}        $(${ENABLE_BOOT} && echo "Yes (systemd)" || echo "No")"
echo -e "  ${BOLD}Open UFW Port:${NC}     $(${CONFIGURE_UFW} && echo "Yes (port ${DSS_PORT})" || echo "N/A")"
echo ""

if ! ask_yn "Proceed with installation?" "y"; then
    info "Installation cancelled."
    exit 0
fi

# ─────────────────────────────────────────────
# Step 4: System update & locale
# ─────────────────────────────────────────────
header "Step 4: Updating System & Ensuring Locale"

info "Running apt update & upgrade..."
apt-get update -y
apt-get upgrade -y
ok "System updated."

info "Ensuring en_US.UTF-8 locale is available..."
if ! locale -a 2>/dev/null | grep -q 'en_US.utf8'; then
    apt-get install -y locales
    locale-gen en_US.UTF-8
    update-locale LANG=en_US.UTF-8
    ok "Locale en_US.UTF-8 generated."
else
    ok "Locale en_US.UTF-8 already available."
fi

# ─────────────────────────────────────────────
# Step 5: Create user
# ─────────────────────────────────────────────
header "Step 5: Creating DSS User"

if id "$DSS_USER" &>/dev/null; then
    ok "User '${DSS_USER}' already exists — skipping creation."
else
    info "Creating user '${DSS_USER}'..."
    adduser --disabled-password --gecos "Dataiku DSS" "$DSS_USER"
    ok "User '${DSS_USER}' created."
fi

# Ensure home directory exists
USER_HOME=$(eval echo "~${DSS_USER}")
mkdir -p "$USER_HOME"
chown "${DSS_USER}:${DSS_USER}" "$USER_HOME"

# Set ulimits for the DSS user
info "Setting file/process limits for ${DSS_USER}..."
cat > /etc/security/limits.d/99-dataiku.conf <<EOF
${DSS_USER}  hard  nofile   65536
${DSS_USER}  soft  nofile   65536
${DSS_USER}  hard  nproc    65536
${DSS_USER}  soft  nproc    65536
EOF
ok "Limits configured in /etc/security/limits.d/99-dataiku.conf"

# ─────────────────────────────────────────────
# Step 6: Download DSS
# ─────────────────────────────────────────────
header "Step 6: Downloading Dataiku DSS ${DSS_VERSION}"

TARBALL="dataiku-dss-${DSS_VERSION}.tar.gz"
DOWNLOAD_URL="https://cdn.downloads.dataiku.com/public/dss/${DSS_VERSION}/${TARBALL}"

mkdir -p "$INSTALL_BASE"
cd "$INSTALL_BASE"

if [[ -f "$TARBALL" ]]; then
    info "Tarball already exists at ${INSTALL_BASE}/${TARBALL} — skipping download."
else
    info "Downloading from ${DOWNLOAD_URL} ..."
    if ! wget -q --show-progress "$DOWNLOAD_URL" -O "$TARBALL"; then
        err "Download failed. Please check the version number and your network."
        err "You can also download manually from: https://www.dataiku.com/product/get-started/linux"
        exit 1
    fi
    ok "Download complete."
fi

# ─────────────────────────────────────────────
# Step 7: Unpack
# ─────────────────────────────────────────────
header "Step 7: Unpacking DSS"

INSTALL_DIR="${INSTALL_BASE}/dataiku-dss-${DSS_VERSION}"

if [[ -d "$INSTALL_DIR" ]]; then
    info "Directory ${INSTALL_DIR} already exists — skipping unpack."
else
    info "Extracting ${TARBALL}..."
    sudo -u "$DSS_USER" tar xzf "$TARBALL"
    ok "Extracted to ${INSTALL_DIR}"
fi

chown -R "${DSS_USER}:${DSS_USER}" "$INSTALL_BASE"

# ─────────────────────────────────────────────
# Step 8: Install system dependencies
# ─────────────────────────────────────────────
header "Step 8: Installing System Dependencies"

info "Running Dataiku's dependency installer..."
DEPS_CMD="${INSTALL_DIR}/scripts/install/install-deps.sh"

if $INSTALL_R; then
    "$DEPS_CMD" -with-r
else
    "$DEPS_CMD"
fi
ok "System dependencies installed."

# ─────────────────────────────────────────────
# Step 9: Run the DSS installer
# ─────────────────────────────────────────────
header "Step 9: Running DSS Installer"

INSTALLER_ARGS="-d ${DATA_DIR} -p ${DSS_PORT}"
if $HAS_LICENSE; then
    INSTALLER_ARGS="${INSTALLER_ARGS} -l ${LICENSE_PATH}"
fi

info "Running installer as user '${DSS_USER}'..."
sudo -u "$DSS_USER" "${INSTALL_DIR}/installer.sh" $INSTALLER_ARGS
ok "Dataiku DSS installed successfully!"

# ─────────────────────────────────────────────
# Step 10: (Optional) Boot-time startup
# ─────────────────────────────────────────────
if $ENABLE_BOOT; then
    header "Step 10: Configuring Auto-Start (systemd)"
    "${INSTALL_DIR}/scripts/install/install-boot.sh" "$DATA_DIR" "$DSS_USER"
    systemctl enable dataiku
    ok "Systemd service 'dataiku' created and enabled."
fi

# ─────────────────────────────────────────────
# Step 11: Open firewall port
# ─────────────────────────────────────────────
if $CONFIGURE_UFW; then
    header "Step 11: Configuring UFW Firewall"
    ufw allow "$DSS_PORT"/tcp
    ok "UFW: port ${DSS_PORT}/tcp opened."
fi

# ─────────────────────────────────────────────
# Step 12: Start DSS
# ─────────────────────────────────────────────
header "Step 12: Starting Dataiku DSS"

if $ENABLE_BOOT; then
    info "Starting via systemd..."
    systemctl start dataiku
else
    info "Starting DSS manually..."
    sudo -u "$DSS_USER" "${DATA_DIR}/bin/dss" start
fi

# Wait for backend
info "Waiting for DSS backend to become ready..."
for i in $(seq 1 30); do
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:${DSS_PORT}" 2>/dev/null | grep -q "200\|302"; then
        break
    fi
    sleep 2
done
ok "Dataiku DSS is running!"

# ─────────────────────────────────────────────
# Final summary
# ─────────────────────────────────────────────
header "Installation Complete!"

# Try to detect public IP
PUBLIC_IP=$(curl -s --connect-timeout 3 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "<your-ec2-public-ip>")
# Fallback to IMDSv2
if [[ "$PUBLIC_IP" == "<your-ec2-public-ip>" ]]; then
    TOKEN=$(curl -s --connect-timeout 3 -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null || true)
    if [[ -n "$TOKEN" ]]; then
        PUBLIC_IP=$(curl -s --connect-timeout 3 -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "<your-ec2-public-ip>")
    fi
fi

echo ""
echo -e "  ${GREEN}${BOLD}Dataiku DSS is live!${NC}"
echo ""
echo -e "  ${BOLD}Access URL:${NC}        http://${PUBLIC_IP}:${DSS_PORT}"
echo -e "  ${BOLD}Default Login:${NC}     admin / admin"
echo -e "  ${BOLD}Data Directory:${NC}    ${DATA_DIR}"
echo -e "  ${BOLD}Install Directory:${NC} ${INSTALL_DIR}"
echo ""
echo -e "  ${RED}${BOLD}⚠  IMPORTANT: Change the default admin password immediately!${NC}"
echo ""
echo -e "  ${BOLD}Useful commands:${NC}"
if $ENABLE_BOOT; then
    echo -e "    Stop DSS:     ${CYAN}sudo systemctl stop dataiku${NC}"
    echo -e "    Start DSS:    ${CYAN}sudo systemctl start dataiku${NC}"
    echo -e "    Status:       ${CYAN}sudo systemctl status dataiku${NC}"
    echo -e "    Logs:         ${CYAN}sudo journalctl -u dataiku -f${NC}"
else
    echo -e "    Stop DSS:     ${CYAN}sudo -u ${DSS_USER} ${DATA_DIR}/bin/dss stop${NC}"
    echo -e "    Start DSS:    ${CYAN}sudo -u ${DSS_USER} ${DATA_DIR}/bin/dss start${NC}"
    echo -e "    Status:       ${CYAN}sudo -u ${DSS_USER} ${DATA_DIR}/bin/dss status${NC}"
fi
echo ""
echo -e "  ${BOLD}EC2 Security Group Reminder:${NC}"
echo -e "    Make sure port ${BOLD}${DSS_PORT}${NC} (Custom TCP) is open from your IP."
echo ""
echo -e "  ${BOLD}Next steps:${NC}"
echo -e "    1. Log in and change the admin password"
echo -e "    2. Create your first project"
echo -e "    3. (Optional) Add a license via Administration > Licensing"
echo -e "    4. (Optional) Set up HTTPS with a reverse proxy (nginx)"
echo ""
ok "Done! Enjoy Dataiku DSS."
