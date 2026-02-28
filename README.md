# Mac to Android Display Pairing

A high-performance, low-latency solution to use your Android tablet or phone as an extended display for your Mac.

## How it Works

1.  **Virtual Display**: Uses [BetterDisplay](https://betterdisplay.pro/) to create a high-quality virtual screen on your Mac.
2.  **Streaming**: Uses `ffmpeg` to capture the virtual display at 60 FPS.
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
Run the provided stream script from your Mac terminal:
```bash
./stream.sh
```
This script will:
- Set up ADB port forwarding.
- Start the `MacDisplay` app on your Android device.
- Begin streaming your screen via FFmpeg.

> [!TIP]
> **Finding your Display Index**:
> In `stream.sh`, you may need to update the `DISPLAY_INDEX`. Run this to find yours:
> ```bash
> ffmpeg -f avfoundation -list_devices true -i ""
> ```

> [!NOTE]
> You may need to grant screen recording permissions to `ffmpeg` or `Terminal` in System Settings > Privacy & Security.

### 5. Stopping
To stop the session, press `Ctrl+C` in the terminal where `stream.sh` is running.

## Troubleshooting

- **No device found**: Check your USB cable and ensure "USB Debugging" is on.
- **FFmpeg error**: Ensure you have granted Screen Recording permissions and that the `DISPLAY_INDEX` in `stream.sh` is correct.
- **High latency**: Use a high-quality USB cable. The script is configured to use `h264_videotoolbox` (hardware encoding) for best performance on Mac.
