# User Guide

Complete guide for using the 1Panel Open Source App to manage your 1Panel servers.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [First Launch](#first-launch)
3. [Adding a Server](#adding-a-server)
4. [Dashboard Overview](#dashboard-overview)
5. [Managing Containers](#managing-containers)
6. [File Management](#file-management)
7. [Database Management](#database-management)
8. [Website Management](#website-management)
9. [System Settings](#system-settings)
10. [Troubleshooting](#troubleshooting)

---

## Getting Started

### What is 1Panel Open Source App?

1Panel Open Source App is a Flutter-based mobile and desktop client for managing 1Panel servers. It provides a modern, intuitive interface for:

- Monitoring server status and resources
- Managing Docker containers and images
- Browsing and editing files
- Managing databases (MySQL, PostgreSQL, Redis)
- Managing websites and SSL certificates
- Viewing system logs

### System Requirements

**Mobile:**
- Android 6.0+ (API 23+)
- iOS 12.0+

**Desktop:**
- Windows 10+
- macOS 10.14+
- Linux (Ubuntu 18.04+, Fedora 30+)

**Web:**
- Modern browsers (Chrome, Firefox, Safari, Edge)

---

## First Launch

When you first open the app, you'll see the welcome screen:

1. **Welcome**: Introduction to the app features
2. **Server Setup**: Add your first 1Panel server
3. **Get Started**: Begin managing your server

---

## Adding a Server

### Prerequisites

Before adding a server, ensure:
- Your 1Panel server is running and accessible
- You have the API key from your 1Panel panel
- Your device can connect to the server network

### Step-by-Step Setup

1. **Tap "Add Server"** on the main screen
2. **Enter Server Information**:
   - **Name**: A friendly name for this server (e.g., "Production Server")
   - **Address**: Server URL (e.g., `https://panel.example.com` or `http://192.168.1.100:8080`)
   - **API Key**: Your 1Panel API key (found in 1Panel Panel Settings → API Interface)

3. **Test Connection**: Tap "Test Connection" to verify
4. **Save**: Tap "Save" to add the server

### Finding Your API Key

1. Log in to your 1Panel web interface
2. Go to **Panel Settings** → **API Interface**
3. Enable API access if not already enabled
4. Copy the API key
5. Add allowed IPs (your device's IP or `0.0.0.0/0` for all IPs)

### Security Tips

- **Use HTTPS**: Always use HTTPS in production
- **IP Whitelist**: Restrict API access to specific IPs
- **API Key**: Keep your API key secure and rotate it regularly
- **Network**: Use VPN for remote server access when possible

---

## Dashboard Overview

The dashboard provides a quick overview of your server's status:

### Status Cards

- **System Status**: CPU, Memory, Disk usage
- **Container Status**: Running/stopped containers count
- **Website Status**: Active websites count
- **Database Status**: Database services status

### Quick Actions

- **Containers**: Jump to container management
- **Files**: Open file manager
- **Databases**: Access database management
- **Websites**: Manage websites
- **Logs**: View system logs

### Real-time Monitoring

The dashboard updates in real-time showing:
- CPU usage percentage
- Memory usage (used/total)
- Disk usage (used/total)
- Network I/O statistics

---

## Managing Containers

### Container List

View all Docker containers with:
- **Status indicator**: Green (running), Red (stopped)
- **Name**: Container name
- **Image**: Docker image
- **Ports**: Exposed ports
- **Uptime**: How long the container has been running

### Container Actions

Tap any container to:
- **View Details**: Inspect container configuration
- **View Logs**: Stream container logs in real-time
- **Start/Stop**: Control container state
- **Restart**: Restart the container
- **Delete**: Remove the container

### Container Logs

The log viewer provides:
- Real-time log streaming
- Search functionality
- Log level filtering
- Copy and share logs
- Auto-scroll toggle

### Creating Containers

1. Tap the **+** button in the Containers tab
2. Select an image from the list or enter custom image name
3. Configure container options:
   - Container name
   - Port mappings
   - Volume mounts
   - Environment variables
4. Tap **Create** to start the container

---

## File Management

### File Browser

Navigate your server's filesystem with:
- **Breadcrumb navigation**: Quick folder jumping
- **File listing**: Name, size, modification date
- **Quick actions**: Tap and hold for context menu

### File Operations

- **Open**: View file contents (text files)
- **Download**: Save files to your device
- **Upload**: Send files to the server
- **Rename**: Change file/folder names
- **Delete**: Remove files/folders
- **Create**: New file or folder
- **Permissions**: View and edit file permissions

### Text Editor

Built-in text editor for configuration files:
- Syntax highlighting for common formats
- Line numbers
- Search and replace
- Auto-save
- Share/export files

### Supported File Types

- **Text files**: .txt, .md, .json, .yaml, .xml
- **Code files**: .py, .js, .html, .css, .dart, etc.
- **Config files**: .conf, .ini, .env
- **Logs**: .log files with special formatting

---

## Database Management

### Supported Databases

- **MySQL/MariaDB**: Full management support
- **PostgreSQL**: Connection and query support
- **Redis**: Key-value operations

### Database Operations

1. **Select Database Type**: Choose from MySQL, PostgreSQL, or Redis
2. **Connection**: App automatically connects using 1Panel configuration
3. **Browse**: View databases, tables, and data
4. **Query**: Execute SQL queries (MySQL/PostgreSQL)
5. **Manage**: Create, backup, and restore databases

### MySQL/MariaDB Features

- Database list and management
- Table structure viewing
- Data browsing with pagination
- SQL query execution
- User management
- Backup and restore

### Redis Features

- Key browsing and search
- Value viewing (string, hash, list, set, zset)
- Key expiration management
- Redis CLI interface
- Memory usage statistics

---

## Website Management

### Website List

View all configured websites:
- **Domain**: Primary domain name
- **Status**: Running/stopped indicator
- **SSL**: Certificate status
- **Type**: Static, PHP, Reverse Proxy, etc.

### Website Actions

- **View Details**: Configuration and statistics
- **Start/Stop**: Control website availability
- **Configure**: Edit website settings
- **SSL**: Manage certificates
- **Delete**: Remove website configuration

### SSL Certificate Management

- **View Certificates**: List all SSL certificates
- **Renew**: Manual certificate renewal
- **Auto-renewal**: Enable automatic renewal
- **Let's Encrypt**: Issue free certificates
- **Custom**: Upload your own certificates

---

## System Settings

### App Settings

Customize the app behavior:

- **Theme**: Light, Dark, or System default
- **Language**: English, Chinese, or System default
- **Notifications**: Enable/disable push notifications
- **Auto-refresh**: Dashboard refresh interval
- **Cache**: Clear app cache

### Server Settings

Manage your server connections:

- **Edit Server**: Update server details
- **Test Connection**: Verify server connectivity
- **Delete Server**: Remove server from app
- **Default Server**: Set primary server

### Security Settings

- **Biometric Lock**: Fingerprint/Face ID protection
- **PIN Code**: App access PIN
- **Auto-lock**: Lock app after inactivity
- **Hide Sensitive Data**: Mask API keys and passwords

---

## Troubleshooting

### Connection Issues

**Problem**: Cannot connect to server

**Solutions**:
1. Verify server URL is correct
2. Check API key is valid
3. Ensure IP whitelist includes your device
4. Test network connectivity (ping server)
5. Verify HTTPS certificate if using SSL

### Authentication Errors

**Problem**: "API key error" or "Unauthorized"

**Solutions**:
1. Regenerate API key in 1Panel settings
2. Update IP whitelist
3. Check system time is synchronized
4. Verify API interface is enabled

### Performance Issues

**Problem**: App is slow or unresponsive

**Solutions**:
1. Check network connection quality
2. Reduce dashboard refresh frequency
3. Clear app cache
4. Restart the app
5. Update to latest version

### Data Not Updating

**Problem**: Dashboard shows stale data

**Solutions**:
1. Pull down to refresh
2. Check server connectivity
3. Verify API permissions
4. Restart the app

### Common Error Codes

| Code | Meaning | Solution |
|------|---------|----------|
| 401 | Unauthorized | Check API key and IP whitelist |
| 403 | Forbidden | Verify API permissions |
| 404 | Not Found | Check server URL |
| 500 | Server Error | Check 1Panel server logs |
| 503 | Service Unavailable | 1Panel service may be down |

---

## Tips and Best Practices

### Security

- Use strong, unique API keys
- Enable IP whitelisting
- Use HTTPS for all connections
- Enable app lock (biometric or PIN)
- Regularly rotate API keys

### Performance

- Use local network when possible
- Limit concurrent connections
- Close unused server connections
- Regularly clear app cache

### Organization

- Use descriptive server names
- Group related containers with labels
- Document custom configurations
- Regular backups of important data

---

## Getting Help

### In-App Help

- Tap **?** icon in any screen for context-sensitive help
- Check tooltips on settings and options

### Online Resources

- **Documentation**: [GitHub Docs](https://github.com/yourusername/1PanelOpenSourceApp/tree/main/docs)
- **Issues**: [GitHub Issues](https://github.com/yourusername/1PanelOpenSourceApp/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/1PanelOpenSourceApp/discussions)

### Community

- Join our community forums
- Follow us on social media
- Contribute to the project

---

## Keyboard Shortcuts (Desktop)

| Shortcut | Action |
|----------|--------|
| `Ctrl/Cmd + R` | Refresh current view |
| `Ctrl/Cmd + F` | Search |
| `Ctrl/Cmd + N` | Add new server |
| `Ctrl/Cmd + ,` | Open settings |
| `Esc` | Go back/Close modal |

---

*Last updated: 2026-03-30*
