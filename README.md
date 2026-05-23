# siren

Reproducible **8-channel judge recording** on Pop!_OS / Ubuntu with two identical **Thesycon USB HIFI AUDIO** interfaces (`152a:893a`) and **Tracktion Waveform 13**.

| Unit | Hub role | Waveform tracks | Playback |
|------|----------|-----------------|----------|
| **blood** | Fixed hub port | Inputs **1–4** | Stereo master mix → headphones / main outs |
| **siren** | Fixed hub port | Inputs **5–8** | Inputs only (turn down its **direct monitor** knob) |

**Goal:** one stereo monitor on **blood** that hears all 8 judge inputs, while Waveform records 8 separate tracks.

---

## Why this repo exists

Two identical USB boxes share the same vendor ID, serial, and driver. Linux and Waveform do not handle that gracefully out of the box:

- **PipeWire** can collapse both units into one card.
- **ALSA `route` / `asym` duplex** devices make Waveform probe nonsense channel counts (4, 256, or thousands).
- **Laptop USB** often cannot power both interfaces — one box drops off and you get **4 inputs**.

This repo installs ALSA virtual devices, WirePlumber rules, hub-port detection, and scripts that reset Waveform when channel counts go wrong.

---

## Requirements

- **Powered USB hub** (required — not optional)
- Both HIFI units on the **same hub ports every session**
- **Waveform 13** with **ALSA** backend (not JACK for the main path)
- PipeWire (default on Pop!_OS)

---

## Quick install (new laptop)

```bash
git clone git@github.com:platysonique/siren.git
cd siren
chmod +x scripts/*.sh
./scripts/install.sh
```

Plug **both** units into the powered hub, then:

```bash
./scripts/detect-hub-ports.sh      # finds ports → ~/.config/bloodsiren/hub-ports.env
./scripts/refresh-bloodsiren.sh    # writes ~/.asoundrc
./scripts/test-input8.sh           # must print: Channels 8
./scripts/test-blood-output.sh     # tone on blood headphones
./scripts/fix-waveform-stereo-sum.sh
```

Open Waveform → **Settings → Audio** → **Reset Input Devices** and **Reset Output Devices**, then confirm the table below.

---

## Waveform settings (required)

| Setting | Value |
|---------|--------|
| Device type | **ALSA** |
| Input device | **`bloodsiren_in`** |
| Output device | **`blood_mix_out`** |
| Sample rate | **48000 Hz** |
| Input channels | **1–8** enabled |
| Output channels | **1+2 only** (stereo master) |

### Do not use these devices in Waveform

| Device | Why |
|--------|-----|
| `bloodsiren` | Duplex device — Waveform channel probe breaks (4 / 256 / crash) |
| `default` | PipeWire → laptop speakers, not your interface |
| `blood_playback` / `siren_playback` | Per-card routing; use **`blood_mix_out`** for one master mix |

More detail: [bloodsiren-docs/WAVEFORM_SETTINGS.md](bloodsiren-docs/WAVEFORM_SETTINGS.md)

---

## “Only 4 inputs” — two different causes

This is the most common confusion. Check which case you have.

### Case A: Hardware — only one box is active

**Symptoms:** `test-input8.sh` reports **Channels 4**; `identify-units.sh` shows one unit missing.

**Causes:**

- Second unit unplugged or on a dead hub port
- **Unpowered** USB hub or laptop port — second unit never enumerates
- Wrong hub port in `hub-ports.env` after moving cables

**Fix:**

```bash
./scripts/detect-hub-ports.sh
./scripts/refresh-bloodsiren.sh
./scripts/test-input8.sh    # must say Channels 8
```

Use a **powered** hub. Keep blood and siren on the same physical ports every show.

---

### Case B: Software — both boxes work, but Waveform shows 4 inputs

**Symptoms:** `arecord -D bloodsiren_in -c 8` works in the terminal, but Waveform only offers 4 input channels (or hundreds of phantom channels).

