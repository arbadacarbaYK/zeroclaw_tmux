# Running ZeroClaw on Android (Termux)

Yes, really. ZeroClaw’s tiny binary and <5 MB RAM appetite make it a surprisingly good fit for Android devices running [Termux](https://f-droid.org/en/packages/com.termux/). You can build it right on the phone — no need for a fancy rig. This guide covers the on-device build, an optional one-shot install script, and (if you’re into that) SSH from your laptop over USB so you don’t have to type everything on a 5-inch keyboard.

**Tested on:** Android 7, ~2.8 GB RAM. Termux supports **Android 5.0+** (pick the right F-Droid build for 5–6 vs 7+). Build time on a low-RAM device: 15–30+ minutes. Perfect for a tea break. Or two.

---

## Before you run anything

1. **Install Termux** from [F-Droid](https://f-droid.org/en/packages/com.termux/) (not the Play Store — that one’s deprecated and will make you sad).  
2. **Grant Storage** (or “Files and media”) in Android: Settings → Apps → Termux → Permissions. You’ll need this if you push the install script via adb or copy files from `/sdcard/`.  
3. **Credentials and config:** ZeroClaw needs an API key and provider (e.g. OpenRouter, OpenAI). You can run `zeroclaw onboard` *after* the build to set that up, or copy an existing `~/.zeroclaw/config.toml` onto the device. Have your key and provider name ready for the “after the script” step.

---

## Option A: One script (recommended)

We ship a script that does the boring bits for you. Same steps on any Termux device.

### Get the script onto the phone

- **From the ZeroClaw repo (if you cloned it on a computer):** Copy `scripts/termux-install.sh` to the phone (e.g. `adb push scripts/termux-install.sh /sdcard/` with USB debugging and adb), or download it from the repo on the phone (e.g. Termux: `curl -O https://raw.githubusercontent.com/zeroclaw-labs/zeroclaw/main/scripts/termux-install.sh` and move it to your home if needed).  
- **If you pushed to /sdcard/:** Android often doesn’t allow executing scripts directly from `/sdcard/`. Copy to your home first, then run:

  ```bash
  cp /sdcard/termux-install.sh ~/
  bash ~/termux-install.sh
  ```

### What the script does

It runs: `pkg update` / `pkg upgrade`, installs `git` and `rust`, clones the ZeroClaw repo, and runs `CARGO_BUILD_JOBS=1 cargo build --release`. When it finishes, the binary is at **`~/zeroclaw/target/release/zeroclaw`**.

### After the script: credentials and config

- **First-time setup:**  
  `~/zeroclaw/target/release/zeroclaw onboard --api-key <your-key> --provider openrouter`  
  (or your preferred provider). Follow the prompts.  
- **Or reuse existing config:** Copy your `~/.zeroclaw/config.toml` to the phone (e.g. into Termux’s home and then `mkdir -p ~/.zeroclaw && mv config.toml ~/.zeroclaw/`).  
- Run ZeroClaw: `~/zeroclaw/target/release/zeroclaw agent` (or `gateway`, `daemon`, etc.). Use **tmux** (`pkg install tmux`) to keep it running in the background so your phone can finally earn its keep.

---

## Option B: Manual build (same steps, no script)

Open Termux and run:

```bash
pkg update -y && pkg upgrade -y
pkg install -y git rust
git clone https://github.com/zeroclaw-labs/zeroclaw.git
cd zeroclaw
CARGO_BUILD_JOBS=1 cargo build --release
```

Then same as above: binary at `~/zeroclaw/target/release/zeroclaw`, run `zeroclaw onboard` or copy config, and use tmux to keep it alive.

---

## Optional: SSH from your laptop over USB

Because typing long commands on a phone keyboard is *fun* but only once. Use **adb** and Termux’s SSH server so the laptop does the work.

### USB debugging (one-time)

- **Phone:** Settings → About phone → tap **Build number** 7 times (“You are now a developer.” — we know). Then Settings → Developer options → **USB debugging** on.  
- Plug in the USB cable. When the phone asks **“Allow USB debugging?”**, tap Allow.  
- **Host:** `adb devices -l` — your device should show up. No adb? On Linux: `sudo apt-get install -y android-tools-adb`.

### SSH in Termux

In Termux:

```bash
pkg install -y openssh
passwd          # set a password (you’ll need it if you don’t set up keys)
sshd
whoami          # e.g. u0_a102 — this is your Termux username; note it
```

**Username:** Whatever `whoami` prints is your SSH login. Use it in place of `u0_a102` in the examples below.

### Ports (the slightly tricky bit)

- **8022** = Termux’s default SSH port **on the phone**. `sshd` listens there. In Termux you can check: `netstat -tlnp | grep 8022`.  
- The **host** can’t talk to the phone’s 8022 directly over USB. Use **adb forward** to map a **host port** (e.g. 8023) to the phone’s 8022. Then you run `ssh -p 8023 ...@127.0.0.1` on the host; adb forwards that to the phone.  
- Use **adb forward** (host → device), not **adb reverse** (device → host). We wanted the host to call the device, not the other way around. Forward = correct.

On the **host** (phone connected by USB):

```bash
adb forward tcp:8023 tcp:8022
ssh -o StrictHostKeyChecking=no -p 8023 <TERMUX_USERNAME>@127.0.0.1
```

Replace `<TERMUX_USERNAME>` with the output of `whoami` in Termux. If you get “Connection refused”, run `sshd` again in Termux and re-run `adb forward` (the forward disappears after you unplug).

---

## Gotchas

| Issue | Cause | Fix |
|-------|--------|-----|
| `cp: cannot open '/sdcard/...' for reading: Permission denied` | Termux doesn’t have Storage permission. | Settings → Apps → Termux → Permissions → enable Storage (or Files and media). |
| Script won’t run from `/sdcard/` | `/sdcard/` is often **noexec** on Android. | Copy to home first: `cp /sdcard/termux-install.sh ~/ && bash ~/termux-install.sh`. |
| `Connection refused` when running `ssh -p 8023 ...@127.0.0.1` on the host | Either `sshd` isn’t running in Termux, or you used **adb reverse** instead of **adb forward**. | In Termux run `sshd`. On the host use **adb forward**: `adb forward tcp:8023 tcp:8022`, then `ssh -p 8023 ...@127.0.0.1`. |
| Build takes forever | Rust on a phone is not a gaming PC. | Normal. Keep `CARGO_BUILD_JOBS=1`. To see if it’s still working: in Termux run `ps aux | grep -E 'cargo|rustc'`. |

---

## Quick reference

| Item | Value |
|------|--------|
| Termux user | Output of `whoami` in Termux (e.g. `u0_a102`). Use it in every `ssh ... @127.0.0.1` command. |
| SSH port on phone | **8022** (Termux default). Check: `netstat -tlnp | grep 8022` in Termux. |
| Host port for adb forward | Any free port (e.g. **8023**). `adb forward tcp:8023 tcp:8022` then `ssh -p 8023 <user>@127.0.0.1`. |
| ZeroClaw binary (on phone) | `~/zeroclaw/target/release/zeroclaw` |
| Config (on phone) | `~/.zeroclaw/config.toml` (create with `zeroclaw onboard` or copy from elsewhere). |

---

## Cross-compile (alternative)

If building on the device is too slow or runs out of memory, you can cross-compile on a Linux host for the Termux/Android target and push the binary (e.g. via adb to a path Termux can read, then `cp` and `chmod +x` in Termux). That’s out of scope here; the on-device build (or the script) is the straightforward path for most people.
