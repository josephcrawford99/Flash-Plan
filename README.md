# Flash Plan

A native iOS app that scans a room with the iPhone's LiDAR (via Apple's RoomPlan) and
turns it into a clean, top-down 2D floorplan you can save to Photos. Walls, doors, and
windows come from a single scan; the app projects that 3D geometry to 2D, draws it, and
exports it.

Accuracy is a rough guide, not survey-grade.

## Requirements

- iPhone with a LiDAR sensor (iPhone 12 Pro or newer Pro model). RoomPlan does not run in
  the Simulator.
- iOS 17 or later.

## Building

Open `Flash Plan.xcodeproj` in Xcode, select a physical device, and run. There is no
package manifest or build script; the Xcode project is the source of truth. Apple
frameworks only, no third-party dependencies.

## Privacy

Everything runs on device. No accounts, no network, no analytics, no tracking. The only
output is the floorplan image you choose to save to your own photo library. See
[docs/privacy.md](docs/privacy.md).
