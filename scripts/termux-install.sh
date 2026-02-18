#!/data/data/com.termux/files/usr/bin/bash
# ZeroClaw on Android (Termux) — one script to rule them all.
# Run this inside Termux. Works on any device with Termux (Android 5+).
# Prerequisites: Termux from F-Droid, Storage permission if you got this script via adb push to /sdcard/.
# After the script: run zeroclaw onboard (or copy config) to add your API key and provider.

set -e
echo "=== ZeroClaw Termux install ==="
echo "Go grab a tea. Or two. This can take a while on a phone."
echo ""

echo "--- Updating packages ---"
pkg update -y && pkg upgrade -y

echo "--- Installing git and Rust ---"
pkg install -y git rust

echo "--- Cloning ZeroClaw ---"
cd ~
if [ -d zeroclaw ]; then
  echo "zeroclaw dir already exists; pulling latest."
  cd zeroclaw && git pull
else
  git clone https://github.com/zeroclaw-labs/zeroclaw.git
  cd zeroclaw
fi

echo "--- Building (single job to be nice to RAM). This is the long part. ---"
# On Android, default "hardware" feature uses nusb::list_devices() which is not available;
# --no-default-features builds software-only (agent, gateway, etc.) and avoids compile failure.
CARGO_BUILD_JOBS=1 cargo build --release --no-default-features

echo ""
echo "=== Done. Binary at: ~/zeroclaw/target/release/zeroclaw ==="
echo "Next: run   ~/zeroclaw/target/release/zeroclaw onboard --api-key <your-key> --provider openrouter"
echo "Or copy your existing ~/.zeroclaw/config.toml to this device."
echo "Use tmux to keep it running in the background. You're welcome."
