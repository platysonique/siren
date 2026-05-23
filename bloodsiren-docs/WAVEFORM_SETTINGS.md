# Waveform 13 (ALSA)

Run after install:

```bash
~/path/to/bloodsiren/scripts/fix-waveform-stereo-sum.sh
```

## Device selection

| | Device |
|---|--------|
| Input | `bloodsiren_in` |
| Output | `blood_mix_out` |
| Rate | 48000 Hz |

Enable **input channels 1–8**. Enable **output channel 1+2 only**.

## Do not use

- `bloodsiren` (duplex)
- `default` (PipeWire laptop speakers)
- `siren_playback` for Waveform output

## Reset

Settings → Audio → **Reset Input Devices** and **Reset Output Devices** after any `~/.asoundrc` change.
