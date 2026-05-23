"""SIREN blood-red visual theme."""

BLOOD = "#8B0000"
CRIMSON = "#DC143C"
GLOW = "#FF2D55"
DARK = "#0D0A0A"
PANEL = "#1A0F0F"
PANEL_ALT = "#241414"
BORDER = "#5C1010"
TEXT = "#F5E6E6"
MUTED = "#B08080"

STYLESHEET = f"""
QMainWindow, QWidget {{
    background-color: {DARK};
    color: {TEXT};
    font-family: "Segoe UI", "Ubuntu", sans-serif;
    font-size: 13px;
}}
QGroupBox {{
    background-color: {PANEL};
    border: 1px solid {BORDER};
    border-radius: 10px;
    margin-top: 14px;
    padding: 14px 10px 10px 10px;
    font-weight: 600;
}}
QGroupBox::title {{
    subcontrol-origin: margin;
    left: 12px;
    padding: 0 8px;
    color: {CRIMSON};
}}
QLineEdit, QTextEdit, QListWidget, QScrollArea {{
    background-color: {PANEL_ALT};
    color: {TEXT};
    border: 1px solid {BORDER};
    border-radius: 8px;
    padding: 6px;
    selection-background-color: {BLOOD};
}}
QToolBox {{
    background-color: {PANEL};
    border: none;
}}
QToolBox::tab {{
    background: {PANEL_ALT};
    border: 1px solid {BORDER};
    border-radius: 8px;
    padding: 8px 14px;
    color: {CRIMSON};
    font-weight: 700;
    margin-bottom: 4px;
}}
QToolBox::tab:selected {{
    background: {BLOOD};
    color: white;
}}
QListWidget::item {{
    padding: 8px;
    border-radius: 6px;
}}
QListWidget::item:selected {{
    background-color: {BLOOD};
    color: white;
}}
QListWidget::item:hover {{
    background-color: #3A1515;
}}
QPushButton {{
    background-color: qlineargradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 {CRIMSON}, stop:1 {BLOOD});
    color: white;
    border: 1px solid {GLOW};
    border-radius: 8px;
    padding: 9px 16px;
    font-weight: 700;
}}
QPushButton:hover {{
    background-color: {GLOW};
    color: {DARK};
}}
QPushButton:pressed {{
    background-color: {BLOOD};
}}
QPushButton#secondary {{
    background-color: {PANEL_ALT};
    border: 1px solid {BORDER};
    color: {TEXT};
    font-weight: 600;
}}
QPushButton#secondary:hover {{
    border-color: {CRIMSON};
    color: {CRIMSON};
}}
QCheckBox {{
    spacing: 8px;
}}
QCheckBox::indicator {{
    width: 18px;
    height: 18px;
    border-radius: 4px;
    border: 1px solid {BORDER};
    background: {PANEL_ALT};
}}
QCheckBox::indicator:checked {{
    background: {CRIMSON};
    border-color: {GLOW};
}}
QLabel#title {{
    font-size: 28px;
    font-weight: 800;
    color: {GLOW};
    letter-spacing: 4px;
}}
QLabel#subtitle {{
    color: {MUTED};
    font-size: 12px;
}}
QLabel#statusOk {{
    color: #7CFF9B;
}}
QLabel#statusWarn {{
    color: {GLOW};
}}
QSplitter::handle {{
    background: {BORDER};
    width: 2px;
}}
"""
