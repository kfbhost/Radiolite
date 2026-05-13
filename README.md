# RadioLite — Lightweight Internet Radio Automation System

A browser-based radio automation platform for Ubuntu 24.04 VPS servers.

## Features

- **Stream to Icecast** — Broadcast your radio station to the world
- **Upload Music** — Drag & drop MP3/OGG/FLAC/WAV uploads with auto-metadata
- **Playlists** — Create, manage, and schedule playlists
- **AutoDJ Engine** — Liquidsoap-powered continuous random playback
- **Live DJ Takeover** — DJs connect via BUTT/Mixxx/SAM Broadcaster
- **DJ Management** — Web-based DJ account management
- **Scheduling** — Time-based playlist scheduling
- **Now Playing** — Real-time currently playing track display

## Requirements

- Ubuntu 24.04 (VPS or dedicated server)
- Minimum 512MB RAM
- Root or sudo access
- Domain name or static IP (recommended)

## Quick Install

```bash
# Download and run the installer
wget https://raw.githubusercontent.com/yourrepo/radiolite/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

The installer will:
1. Install all dependencies (PHP 8.3, Icecast2, Liquidsoap, FFmpeg, SQLite)
2. Configure Apache web server
3. Create the SQLite database with all tables
4. Set up directory structure and permissions
5. Configure Icecast2 automatically
6. Create default admin account (admin/admin123)
7. Start all services

## Post-Installation

1. Open `http://your-server-ip/admin` in a browser
2. Login with: **admin** / **admin123**
3. **Immediately change your password** (you'll be prompted)
4. Upload music files via the Upload page
5. Create playlists and assign tracks
6. Configure stream settings under Settings
7. Start the AutoDJ engine

## Directory Structure

```
/opt/radiolite/
├── app/
│   ├── api/           # API endpoints
│   │   ├── login.php      # Authentication API
│   │   ├── tracks.php     # Track management API
│   │   ├── playlists.php  # Playlist management API
│   │   ├── autodj.php     # AutoDJ control API
│   │   ├── schedule.php   # Schedule management API
│   │   ├── users.php      # User/DJ management API
│   │   └── live.php       # Live DJ takeover API
│   ├── config/         # Configuration files
│   │   ├── db.php          # Database class
│   │   └── config.php      # App configuration
│   └── includes/       # Core classes
│       ├── auth.php        # Authentication system
│       ├── helpers.php     # Helper functions
│       ├── tracks.php      # Track management
│       ├── playlists.php   # Playlist management
│       ├── users.php       # User management
│       ├── autodj.php      # AutoDJ engine
│       ├── schedule.php    # Schedule management
│       └── live.php        # Live takeover system
├── public/             # Web root
│   ├── css/
│   │   └── style.css       # Dark modern theme
│   ├── js/
│   │   └── app.js          # Frontend application
│   ├── index.php           # Main application layout
│   ├── login.php           # Login page
│   ├── logout.php          # Logout handler
│   ├── change-password.php # Password change page
│   ├── api.php             # API router
│   └── .htaccess           # Apache configuration
├── music/              # Music library storage
├── uploads/            # Temporary upload directory
├── config/             # Application config & database
│   ├── radiolite.db    # SQLite database
│   └── icecast.conf    # Icecast credentials
├── logs/               # Application logs
├── scripts/            # System scripts
│   ├── autodj.liq      # Liquidsoap AutoDJ script
│   └── monitor.sh      # AutoDJ/monitoring daemon
└── install.sh          # Installation script
```

## API Endpoints

All API endpoints require authentication (except status).

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/login` | POST | Login/logout/status |
| `/api/tracks` | GET/POST | List, upload, delete, scan tracks |
| `/api/playlists` | GET/POST | CRUD playlists, manage tracks |
| `/api/autodj` | GET/POST | AutoDJ control and settings |
| `/api/schedule` | GET/POST | Schedule management |
| `/api/users` | GET/POST | User/DJ management |
| `/api/live` | GET/POST | Live DJ takeover |
| `/api/status` | GET | Public station status |

## AutoDJ Engine

The AutoDJ uses Liquidsoap for continuous playback:
- Random playlist track selection
- Automatic Icecast streaming
- Live DJ takeover support (AutoDJ pauses when live source connects)
- Automatic restart on crash
- Metadata updates from Icecast

## Live DJ Takeover

DJs can connect using any Icecast source client:
- **BUTT** (Broadcast Using This Tool)
- **Mixxx**
- **SAM Broadcaster**
- **OBS Studio** (with audio capture)

When a live source connects:
1. AutoDJ automatically pauses
2. Live audio is streamed to listeners
3. When the DJ disconnects, AutoDJ resumes

## Security

- Password hashing with bcrypt
- Session-based authentication
- CSRF protection via session tokens
- Input sanitization
- Force password change on first login
- Role-based access control (admin/dj)

## Configuration

Stream settings can be changed via the web interface under Settings:
- Stream name, genre, description
- Icecast host, port, mount point
- Source password
- Audio bitrate, sample rate, format (MP3/OGG)

## Troubleshooting

**AutoDJ won't start:**
```bash
# Check logs
tail -f /opt/radiolite/logs/autodj.log
tail -f /opt/radiolite/logs/liquidsoap.log

# Check if port is available
sudo lsof -i :8000
```

**Can't upload files:**
```bash
# Check permissions
sudo chown -R www-data:www-data /opt/radiolite/uploads
sudo chmod -R 775 /opt/radiolite/uploads

# Check PHP limits
sudo nano /etc/php/8.3/apache2/php.ini
# upload_max_filesize = 50M
# post_max_size = 55M
```

**Icecast not accessible:**
```bash
# Check Icecast status
sudo systemctl status icecast2
# Check firewall
sudo ufw allow 8000/tcp
```

## License

MIT License — Free to use and modify