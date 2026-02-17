# Running ZeroClaw on Android (Termux)

Build and run ZeroClaw on Android using [Termux](https://f-droid.org/en/packages/com.termux/) (F-Droid only; Play Store build is deprecated). Termux supports Android 5.0+; use the F-Droid build that matches your Android version. Build can take 15–30+ minutes on low-RAM devices.

---

## 1. Prerequisites

- **Termux** installed from F-Droid.
- **Storage permission:** Android → Settings → Apps → Termux → Permissions → enable Storage (or “Files and media”). Required if you put the install script on `/sdcard/` (e.g. via adb).
- **API key and provider** for ZeroClaw (e.g. OpenRouter). You’ll use these after the build in step 4, or copy an existing `~/.zeroclaw/config.toml` to the device.

---

## 2. Get the install script onto the phone

- **From a computer (with adb):** Enable USB debugging on the phone (Settings → About phone → tap Build number 7 times, then Settings → Developer options → USB debugging). On the computer: `adb push /path/to/zeroclaw/scripts/termux-install.sh /sdcard/`. If you get permission errors copying from `/sdcard/` in Termux, ensure Storage permission is enabled (step 1).
- **From the phone in Termux:**  
  `curl -Lo ~/termux-install.sh https://raw.githubusercontent.com/zeroclaw-labs/zeroclaw/main/scripts/termux-install.sh`

If the script is on `/sdcard/`: copy it to home first (Android often mounts `/sdcard/` noexec, so scripts there cannot be executed). In Termux:

```bash
cp /sdcard/termux-install.sh ~/
bash ~/termux-install.sh
```

If you downloaded to `~/` already, run:

```bash
bash ~/termux-install.sh
```

---

## 3. After the script finishes

The binary is at `~/zeroclaw/target/release/zeroclaw`.

---

## 4. Configure ZeroClaw

- **First-time:** Run `~/zeroclaw/target/release/zeroclaw onboard --api-key <your-key> --provider openrouter` (or your provider). Replace `<your-key>` with your API key.
- **Reuse existing config:** Copy your `config.toml` into Termux’s home, then: `mkdir -p ~/.zeroclaw && mv config.toml ~/.zeroclaw/config.toml`

---

## 5. Run ZeroClaw

```bash
~/zeroclaw/target/release/zeroclaw agent
```

Or `gateway`, `daemon`, etc. Use `pkg install tmux` and run inside tmux if you want the process to survive closing the session.

---

## 6. Optional: SSH from laptop over USB

**6.1 — USB debugging (one-time)**  
Phone: Settings → About phone → tap Build number 7 times; then Settings → Developer options → USB debugging on. Connect USB; when prompted, allow USB debugging.  
Host: run `adb devices -l`; the device should appear. Install adb if needed (e.g. Linux: `sudo apt-get install -y android-tools-adb`).

**6.2 — SSH server in Termux**  
In Termux:

```bash
pkg install -y openssh
passwd
sshd
whoami
```

Use the value printed by `whoami` as your **Termux username** in the next steps (e.g. `u0_a102`).

**6.3 — Connect from the host**  
Termux’s `sshd` listens on port **8022** on the phone. The host cannot open a TCP connection to that port over USB. Map a host port to the phone’s 8022: on the **host** run:

```bash
adb forward tcp:8023 tcp:8022
```

Then from the host, SSH using the **Termux username** from step 6.2 and the **host port** you used (here 8023):

```bash
ssh -o StrictHostKeyChecking=no -p 8023 <TERMUX_USERNAME>@127.0.0.1
```

Use **adb forward** (host port → device port), not **adb reverse**. If you get “Connection refused”, in Termux run `sshd` again and on the host run `adb forward tcp:8023 tcp:8022` again (the forward is lost after unplug).

**6.4 — Optional: key-based auth**  
On the laptop, print your public key: `cat ~/.ssh/id_ed25519.pub` (or the key file you use). In Termux, ensure `~/.ssh` exists, then append that single line to `~/.ssh/authorized_keys`. Next SSH login will use the key.

---

## Alternative: build without the script

In Termux, in order:

```bash
pkg update -y && pkg upgrade -y
pkg install -y git rust
git clone https://github.com/zeroclaw-labs/zeroclaw.git
cd zeroclaw
CARGO_BUILD_JOBS=1 cargo build --release
```

Binary: `~/zeroclaw/target/release/zeroclaw`. Then do step 4 (config) and step 5 (run).

---

## Cross-compile (optional)

You can cross-compile on a Linux host for the Termux/Android target and push the binary (e.g. via adb) instead of building on the device. Out of scope for this doc.
