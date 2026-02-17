# Running ZeroClaw on Android (Termux)

Build and run ZeroClaw on Android using [Termux](https://f-droid.org/en/packages/com.termux/) (F-Droid only; Play Store build is deprecated). Termux supports Android 5.0+; use the F-Droid build that matches your Android version. Build can take 15–30+ minutes on low-RAM devices.

**Two ways:**

- **Path A — From the phone:** You do everything inside Termux on the device. No laptop.
- **Path B — From a laptop/PC over USB:** Phone is USB-connected; you or an agent run commands from the host via adb and SSH into Termux. All steps below in order, with copyable commands.

---

## Prerequisites (both paths)

- **Termux** installed from F-Droid.
- **Storage permission:** Android → Settings → Apps → Termux → Permissions → enable Storage (or “Files and media”). Required for Path B (script pushed to `/sdcard/`) and for Path A if you use adb to put the script on the phone.
- **API key and provider** for ZeroClaw (e.g. OpenRouter), or an existing `~/.zeroclaw/config.toml` to copy to the device. You’ll use these after the build.

**Path B only:** USB cable; adb on the host (e.g. Linux: `sudo apt-get install -y android-tools-adb`).

---

# Path A — Setup from the phone (Termux only)

All commands run inside Termux on the phone.

**1. Get the install script**

```bash
curl -Lo ~/termux-install.sh https://raw.githubusercontent.com/zeroclaw-labs/zeroclaw/main/scripts/termux-install.sh
```

**2. Run the script**

```bash
bash ~/termux-install.sh
```

**3. Configure ZeroClaw**

First-time (replace `<your-key>` with your API key):

```bash
~/zeroclaw/target/release/zeroclaw onboard --api-key <your-key> --provider openrouter
```

Or reuse config: copy your `config.toml` into Termux’s home, then:

```bash
mkdir -p ~/.zeroclaw && mv config.toml ~/.zeroclaw/config.toml
```

**4. Run ZeroClaw**

```bash
~/zeroclaw/target/release/zeroclaw agent
```

Or `gateway`, `daemon`, etc. To keep it running after closing the session: `pkg install tmux` and run the command inside tmux.

**Alternative to steps 1–2 (manual build):**

```bash
pkg update -y && pkg upgrade -y
pkg install -y git rust
git clone https://github.com/zeroclaw-labs/zeroclaw.git
cd zeroclaw
CARGO_BUILD_JOBS=1 cargo build --release
```

Then do steps 3 and 4. Binary is at `~/zeroclaw/target/release/zeroclaw`.

---

# Path B — Setup from a laptop/PC over USB (agent or you)

Phone USB-connected. You (or an agent) run commands from the host. Termux runs on the phone; you drive it via adb and SSH. Do the steps in order.

**B.1 — USB debugging and adb**

- **Phone:** Settings → About phone → tap Build number 7 times. Then Settings → Developer options → USB debugging on. Connect USB; when the phone asks, allow USB debugging.
- **Host:** Verify device:

```bash
adb devices -l
```

Install adb if needed (e.g. Linux: `sudo apt-get install -y android-tools-adb`).

**B.2 — One-time: SSH from host into Termux**

On the **phone**, open Termux and run (you need the username for the next step):

```bash
pkg install -y openssh
passwd
sshd
whoami
```

Use the value printed by `whoami` as `<TERMUX_USER>` in the commands below (e.g. `u0_a102`).

On the **host**, forward a host port to Termux’s SSH port (8022 on the phone):

```bash
adb forward tcp:8023 tcp:8022
```

From the **host**, SSH into Termux (replace `<TERMUX_USER>` with the value from `whoami`):

```bash
ssh -o StrictHostKeyChecking=no -p 8023 <TERMUX_USER>@127.0.0.1
```

You are now in a shell inside Termux on the phone. Use **adb forward** (host → device), not adb reverse. If you get “Connection refused”, run `sshd` again in Termux and run `adb forward tcp:8023 tcp:8022` again on the host (forward is lost after unplug).

Optional key-based auth: on the host run `cat ~/.ssh/id_ed25519.pub` (or your key path). In the Termux SSH session: `mkdir -p ~/.ssh`, then append that one line to `~/.ssh/authorized_keys`. Next logins use the key.

**B.3 — Get the install script onto the phone and run it**

From the **host** (use the path to your zeroclaw clone or the script):

```bash
adb push /path/to/zeroclaw/scripts/termux-install.sh /sdcard/
```

In the **SSH session** (Termux on the phone), copy from `/sdcard/` to home and run (Storage permission must be enabled; `/sdcard/` is noexec so run from home):

```bash
cp /sdcard/termux-install.sh ~/
bash ~/termux-install.sh
```

**B.4 — Configure ZeroClaw**

In the same SSH session (or in Termux on the phone).

First-time (replace `<your-key>` with your API key):

```bash
~/zeroclaw/target/release/zeroclaw onboard --api-key <your-key> --provider openrouter
```

Or reuse config: copy your `config.toml` to the device (e.g. via adb or scp), then in Termux:

```bash
mkdir -p ~/.zeroclaw && mv config.toml ~/.zeroclaw/config.toml
```

**B.5 — Run ZeroClaw**

In the SSH session (or in Termux on the phone):

```bash
~/zeroclaw/target/release/zeroclaw agent
```

Or `gateway`, `daemon`, etc. Use tmux so the process survives disconnect: `pkg install tmux`, then run the zeroclaw command inside tmux.

**Alternative to B.3 (manual build from SSH session):** In the SSH session (Termux):

```bash
pkg update -y && pkg upgrade -y
pkg install -y git rust
git clone https://github.com/zeroclaw-labs/zeroclaw.git
cd zeroclaw
CARGO_BUILD_JOBS=1 cargo build --release
```

Then do B.4 and B.5. Binary: `~/zeroclaw/target/release/zeroclaw`.

---

## Cross-compile (optional)

You can cross-compile on a Linux host for the Termux/Android target and push the binary (e.g. via adb) instead of building on the device. Out of scope for this doc.
