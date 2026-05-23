# Zero-sound hardware checklist

Use this only after `scripts/test-blood-output.sh` and `scripts/test-blood-four-channels.sh` show ALSA playback is running.

## Physical controls

- Turn up physical phones level.
- Turn up main/line output level.
- Check monitor/source switch positions.
- Check direct monitor blend knob; set it away from pure input/direct if USB return is on the other side.
- Check if headphones follow outputs 1/2, 3/4, or a dedicated monitor bus.
- Check whether the unit has a class-compliant mode switch.
- Check whether playback is muted until the device is initialized by vendor software.

## Jack mapping

Run:

```bash
~/Downloads/waveformstuff/scripts/test-blood-four-channels.sh
```

Try all physical outputs while each channel plays.

Expected mapping attempts:

- playback 1/2: FL/FR, usually main L/R
- playback 3/4: RL/RR, sometimes alternate line pair or phones cue

## Windows/vendor control panel check

If Linux shows USB playback running but every analog output is silent, test the same unit on Windows with the vendor/Thesycon control panel.

Things to set there if exposed:

- USB return routed to phones
- USB return routed to line/main output
- monitor source set to DAW/USB
- mixer channels unmuted
- output bus not dimmed/muted
- firmware not in standalone/direct-monitor-only mode

After setting, power-cycle the unit and test again on Linux.

