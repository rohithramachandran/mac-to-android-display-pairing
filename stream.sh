#!/bin/bash

# Port to use for streaming
PORT=5000

# Function to run adb command
run_adb() {
    adb "$@"
}

echo "Checking for connected Android devices..."
devices=$(run_adb devices | grep -w "device")

if [ -z "$devices" ]; then
    echo "Error: No Android device connected or authorized."
    echo "Please connect a device via USB and ensure USB debugging is enabled."
    exit 1
fi

echo "Setting up adb port forwarding on port $PORT..."
run_adb forward tcp:$PORT tcp:$PORT
if [ $? -ne 0 ]; then
    echo "Failed to set up adb forward. Is adb running?"
    exit 1
fi

echo "Searching for Android app..."
# Optional: install APK if not installed or update
APK_PATH="android/app/build/outputs/apk/debug/app-debug.apk"
if [ -f "$APK_PATH" ]; then
    echo "Installing/Updating APK on device..."
    run_adb install -r -d "$APK_PATH"
fi

echo "Starting MacDisplay app on Android device..."
run_adb shell am start -n com.macdisplay.app/.MainActivity

echo "Waiting a few seconds for app to initialize server..."
sleep 3

echo "Starting ffmpeg screen capture and streaming to Android device..."
# Notes on ffmpeg command:
# -f avfoundation -i "1:none" captures screen index 1. On some Macs this should be "1" or "2"
# -pix_fmt yuv420p is required for MediaCodec compatibility
# -vcodec libx264 software encoding (or h264_videotoolbox for hardware, but tricky with latency)
# -tune zerolatency vital for low latency
# -preset ultrafast uses minimum CPU but higher bandwidth
# -f h264 outputs raw H.264 stream
# tcp://127.0.0.1:5000 sends it to the adb forwarded port

# To find your display index, you can run: ffmpeg -f avfoundation -list_devices true -i ""
DISPLAY_INDEX="6" # Usually "Capture screen 1"

ffmpeg -fflags nobuffer -flags low_delay \
    -f avfoundation \
    -pix_fmt uyvy422 \
    -probesize 5M \
    -capture_cursor 1 \
    -framerate 60 \
    -i "$DISPLAY_INDEX" \
    -vf "scale=1920:1080,format=yuv420p" \
    -r 60 \
    -c:v h264_videotoolbox \
    -profile:v baseline \
    -realtime 1 \
    -bf 0 \
    -g 60 \
    -b:v 6M \
    -f h264 "tcp://127.0.0.1:$PORT"

# When ffmpeg exits, remove the forward
echo "Cleaning up..."
run_adb forward --remove tcp:$PORT