**Cause:** Waveform was pointed at the wrong ALSA device (`bloodsiren` duplex, `default`, or an old config). ALSA `route`/`asym` wrappers also confuse Waveform’s channel probe.

**What this repo does instead:**

- **`bloodsiren_in`** — plain `multi` aggregate (blood 4ch + siren 4ch), **no** route/asym wrapper
- **`blood_mix_out`** — stereo sum on the blood card only
- **`fix-waveform-stereo-sum.sh`** — rewrites Waveform.settings to the correct devices and strips bad channel entries

**Fix:**

```bash
./scripts/refresh-bloodsiren.sh
./scripts/fix-waveform-stereo-sum.sh
```

Quit Waveform completely before running the fix script. Then in Waveform: **Reset Input Devices** → pick **`bloodsiren_in`** → enable channels **1–8**.

---

## Daily workflow (before a session)

```bash
./scripts/identify-units.sh          # both blood + siren present?
./scripts/refresh-bloodsiren.sh      # after moving USB ports or replugging hub
./scripts/fix-waveform-stereo-sum.sh # if Waveform lost 8ch or monitor is split per card
```

**Hardware:** On the **siren** box, turn **down** direct/local monitor so judges 5–8 are not isolated on that unit’s headphones — the full mix should come from **blood**.

---

## What gets installed

| Path | Purpose |
|------|---------|
| `~/.asoundrc` | Virtual devices: `bloodsiren_in`, `blood_mix_out`, … |
| `~/.config/bloodsiren/hub-ports.env` | Your hub port numbers (blood / siren) |
| `~/.config/wireplumber/.../51-hifi-audio-dual.conf` | Prevents merging both USB cards into one |
| `~/.config/pipewire/.../90-combine-judge-inputs.conf` | Optional 8ch PipeWire source for OBS |

Hub ports are matched by **USB path** (e.g. `2.3`, `2.2`), not by card number — card numbers change when you replug.

Example `~/.config/bloodsiren/hub-ports.env`:

```
HUB_PORT_BLOOD=2.3
HUB_PORT_SIREN=2.2
```

If blood and siren are swapped on the hub, swap the two lines and run `refresh-bloodsiren.sh`.

---

## Troubleshooting

| Symptom | What to run |
|---------|-------------|
| Only **4** inputs in terminal (`test-input8.sh`) | `detect-hub-ports.sh` → powered hub, both units plugged |
| **4** inputs in Waveform only, terminal has 8 | `fix-waveform-stereo-sum.sh` → input = `bloodsiren_in` |
| **256** or thousands of channels | Never use `bloodsiren` duplex; use `bloodsiren_in` |
| No sound on blood headphones | `test-blood-output.sh`; check powered hub; blood front-panel routing |
| Mix only on siren headphones | Turn down **siren direct monitor**; output = `blood_mix_out` |
| One unit disappears randomly | Powered hub — laptop USB is underpowered |

Deep dive / session notes: [DIAGNOSTICS.md](DIAGNOSTICS.md)

---

## Scripts

| Script | Purpose |
|--------|---------|
| `install.sh` | First-time copy configs + dependencies |
| `detect-hub-ports.sh` | Auto-detect hub ports → `hub-ports.env` |
| `refresh-bloodsiren.sh` | Regenerate `~/.asoundrc` from hub ports |
| `fix-waveform-stereo-sum.sh` | Fix Waveform 8ch input + stereo master output |
| `test-input8.sh` | Verify 8-channel capture (`bloodsiren_in`) |
| `test-blood-output.sh` | Verify playback on blood |
| `identify-units.sh` | Show which units are on the bus |

---

## Optional: PyQt helper app

```bash
cd siren && python3 -m venv .venv && .venv/bin/pip install PyQt6
./run.sh
```

---

## License

MIT — use at your own risk for live event recording setups.
