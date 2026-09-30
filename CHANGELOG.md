# Attendance Management Changelog

## [1.0.0] - 2025-09-29

Initial release of Attendance Management.

### Features

- **Dashboard** — View an overview of the application's status.
- **Member Registration** — Register and manage attendance members.
- **Event Registration** — Create and manage attendance events.
- **Wi-Fi Configuration** — Configure the ESP32 Wi-Fi connection.
- **Bluetooth Configuration** — Configure and communicate with the attendance device via Bluetooth.
- **Attendance Management** — Manage member attendance records with different presence modes.
- **API Integration** — Integrate with external APIs for data exchange.
- **Settings** — Configure application settings.

### Notes

This is the initial release of Attendance Management.

Since a release changelog was not created when the APK was initially released,
the source code and repository files associated with this release may represent
a later state of the project rather than the exact state of the original `v1.0.0`
release.

## [1.1.0] - 2026-09-30

### Added

- Add total members count to the dashboard.
- Add animations to the Members and Events pages.
- Add member filtering when managing member data.
- Add a Quick Actions button to the Bottom Navigation.
- Add an auto-reconnect setting to automatically reconnect to the last connected Bluetooth device
  after an unexpected disconnection.

### Changed

#### UI/UX

- Move the theme mode toggle from the App Bar to the Settings page.
- Redesign the active event overview on the dashboard.
- Redesign the registration view with a simpler form.
- Redesign the attendance view with a simpler carousel-based presence selection.
- Redesign the Bottom Navigation with a glassmorphism style.
- Reorganize the Bottom Navigation items.
- Reorganize the Settings options into categories.
- Reposition action buttons on Member and Event cards.

#### Bluetooth

- Sort the Bluetooth device list by name.
- Improve Bluetooth device scanning.
- Improve Bluetooth connection status feedback.
- Improve Bluetooth received-data serialization and deserialization.

#### Data & Synchronization

- Improve pagination for member and event data.
- Improve member registration and attendance synchronization.
- Improve loading feedback during member registration and attendance operations.

#### Development & Toolchain

- Upgrade Java from 11 to 17.
- Upgrade Gradle from 8.12 to 9.5.0.
- Upgrade Flutter from 3.44.4 to 3.47.2.
- Upgrade dependencies to their latest compatible versions.

### Removed

- Remove the App Bar from the Members, Events, Bluetooth, and Settings page.
- Remove the ESP32 Wi-Fi and Bluetooth connection status from the dashboard.
- Remove ESP32 Wi-Fi configuration in favor of using the ESP32's cellular internet connection.

### Fixed

- Fix member data not being sorted properly by name.
- Fix an issue where Bluetooth received data could overlap.
