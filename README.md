# siren

8-channel judge recording on **Pop!_OS / Ubuntu** with two identical **Thesycon USB HIFI AUDIO** (`152a:893a`) interfaces and **Trackition Waveform 13**.

| Unit | Role | Tracks |
|------|------|--------|
| **blood** | Monitor / playback + inputs 1–4 | 1–4 |
| **siren** | Inputs only | 5–8 |

## Requirements

- **Powered USB hub** (laptop ports cannot reliably power both units)
- Both boxes on **fixed hub ports** every session
- **Waveform 13** with ALSA backend
- PipeWire (default on Pop!_OS)

## Quick install (new laptop)

```bash
git clone git@github.com:platysonique/siren.git
cd siren
chmod +x scripts/*.sh
./scripts/install.sh
```

Plug both HIFI units into the powered hub **before** or **after** install — then:

```bash
./scripts/detect-hub-ports.sh    # writes ~/.config/bloodsiren/hub-ports.env
./scripts/refresh-bloodsiren.sh
./scripts/test-input8.sh         # must say Channels 8
./scripts/test-blood-output.sh
./scripts/fix-waveform-stereo-sum.sh
```

## Waveform settings

| Setting | Value |
|---------|--------|
| Device type | **ALSA** |
| Input | **`bloodsiren_in`** |
| Output | **`blood_mix_out`** |
| Sample rate | **48000 Hz** |
| Input channels | **1–8 enabled** |
| Output channels | **1+2 only** (stereo master sum) |

After changing devices: **Settings → Audio → Reset Input Devices** and **Reset Output Devices**.

**Do not use** the `bloodsiren` duplex device — it breaks channel counts in Waveform.

## Daily workflow

```bash
./scripts/identify-units.sh          # both units present?
./scripts/refresh-bloodsiren.sh      # regen ~/.asoundrc if you moved USB ports
./scripts/fix-waveform-stereo-sum.sh # if Waveform lost 8 inputs or split output
```

## What gets installed

| Path | Purpose |
|------|---------|
| `~/.asoundrc` | ALSA virtual devices (`bloodsiren_in`, `blood_mix_out`, …) |
| `~/.config/bloodsiren/hub-ports.env` | Your hub port numbers |
| `~/.config/wireplumber/.../51-hifi-audio-dual.conf` | Keep both USB cards separate |
| `~/.config/pipewire/.../90-combine-judge-inputs.conf` | 8ch source for OBS (optional) |

## Hub ports

Port numbers change when you switch from laptop USB → powered hub. They live in:

`~/.config/bloodsiren/hub-ports.env`

Example (powered hub):

```
HUB_PORT_BLOOD=2.3
HUB_PORT_SIREN=2.2
```

If blood/siren are swapped, swap the two lines and run `refresh-bloodsiren.sh`.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Only 4 inputs | Second unit unplugged or wrong hub port — run `detect-hub-ports.sh` |
| No sound | **Powered hub**; run `test-blood-output.sh`; check blood headphones |
| Split output per card | Run `fix-waveform-stereo-sum.sh`; turn down **siren direct monitor** hardware knob |
| Waveform shows 256 channels | Input must be `bloodsiren_in`, not `bloodsiren` duplex |
| One unit vanishes | Underpowered USB — use powered hub |

## Scripts

| Script | Purpose |
|--------|---------|
| `install.sh` | First-time setup |
| `detect-hub-ports.sh` | Find hub ports, write config |
| `refresh-bloodsiren.sh` | Regenerate `~/.asoundrc` |
| `fix-waveform-stereo-sum.sh` | 8 inputs + stereo master on blood |
| `test-input8.sh` | Record 8ch test |
| `test-blood-output.sh` | Playback tone on blood |
| `identify-units.sh` | Show blood/siren presence |

## Optional: SIREN PyQt app

```bash
cd siren && python3 -m venv .venv && .venv/bin/pip install PyQt6
./run.sh
```

## License

MIT — use at your own risk for live event recording setups.
