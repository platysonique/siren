"""Persist and restore SIREN profiles."""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field
from pathlib import Path

from siren.config import CombinedNames
from siren.devices import DeviceConfig, PortRoles


CONFIG_DIR = Path.home() / ".config" / "siren"
PROFILE_PATH = CONFIG_DIR / "profile.json"


@dataclass
class HubMapping:
    port: str
    alias: str


@dataclass
class AppProfile:
    combined: CombinedNames = field(default_factory=CombinedNames)
    hub_primary: str = "2.3"
    hub_secondary: str = "2.4"
    usb_vendor: str = "152a"
    usb_product: str = "893a"
    install_pipewire: bool = True
    install_wireplumber: bool = True
    install_udev: bool = True
    devices: list[dict] = field(default_factory=list)

    def save(self, path: Path = PROFILE_PATH) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        payload = {
            "combined": asdict(self.combined),
            "hub_primary": self.hub_primary,
            "hub_secondary": self.hub_secondary,
            "usb_vendor": self.usb_vendor,
            "usb_product": self.usb_product,
            "install_pipewire": self.install_pipewire,
            "install_wireplumber": self.install_wireplumber,
            "install_udev": self.install_udev,
            "devices": self.devices,
        }
        path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    @classmethod
    def load(cls, path: Path = PROFILE_PATH) -> AppProfile:
        if not path.exists():
            return cls()
        data = json.loads(path.read_text(encoding="utf-8"))
        return cls(
            combined=CombinedNames(**data.get("combined", {})),
            hub_primary=data.get("hub_primary", "2.3"),
            hub_secondary=data.get("hub_secondary", "2.4"),
            usb_vendor=data.get("usb_vendor", "152a"),
            usb_product=data.get("usb_product", "893a"),
            install_pipewire=data.get("install_pipewire", True),
            install_wireplumber=data.get("install_wireplumber", True),
            install_udev=data.get("install_udev", True),
            devices=data.get("devices", []),
        )


def device_config_to_dict(cfg: DeviceConfig) -> dict:
    return {
        "card_number": cfg.device.card_number,
        "alias": cfg.alias,
        "combine": cfg.combine,
        "ports": [asdict(p) for p in cfg.ports],
    }


def apply_profile_to_configs(profile: AppProfile, configs: list[DeviceConfig]) -> None:
    saved = {item["card_number"]: item for item in profile.devices}
    for cfg in configs:
        item = saved.get(cfg.device.card_number)
        if not item:
            continue
        cfg.alias = item.get("alias", cfg.alias)
        cfg.combine = item.get("combine", cfg.combine)
        cfg.ports = [PortRoles(**p) for p in item.get("ports", [])]
