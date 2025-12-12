# Project File Summary

## Top Level
*   **`CameraAccess.entitlements`**: Specifies app capabilities and permissions (currently empty).
*   **`CameraAccessApp.swift`**: The main entry point. It initializes the Wearables SDK and sets up the primary SwiftUI views (`MainAppView`).
*   **`Info.plist`**: Configures app properties like display name, bundle ID, URL schemes, and privacy permissions (Bluetooth, Photo Library) required for the app's functionality.

## Utils
*   **`Utils/TimeUtils.swift`**: Defines the `StreamTimeLimit` enum for managing stream durations (e.g., 1 min, 5 min) and `TimeInterval` extensions for formatting countdowns, used by `StreamSessionViewModel`.

## ViewModels
*   **`ViewModels/DebugMenuViewModel.swift`**: (Debug only) Manages the debug menu visibility and integrates with `MockDeviceKitViewModel` for testing without physical hardware.
*   **`ViewModels/MockDeviceKit/MockDeviceKitViewModel.swift`**: Manages a collection of mock devices (`MockDeviceCardView.ViewModel`), allowing pairing/unpairing of simulated devices.
*   **`ViewModels/MockDeviceKit/MockDeviceViewModel.swift`**: Represents a single mock device, controlling simulated states (power, fold status) and media content (mock camera feeds/images).
*   **`ViewModels/StreamSessionViewModel.swift`**: Core view model for video streaming. It manages the `StreamSession` (from DAT SDK), video frames, photo capture, streaming status, and stream timers.
*   **`ViewModels/WearablesViewModel.swift`**: Primary view model managing DAT SDK integration. It handles device availability, registration state, and permission requests, driving `CameraAccessApp`.

## Views

### Components
*   **`Views/Components/CardView.swift`**: Reusable container with consistent card styling.
*   **`Views/Components/CircleButton.swift`**: Reusable circular button, used in streaming controls.
*   **`Views/Components/CustomButton.swift`**: Reusable button with primary/destructive styles, used throughout the app.
*   **`Views/Components/MediaPickerView.swift`**: UIKit-SwiftUI bridge for selecting media from the photo library (used by Mock Device Kit).
*   **`Views/Components/StatusText.swift`**: Reusable component for displaying conditional status text.

### Feature Views
*   **`Views/DebugMenuView.swift`**: Debug overlay for accessing mock device functionality via `DebugMenuViewModel`.
*   **`Views/HomeScreenView.swift`**: Welcome screen guiding users through DAT SDK registration; displayed when unregistered.
*   **`Views/MainAppView.swift`**: Central navigation hub. Shows `StreamSessionView` if registered, otherwise `HomeScreenView`.
*   **`Views/NonStreamView.swift`**: Displayed when not streaming. Shows tips, a "Start streaming" button, and disconnect options.
*   **`Views/PhotoPreviewView.swift`**: Displays and shares photos captured from the device.
*   **`Views/RegistrationView.swift`**: Invisible background view handling Deep Link callbacks from the Meta AI app to complete registration.
*   **`Views/StreamSessionView.swift`**: Container view switching between `StreamView` (active stream) and `NonStreamView` (idle).
*   **`Views/StreamView.swift`**: Main video streaming UI. Displays live video, stream controls, timer, and photo capture buttons.

### MockDeviceKit Views
*   **`Views/MockDeviceKit/MockDeviceCardView.swift`**: Controls for a single mock device (power, fold, media selection).
*   **`Views/MockDeviceKit/MockDeviceKitButton.swift`**: Specialized button for the debug interface.
*   **`Views/MockDeviceKit/MockDeviceKitView.swift`**: List view for managing multiple mock devices.

