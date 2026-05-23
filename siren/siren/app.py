"""SIREN — blood-red ALSA / PipeWire interface combiner."""

from __future__ import annotations

import sys
from pathlib import Path

from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import (
    QApplication,
    QCheckBox,
    QFormLayout,
    QGroupBox,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QListWidget,
    QListWidgetItem,
    QMainWindow,
    QMessageBox,
    QPushButton,
    QScrollArea,
    QSplitter,
    QTextEdit,
    QToolBox,
    QVBoxLayout,
    QWidget,
)

from siren.config import CombinedNames, generate_asoundrc
from siren.devices import DeviceConfig, PortRoles, default_alias, list_capture_devices
from siren.profile import (
    AppProfile,
    PROFILE_PATH,
    apply_profile_to_configs,
    device_config_to_dict,
)
from siren.system import deploy_all
from siren.theme import CRIMSON, GLOW, MUTED, STYLESHEET


class PortMatrix(QWidget):
    def __init__(self, port_count: int, parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self._rows: list[tuple[QLineEdit, QCheckBox, QCheckBox, QCheckBox]] = []
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)

        header = QHBoxLayout()
        for text, stretch in (("Port", 0), ("Name", 2), ("In", 1), ("Out", 1), ("Combined", 1)):
            label = QLabel(text)
            align = Qt.AlignmentFlag.AlignCenter if text != "Port" and text != "Name" else Qt.AlignmentFlag.AlignLeft
            header.addWidget(label, stretch, align)
        layout.addLayout(header)

        for port in range(1, port_count + 1):
            row = QHBoxLayout()
            row.addWidget(QLabel(str(port)), 0)
            name_edit = QLineEdit()
            name_edit.setPlaceholderText(f"Port {port}")
            in_box = QCheckBox()
            out_box = QCheckBox()
            combined_box = QCheckBox()
            in_box.setChecked(True)
            combined_box.setChecked(True)
            row.addWidget(name_edit, 2)
            row.addWidget(in_box, 1, Qt.AlignmentFlag.AlignCenter)
            row.addWidget(out_box, 1, Qt.AlignmentFlag.AlignCenter)
            row.addWidget(combined_box, 1, Qt.AlignmentFlag.AlignCenter)
            layout.addLayout(row)
            self._rows.append((name_edit, in_box, out_box, combined_box))

    def roles(self) -> list[PortRoles]:
        return [
            PortRoles(
                label=name.text().strip(),
                input=i.isChecked(),
                output=o.isChecked(),
                combined=c.isChecked(),
            )
            for name, i, o, c in self._rows
        ]

    def set_roles(self, roles: list[PortRoles]) -> None:
        for idx, (name, i, o, c) in enumerate(self._rows):
            if idx >= len(roles):
                break
            name.setText(roles[idx].label)
            i.setChecked(roles[idx].input)
            o.setChecked(roles[idx].output)
            c.setChecked(roles[idx].combined)


