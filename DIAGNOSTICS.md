# bloodsiren / Waveform — full diagnostic record

Generated: 2026-05-23 02:16 CDT  
Machine: Pop!_OS, PipeWire 1.5.85, Tracktion Waveform 13  
Hardware: 2× Thesycon `152a:893a` USB HIFI AUDIO on hub ports 2.3 (blood) and 2.4 (siren)

> **Perplexity note:** Your thread at https://www.perplexity.ai/search/8f115e20-7337-4494-9bf4-741b6b65cf50 could not be fetched (login wall). Research below uses the same sources Perplexity cites (ALSA wiki, JACK multi-device FAQ, PortAudio plug/asym channel bug, Thesycon docs) via web search. Install `parallel-cli` (`/parallel-setup`) for live Perplexity-style searches from Cursor.

---

## 1. Executive summary

| Layer | Status | Evidence |
|-------|--------|----------|
| USB detection | **OK** | Both units on hub 2.3 / 2.4, stable `by-path` symlinks |
| ALSA 8ch capture | **OK** | `arecord -D bloodsiren_in -c 8` succeeds |
| ALSA blood playback (CLI) | **OK** | `aplay -D blood_playback` exits 0; all 4 per-channel tests exit 0 |
| **Audible output on blood headphones** | **FAIL (user)** | All 4 channel tones + stereo test complete with no errors but user hears nothing |
| Waveform output test button | **FAIL (user)** | Same silent output; settings re-corrupt to 128ch on every launch |
| PipeWire combine source | **OK (idle)** | 8ch `combine_source_bloodsiren` linked to both USB captures |

