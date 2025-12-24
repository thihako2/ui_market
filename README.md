# UI Market CLI

A command-line tool for browsing, installing, and uploading Flutter UI packs from the Flutter UI Marketplace.

## Features

- 🔍 **Search** - Browse and search UI packs from the marketplace
- 📦 **Install** - Add UI packs to your Flutter project with one command
- 🗑️ **Remove** - Clean removal of installed packs
- 🔄 **Build** - Regenerate routes after changes
- ⬆️ **Upload** - Publish your UI packs to the marketplace

## Installation

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  ui_market: ^1.0.0
```

Or install globally:

```bash
dart pub global activate ui_market
```

## Quick Start

### 1. Initialize your project

```bash
dart run ui_market init
```

This creates:
```
lib/ui/
├── screens/
├── components/
├── theme/
└── generated/
    └── ui_routes.g.dart
ui_market.yaml
```

### 2. Search for UI packs

```bash
dart run ui_market search onboarding
```

### 3. Install a pack

```bash
dart run ui_market add onboarding_pack
```

### 4. Use in your app

```dart
import 'package:your_app/ui/generated/ui_routes.g.dart';

MaterialApp(
  routes: UIRoutes.routes,
  onGenerateRoute: UIRoutes.onGenerateRoute,
);
```

## Commands

### `init`

Initialize ui_market in a Flutter project.

```bash
dart run ui_market init [--registry <url>] [--output-dir <path>]
```

Options:
- `--registry, -r` - Custom registry URL
- `--output-dir, -o` - Output directory for UI files (default: `lib/ui`)

### `search`

Search for UI packs in the marketplace.

```bash
dart run ui_market search <keyword>
dart run ui_market search --tag <tag>
dart run ui_market search --all
```

### `add`

Install a UI pack.

```bash
dart run ui_market add <pack_id> [--version <version>] [--dry-run]
```

Options:
- `--version, -v` - Specific version to install
- `--skip-validation` - Skip code validation (not recommended)
- `--dry-run` - Preview what would be installed

### `remove`

Remove an installed pack.

```bash
dart run ui_market remove <pack_id> [--force] [--keep-files]
```

Options:
- `--force, -f` - Skip confirmation
- `--keep-files` - Keep files but remove from tracking

### `build`

Regenerate routes from installed packs.

```bash
dart run ui_market build [--verbose]
```

### `upload`

Upload a UI pack to the marketplace.

```bash
dart run ui_market upload [path] [--pr] [--dry-run]
```

Options:
- `--pr` - Create a pull request instead of direct publish
- `--dry-run` - Validate only, don't upload
- `--skip-format` - Skip dart format check
- `--token` - GitHub token (or use `GITHUB_TOKEN` env var)

## Creating UI Packs

### Pack Structure

```
my_pack/
├── screens/
│   └── my_screen.dart
├── components/
│   └── my_widget.dart
├── theme/
│   └── my_theme.dart
├── assets/
│   └── images/
├── previews/
│   ├── preview_1.png
│   └── preview_2.png
└── ui_manifest.json
```

### ui_manifest.json

```json
{
  "id": "my_pack",
  "name": "My UI Pack",
  "version": "1.0.0",
  "description": "Description of your pack",
  "author": "Your Name",
  "authorUrl": "https://github.com/yourname",
  "license": "MIT",
  "flutter": ">=3.10.0 <4.0.0",
  "screens": [
    {
      "name": "MyScreen",
      "route": "/my-screen",
      "file": "screens/my_screen.dart"
    }
  ],
  "dependencies": {},
  "assets": [],
  "tags": ["tag1", "tag2"]
}
```

### UI Code Rules

Your code must follow these rules:

✅ **Allowed:**
- `StatelessWidget` only
- Relative imports
- `package:flutter/*` imports
- Approved packages (flutter_svg, google_fonts, etc.)

❌ **Not Allowed:**
- `StatefulWidget` / `setState`
- State management (provider, bloc, riverpod, etc.)
- Networking (http, dio, etc.)
- Database / Storage
- `dart:io` or platform channels

### Upload

```bash
# Validate first
dart run ui_market upload ./my_pack --dry-run

# Upload with GitHub token
export GITHUB_TOKEN=ghp_yourtoken
dart run ui_market upload ./my_pack

# Or via PR
dart run ui_market upload ./my_pack --pr
```

## Configuration

### ui_market.yaml

```yaml
registry: https://github.com/your-org/flutter-ui-registry
output_dir: lib/ui
routes_file: lib/ui/generated/ui_routes.g.dart

installed_packs:
  onboarding_pack:
    version: "1.0.0"
    installed_at: "2025-01-15T10:00:00Z"
    files:
      - "lib/ui/onboarding_pack/screens/welcome_screen.dart"
```

## Self-Hosting

You can fork and run your own registry:

1. Fork `flutter-ui-registry` repository
2. Update `registry` URL in your projects' `ui_market.yaml`
3. Upload packs to your fork

## License

MIT