class DeviceCard(QWidget):
    def __init__(self, cfg: DeviceConfig, parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self.cfg = cfg
        port_count = max(cfg.device.capture_channels, cfg.device.playback_channels, 1)
        cfg.ensure_ports(port_count)

        layout = QVBoxLayout(self)
        title = QLabel(cfg.device.display_name)
        title.setWordWrap(True)
        title.setStyleSheet(f"color: {CRIMSON}; font-weight: 700;")
        layout.addWidget(title)

        meta = QLabel(
            f"{cfg.device.capture_channels} in · {cfg.device.playback_channels} out"
            + (f" · hub {cfg.device.hub_port}" if cfg.device.hub_port else "")
        )
        meta.setStyleSheet(f"color: {MUTED}; font-size: 11px;")
        layout.addWidget(meta)

        alias_row = QHBoxLayout()
        alias_row.addWidget(QLabel("Interface name"))
        self.alias_edit = QLineEdit(cfg.alias)
        self.alias_edit.setPlaceholderText("blood / siren")
        alias_row.addWidget(self.alias_edit)
        layout.addLayout(alias_row)

        self.matrix = PortMatrix(port_count)
        self.matrix.set_roles(cfg.ports)
        layout.addWidget(self.matrix)

    def sync(self) -> None:
        self.cfg.alias = self.alias_edit.text().strip()
        self.cfg.ports = self.matrix.roles()


class MainWindow(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("SIREN")
        self.resize(1180, 820)
        self.profile = AppProfile.load()

        self.device_configs: list[DeviceConfig] = []
        self.device_items: dict[int, QListWidgetItem] = {}
        self.device_cards: dict[int, DeviceCard] = {}
        self.toolbox: QToolBox | None = None

        root = QWidget()
        self.setCentralWidget(root)
        outer = QVBoxLayout(root)
        outer.setSpacing(12)
        outer.setContentsMargins(16, 16, 16, 16)

        header = QHBoxLayout()
        title_col = QVBoxLayout()
        title = QLabel("SIREN")
        title.setObjectName("title")
        subtitle = QLabel("Combine interfaces · name ports · deploy ALSA + PipeWire")
        subtitle.setObjectName("subtitle")
        title_col.addWidget(title)
        title_col.addWidget(subtitle)
        header.addLayout(title_col)
        header.addStretch()
        self.status_label = QLabel("Ready")
        self.status_label.setObjectName("statusOk")
        header.addWidget(self.status_label, alignment=Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignVCenter)
        outer.addLayout(header)

        toolbar = QHBoxLayout()
        refresh_btn = self._secondary_button("Refresh")
        refresh_btn.clicked.connect(self.refresh_devices)
        preview_btn = self._secondary_button("Preview")
        preview_btn.clicked.connect(self.preview_config)
        save_btn = self._secondary_button("Save profile")
        save_btn.clicked.connect(self.save_profile)
        deploy_btn = QPushButton("Deploy everything")
        deploy_btn.clicked.connect(self.deploy_everything)
        toolbar.addWidget(refresh_btn)
        toolbar.addStretch()
        toolbar.addWidget(save_btn)
        toolbar.addWidget(preview_btn)
        toolbar.addWidget(deploy_btn)
        outer.addLayout(toolbar)

        top_split = QSplitter(Qt.Orientation.Horizontal)

        left = QGroupBox("Devices")
        left_layout = QVBoxLayout(left)
        hint = QLabel("Check devices to include in the combined stack.")
        hint.setStyleSheet(f"color: {MUTED};")
        left_layout.addWidget(hint)
        self.device_list = QListWidget()
        self.device_list.itemChanged.connect(self.on_combine_toggled)
        left_layout.addWidget(self.device_list)
        top_split.addWidget(left)

        right = QGroupBox("Stack naming & hub map")
        right_layout = QVBoxLayout(right)
        form = QFormLayout()
        self.base_name = QLineEdit(self.profile.combined.base)
        self.in_suffix = QLineEdit(self.profile.combined.input_suffix)
        self.out_suffix = QLineEdit(self.profile.combined.output_suffix)
        self.hub_primary = QLineEdit(self.profile.hub_primary)
        self.hub_secondary = QLineEdit(self.profile.hub_secondary)
        self.usb_vendor = QLineEdit(self.profile.usb_vendor)
        self.usb_product = QLineEdit(self.profile.usb_product)
        form.addRow("Combined base", self.base_name)
        form.addRow("Input suffix", self.in_suffix)
        form.addRow("Output suffix", self.out_suffix)
        form.addRow("Hub port → 1–4", self.hub_primary)
        form.addRow("Hub port → 5–8", self.hub_secondary)
        form.addRow("USB vendor", self.usb_vendor)
        form.addRow("USB product", self.usb_product)
        right_layout.addLayout(form)

        self.pipewire_box = QCheckBox("Install PipeWire combine source")
        self.pipewire_box.setChecked(self.profile.install_pipewire)
        self.wireplumber_box = QCheckBox("Install WirePlumber duplicate-USB fix")
        self.wireplumber_box.setChecked(self.profile.install_wireplumber)
        self.udev_box = QCheckBox("Install udev rules (sudo)")
        self.udev_box.setChecked(self.profile.install_udev)
        right_layout.addWidget(self.pipewire_box)
        right_layout.addWidget(self.wireplumber_box)
        right_layout.addWidget(self.udev_box)
        right_layout.addStretch()
        top_split.addWidget(right)
        top_split.setStretchFactor(0, 3)
        top_split.setStretchFactor(1, 2)
        outer.addWidget(top_split)

        cards_label = QLabel("Port assignment")
        cards_label.setStyleSheet(f"color: {GLOW}; font-weight: 700; margin-top: 4px;")
        outer.addWidget(cards_label)

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        self.cards_host = QWidget()
        self.cards_layout = QVBoxLayout(self.cards_host)
        scroll.setWidget(self.cards_host)
        outer.addWidget(scroll, stretch=1)

        log_label = QLabel("Output")
        log_label.setStyleSheet(f"color: {MUTED};")
        outer.addWidget(log_label)
        self.log = QTextEdit()
        self.log.setReadOnly(True)
        self.log.setMaximumHeight(180)
        self.log.setPlaceholderText("Deploy log and generated config preview…")
        outer.addWidget(self.log)

        self.refresh_devices()

    @staticmethod
    def _secondary_button(text: str) -> QPushButton:
        btn = QPushButton(text)
        btn.setObjectName("secondary")
        return btn

    def _hub_primary(self) -> str:
        return self.hub_primary.text().strip() or "2.3"

    def _hub_secondary(self) -> str:
        return self.hub_secondary.text().strip() or "2.4"

    def _set_status(self, text: str, ok: bool = True) -> None:
        self.status_label.setText(text)
        self.status_label.setObjectName("statusOk" if ok else "statusWarn")

    def _append_log(self, text: str) -> None:
        self.log.append(text)

    def refresh_devices(self) -> None:
        existing = {c.device.card_number: c for c in self.device_configs}
        discovered = list_capture_devices(include_internal=False)
        if not discovered:
            discovered = list_capture_devices(include_internal=True)

        self.device_list.blockSignals(True)
        self.device_list.clear()
        self.device_configs.clear()
        self.device_items.clear()

        while self.cards_layout.count() > 0:
            item = self.cards_layout.takeAt(0)
            if item.widget():
                item.widget().deleteLater()
        self.device_cards.clear()

        self.toolbox = QToolBox()
        self.cards_layout.addWidget(self.toolbox)

        hp = self._hub_primary()
        hs = self._hub_secondary()

        for dev in discovered:
            prev = existing.get(dev.card_number)
            cfg = prev or DeviceConfig(
                device=dev,
                alias=default_alias(dev, hp, hs),
                combine=bool(dev.hub_port) or "USB" in dev.description,
            )
            cfg.device = dev
            port_count = max(dev.capture_channels, dev.playback_channels, 1)
            cfg.ensure_ports(port_count)
            apply_profile_to_configs(self.profile, [cfg])
            self.device_configs.append(cfg)

            item = QListWidgetItem(dev.display_name)
            item.setFlags(item.flags() | Qt.ItemFlag.ItemIsUserCheckable)
            item.setCheckState(
                Qt.CheckState.Checked if cfg.combine else Qt.CheckState.Unchecked
            )
            self.device_list.addItem(item)
            self.device_items[dev.card_number] = item

            card = DeviceCard(cfg)
            self.device_cards[dev.card_number] = card
            tab = f"{cfg.alias or dev.card_id}  ·  {dev.capture_channels}ch"
            self.toolbox.addItem(card, tab)

        self.device_list.blockSignals(False)
        count = len(discovered)
        self._set_status(f"{count} device{'s' if count != 1 else ''} found", ok=count > 0)
        if count == 0:
            self._append_log("No audio devices found. Plug in interfaces and refresh.")

    def on_combine_toggled(self, item: QListWidgetItem) -> None:
        idx = self.device_list.row(item)
        if 0 <= idx < len(self.device_configs):
            self.device_configs[idx].combine = item.checkState() == Qt.CheckState.Checked

    def _sync_from_ui(self) -> None:
        for cfg in self.device_configs:
            card = self.device_cards.get(cfg.device.card_number)
            if card:
                card.sync()
            item = self.device_items.get(cfg.device.card_number)
            if item:
                cfg.combine = item.checkState() == Qt.CheckState.Checked

    def _names(self) -> CombinedNames:
        return CombinedNames(
            base=self.base_name.text(),
            input_suffix=self.in_suffix.text(),
            output_suffix=self.out_suffix.text(),
        )

    def _update_profile_from_ui(self) -> None:
        self._sync_from_ui()
        self.profile.combined = self._names()
        self.profile.hub_primary = self._hub_primary()
        self.profile.hub_secondary = self._hub_secondary()
        self.profile.usb_vendor = self.usb_vendor.text().strip()
        self.profile.usb_product = self.usb_product.text().strip()
        self.profile.install_pipewire = self.pipewire_box.isChecked()
        self.profile.install_wireplumber = self.wireplumber_box.isChecked()
        self.profile.install_udev = self.udev_box.isChecked()
        self.profile.devices = [device_config_to_dict(c) for c in self.device_configs]

    def preview_config(self) -> None:
        try:
            self._sync_from_ui()
            text = generate_asoundrc(self.device_configs, self._names())
            self.log.setPlainText(text)
            self._set_status("Preview ready")
        except ValueError as exc:
            QMessageBox.warning(self, "SIREN", str(exc))
            self._set_status(str(exc), ok=False)

    def save_profile(self) -> None:
        self._update_profile_from_ui()
        self.profile.save()
        self._append_log(f"Saved profile to {PROFILE_PATH}")
        self._set_status("Profile saved")

    def deploy_everything(self) -> None:
        self._update_profile_from_ui()
        self.profile.save()
        try:
            preview = generate_asoundrc(self.device_configs, self._names())
        except ValueError as exc:
            QMessageBox.warning(self, "SIREN", str(exc))
            return

        self.log.setPlainText(preview + "\n\n--- deploy ---\n")
        result = deploy_all(
            self.device_configs,
            self._names(),
            self.profile.hub_primary,
            self.profile.hub_secondary,
            self.profile.usb_vendor,
            self.profile.usb_product,
            self.profile.install_pipewire,
            self.profile.install_wireplumber,
            self.profile.install_udev,
        )
        for line in result.messages:
            self._append_log(f"✓ {line}")
        for line in result.errors:
            self._append_log(f"✗ {line}")

        if result.errors:
            self._set_status("Deployed with warnings", ok=False)
            QMessageBox.warning(self, "SIREN", "\n".join(result.errors))
        else:
            self._set_status("Deployed successfully")
            QMessageBox.information(
                self,
                "SIREN",
                "Audio stack deployed.\n\nWaveform: ALSA\n"
                f"  Input:  {self._names().base}{self._names().input_suffix}\n"
                f"  Output: blood_playback (NOT duplex — avoids 256ch bug)",
            )


def main() -> int:
    app = QApplication(sys.argv)
    app.setApplicationName("SIREN")
    app.setStyleSheet(STYLESHEET)
    window = MainWindow()
    window.show()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
