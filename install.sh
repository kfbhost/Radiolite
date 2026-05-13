#!/bin/bash
#===============================================================================
# RadioLite - Lightweight Internet Radio Automation System
# Installation Script for Ubuntu 24.04
#===============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}  RadioLite - Internet Radio Automation System Installer${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""

# Configuration
INSTALL_DIR="/opt/radiolite"
ADMIN_PASSWORD="admin123"
ICECAST_PORT=8000
STREAM_MOUNT="/stream"

# Detect public IP
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#===============================================================================
# Step 1: Update System & Install Dependencies
#===============================================================================
echo -e "${YELLOW}[1/10] Updating system and installing dependencies...${NC}"
apt-get update -qq
apt-get upgrade -y -qq
apt-get install -y -qq \
    apache2 \
    php8.3 \
    php8.3-cli \
    php8.3-sqlite3 \
    php8.3-curl \
    php8.3-gd \
    php8.3-mbstring \
    php8.3-xml \
    sqlite3 \
    ffmpeg \
    liquidsoap \
    icecast2 \
    curl \
    cron \
    pwgen \
    jq \
    coreutils \
    2>&1 | tail -5

echo -e "${GREEN}  Dependencies installed${NC}"

#===============================================================================
# Step 2: Create Directory Structure
#===============================================================================
echo -e "${YELLOW}[2/10] Creating directory structure...${NC}"
mkdir -p "${INSTALL_DIR}/app/config"
mkdir -p "${INSTALL_DIR}/app/includes"
mkdir -p "${INSTALL_DIR}/app/api"
mkdir -p "${INSTALL_DIR}/public/css"
mkdir -p "${INSTALL_DIR}/public/js"
mkdir -p "${INSTALL_DIR}/public/partials"
mkdir -p "${INSTALL_DIR}/music"
mkdir -p "${INSTALL_DIR}/uploads"
mkdir -p "${INSTALL_DIR}/config"
mkdir -p "${INSTALL_DIR}/logs"
mkdir -p "${INSTALL_DIR}/scripts"
mkdir -p "${INSTALL_DIR}/tmp"
mkdir -p "${INSTALL_DIR}/playlists"
mkdir -p /var/lib/icecast2

echo -e "${GREEN}  Directory structure created${NC}"

#===============================================================================
# Step 3: Set Permissions
#===============================================================================
echo -e "${YELLOW}[3/10] Setting permissions...${NC}"
useradd -r -s /bin/false radiolite 2>/dev/null || true
chown -R www-data:www-data "${INSTALL_DIR}"
chmod -R 755 "${INSTALL_DIR}"
chmod 775 "${INSTALL_DIR}/music" "${INSTALL_DIR}/uploads" "${INSTALL_DIR}/config" "${INSTALL_DIR}/playlists"
chmod 777 "${INSTALL_DIR}/uploads"
chmod 777 "${INSTALL_DIR}/logs"
chmod 777 "${INSTALL_DIR}/tmp"

echo -e "${GREEN}  Permissions configured${NC}"

#===============================================================================
# Step 4: Configure Icecast2
#===============================================================================
echo -e "${YELLOW}[4/10] Configuring Icecast2...${NC}"

ICECAST_SOURCE_PASSWORD=$(openssl rand -hex 12)
ICECAST_RELAY_PASSWORD=$(openssl rand -hex 12)
ICECAST_ADMIN_PASSWORD=$(openssl rand -hex 12)

