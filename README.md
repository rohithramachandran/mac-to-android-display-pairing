# Mac to Android Display Pairing

A high-performance, low-latency solution to use your Android tablet or phone as an extended display for your Mac.

## How it Works

1.  **Virtual Display**: Uses [BetterDisplay](https://betterdisplay.pro/) to create a high-quality virtual screen on your Mac.
2.  **Streaming Application**: A native macOS app (`MacStreamer`) uses `ffmpeg` to capture the virtual display at 60 FPS.
3.  **Low Latency**: The video stream is sent via `adb` port forwarding directly to an Android app, ensuring minimal delay compared to Wi-Fi based solutions.
4.  **Android Receiver**: A dedicated Android app receives the H.264 stream and displays it using hardware-accelerated decoding.

## Prerequisites

### On your Mac
- **macOS Catalina (10.15) or newer**.
- **BetterDisplay**: To create virtual screens. [Download here](https://betterdisplay.pro/).
- **FFmpeg**: Required for screen capture and encoding.
  ```bash
  brew install ffmpeg
  ```
- **Android Platform Tools (ADB)**:
  ```bash
  brew install --cask android-platform-tools
  ```

### On your Android Device
- **USB Debugging**: Enabled in Developer Options.
- **Android 7.0 (Nougat) or newer**.

## Setup Instructions

### 1. Configure BetterDisplay
- Open BetterDisplay.
- Create a new Virtual Screen (e.g., 1920x1080).
- Ensure it is active and positioned in your Display Settings.

### 2. Connect your Android Device
Connect your tablet/phone via USB and ensure it's recognized:
```bash
adb devices
```

### 3. Install the Android App

You have two options for the Android receiver app:

#### Option A: Use Pre-built APK (Recommended)
The repository includes a pre-built debug APK. You don't need to build the Android project unless you want to make changes.
- **Location**: `android/app/build/outputs/apk/debug/app-debug.apk`
- **Install via ADB**:
  ```bash
  adb install android/app/build/outputs/apk/debug/app-debug.apk
  ```

#### Option B: Build from Source (Optional)
If you want to modify the app or build it yourself:
- Open the `android` folder in **Android Studio**.
- Build and run the `app` module on your connected device.

### 4. Start Streaming

You can use the native macOS application for a fully guided UI experience:

1. Open **MacStreamer** (found in `macos/dist/MacStreamer.app` or you can install the `.dmg`).
2. The app will automatically detect your connected Android device via ADB.
3. Click the **"List Displays"** button to find the correct **Display Index** for your virtual screen.
4. Update the "Display Index" in the app's settings.
5. Provide the Optional APK path if you haven't installed the Android app yet.
6. Click **Start Streaming**.

This will:
- Set up ADB port forwarding.
- Start the `MacDisplay` app on your Android device.
- Begin streaming your screen via hardware-accelerated FFmpeg.

> [!NOTE]
> You may need to grant screen recording permissions to `MacStreamer` in System Settings > Privacy & Security.

#### Optional CLI (for advanced users)
You can still run the provided stream script from your Mac terminal instead of using the UI:
```bash
./stream.sh
```

### 5. Stopping
To stop the session, simply click the **Stop Streaming** button in the MacStreamer app, or press `Ctrl+C` in the terminal if you are using `stream.sh`.

## Troubleshooting

- **No device found**: Check your USB cable and ensure "USB Debugging" is on. In the MacStreamer app, check if the device shows up under the "Devices" section.
- **FFmpeg error**: Ensure you have granted Screen Recording permissions and that the correct AVFoundation **Display Index** is selected. Use the "List Displays" button in the Mac app to help find it.
- **High latency**: Use a high-quality USB cable. The app and script are configured to use `h264_videotoolbox` (hardware encoding) for best performance on Mac.

## Contributing

Contributions are welcome! If you have ideas for enhancements, bug fixes, or new features, feel free to raise a request via a **Pull Request (PR)**. I am happy to review and accept improvements from the community.

## License

This project is fully open-source and released under the [MIT License](LICENSE). You are free to use, modify, and distribute it as you wish.
