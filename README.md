# Mac to Android Display Pairing

A high-performance, low-latency solution to use your Android tablet or phone as an extended display for your Mac.

## How it Works

1.  **Virtual Display**: A Swift-based utility creates a virtual display on your Mac.
2.  **Streaming**: Uses `ffmpeg` to capture the virtual display at 60 FPS.
3.  **Low Latency**: The video stream is sent via `adb` port forwarding directly to an Android app, ensuring minimal delay compared to Wi-Fi based solutions.
4.  **Android Receiver**: A dedicated Android app receives the H.264 stream and displays it using hardware-accelerated decoding.

## Prerequisites

### On your Mac
- **macOS Catalina (10.15) or newer**.
- **Xcode Command Line Tools**: Required to compile the Swift utility.
  ```bash
  xcode-select --install
  ```
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

### 1. Build the Virtual Display Utility
In the root directory, compile the Swift script:
```bash
swiftc virtual_display.swift -o virtual_display
```

### 2. Connect your Android Device
Connect your tablet/phone via USB and ensure it's recognized:
```bash
adb devices
```

### 3. Start the Extended Display
Run the provided stream script. This will:
- Set up ADB port forwarding.
- (Optional) Install the Android app if you have the build environment set up.
- Start the Android app.
- Start a virtual display on your Mac.
- Begin streaming via FFmpeg.

```bash
./stream.sh
```

> [!NOTE]
> You may need to grant screen recording permissions to `ffmpeg` or `Terminal` in System Settings > Privacy & Security.

### 4. Stopping
To stop the session, press `Ctrl+C` in the terminal where `stream.sh` is running.

## Troubleshooting

- **No device found**: Check your USB cable and ensure "USB Debugging" is on.
- **FFmpeg error**: Ensure you have granted Screen Recording permissions.
- **High latency**: Use a high-quality USB cable. Software encoding (libx264) is currently used for widest compatibility, but `h264_videotoolbox` (hardware) is configured in the script for best performance.