cat > /etc/icecast2/icecast.xml << ICECAST_EOF
<icecast>
    <limits>
        <clients>100</clients>
        <sources>2</sources>
        <queue-size>524288</queue-size>
        <client-timeout>30</client-timeout>
        <header-timeout>15</header-timeout>
        <source-timeout>10</source-timeout>
        <burst-on-connect>1</burst-on-connect>
        <burst-size>65535</burst-size>
    </limits>
    
    <authentication>
        <source-password>${ICECAST_SOURCE_PASSWORD}</source-password>
        <relay-password>${ICECAST_RELAY_PASSWORD}</relay-password>
        <admin-user>admin</admin-user>
        <admin-password>${ICECAST_ADMIN_PASSWORD}</admin-password>
    </authentication>
    
    <hostname>${PUBLIC_IP}</hostname>
    <listen-socket>
        <port>${ICECAST_PORT}</port>
        <bind-address>0.0.0.0</bind-address>
        <shoutcast-mount>${STREAM_MOUNT}</shoutcast-mount>
    </listen-socket>
    
    <paths>
        <basedir>/usr/share/icecast2</basedir>
        <logdir>/var/log/icecast2</logdir>
        <webroot>/usr/share/icecast2/web</webroot>
        <adminroot>/usr/share/icecast2/admin</adminroot>
        <alias source="/" destination="/status.xsl"/>
    </paths>
    
    <logging>
        <accesslog>access.log</accesslog>
        <errorlog>error.log</errorlog>
        <playlistlog>playlist.log</playlistlog>
        <loglevel>3</loglevel>
        <logsize>10000</logsize>
    </logging>
    
    <security>
        <chroot>0</chroot>
    </security>
</icecast>
ICECAST_EOF

# Store passwords in config
cat > "${INSTALL_DIR}/config/icecast.conf" << CONF_EOF
ICECAST_PORT=${ICECAST_PORT}
ICECAST_MOUNT=${STREAM_MOUNT}
ICECAST_HOST=${PUBLIC_IP}
ICECAST_SOURCE_PASSWORD=${ICECAST_SOURCE_PASSWORD}
ICECAST_ADMIN_PASSWORD=${ICECAST_ADMIN_PASSWORD}
CONF_EOF

chown www-data:www-data "${INSTALL_DIR}/config/icecast.conf"
chmod 600 "${INSTALL_DIR}/config/icecast.conf"

sed -i 's/ENABLE=false/ENABLE=true/' /etc/default/icecast2

echo -e "${GREEN}  Icecast2 configured${NC}"

#===============================================================================
# Step 5: Deploy Application Files
#===============================================================================
echo -e "${YELLOW}[5/10] Deploying application files...${NC}"

# Copy PHP includes
cp "${SCRIPT_DIR}/app/config/db.php" "${INSTALL_DIR}/app/config/db.php"
cp "${SCRIPT_DIR}/app/config/config.php" "${INSTALL_DIR}/app/config/config.php"
cp "${SCRIPT_DIR}/app/includes/auth.php" "${INSTALL_DIR}/app/includes/auth.php"
cp "${SCRIPT_DIR}/app/includes/helpers.php" "${INSTALL_DIR}/app/includes/helpers.php"
cp "${SCRIPT_DIR}/app/includes/tracks.php" "${INSTALL_DIR}/app/includes/tracks.php"
cp "${SCRIPT_DIR}/app/includes/playlists.php" "${INSTALL_DIR}/app/includes/playlists.php"
cp "${SCRIPT_DIR}/app/includes/users.php" "${INSTALL_DIR}/app/includes/users.php"
cp "${SCRIPT_DIR}/app/includes/autodj.php" "${INSTALL_DIR}/app/includes/autodj.php"
cp "${SCRIPT_DIR}/app/includes/schedule.php" "${INSTALL_DIR}/app/includes/schedule.php"
cp "${SCRIPT_DIR}/app/includes/live.php" "${INSTALL_DIR}/app/includes/live.php"

