# Flutter UI Marketplace & CLI 📦

A comprehensive ecosystem for sharing, discovering, and installing production-ready Flutter UI components.

[![pub package](https://img.shields.io/pub/v/ui_market.svg)](https://pub.dev/packages/ui_market)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Table of Contents

- [Introduction](#introduction)
- [Installation](#installation)
- [Usage Guide](#usage-guide)
  - [Initialization](#initialization)
  - [Browsing & Searching](#browsing--searching)
  - [Installing Packs](#installing-packs)
  - [Using Components](#using-components)
- [Pack Development Guide](#pack-development-guide)
  - [Anatomy of a Pack](#anatomy-of-a-pack)
  - [Coding Guidelines & Constraints](#coding-guidelines--constraints)
  - [The Manifest File](#the-manifest-file)
- [Publishing Guide](#publishing-guide)
  - [Preparation](#preparation)
  - [Uploading](#uploading)
- [Architecture & Self-Hosting](#architecture--self-hosting)

---

## Introduction

**ui_market** solves the problem of "copy-pasting" UI code between projects. Instead of maintaining a snippets library or rewriting common screens, you can:

1.  **Package** your UI (Screens, Components, Themes) into a "Pack".
2.  **Upload** it to the shared registry.
3.  **Install** it into any project with a single command.

Unlike traditional packages, `ui_market` installs **source code** directly into your project, giving you full ownership and the ability to modify the UI to fit your needs.

---

## Installation

You can install the CLI globally to use it anywhere on your machine.

```bash
dart pub global activate ui_market
```

Once installed, verify it's working:

```bash
ui_market --version
```

---

## Usage Guide

### Initialization

Before using `ui_market` in a Flutter project, you need to initialize it. This sets up the configuration file and directory structure.

```bash
cd my_flutter_app
ui_market init
```

This creates:
- `ui_market.yaml`: Configuration file (defines registry URL, output paths).
- `lib/ui/`: The default directory where installed packs will live.

### Browsing & Searching

You don't need to leave your terminal to find components.

**List all available packs:**
```bash
ui_market search --all
```

**Search by keyword:**
```bash
# Search for onboarding screens
ui_market search onboarding

# Search for authentication related packs
ui_market search login
```

**Search by tag:**
```bash
ui_market search --tag modern
```

### Installing Packs

When you find a pack you like, install it by its ID.

```bash
ui_market add onboarding_pack
```

**What happens during installation?**
1.  **Fetch**: Downloads the pack bundle from the registry.
2.  **Validate**: Checks the code for security and compatibility.
3.  **Install**: Copies files to `lib/ui/<pack_id>/`.
4.  **Dependencies**: Automatically adds required packages (e.g., `google_fonts`, `flutter_svg`) to your `pubspec.yaml`.
5.  **Routes**: Generates a `ui_routes.g.dart` file for easy navigation.

### Using Components

After installation, you can use the screens immediately using the generated routes.

#### 1. Import Routes

In your `main.dart` or wherever you define your `MaterialApp`:

```dart
import 'package:your_app/ui/generated/ui_routes.g.dart';
```

#### 2. Register Routes

Connect the generated routes to your app:

```dart
MaterialApp(
  title: 'My App',
  // Register all installed UI routes
  routes: UIRoutes.routes,
  // Optional: Handle dynamic routing if supported
  onGenerateRoute: UIRoutes.onGenerateRoute,
);
```

#### 3. Navigate

Navigate to the installed screens using their predefined route names:

```dart
// Navigate to the onboarding welcome screen
Navigator.pushNamed(context, UIRoutes.welcome);
```

You can also inspect `lib/ui/generated/ui_routes.g.dart` to see all available route constants.

---

## Pack Development Guide

Want to contribute? Creating a pack is straightforward.

### Anatomy of a Pack

A clean pack structure is essential. Here is the recommended layout:

```
my_awesome_pack/
├── ui_manifest.json          # Metadata (REQUIRED)
├── screens/                  # Screen widgets (REQUIRED)
│   ├── login_screen.dart
│   └── signup_screen.dart
├── components/               # Reusable widgets
│   ├── custom_button.dart
│   └── social_icon.dart
├── theme/                    # Theme definitions
│   └── app_theme.dart
├── assets/                   # Static assets (images, icons)
│   └── images/
│       └── logo.png
└── previews/                 # Preview images for the marketplace
    └── screen1.png
```

### Coding Guidelines & Constraints

To ensure packs are universally compatible and secure, we enforce strict validation rules:

✅ **ALLOWED**:
- `StatelessWidget`: For pure UI components.
- `StatefulWidget`: Use sparingly, only for ephemeral UI state (animations, text input).
- Relative imports: `import '../components/button.dart';`
- Flutter SDK imports: `import 'package:flutter/material.dart';`
- Allowed 3rd party packages: `google_fonts`, `flutter_svg`, `intl`, `lucide_icons`.

❌ **FORBIDDEN (Strict Validation)**:
- **Networking**: No `http`, `dio`, or direct API calls. UI packs must be pure UI.
- **State Management**: No `bloc`, `provider`, `riverpod` logic inside the UI. State should be lifted out by the consumer.
- **File System**: No `dart:io` access.
- **Platform Channels**: No native code integration.
- **Absolute Paths**: No imports from your local project structure.

### The Manifest File

The `ui_manifest.json` is the heart of your pack. It tells the registry what your pack is.

```json
{
  "id": "modern_login_v1",                 // Unique ID (lowercase, underscores)
  "name": "Modern Login V1",               // Display name
  "version": "1.0.0",                      // Semantic version
  "description": "Clean login screen with social auth buttons",
  "author": "PixelPerfect",
  "authorUrl": "https://github.com/pixelperfect",
  "license": "MIT",
  "flutter": ">=3.10.0 <4.0.0",            // Supported Flutter versions
  "tags": ["login", "auth", "modern", "clean"],
  
  // List of screens to expose as routes
  "screens": [
    {
      "name": "LoginScreen",               // Class name
      "route": "/login",                   // Default route path
      "file": "screens/login_screen.dart", // File path relative to pack root
      "description": "Main login screen"
    }
  ],
  
  // 3rd party dependencies this pack needs
  "dependencies": {
    "google_fonts": "^6.1.0",
    "flutter_svg": "^2.0.0"
  },
  
  // Hosted preview images (URLs)
  "previews": [
    "https://example.com/previews/login_v1.png"
  ]
}
```

---

## Publishing Guide

Ready to share your work with the community?

### Preparation

1.  **Format your code**:
    ```bash
    dart format .
    ```
2.  **Verify structure**: Ensure `ui_manifest.json` is valid.
3.  **Validate locally**: Use the CLI to check for errors before uploading.
    ```bash
    ui_market upload ./my_pack --dry-run
    ```

### Uploading

We use a **Shared Community Registry**, so you don't need to configure your own servers or tokens.

**Command:**
```bash
ui_market upload ./my_pack
```

**That's it!** failed validation will be rejected. If successful:

1.  The CLI bundles your files into a zip.
2.  It uploads the bundle to the community GitHub Repository as a Release.
3.  It updates the Registry Index so everyone can see it immediately.

---

## Architecture & Self-Hosting

`ui_market` is decentralized by design.

- **Registry**: A simple GitHub repository containing an `index.json` and Release assets.
- **Marketplace App**: A Flutter web app that reads the `index.json` to display a nice UI.
- **CLI**: The tool that interacts with the registry.

**Want your own private registry?**

1.  **Fork** the [ui_registry](https://github.com/thihasithuleon369kk-rgb/ui_registry).
2.  **Edit** your project's `ui_market.yaml`:
    ```yaml
    registry: https://github.com/YOUR_ORG/your_private_registry
    ```
3.  **Configure** your CLI to upload to this new repo (requires a GitHub Token).

```bash
export GITHUB_TOKEN=your_private_token
ui_market upload ./pack
```

---

Made with ❤️ by the Flutter Community.
