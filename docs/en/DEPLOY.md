# Deployment Guide

## Prerequisites

- Flutter 3.16+ or later
- Dart 3.6+
- Access to a 1Panel server with API access enabled

## Developer Standards

- Authoritative standards: `AGENTS.md` (hard rules) and `CLAUDE.md` (process/details).
- Pre-commit baseline: `flutter analyze` and `dart run test_runner.dart unit`; run `integration` and `ui` when changes touch API/network or UI.

## Authentication Setup

1Panel API uses **API Key + Timestamp** authentication (No username/password required):

```
Token = MD5("1panel" + API-Key + UnixTimestamp)
```

**Required Headers:**
- `1Panel-Token`: MD5 hash of the authentication string
- `1Panel-Timestamp`: Current Unix timestamp (seconds)

## Environment Configuration

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and configure your settings:
   ```bash
   # Server Configuration
   PANEL_BASE_URL=http://your-panel-server:port
   API_VERSION=v2

   # Authentication (API Key only, no username/password)
   PANEL_API_KEY=your_api_key_here

   # Get API Key from: 1Panel Panel → Settings → API Interface
   ```

3. **Important**: Never commit `.env` to version control!

## Build for Production

### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle (for Google Play)
flutter build appbundle --release
```

Output locations:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### iOS

```bash
# Build for App Store
flutter build ios --release

# Or build IPA
flutter build ipa --release
```

### Web

```bash
flutter build web --release
```

Output location: `build/web/`

## Deployment Checklist

- [ ] API key configured correctly
- [ ] Server URL is accessible
- [ ] SSL certificate valid (for HTTPS)
- [ ] Time synchronization enabled (NTP)
- [ ] Test authentication before deployment

## API Key Authentication

### How to Get API Key

Login to 1Panel → Settings → API Interface → Generate API Key

### Token Generation

```dart
import 'package:crypto/crypto.dart';
import 'dart:convert';

String generateToken(String apiKey, int timestamp) {
  final data = '1panel$apiKey$timestamp';
  final bytes = utf8.encode(data);
  final digest = md5.convert(bytes);
  return digest.toString();
}
```

### Request Headers

```dart
final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
final token = generateToken(apiKey, timestamp);

final headers = {
  '1Panel-Token': token,
  '1Panel-Timestamp': timestamp.toString(),
  'Content-Type': 'application/json',
};
```

## Troubleshooting

### Common Issues

1. **401 Unauthorized**: Check API key and timestamp synchronization
2. **Connection refused**: Verify server URL and network connectivity
3. **SSL certificate error**: Check certificate validity or use HTTP for testing

### Time Synchronization

Ensure your device and server are time-synchronized using NTP.

```bash
# Linux - Enable NTP
sudo timedatectl set-ntp true
```

---

*Last updated: 2024-02-12*