# Copy API endpoints
cp "${SCRIPT_DIR}/app/api/login.php" "${INSTALL_DIR}/app/api/login.php"
cp "${SCRIPT_DIR}/app/api/tracks.php" "${INSTALL_DIR}/app/api/tracks.php"
cp "${SCRIPT_DIR}/app/api/playlists.php" "${INSTALL_DIR}/app/api/playlists.php"
cp "${SCRIPT_DIR}/app/api/autodj.php" "${INSTALL_DIR}/app/api/autodj.php"
cp "${SCRIPT_DIR}/app/api/schedule.php" "${INSTALL_DIR}/app/api/schedule.php"
cp "${SCRIPT_DIR}/app/api/users.php" "${INSTALL_DIR}/app/api/users.php"
cp "${SCRIPT_DIR}/app/api/live.php" "${INSTALL_DIR}/app/api/live.php"
cp "${SCRIPT_DIR}/app/api/upload.php" "${INSTALL_DIR}/app/api/upload.php"

# Copy public files
cp "${SCRIPT_DIR}/public/index.php" "${INSTALL_DIR}/public/index.php"
cp "${SCRIPT_DIR}/public/login.php" "${INSTALL_DIR}/public/login.php"
cp "${SCRIPT_DIR}/public/logout.php" "${INSTALL_DIR}/public/logout.php"
cp "${SCRIPT_DIR}/public/change-password.php" "${INSTALL_DIR}/public/change-password.php"
cp "${SCRIPT_DIR}/public/404.php" "${INSTALL_DIR}/public/404.php"
cp "${SCRIPT_DIR}/public/api.php" "${INSTALL_DIR}/public/api.php"
cp "${SCRIPT_DIR}/public/.htaccess" "${INSTALL_DIR}/public/.htaccess"
cp "${SCRIPT_DIR}/public/css/style.css" "${INSTALL_DIR}/public/css/style.css"
cp "${SCRIPT_DIR}/public/js/app.js" "${INSTALL_DIR}/public/js/app.js"

# Copy scripts
cp "${SCRIPT_DIR}/scripts/monitor.sh" "${INSTALL_DIR}/scripts/monitor.sh"

chown -R www-data:www-data "${INSTALL_DIR}"
chmod +x "${INSTALL_DIR}/scripts/monitor.sh"
chmod +x "${INSTALL_DIR}/app/api/*.php"

echo -e "${GREEN}  Application files deployed${NC}"

#===============================================================================
# Step 6: Create SQLite Database
#===============================================================================
echo -e "${YELLOW}[6/10] Creating database...${NC}"

DB_PATH="${INSTALL_DIR}/config/radiolite.db"

# Initialize database via PHP
php -r "
require_once '${INSTALL_DIR}/app/config/db.php';
require_once '${INSTALL_DIR}/app/config/config.php';
Database::init();
echo \"Database tables created.\n\";
"

# Create default admin user
ADMIN_HASH=$(php -r "echo password_hash('${ADMIN_PASSWORD}', PASSWORD_BCRYPT);")

sqlite3 "${DB_PATH}" << SQL_EOF
INSERT OR REPLACE INTO users (id, username, password, email, role, force_password_change, is_active, created_at)
VALUES (1, 'admin', '${ADMIN_HASH}', 'admin@radiolite.local', 'admin', 1, 1, datetime('now'));
SQL_EOF

chown www-data:www-data "${DB_PATH}"
chmod 660 "${DB_PATH}"

echo -e "${GREEN}  Database created with admin account (admin/${ADMIN_PASSWORD})${NC}"

#===============================================================================
# Step 7: Create Liquidsoap Script
#===============================================================================
echo -e "${YELLOW}[7/10] Creating Liquidsoap AutoDJ script...${NC}"

# Generate empty playlist file
cat > "${INSTALL_DIR}/playlists/main.m3u" << M3U_EOF
#EXTM3U
# RadioLite Main Playlist
M3U_EOF

chown www-data:www-data "${INSTALL_DIR}/playlists/main.m3u"

# Generate Liquidsoap config via PHP
php -r "
require_once '${INSTALL_DIR}/app/config/config.php';
require_once '${INSTALL_DIR}/app/includes/autodj.php';
AutoDJ::generateLiquidsoapConfig();
echo \"Liquidsoap script generated.\n\";
"

