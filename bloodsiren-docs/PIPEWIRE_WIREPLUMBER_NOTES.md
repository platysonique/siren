# PipeWire / WirePlumber notes

Your existing `api.alsa.use-acp = false` choice is the right direction for duplicate-serial USB audio devices.

For the recording path, keep using either:

- ALSA `bloodsiren_in` in Waveform, or
- PipeWire/JACK graph ports directly.

For monitoring, do not route Waveform into a two-device ALSA `multi` output. Keep monitoring on `blood` only.

Useful commands:

```bash
wpctl status
pw-link -i
pw-link -o
pw-top
```

If PipeWire grabs the device during ALSA-only tests:

```bash
~/Downloads/waveformstuff/scripts/stop-pipewire-user.sh
```

Restart:

```bash
~/Downloads/waveformstuff/scripts/start-pipewire-user.sh
```

