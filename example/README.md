# UI Market Example

This is a Flutter application demonstrating how to use the `ui_market` CLI tool to install and use UI packs.

## Getting Started

1.  **Install the CLI:**

    ```bash
    dart pub global activate ui_market
    ```

2.  **Initialize `ui_market` in this directory (if not already done):**

    ```bash
    ui_market init
    ```

3.  **Search for packs:**

    ```bash
    ui_market search onboarding
    ```

4.  **Install a pack:**

    ```bash
    ui_market add onboarding_pack
    ```

    (Note: This example project already has `onboarding_pack` installed).

5.  **Run the app:**

    ```bash
    flutter run
    ```

## Installed Packs

- **onboarding_pack**: A beautiful onboarding flow.

## Code Structure

- `lib/ui/`: Contains installed UI packs and generated routes.
- `lib/main.dart`: Demonstrates how to use the generated routes.