echo -e "${GREEN}  Liquidsoap script created${NC}"

#===============================================================================
# Step 8: Configure Apache
#===============================================================================
echo -e "${YELLOW}[8/10] Configuring Apache...${NC}"

cat > /etc/apache2/sites-available/radiolite.conf << APACHE_EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName ${PUBLIC_IP}
    DocumentRoot ${INSTALL_DIR}/public
    
    <Directory ${INSTALL_DIR}/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    <Directory ${INSTALL_DIR}/music>
        Options -Indexes
        Require all granted
    </Directory>
    
    <Directory ${INSTALL_DIR}/uploads>
        Options -Indexes
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/radiolite_error.log
    CustomLog \${APACHE_LOG_DIR}/radiolite_access.log combined
</VirtualHost>
APACHE_EOF

a2ensite radiolite.conf 2>/dev/null || true
a2dissite 000-default.conf 2>/dev/null || true
a2enmod rewrite headers 2>/dev/null || true

# Configure PHP
cat > /etc/php/8.3/apache2/conf.d/99-radiolite.ini << PHP_EOF
upload_max_filesize = 50M
post_max_size = 55M
max_execution_time = 300
memory_limit = 256M
PHP_EOF

echo -e "${GREEN}  Apache configured${NC}"

#===============================================================================
# Step 9: Create Systemd Services
#===============================================================================
echo -e "${YELLOW}[9/10] Creating systemd services...${NC}"

# Icecast2 service (already exists, just enable)
systemctl enable icecast2 2>/dev/null || true

# Liquidsoap AutoDJ service
cat > /etc/systemd/system/radiolite-autodj.service << AUTODJ_EOF
[Unit]
Description=RadioLite AutoDJ Engine
After=network.target icecast2.service
Wants=icecast2.service

[Service]
Type=simple
User=www-data
Group=www-data
ExecStart=/usr/bin/liquidsoap ${INSTALL_DIR}/scripts/autodj.liq
Restart=always
RestartSec=5
StandardOutput=append:${INSTALL_DIR}/logs/autodj.log
StandardError=append:${INSTALL_DIR}/logs/autodj-error.log

[Install]
WantedBy=multi-user.target
AUTODJ_EOF

# RadioLite monitor service
cat > /etc/systemd/system/radiolite-monitor.service << MONITOR_EOF
[Unit]
Description=RadioLite System Monitor
After=network.target

[Service]
Type=simple
User=www-data
ExecStart=${INSTALL_DIR}/scripts/monitor.sh
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
MONITOR_EOF

systemctl daemon-reload
systemctl enable radiolite-autodj radiolite-monitor

echo -e "${GREEN}  Systemd services created${NC}"

#===============================================================================
# Step 10: Start Services
#===============================================================================
echo -e "${YELLOW}[10/10] Starting services...${NC}"

systemctl start icecast2
sleep 2
systemctl start radiolite-autodj
sleep 2
systemctl start radiolite-monitor

echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}  RadioLite Installation Complete!${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo -e "  Admin URL:    http://${PUBLIC_IP}/admin"
echo -e "  DJ URL:       http://${PUBLIC_IP}/dj"
echo -e "  Stream URL:   http://${PUBLIC_IP}:${ICECAST_PORT}${STREAM_MOUNT}"
echo -e "  Admin Login:  admin / ${ADMIN_PASSWORD}"
echo ""
echo -e "  ${YELLOW}IMPORTANT: Change the admin password after first login!${NC}"
echo ""
echo -e "  Icecast Status: http://${PUBLIC_IP}:${ICECAST_PORT}/status.xsl"
echo -e "  AutoDJ Logs:    tail -f ${INSTALL_DIR}/logs/autodj.log"
echo -e "  Monitor Logs:   tail -f ${INSTALL_DIR}/logs/monitor.log"
echo ""