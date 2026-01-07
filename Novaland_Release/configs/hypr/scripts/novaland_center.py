#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Novaland Command Center (Updated)
- Full User Friendly UI Update
- Added Wallpaper Tab (Hyprpaper support)
- Preserved all original functionality
"""

import sys
import os
import re
import json
import shutil
import subprocess
from dataclasses import dataclass
from datetime import datetime
from typing import List, Tuple, Optional

# --- CẬP NHẬT IMPORT (Thêm QFileDialog, QPixmap, QIcon, QSize...) ---
from PyQt6.QtCore import Qt, QPointF, pyqtSignal, QTimer, QSize
from PyQt6.QtGui import (
    QPainter, QPen, QColor, QBrush, QPainterPath, QPalette, QIcon, QPixmap
)
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QLabel, QPushButton, QTabWidget, QCheckBox,
    QDoubleSpinBox, QGroupBox, QComboBox, QScrollArea, QTableWidget,
    QTableWidgetItem, QLineEdit, QHeaderView, QAbstractItemView,
    QListView, QStyleFactory, QFrame, QGridLayout, QSpinBox,
    QFileDialog, QMessageBox  # Thêm cái này
)

# =========================================================
# CONFIG MANAGER
# =========================================================
class HyprConfigManager:
    def __init__(self, conf_dir: str):
        self.conf_dir = conf_dir
        self.backup_dir = os.path.join(conf_dir, ".backup")
        os.makedirs(self.backup_dir, exist_ok=True)

    def path(self, file: str) -> str:
        return os.path.join(self.conf_dir, file)

    def backup(self, file: str) -> None:
        src = self.path(file)
        if not os.path.exists(src):
            return
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        dst = os.path.join(self.backup_dir, f"{file}.{ts}.bak")
        try:
            shutil.copy(src, dst)
        except Exception as e:
            print(f"[backup] failed: {e}")

    def read_content(self, file: str) -> str:
        p = self.path(file)
        if not os.path.exists(p):
            return ""
        with open(p, "r", encoding="utf-8") as f:
            return f.read()

    # Compatibility helpers
    def read_text(self, file: str) -> str:
        return self.read_content(file)

    def write_text(self, file: str, text: str) -> None:
        self.backup(file)
        p = self.path(file)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        if not text.endswith("\n"):
            text += "\n"
        with open(p, "w", encoding="utf-8") as f:
            f.write(text)

    def read_block(self, file: str, block_name: str) -> str:
        p = self.path(file)
        if not os.path.exists(p):
            return ""
        with open(p, "r", encoding="utf-8") as f:
            txt = f.read()

        m = re.search(rf"(^|\n)\s*{re.escape(block_name)}\s*\{{", txt)
        if not m:
            return ""

        brace_start = txt.find("{", m.end() - 1)
        if brace_start == -1:
            return ""

        depth = 0
        end = None
        for i in range(brace_start, len(txt)):
            ch = txt[i]
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    end = i
                    break

        if end is None or end <= brace_start:
            return ""

        return txt[brace_start + 1:end].strip()

    def write_block(self, file: str, block_name: str, body_content: str) -> None:
        self.backup(file)
        p = self.path(file)
        os.makedirs(os.path.dirname(p), exist_ok=True)

        if not os.path.exists(p):
            with open(p, "w", encoding="utf-8") as f:
                f.write(f"{block_name} {{\n{body_content}\n}}\n")
            return

        with open(p, "r", encoding="utf-8") as f:
            txt = f.read()

        m = re.search(rf"(^|\n)(?P<indent>[ \t]*){re.escape(block_name)}\s*\{{", txt)
        if not m:
            new_txt = txt.rstrip() + f"\n\n{block_name} {{\n{body_content}\n}}\n"
            with open(p, "w", encoding="utf-8") as f:
                f.write(new_txt)
            return

        indent = m.group("indent") or ""
        brace_start = txt.find("{", m.end() - 1)
        if brace_start == -1:
             new_txt = txt.rstrip() + f"\n\n{block_name} {{\n{body_content}\n}}\n"
             with open(p, "w", encoding="utf-8") as f:
                f.write(new_txt)
             return

        depth = 0
        end = None
        for i in range(brace_start, len(txt)):
            ch = txt[i]
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    end = i + 1
                    break

        if end is None:
            new_txt = txt.rstrip() + f"\n\n{block_name} {{\n{body_content}\n}}\n"
        else:
            start = m.start(0) + (1 if m.group(1) == "\n" else 0)
            prefix = txt[:start]
            suffix = txt[end:]
            block_text = f"{indent}{block_name} {{\n{body_content}\n{indent}}}\n"
            new_txt = prefix + block_text + suffix.lstrip("\n")

        with open(p, "w", encoding="utf-8") as f:
            f.write(new_txt)

    def reload_hyprland(self) -> None:
        try:
            subprocess.run(["hyprctl", "reload"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception as e:
            print(f"[hyprctl reload] failed: {e}")

    def set_animation_enabled(self, enabled: bool) -> None:
        body = self.read_block("animation.conf", "animations")
        new_status = "yes" if enabled else "no"
        if re.search(r"enabled\s*=", body):
            body = re.sub(r"(enabled\s*=\s*)\w+", rf"\1{new_status}", body)
        else:
            body = f"    enabled = {new_status}\n{body}"
        self.write_block("animation.conf", "animations", body)
        try:
            subprocess.run(["hyprctl", "keyword", "animations:enabled", "1" if enabled else "0"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass

    # --- CẬP NHẬT: LOGIC WALLPAPER MỚI ---
    def read_wallpaper_conf(self) -> dict:
        """Đọc config hyprpaper style block mới."""
        content = self.read_block("hyprpaper.conf", "wallpaper")
        data = {"path": "", "monitor": ""}
        if not content:
            return data
        for line in content.splitlines():
            line = line.strip()
            if line.startswith("path"):
                parts = line.split("=", 1)
                if len(parts) > 1:
                    data["path"] = parts[1].strip()
            elif line.startswith("monitor"):
                parts = line.split("=", 1)
                if len(parts) > 1:
                    data["monitor"] = parts[1].strip()
        return data

    def write_wallpaper_conf(self, path: str, monitor: str = "") -> None:
        """Ghi config hyprpaper và reload."""
        # Force block syntax
        body = f"    monitor = {monitor}\n    path = {path}\n"
        full_conf = f"ipc = on\nsplash = false\n\nwallpaper {{\n{body}}}\n"
        self.write_text("hyprpaper.conf", full_conf)
        
        # Reload Hyprpaper
        try:
            subprocess.run("killall hyprpaper; hyprpaper & disown", shell=True)
        except Exception:
            pass

    # ... (Các hàm decoration cũ giữ nguyên) ...
    def _parse_bool(self, v: str, default: bool = False) -> bool:
        s = (v or "").strip().lower()
        return s in ("true", "yes", "1", "on", "enabled") if s not in ("false", "no", "0", "off", "disabled") else False

    def _parse_float(self, v: str, default: float = 0.0) -> float:
        try: return float(str(v).strip())
        except: return default

    def _parse_int(self, v: str, default: int = 0) -> int:
        try: return int(float(str(v).strip()))
        except: return default

    def read_decoration(self) -> dict:
        body = self.read_block("decoration.conf", "decoration")
        data = {
            "rounding": 10, "active_opacity": 0.9, "fullscreen_opacity": 1.0,
            "dim_inactive": True, "dim_strength": 0.1, "dim_special": 0.8,
            "blur": {"enabled": True, "size": 6, "passes": 2, "ignore_opacity": True, "new_optimizations": True, "special": True, "popups": True},
            "shadow": {"enabled": True, "range": 15, "render_power": 3, "color": "rgb(2de2e6)", "color_inactive": "0x50000000"}
        }
        if not body: return data

        def subblock(text: str, name: str) -> str:
            m = re.search(rf"{re.escape(name)}\s*\{{(.*?)\}}", text, re.DOTALL)
            return m.group(1).strip() if m else ""

        blur_body = subblock(body, "blur")
        shadow_body = subblock(body, "shadow")
        body_top = re.sub(r"blur\s*\{.*?\}", "", body, flags=re.DOTALL)
        body_top = re.sub(r"shadow\s*\{.*?\}", "", body_top, flags=re.DOTALL)

        def parse_kv(text):
            o={}
            for l in text.splitlines():
                if "=" in l and not l.strip().startswith("#"):
                    k,v = l.split("=",1)
                    o[k.strip()] = v.strip()
            return o

        top = parse_kv(body_top)
        data["rounding"] = self._parse_int(top.get("rounding"), 10)
        data["active_opacity"] = self._parse_float(top.get("active_opacity"), 0.9)
        data["fullscreen_opacity"] = self._parse_float(top.get("fullscreen_opacity"), 1.0)
        data["dim_inactive"] = self._parse_bool(top.get("dim_inactive"), True)
        data["dim_strength"] = self._parse_float(top.get("dim_strength"), 0.1)
        data["dim_special"] = self._parse_float(top.get("dim_special"), 0.8)

        b_kv = parse_kv(blur_body)
        data["blur"]["enabled"] = self._parse_bool(b_kv.get("enabled"), True)
        data["blur"]["size"] = self._parse_int(b_kv.get("size"), 6)
        data["blur"]["passes"] = self._parse_int(b_kv.get("passes"), 2)
        data["blur"]["ignore_opacity"] = self._parse_bool(b_kv.get("ignore_opacity"), True)
        data["blur"]["new_optimizations"] = self._parse_bool(b_kv.get("new_optimizations"), True)
        data["blur"]["special"] = self._parse_bool(b_kv.get("special"), True)
        data["blur"]["popups"] = self._parse_bool(b_kv.get("popups"), True)

        s_kv = parse_kv(shadow_body)
        data["shadow"]["enabled"] = self._parse_bool(s_kv.get("enabled"), True)
        data["shadow"]["range"] = self._parse_int(s_kv.get("range"), 15)
        data["shadow"]["render_power"] = self._parse_int(s_kv.get("render_power"), 3)
        data["shadow"]["color"] = s_kv.get("color", "rgb(2de2e6)")
        data["shadow"]["color_inactive"] = s_kv.get("color_inactive", "0x50000000")
        return data

    def write_decoration(self, data: dict) -> None:
        def b(x): return "true" if x else "false"
        blur = data.get("blur", {})
        shadow = data.get("shadow", {})
        lines = [
            f"    rounding = {data.get('rounding')}",
            f"    active_opacity = {data.get('active_opacity')}",
            f"    fullscreen_opacity = {data.get('fullscreen_opacity')}",
            "",
            f"    dim_inactive = {b(data.get('dim_inactive'))}",
            f"    dim_strength = {data.get('dim_strength')}",
            f"    dim_special = {data.get('dim_special')}",
            "",
            "    blur {",
            f"        enabled = {b(blur.get('enabled'))}",
            f"        size = {blur.get('size')}",
            f"        passes = {blur.get('passes')}",
            f"        ignore_opacity = {b(blur.get('ignore_opacity'))}",
            f"        new_optimizations = {b(blur.get('new_optimizations'))}",
            f"        special = {b(blur.get('special'))}",
            f"        popups = {b(blur.get('popups'))}",
            "    }",
            "",
            "    shadow {",
            f"        enabled = {b(shadow.get('enabled'))}",
            f"        range = {shadow.get('range')}",
            f"        render_power = {shadow.get('render_power')}",
            f"        color = {shadow.get('color')}",
            f"        color_inactive = {shadow.get('color_inactive')}",
            "    }",
        ]
        self.write_block("decoration.conf", "decoration", "\n".join(lines))
        self.reload_hyprland()

    def apply_preset(self, preset_path: str) -> bool:
        if not os.path.exists(preset_path): return False
        try:
            with open(preset_path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except: return False
        lines = [f"    enabled = {data.get('enabled', 'yes')}"]
        for name, pts in data.get("bezier", {}).items():
            lines.append(f"    bezier = {name}, {', '.join(map(str, pts))}")
        for anim in data.get("animations", []):
            lines.append(f"    animation = {', '.join(map(str, anim))}")
        self.write_block("animation.conf", "animations", "\n".join(lines))
        self.reload_hyprland()
        return True

# =========================================================
# THEME & UI HELPERS
# =========================================================
@dataclass
class Theme:
    bg_main: str = "#1a1b26"
    bg_secondary: str = "#24283b"
    panel: str = "#16161e"
    accent: str = "#7aa2f7"
    text: str = "#c0caf5"
    muted: str = "#565f89"
    border: str = "#414868"
    purple: str = "#bb9af7"
    cyan: str = "#2de2e6"
    orange: str = "#ff9e64"
    # Added for new UI
    green: str = "#9ece6a" 
    red: str = "#f7768e"

class ModernButton(QPushButton):
    """Nút bấm đẹp hơn"""
    def __init__(self, text, theme: Theme, color="accent"):
        super().__init__(text)
        self.setCursor(Qt.CursorShape.PointingHandCursor)
        self.setFixedHeight(38)
        
        bg = theme.accent
        if color == "green": bg = theme.green
        if color == "red": bg = theme.red
        if color == "cyan": bg = theme.cyan
        
        self.setStyleSheet(f"""
            QPushButton {{
                background-color: {bg};
                color: {theme.bg_main};
                border-radius: 8px;
                padding: 0 16px;
                font-weight: bold;
                border: none;
            }}
            QPushButton:hover {{
                background-color: {theme.text}; 
                color: {theme.bg_main};
            }}
            QPushButton:pressed {{
                background-color: {bg};
                margin-top: 1px;
            }}
        """)

# =========================================================
# ORIGINAL TABS (PRESERVED)
# =========================================================
class BezierCanvas(QWidget):
    valuesChanged = pyqtSignal(list)
    interactionFinished = pyqtSignal()
    def __init__(self, points: List[float]):
        super().__init__()
        self.setMinimumSize(220, 160)
        self.points = points[:]
        self.drag_idx: Optional[int] = None

    def paintEvent(self, _e):
        p = QPainter(self)
        p.setRenderHint(QPainter.RenderHint.Antialiasing)
        w, h = self.width(), self.height()
        p.fillRect(self.rect(), QColor("#16161e"))
        p.setPen(QPen(QColor("#2de2e622"), 1, Qt.PenStyle.DashLine))
        p.drawLine(0, int(h), int(w), 0)
        pad = 20
        draw_w, draw_h = w - 2 * pad, h - 2 * pad
        def mp(x, y): return QPointF(pad + x * draw_w, (draw_h + pad) - (y * draw_h))
        start_p, end_p = mp(0, 0), mp(1, 1)
        c1, c2 = mp(self.points[0], self.points[1]), mp(self.points[2], self.points[3])
        p.setPen(QPen(QColor("#565f89"), 1))
        p.drawLine(start_p, c1)
        p.drawLine(end_p, c2)
        path = QPainterPath()
        path.moveTo(start_p)
        path.cubicTo(c1, c2, end_p)
        p.setPen(QPen(QColor("#2de2e6"), 3))
        p.drawPath(path)
        p.setBrush(QBrush(QColor("#ff9e64")))
        p.setPen(Qt.PenStyle.NoPen)
        p.drawEllipse(c1, 6, 6)
        p.drawEllipse(c2, 6, 6)

    def _to_value(self, pos) -> Tuple[float, float]:
        pad = 20
        return (pos.x() - pad) / (self.width() - 2 * pad), ((self.height() - 2 * pad + pad) - pos.y()) / (self.height() - 2 * pad)

    def mousePressEvent(self, e):
        vx, vy = self._to_value(e.position())
        d1 = abs(vx - self.points[0]) + abs(vy - self.points[1])
        d2 = abs(vx - self.points[2]) + abs(vy - self.points[3])
        self.drag_idx = 0 if d1 < d2 else 2
        self.update()

    def mouseMoveEvent(self, e):
        if self.drag_idx is None: return
        vx, vy = self._to_value(e.position())
        self.points[self.drag_idx] = max(0.0, min(1.0, vx))
        self.points[self.drag_idx + 1] = max(-2.0, min(2.0, vy))
        self.valuesChanged.emit(self.points[:])
        self.update()

    def mouseReleaseEvent(self, _e):
        if self.drag_idx is not None:
            self.drag_idx = None
            self.interactionFinished.emit()

class AnimationTab(QWidget):
    def __init__(self, cfg: HyprConfigManager, status_cb, theme: Theme):
        super().__init__()
        self.cfg = cfg
        self.status_cb = status_cb
        self.theme = theme
        self.preset_dir = os.path.expanduser("~/.config/hypr/novaland_presets/animations")
        os.makedirs(self.preset_dir, exist_ok=True)
        self._build()

    def _build(self):
        outer = QVBoxLayout(self)
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QFrame.Shape.NoFrame)
        content = QWidget()
        v = QVBoxLayout(content)
        v.setSpacing(18)

        anim_block = self.cfg.read_block("animation.conf", "animations")
        row = QHBoxLayout()
        self.enable_cb = QCheckBox("Enable Animations")
        self.enable_cb.setChecked(bool(re.search(r"enabled\s*=\s*yes", anim_block)))
        self.enable_cb.toggled.connect(lambda c: (self.cfg.set_animation_enabled(c), self.status_cb("Animation toggled")))
        row.addWidget(self.enable_cb)
        row.addStretch()
        v.addLayout(row)

        pre_grp = QGroupBox("Presets")
        pre_layout = QHBoxLayout(pre_grp)
        self.preset_box = QComboBox()
        self._make_combobox_popup_stylable(self.preset_box)
        self.preset_box.addItem("— Select a Preset —")
        self._reload_presets()
        self.preset_box.currentTextChanged.connect(self._on_preset_changed)
        pre_layout.addWidget(self.preset_box)
        v.addWidget(pre_grp)

        v.addWidget(QLabel("Bezier Editor"))
        self.bezier_container = QWidget()
        self.bezier_layout = QVBoxLayout(self.bezier_container)
        v.addWidget(self.bezier_container)
        self.refresh_from_config(anim_block)
        v.addStretch(1)
        scroll.setWidget(content)
        outer.addWidget(scroll)

    def _reload_presets(self):
        while self.preset_box.count() > 1: self.preset_box.removeItem(1)
        if os.path.exists(self.preset_dir):
            for f in sorted(os.listdir(self.preset_dir)):
                if f.endswith(".json"): self.preset_box.addItem(f)

    def _on_preset_changed(self, name: str):
        if name.endswith(".json"):
            ok = self.cfg.apply_preset(os.path.join(self.preset_dir, name))
            self.status_cb(f"Applied {name}" if ok else "Error applying preset")
            self.refresh_from_config()

    def refresh_from_config(self, anim_block: Optional[str] = None):
        if anim_block is None: anim_block = self.cfg.read_block("animation.conf", "animations")
        while self.bezier_layout.count():
            item = self.bezier_layout.takeAt(0)
            if item.widget(): item.widget().deleteLater()
        
        beziers = []
        for line in anim_block.splitlines():
            m = re.match(r"\s*bezier\s*=\s*([^,\s]+)\s*,\s*(.+?)\s*$", line)
            if m: beziers.append((m.group(1), m.group(2)))
        
        if not beziers:
            self.bezier_layout.addWidget(QLabel("No bezier curves found."))
            return

        for name, vals in beziers:
            nums = re.findall(r"[-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?", vals)
            if len(nums) != 4: continue
            try: raw_pts = [float(n) for n in nums]
            except: continue

            grp = QGroupBox(f"Bezier: {name}")
            row = QHBoxLayout(grp)
            left = QVBoxLayout()
            spins = []
            canvas = BezierCanvas(raw_pts[:])

            def save_curve(n=name, c=canvas, s=spins): # Capture vars
                current_vals = [sp.value() for sp in s]
                body = self.cfg.read_block("animation.conf", "animations")
                new_line = f"    bezier = {n}, {', '.join(f'{x:.2f}' for x in current_vals)}"
                body = re.sub(rf"^\s*bezier\s*=\s*{re.escape(n)}\s*,.*$", new_line, body, flags=re.MULTILINE)
                if new_line not in body: body = body.strip() + "\n" + new_line
                self.cfg.write_block("animation.conf", "animations", body)
                self.cfg.reload_hyprland()
                self.status_cb(f"Saved {n}")

            for i, lab in enumerate(["X1", "Y1", "X2", "Y2"]):
                h = QHBoxLayout()
                h.addWidget(QLabel(lab + ":"))
                sp = QDoubleSpinBox()
                sp.setRange(-3.0, 3.0)
                sp.setSingleStep(0.1)
                sp.setValue(raw_pts[i])
                spins.append(sp)
                sp.editingFinished.connect(lambda: save_curve(name, canvas, spins))
                sp.valueChanged.connect(lambda v, idx=i: [setattr(canvas.points, str(idx), v), canvas.points.__setitem__(idx, v), canvas.update()])
                h.addWidget(sp)
                left.addLayout(h)
            
            row.addLayout(left, 1)
            
            canvas.valuesChanged.connect(lambda p, s=spins: [s[j].setValue(p[j]) for j in range(4)])
            canvas.interactionFinished.connect(lambda: save_curve(name, canvas, spins))
            row.addWidget(canvas, 2)
            self.bezier_layout.addWidget(grp)

    def _make_combobox_popup_stylable(self, combo: QComboBox):
        view = QListView()
        combo.setView(view)
        combo.setStyle(QStyleFactory.create("Fusion"))

class DecorationTab(QWidget):
    def __init__(self, cfg: HyprConfigManager, status_cb, theme: Theme):
        super().__init__()
        self.cfg = cfg
        self.status_cb = status_cb
        self.theme = theme
        self._build()

    def _build(self):
        outer = QVBoxLayout(self)
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QFrame.Shape.NoFrame)
        content = QWidget()
        v = QVBoxLayout(content)
        
        # General
        self.general_box = QGroupBox("General")
        g = QGridLayout(self.general_box)
        self.rounding = QSpinBox()
        self.rounding.setRange(0, 50)
        self.active_opacity = QDoubleSpinBox()
        self.active_opacity.setRange(0, 1)
        self.active_opacity.setSingleStep(0.05)
        self.fullscreen_opacity = QDoubleSpinBox()
        self.fullscreen_opacity.setRange(0, 1)
        self.fullscreen_opacity.setSingleStep(0.05)
        g.addWidget(QLabel("Rounding"),0,0); g.addWidget(self.rounding,0,1)
        g.addWidget(QLabel("Active Opacity"),1,0); g.addWidget(self.active_opacity,1,1)
        g.addWidget(QLabel("Fullscreen Opacity"),2,0); g.addWidget(self.fullscreen_opacity,2,1)
        v.addWidget(self.general_box)

        # Blur
        self.blur_box = QGroupBox("Blur")
        b = QGridLayout(self.blur_box)
        self.blur_enabled = QCheckBox("Enable Blur")
        self.blur_size = QSpinBox()
        self.blur_passes = QSpinBox()
        self.blur_ignore_opacity = QCheckBox("Ignore Opacity")
        self.blur_new_opt = QCheckBox("New Optimizations")
        self.blur_special = QCheckBox("Special")
        self.blur_popups = QCheckBox("Popups")
        b.addWidget(self.blur_enabled,0,0,1,2)
        b.addWidget(QLabel("Size"),1,0); b.addWidget(self.blur_size,1,1)
        b.addWidget(QLabel("Passes"),2,0); b.addWidget(self.blur_passes,2,1)
        b.addWidget(self.blur_ignore_opacity,3,0)
        b.addWidget(self.blur_new_opt,3,1)
        b.addWidget(self.blur_special,4,0)
        b.addWidget(self.blur_popups,4,1)
        v.addWidget(self.blur_box)

        # Shadow
        self.shadow_box = QGroupBox("Shadow")
        s = QGridLayout(self.shadow_box)
        self.shadow_enabled = QCheckBox("Enable Shadow")
        self.shadow_range = QSpinBox()
        self.shadow_power = QSpinBox()
        self.shadow_color = QLineEdit()
        self.shadow_color_inactive = QLineEdit()
        s.addWidget(self.shadow_enabled,0,0,1,2)
        s.addWidget(QLabel("Range"),1,0); s.addWidget(self.shadow_range,1,1)
        s.addWidget(QLabel("Power"),2,0); s.addWidget(self.shadow_power,2,1)
        s.addWidget(QLabel("Color"),3,0); s.addWidget(self.shadow_color,3,1)
        s.addWidget(QLabel("Inactive Color"),4,0); s.addWidget(self.shadow_color_inactive,4,1)
        v.addWidget(self.shadow_box)

        btn_row = QHBoxLayout()
        self.reload_btn = ModernButton("Reset UI", self.theme, "cyan")
        self.apply_btn = ModernButton("Apply Changes", self.theme, "green")
        btn_row.addWidget(self.reload_btn)
        btn_row.addStretch()
        btn_row.addWidget(self.apply_btn)
        v.addLayout(btn_row)

        self.reload_btn.clicked.connect(self.refresh_from_config)
        self.apply_btn.clicked.connect(self.apply_to_config)

        v.addStretch()
        scroll.setWidget(content)
        outer.addWidget(scroll)
        self.refresh_from_config()

    def refresh_from_config(self):
        d = self.cfg.read_decoration()
        self.rounding.setValue(d["rounding"])
        self.active_opacity.setValue(d["active_opacity"])
        self.fullscreen_opacity.setValue(d["fullscreen_opacity"])
        
        b = d["blur"]
        self.blur_enabled.setChecked(b["enabled"])
        self.blur_size.setValue(b["size"])
        self.blur_passes.setValue(b["passes"])
        self.blur_ignore_opacity.setChecked(b["ignore_opacity"])
        self.blur_new_opt.setChecked(b["new_optimizations"])
        self.blur_special.setChecked(b["special"])
        self.blur_popups.setChecked(b["popups"])

        s = d["shadow"]
        self.shadow_enabled.setChecked(s["enabled"])
        self.shadow_range.setValue(s["range"])
        self.shadow_power.setValue(s["render_power"])
        self.shadow_color.setText(str(s["color"]))
        self.shadow_color_inactive.setText(str(s["color_inactive"]))
        self.status_cb("Decoration loaded")

    def apply_to_config(self):
        data = {
            "rounding": self.rounding.value(),
            "active_opacity": self.active_opacity.value(),
            "fullscreen_opacity": self.fullscreen_opacity.value(),
            "dim_inactive": True, "dim_strength": 0.1, "dim_special": 0.8,
            "blur": {
                "enabled": self.blur_enabled.isChecked(),
                "size": self.blur_size.value(),
                "passes": self.blur_passes.value(),
                "ignore_opacity": self.blur_ignore_opacity.isChecked(),
                "new_optimizations": self.blur_new_opt.isChecked(),
                "special": self.blur_special.isChecked(),
                "popups": self.blur_popups.isChecked(),
            },
            "shadow": {
                "enabled": self.shadow_enabled.isChecked(),
                "range": self.shadow_range.value(),
                "render_power": self.shadow_power.value(),
                "color": self.shadow_color.text(),
                "color_inactive": self.shadow_color_inactive.text(),
            }
        }
        self.cfg.write_decoration(data)
        self.status_cb("Decoration Applied")

class AutostartTab(QWidget):
    def __init__(self, cfg, cb, theme):
        super().__init__()
        self.cfg = cfg
        self.show_status = cb
        self.theme = theme
        self.file = "autostart.conf"
        self.model = []
        self._build()
        self.reload_from_file()

    def _build(self):
        root = QVBoxLayout(self)
        self.table = QTableWidget(0, 2)
        self.table.setHorizontalHeaderLabels(["Enable", "Command"])
        self.table.horizontalHeader().setStretchLastSection(True)
        root.addWidget(self.table)
        
        row = QHBoxLayout()
        b_add = ModernButton("Add", self.theme)
        b_del = ModernButton("Remove", self.theme, "red")
        b_save = ModernButton("Save", self.theme, "green")
        row.addWidget(b_add); row.addWidget(b_del); row.addStretch(); row.addWidget(b_save)
        root.addLayout(row)

        b_add.clicked.connect(self.add_entry)
        b_del.clicked.connect(self.remove_selected)
        b_save.clicked.connect(self.apply_to_file)

    def reload_from_file(self):
        text = self.cfg.read_text(self.file)
        self.model = []
        for line in text.splitlines():
            cmd = line.strip()
            if not cmd or cmd.startswith("#AUTOSTART"): continue
            enabled = not cmd.startswith("#")
            clean_cmd = cmd.replace("exec-once =", "").replace("#", "").strip()
            self.model.append({"enabled": enabled, "cmd": clean_cmd})
        self._rebuild_table()

    def _rebuild_table(self):
        self.table.setRowCount(len(self.model))
        for r, item in enumerate(self.model):
            chk = QTableWidgetItem()
            chk.setFlags(Qt.ItemFlag.ItemIsUserCheckable | Qt.ItemFlag.ItemIsEnabled | Qt.ItemFlag.ItemIsSelectable)
            chk.setCheckState(Qt.CheckState.Checked if item["enabled"] else Qt.CheckState.Unchecked)
            self.table.setItem(r, 0, chk)
            self.table.setItem(r, 1, QTableWidgetItem(item["cmd"]))

    def add_entry(self):
        self.model.append({"enabled": True, "cmd": "new_command"})
        self._rebuild_table()

    def remove_selected(self):
        rows = sorted({idx.row() for idx in self.table.selectionModel().selectedRows()}, reverse=True)
        for r in rows: self.model.pop(r)
        self._rebuild_table()

    def apply_to_file(self):
        lines = ["#AUTOSTART\n"]
        for r in range(self.table.rowCount()):
            en = self.table.item(r, 0).checkState() == Qt.CheckState.Checked
            cmd = self.table.item(r, 1).text().strip()
            if cmd:
                prefix = "exec-once = " if en else "# exec-once = "
                lines.append(f"{prefix}{cmd}")
        self.cfg.write_text(self.file, "\n".join(lines))
        self.cfg.reload_hyprland()
        self.show_status("Autostart Saved")

class GeneralTab(QWidget):
    def __init__(self, cfg, cb, theme):
        super().__init__()
        self.cfg = cfg
        self.cb = cb
        self.theme = theme
        self._build()
        self.reload_from_file()

    def _build(self):
        layout = QVBoxLayout(self)
        self.general_box = QGroupBox("General")
        g = QGridLayout(self.general_box)
        self.gaps_in = QSpinBox(); self.gaps_in.setRange(0, 100)
        self.gaps_out = QSpinBox(); self.gaps_out.setRange(0, 100)
        self.border_size = QSpinBox()
        g.addWidget(QLabel("Gaps In"),0,0); g.addWidget(self.gaps_in,0,1)
        g.addWidget(QLabel("Gaps Out"),1,0); g.addWidget(self.gaps_out,1,1)
        g.addWidget(QLabel("Border Size"),2,0); g.addWidget(self.border_size,2,1)
        layout.addWidget(self.general_box)

        self.col_box = QGroupBox("Colors")
        c = QGridLayout(self.col_box)
        self.col_active = QLineEdit()
        self.col_inactive = QLineEdit()
        c.addWidget(QLabel("Active Border"),0,0); c.addWidget(self.col_active,0,1)
        c.addWidget(QLabel("Inactive Border"),1,0); c.addWidget(self.col_inactive,1,1)
        layout.addWidget(self.col_box)

        btn = ModernButton("Apply General", self.theme, "green")
        btn.clicked.connect(self.apply)
        layout.addWidget(btn)
        layout.addStretch()

    def reload_from_file(self):
        txt = self.cfg.read_block("general.conf", "general")
        kv = {}
        for l in txt.splitlines():
            if "=" in l:
                k, v = l.split("=", 1)
                kv[k.strip()] = v.strip()
        self.gaps_in.setValue(int(kv.get("gaps_in", 5)))
        self.gaps_out.setValue(int(kv.get("gaps_out", 10)))
        self.border_size.setValue(int(kv.get("border_size", 2)))
        self.col_active.setText(kv.get("col.active_border", ""))
        self.col_inactive.setText(kv.get("col.inactive_border", ""))

    def apply(self):
        lines = [
            f"    gaps_in = {self.gaps_in.value()}",
            f"    gaps_out = {self.gaps_out.value()}",
            f"    border_size = {self.border_size.value()}",
            f"    col.active_border = {self.col_active.text()}",
            f"    col.inactive_border = {self.col_inactive.text()}",
            "    layout = dwindle"
        ]
        self.cfg.write_block("general.conf", "general", "\n".join(lines))
        self.cfg.reload_hyprland()
        self.cb("General Updated")

class CheatTab(QWidget):
    def __init__(self, conf_dir):
        super().__init__()
        self.conf_dir = conf_dir
        self._build()

    def _build(self):
        l = QVBoxLayout(self)
        self.search = QLineEdit()
        self.search.setPlaceholderText("Search keybinds...")
        l.addWidget(self.search)
        self.table = QTableWidget(0, 4)
        self.table.setHorizontalHeaderLabels(["Mod", "Key", "Action", "Cmd"])
        self.table.horizontalHeader().setSectionResizeMode(3, QHeaderView.ResizeMode.Stretch)
        l.addWidget(self.table)
        
        self.binds = []
        path = os.path.join(self.conf_dir, "keybind.conf")
        if os.path.exists(path):
            with open(path) as f:
                for line in f:
                    if line.strip().startswith("bind"):
                        parts = line.split("=", 1)[1].split(",")
                        if len(parts) >= 3:
                            self.binds.append(parts)
        
        self.update_table("")
        self.search.textChanged.connect(self.update_table)

    def update_table(self, q):
        self.table.setRowCount(0)
        for b in self.binds:
            full = "".join(b).lower()
            if q.lower() in full:
                r = self.table.rowCount()
                self.table.insertRow(r)
                for i in range(min(4, len(b))):
                    self.table.setItem(r, i, QTableWidgetItem(b[i].strip()))

# =========================================================
# NEW: WALLPAPER TAB
# =========================================================
class WallpaperTab(QWidget):
    def __init__(self, cfg: HyprConfigManager, status_cb, theme: Theme):
        super().__init__()
        self.cfg = cfg
        self.status_cb = status_cb
        self.theme = theme
        self._build()

    def _build(self):
        layout = QVBoxLayout(self)
        layout.setSpacing(20)
        layout.setContentsMargins(20, 20, 20, 20)

        title = QLabel("Wallpaper Manager (Hyprpaper)")
        title.setStyleSheet(f"font-size: 18px; font-weight: bold; color: {self.theme.cyan};")
        layout.addWidget(title)

        self.preview_lbl = QLabel("No Wallpaper Selected")
        self.preview_lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.preview_lbl.setStyleSheet(f"""
            background-color: {self.theme.panel};
            border: 2px dashed {self.theme.border};
            border-radius: 12px;
            color: {self.theme.muted};
        """)
        self.preview_lbl.setMinimumHeight(250)
        layout.addWidget(self.preview_lbl)

        ctrl_grp = QGroupBox("Settings")
        form = QGridLayout(ctrl_grp)
        form.setVerticalSpacing(15)

        self.path_edit = QLineEdit()
        self.path_edit.setPlaceholderText("/path/to/wallpaper.png")
        self.path_edit.setReadOnly(True)
        
        btn_browse = ModernButton("Browse...", self.theme)
        btn_browse.clicked.connect(self.browse_file)

        self.monitor_edit = QLineEdit()
        self.monitor_edit.setPlaceholderText("Leave empty for all monitors")

        form.addWidget(QLabel("Current Path:"), 0, 0)
        form.addWidget(self.path_edit, 0, 1)
        form.addWidget(btn_browse, 0, 2)
        form.addWidget(QLabel("Monitor:"), 1, 0)
        form.addWidget(self.monitor_edit, 1, 1, 1, 2)

        layout.addWidget(ctrl_grp)

        btn_row = QHBoxLayout()
        btn_row.addStretch()
        self.btn_apply = ModernButton("Apply & Reload", self.theme, "green")
        self.btn_apply.clicked.connect(self.apply_wallpaper)
        btn_row.addWidget(self.btn_apply)
        layout.addLayout(btn_row)
        layout.addStretch()
        self.refresh()

    def refresh(self):
        data = self.cfg.read_wallpaper_conf()
        self.path_edit.setText(data.get("path", ""))
        self.monitor_edit.setText(data.get("monitor", ""))
        self.load_preview(data.get("path", ""))

    def load_preview(self, path):
        if os.path.exists(path):
            pix = QPixmap(path)
            if not pix.isNull():
                self.preview_lbl.setPixmap(pix.scaled(
                    self.preview_lbl.size(), 
                    Qt.AspectRatioMode.KeepAspectRatio, 
                    Qt.TransformationMode.SmoothTransformation
                ))
                self.preview_lbl.setText("")
                return
        self.preview_lbl.setText("Image not found")
        self.preview_lbl.setPixmap(QPixmap())

    def browse_file(self):
        fname, _ = QFileDialog.getOpenFileName(self, "Select Wallpaper", 
                                             os.path.expanduser("~/Pictures"), 
                                             "Images (*.png *.jpg *.jpeg *.webp)")
        if fname:
            self.path_edit.setText(fname)
            self.load_preview(fname)

    def apply_wallpaper(self):
        path = self.path_edit.text()
        mon = self.monitor_edit.text()
        if not path:
            self.status_cb("Error: No path selected")
            return
        self.cfg.write_wallpaper_conf(path, mon)
        self.status_cb("Wallpaper updated!")

# =========================================================
# MAIN WINDOW (UPDATED LAYOUT)
# =========================================================
class NovalandCenter(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Novaland Command Center")
        self.resize(1100, 750)
        self.theme = Theme()
        self.conf_dir = os.path.expanduser("~/.config/hypr/conf")
        self.cfg = HyprConfigManager(self.conf_dir)
        self._build_ui()
        self.apply_style()

    def _build_ui(self):
        root = QWidget()
        self.setCentralWidget(root)
        main_layout = QVBoxLayout(root)
        main_layout.setContentsMargins(0, 0, 0, 0)

        # Header
        header = QFrame()
        header.setFixedHeight(60)
        header.setStyleSheet(f"background-color: {self.theme.panel}; border-bottom: 1px solid {self.theme.border};")
        hl = QHBoxLayout(header)
        hl.setContentsMargins(20, 0, 20, 0)
        logo = QLabel("🌌 NOVALAND")
        logo.setStyleSheet(f"font-size: 20px; font-weight: 900; color: {self.theme.cyan}; letter-spacing: 1px;")
        hl.addWidget(logo)
        hl.addStretch()
        self.status_lbl = QLabel("Ready")
        self.status_lbl.setStyleSheet(f"color: {self.theme.green}; font-weight: bold;")
        hl.addWidget(self.status_lbl)
        main_layout.addWidget(header)

        # Tabs
        self.tabs = QTabWidget()
        self.tabs.setTabPosition(QTabWidget.TabPosition.West)
        self.tabs.setIconSize(QSize(24, 24))
        
        self.anim_tab = AnimationTab(self.cfg, self.show_status, self.theme)
        self.tabs.addTab(self.anim_tab, " ✨ Animations ")
        
        self.deco_tab = DecorationTab(self.cfg, self.show_status, self.theme)
        self.tabs.addTab(self.deco_tab, " 🎨 Decoration ")
        
        self.wall_tab = WallpaperTab(self.cfg, self.show_status, self.theme)
        self.tabs.addTab(self.wall_tab, " 🖼️ Wallpaper ")
        
        self.gen_tab = GeneralTab(self.cfg, self.show_status, self.theme)
        self.tabs.addTab(self.gen_tab, " ⚙️ General ")

        self.auto_tab = AutostartTab(self.cfg, self.show_status, self.theme)
        self.tabs.addTab(self.auto_tab, " 🚀 Autostart ")

        self.cheat_tab = CheatTab(self.conf_dir)
        self.tabs.addTab(self.cheat_tab, " ⌨️ Keybinds ")

        main_layout.addWidget(self.tabs)

    def show_status(self, msg: str):
        self.status_lbl.setText(msg)
        QTimer.singleShot(3000, lambda: self.status_lbl.setText("Ready"))

    def apply_style(self):
        t = self.theme
        qss = f"""
        QMainWindow, QWidget {{
            background-color: {t.bg_main};
            color: {t.text};
            font-family: 'Segoe UI', Inter, sans-serif;
            font-size: 14px;
        }}
        QTabWidget::pane {{ border: none; background-color: {t.bg_main}; }}
        QTabBar::tab {{
            background: {t.panel};
            color: {t.muted};
            padding: 15px 20px;
            border: none;
            margin-bottom: 2px;
            border-top-left-radius: 8px;
            border-bottom-left-radius: 8px;
            text-align: left;
            font-weight: 600;
        }}
        QTabBar::tab:selected {{
            background: {t.bg_secondary};
            color: {t.cyan};
            border-left: 4px solid {t.cyan};
        }}
        QTabBar::tab:hover {{ background: {t.bg_secondary}; color: {t.text}; }}
        QLineEdit, QDoubleSpinBox, QSpinBox, QComboBox {{
            background-color: {t.bg_secondary};
            border: 1px solid {t.border};
            border-radius: 6px;
            padding: 8px;
            color: {t.text};
            selection-background-color: {t.accent};
        }}
        QGroupBox {{
            font-weight: bold;
            border: 1px solid {t.border};
            border-radius: 8px;
            margin-top: 24px;
            padding-top: 10px;
        }}
        QGroupBox::title {{
            subcontrol-origin: margin;
            subcontrol-position: top left;
            left: 10px;
            padding: 0 5px;
            color: {t.purple};
        }}
        """
        app = QApplication.instance()
        if app:
            app.setStyle(QStyleFactory.create("Fusion"))
            app.setStyleSheet(qss)

def main():
    app = QApplication(sys.argv)
    win = NovalandCenter()
    win.show()
    sys.exit(app.exec())

if __name__ == "__main__":
    main()