**Conclusion:** Linux is delivering PCM to the blood USB playback endpoint. Silence with zero ALSA errors strongly indicates **hardware routing on the IEC unit** (front-panel direct-out / headphone matrix), not a missing driver or broken `.asoundrc`. Waveform adds a **second** problem: probing `bloodsiren_in` via `multi`/`route` reports 1–178956970 channels and re-expands Waveform.settings to 128+ phantom channels every session ([PortAudio #1126](https://github.com/PortAudio/portaudio/issues/1126) describes the same plug/asym probe behavior).

---

## 2. What the system reads RIGHT NOW (live dump 2026-05-23 02:16 selinux)

### 2.1 USB topology

```
Hub Port 002 (480M)
  Port 003 → Dev 027  152a:893a  blood  (snd-usb-audio ×3 interfaces)
  Port 004 → Dev 029  152a:893a  siren  (snd-usb-audio ×3 interfaces)
```

### 2.2 ALSA cards

| Card | ID | Hub path | Role |
|------|-----|----------|------|
| 3 | `AUDIO` | `usb-0000:03:00.3-2.3` | blood |
| 4 | `AUDIO_1` | `usb-0000:03:00.3-2.4` | siren |

Symlinks:
```
/dev/snd/by-path/...usb-0:2.3:1.1 → controlC3
/dev/snd/by-path/...usb-0:2.4:1.1 → controlC4
```

### 2.3 Kernel stream0 (what the driver sees)

**Card 3 (blood) — playback channel map: `FL FR RL RR`**

```
Playback:  Status Stop (idle after test)
Capture:   Status Running  @ 48000 Hz S24_3LE 4ch  map FL FR FC LFE
```

**Card 4 (siren) — playback channel map: `FL FR RL RR`**

```
Playback:  Status Running  @ 48000 Hz S24_3LE 4ch   ← PipeWire holding this
Capture:   Status Running  @ 48000 Hz S24_3LE 4ch  map FL FR FC LFE
```

**Critical:** Linux exposes **one 4-channel playback PCM** per box. It does **not** expose separate “headphone 1 / headphone 2 / direct out 3” devices. Perplexity’s qpwgraph advice applies to **routing between apps**, not picking a headphone jack in Waveform ([ALSA Asoundrc wiki](https://www.alsa-project.org/wiki/Asoundrc)).

### 2.4 Who holds `/dev/snd` (during your test session)

```
/dev/snd/pcmC3D0c  → pipewire   (blood capture — combine source)
/dev/snd/pcmC4D0c  → pipewire   (siren capture — combine source)
/dev/snd/pcmC4D0p  → pipewire   (siren playback — RUNNING)
/dev/snd/pcmC3D0p  → (free when idle)
```

PipeWire’s `combine_source_bloodsiren` keeps both captures open. Something also opened **siren playback**, not blood.

### 2.5 Mixer (both units identical)

```
PCM: FL FR RL RR  all 53% [-21 dB]  [on]
```

Not muted at ALSA level.

### 2.6 Waveform.settings (after 2:10 session — **corrupted again**)

```xml
<DEVICESETUP deviceType="ALSA"
  audioOutputDeviceName="blood_playback"
  audioInputDeviceName="bloodsiren_in"
  audioDeviceRate="48000.0"
  audioDeviceBufferSize="192"/>
```

But file also contains **`wavein_channel 9` through `wavein_channel 128`** and **`waveout_channel 3+4` through `127+128`** — Waveform rewrote these on launch despite our cleanup script.

---

## 3. Perplexity / published research vs our findings

| Perplexity / docs recommendation | What we did | Result |
|----------------------------------|-------------|--------|
| Aggregate USB interfaces via `~/.asoundrc` `multi` ([ALSA wiki](https://www.alsa-project.org/wiki/Asoundrc)) | `bloodsiren_in` = route + multi 8ch | Capture works; Waveform probes 1–178956970 ch |
| Use JACK `-P`/`-C` or `alsa_in` for 2nd device ([JACK FAQ](https://github.com/jackaudio/jackaudio.github.com/blob/master/faq/multiple_devices.md)) | Not implemented | Still recommended for Waveform **output** |
| PipeWire combine + qpwgraph for monitoring | `90-combine-judge-inputs.conf` | 8ch source OK; Waveform bypasses PipeWire |
| Duplicate serial USB → WirePlumber `api.alsa.use-acp = false` | `51-hifi-audio-dual.conf` | Both cards visible separately |
| Thesycon devices: flexible 4×stereo routing on **Windows** ([TUSBAudio](https://thesycon.com/eng/usb_audiodriver.shtml)) | Linux has no TUSBAudioControl | Hardware matrix may be Windows-only / panel-controlled |
| plug/asym wrappers report hardware-max channels to apps ([PortAudio #1126](https://github.com/PortAudio/portaudio/issues/1126)) | Waveform log: `numChannels=256` | Explains silent test button + settings bloat |

---

## 4. Every config iteration we tried (chronological)

| Ver | Input | Output | Waveform behavior | CLI |
|-----|-------|--------|-------------------|-----|
| v1 | `bloodsiren` 8ch multi | same | `requested 64 channels, got 4` crash | fail |
| v2 | `bloodsiren_in` | `bloodsiren_out` 8ch multi | 256ch open, silent out | partial |
| v3 | asym + **null** unused dir | — | `getDeviceNumChannels: 1 10000` crash | fail |
| v4 | route+multi 8ch in | stereo route out | capture OK | out OK |
| v5 | duplex `bloodsiren` | asym | 256ch in+out, silent monitor | in OK |
| v6 | `bloodsiren_in` | `blood_playback` direct hw 2ch | `Slave PCM not usable` on stereo | per-ch OK, stereo fail |
| **v7 (current)** | `bloodsiren_in` | `blood_playback` → `blood_out` → 4ch hw | settings corrupt to 128ch; user silent | **all tests exit 0** |

---

## 5. Current `~/.asoundrc` (full)

```asoundrc
# Auto-generated by refresh-bloodsiren.sh
# Waveform: in=bloodsiren_in  out=blood_playback  (do NOT use bloodsiren duplex)

pcm.blood { type hw; card AUDIO; device 0 }
pcm.siren { type hw; card AUDIO_1; device 0 }

pcm.bloodsiren_in {
    type route
    slave.pcm {
        type multi
        slaves.a.pcm "blood"
        slaves.a.channels 4
        slaves.b.pcm "siren"
        slaves.b.channels 4
        bindings.0 { slave a; channel 0; }
        bindings.1 { slave a; channel 1; }
        bindings.2 { slave a; channel 2; }
        bindings.3 { slave a; channel 3; }
        bindings.4 { slave b; channel 0; }
        bindings.5 { slave b; channel 1; }
        bindings.6 { slave b; channel 2; }
        bindings.7 { slave b; channel 3; }
    }
    slave.channels 8
    ttable.0.0 1
    ttable.1.1 1
    ttable.2.2 1
    ttable.3.3 1
    ttable.4.4 1
    ttable.5.5 1
    ttable.6.6 1
    ttable.7.7 1
}

pcm.blood_out {
    type route
    slave.pcm "blood"
    slave.channels 4
    ttable.0.0 1    # stereo L → hw FL
    ttable.1.1 1    # stereo R → hw FR
    ttable.0.2 1    # stereo L → hw RL  (duplicate for direct outs)
    ttable.1.3 1    # stereo R → hw RR
}

pcm.blood_playback {
    type plug
    slave.pcm "blood_out"
    slave.channels 2
}

pcm.blood_test_ch0 { type route; slave.pcm "blood"; slave.channels 4; ttable.0.0 1 }
pcm.blood_test_ch1 { type route; slave.pcm "blood"; slave.channels 4; ttable.0.1 1 }
pcm.blood_test_ch2 { type route; slave.pcm "blood"; slave.channels 4; ttable.0.2 1 }
pcm.blood_test_ch3 { type route; slave.pcm "blood"; slave.channels 4; ttable.0.3 1 }

pcm.bloodsiren {
    type asym
    capture.pcm "bloodsiren_in"
    playback.pcm "bloodsiren_out"
}
```

Regenerate: `~/Downloads/waveformstuff/scripts/refresh-bloodsiren.sh`

---

## 6. Waveform log excerpts (proof of 256/128ch bug)

**Duplex `bloodsiren` (session 1:43:58):**
```
ALSA: getDeviceNumChannels: 1 178956970
ALSA: getDeviceNumChannels: 1 10000
ALSA: snd_pcm_open (bloodsiren, forInput=1)
ALSA: numChannels=256
ALSA: snd_pcm_open (bloodsiren, forInput=0)
ALSA: numChannels=256
```

**Split `bloodsiren_in` + `blood_playback` (session 2:10:35):**
```
ALSA: ID: bloodsiren_in
ALSA: ID: blood_playback
… then Rebuilding Wave Device List creates wavein_channel 1..128 …
```

Log file: `~/.config/Tracktion/Waveform/Temporary/Waveform13Log.txt`

---

## 7. Scripts and what they do

| Script | Purpose |
|--------|---------|
| `scripts/refresh-bloodsiren.sh` | Hub-port → card ID → writes `~/.asoundrc` |
| `scripts/test-blood-outputs.sh` | 880 Hz on USB ch 0–3 + stereo `blood_playback` |
| `scripts/test-bloodsiren.sh` | 8ch capture + stereo playback smoke test |
| `scripts/waveform-audio-reset.sh` | Kill Waveform, refresh asoundrc, scrub settings, set split I/O |
| `scripts/setup-judge-aggregate.sh` | Full setup + udev + PipeWire restart |
| `scripts/99-hifi-audio-dual.rules` | udev stable BLOOD/SIREN card names |
| `siren/` | PyQt6 deploy app (`config.py`, `system.py`, `devices.py`) |

---

## 8. Your test-blood-outputs.sh results (2026-05-23)

```
Channel 0–3:  Playing WAVE … Mono     ← ALSA OK, no errors
Stereo:       Playing WAVE … Stereo   ← ALSA OK (after v7 blood_out fix)
```

If **all complete with no errors** but **you hear nothing**, the audio is leaving the PC on the USB wire and the **IEC box is not routing it to the jack you're listening on**. This matches Thesycon’s Windows-only mixer matrix documentation — Linux sends 4 logical channels; the box decides which physical jack gets signal.

---

## 9. Recommended next steps (ranked)

### A. Hardware (do first — 5 minutes)

On the **blood** unit while `test-blood-outputs.sh` runs:

1. Rotate every **direct-out / phones / cue** knob and button.
2. Try **both** headphone jacks if present.
3. Try **line/direct outputs 1–4** with speakers or another headphone.
4. Confirm you're listening on **blood (port 2.3)**, not siren (port 2.4).

### B. Waveform (after hardware confirmed)

```bash
pkill -x Waveform13
~/Downloads/waveformstuff/scripts/waveform-audio-reset.sh
```

Settings: **in=`bloodsiren_in` out=`blood_playback`**, 48000 Hz, Reset both devices.

### C. Perplexity Option 2 — JACK (if Waveform ALSA stays broken)

Per [JACK multi-device FAQ](https://github.com/jackaudio/jackaudio.github.com/blob/master/faq/multiple_devices.md):

```bash
# JACK on blood only
jackd -R -d alsa -d hw:AUDIO -r 48000 -p 128 -n 2 &
# Feed siren capture into JACK
alsa_in -d hw:AUDIO_1 -c 4 -r 48000 &
```

Waveform → device type **JACK** → route master to blood playback ports in qjackctl/qpwgraph.

### D. Monitor via PipeWire (record in Waveform, hear via patchbay)

Connect `combine_source_bloodsiren` or a test tone to `alsa_output.usb-…-01.playback` in **qpwgraph** while Waveform records via ALSA.

---

## 10. Files touched in this project

```
~/.asoundrc
~/.config/pipewire/pipewire.conf.d/90-combine-judge-inputs.conf
~/.config/wireplumber/wireplumber.conf.d/51-hifi-audio-dual.conf
~/.config/Tracktion/Waveform/Waveform.settings
~/Downloads/waveformstuff/scripts/*
~/Downloads/waveformstuff/siren/siren/{config,system,devices,app}.py
```

---

## Sources

- [Asoundrc - AlsaProject](https://www.alsa-project.org/wiki/Asoundrc)
- [JACK FAQ: multiple devices](https://github.com/jackaudio/jackaudio.github.com/blob/master/faq/multiple_devices.md)
- [PortAudio #1126: plug/asym channel probe bug](https://github.com/PortAudio/portaudio/issues/1126)
- [ALSA pcm_plugins documentation](https://www.alsa-project.org/alsa-doc/alsa-lib/pcm_plugins.html)
- [Thesycon TUSBAudio driver features](https://thesycon.com/eng/usb_audiodriver.shtml)
- [Linux hardware: Thesycon USB audio](https://linux-hardware.org/?id=usb%3A152a-887e)
- [Your Perplexity thread](https://www.perplexity.ai/search/8f115e20-7337-4494-9bf4-741b6b65cf50) (not fetchable without login)
