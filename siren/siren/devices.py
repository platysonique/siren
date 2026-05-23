"""Scan ALSA audio devices on Linux."""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path


@dataclass
class AudioDevice:
    card_number: int
    card_id: str
    description: str
    usb_path: str = ""
    hub_port: str = ""
    capture_channels: int = 2
    playback_channels: int = 2

    @property
    def display_name(self) -> str:
        if self.hub_port:
            return f"{self.description} ({self.card_id}, hub {self.hub_port})"
        return f"{self.description} ({self.card_id})"


@dataclass
class PortRoles:
    label: str = ""
    input: bool = True
    output: bool = False
    combined: bool = True


@dataclass
class DeviceConfig:
    device: AudioDevice
    alias: str = ""
    combine: bool = True
    ports: list[PortRoles] = field(default_factory=list)

    def ensure_ports(self, count: int) -> None:
        while len(self.ports) < count:
            self.ports.append(PortRoles())
        if len(self.ports) > count:
            self.ports = self.ports[:count]


def _read_cards() -> list[tuple[int, str, str, str]]:
    cards: list[tuple[int, str, str, str]] = []
    text = Path("/proc/asound/cards").read_text(encoding="utf-8", errors="replace")
    for block in re.split(r"\n\s*\n", text.strip()):
        first = block.splitlines()[0]
        match = re.match(r"\s*(\d+)\s+\[([^\]]+)\]:\s*(.+)", first)
        if not match:
            continue
        num, card_id, rest = match.groups()
        card_id = card_id.strip()
        desc = rest.split(" at ")[0].strip()
        usb = ""
        path_match = re.search(r"at (usb-[^\s,]+)", block)
        if path_match:
            usb = path_match.group(1)
        cards.append((int(num), card_id, desc, usb))
    return cards


def _channel_count(card_number: int, direction: str) -> int:
    stream = Path(f"/proc/asound/card{card_number}/stream0")
    if not stream.exists():
        return 2
    text = stream.read_text(encoding="utf-8", errors="replace")
    section = direction.capitalize() + ":"
    if section not in text:
        return 0
    part = text.split(section, 1)[1]
    if "Capture:" in part and direction == "playback":
        part = part.split("Capture:", 1)[0]
    match = re.search(r"Channels:\s*(\d+)", part)
    return int(match.group(1)) if match else 2


def _hub_port_from_by_path(card_number: int) -> str:
    by_path = Path("/dev/snd/by-path")
    if not by_path.exists():
        return ""
    for link in by_path.iterdir():
        if not link.is_symlink():
            continue
        target = link.resolve()
        if target.name != f"controlC{card_number}":
            continue
        name = link.name
        match = re.search(r"usb-0:([\d.]+)", name)
        if match:
            return match.group(1)
    return ""


def list_capture_devices(include_internal: bool = False) -> list[AudioDevice]:
    devices: list[AudioDevice] = []
    for num, card_id, desc, usb in _read_cards():
        capture = _channel_count(num, "capture")
        playback = _channel_count(num, "playback")
        if capture == 0 and playback == 0:
            continue
        is_usb = "usb" in usb.lower() or "USB" in desc
        if not include_internal and not is_usb:
            continue
        devices.append(
            AudioDevice(
                card_number=num,
                card_id=card_id,
                description=desc,
                usb_path=usb,
                hub_port=_hub_port_from_by_path(num),
                capture_channels=max(capture, 0),
                playback_channels=max(playback, 0),
            )
        )
    return devices


def default_alias(device: AudioDevice, hub_primary: str = "2.3", hub_secondary: str = "2.4") -> str:
    if device.hub_port == hub_primary:
        return "blood"
    if device.hub_port == hub_secondary:
        return "siren"
    if "USB" in device.description:
        return f"usb_{device.card_number}"
    return device.card_id.lower().replace(" ", "_")
