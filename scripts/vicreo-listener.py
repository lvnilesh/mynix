#!/usr/bin/env python3
"""
VICREO-compatible TCP hotkey listener for Wayland (Hyprland).

Protocol-compatible with Bitfocus Companion's vicreo-hotkey module.
Uses wtype for keyboard simulation and ydotool for mouse actions.

Listens on TCP port 10001 (configurable via --port).
"""

import argparse
import hashlib
import json
import logging
import os
import shutil
import socket
import subprocess
import sys
import threading

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger("vicreo-listener")

# Password: empty string MD5 = no auth required
EMPTY_MD5 = "d41d8cd98f00b204e9800998ecf8427e"

# Linux evdev keycodes for ydotool (from linux/input-event-codes.h)
EVDEV_KEY_MAP = {
    # Letters
    **{chr(c): c - 97 + 30 for c in range(ord("a"), ord("z") + 1)},
    # Numbers
    "1": 2, "2": 3, "3": 4, "4": 5, "5": 6,
    "6": 7, "7": 8, "8": 9, "9": 10, "0": 11,
    # Special keys
    "backspace": 14, "delete": 111, "enter": 28, "tab": 15,
    "escape": 1, "up": 103, "down": 108, "left": 105, "right": 106,
    "home": 102, "end": 107,
    "pageup": 104, "pagedown": 109, "page_up": 104, "page_down": 109,
    "space": 57, "capslock": 58, "caps_lock": 58,
    "insert": 110, "printscreen": 99, "fn": 0x1D0,
    # Function keys F1-F24
    **{f"f{i}": i + 58 for i in range(1, 11)},
    "f11": 87, "f12": 88,
    "f13": 183, "f14": 184, "f15": 185, "f16": 186, "f17": 187,
    "f18": 188, "f19": 189, "f20": 190, "f21": 191, "f22": 192,
    "f23": 193, "f24": 194,
    # Modifiers
    "alt": 56, "right_alt": 100,
    "ctrl": 29, "control": 29, "left_ctrl": 29, "right_ctrl": 97,
    "shift": 42, "right_shift": 54,
    "command": 125, "win": 125, "super": 125,
    # Media keys
    "audio_mute": 113, "audio_vol_down": 114, "audio_vol_up": 115,
    "audio_play": 200, "audio_pause": 201, "audio_stop": 166,
    "audio_next": 163, "audio_prev": 165,
    # Brightness
    "lights_mon_up": 225, "lights_mon_down": 224,
    "lights_kbd_toggle": 228, "lights_kbd_up": 229,
    # Numpad
    "numpad_0": 82, "numpad_1": 79, "numpad_2": 80, "numpad_3": 81,
    "numpad_4": 75, "numpad_5": 76, "numpad_6": 77,
    "numpad_7": 71, "numpad_8": 72, "numpad_9": 73,
    # Punctuation
    "comma": 51, "period": 52, "slash": 53, "backslash": 43,
    "minus": 12, "plus": 13, "asterisk": 55,
    "semicolon": 39, "apostrophe": 40, "grave": 41,
    "leftbrace": 26, "rightbrace": 27, "equal": 13,
}

# Modifier key names used in VICREO protocol
MODIFIER_KEYS = {"alt", "ctrl", "control", "shift", "command", "win", "super",
                 "right_alt", "right_ctrl", "right_shift"}


def resolve_keycode(name: str) -> int | None:
    """Resolve a VICREO key name to a Linux evdev keycode for ydotool."""
    lower = name.lower()
    if lower in EVDEV_KEY_MAP:
        return EVDEV_KEY_MAP[lower]
    # Single character letter
    if len(name) == 1 and name.isalpha():
        return EVDEV_KEY_MAP.get(name.lower())
    # Single digit
    if len(name) == 1 and name.isdigit():
        return EVDEV_KEY_MAP.get(name)
    return None


def find_tool(name: str) -> str | None:
    """Find a tool in PATH."""
    return shutil.which(name)


class VICREOHandler:
    def __init__(self, password_md5: str):
        self.password_md5 = password_md5
        self.ydotool = find_tool("ydotool")

        if not self.ydotool:
            log.warning("ydotool not found — keyboard/mouse simulation will not work")

    def check_password(self, msg: dict) -> bool:
        pw = msg.get("password", "")
        if self.password_md5 == EMPTY_MD5:
            return True
        return pw == self.password_md5

    def handle_message(self, raw: str) -> str | None:
        """Process a single JSON message. Returns response string or None."""
        try:
            msg = json.loads(raw)
        except json.JSONDecodeError:
            log.warning("Invalid JSON: %s", raw[:200])
            return None

        if not self.check_password(msg):
            log.warning("Bad password from client")
            return None

        msg_type = msg.get("type", "")
        if not msg_type:
            return None
        log.info("Command: %s", msg_type)

        try:
            match msg_type:
                case "press":
                    self._press(msg)
                case "pressSpecial":
                    self._press(msg)
                case "combination":
                    self._combination(msg)
                case "trio":
                    self._combination(msg)
                case "quartet":
                    self._combination(msg)
                case "down":
                    self._key_down(msg)
                case "up":
                    self._key_up(msg)
                case "string":
                    self._type_string(msg)
                case "shell":
                    self._shell(msg)
                case "file":
                    self._open_file(msg)
                case "mousePosition":
                    self._mouse_move(msg)
                case "mouseClick":
                    self._mouse_click(msg)
                case "mouseClickHold":
                    self._mouse_click_hold(msg)
                case "mouseClickRelease":
                    self._mouse_click_release(msg)
                case "mouseScroll":
                    self._mouse_scroll(msg)
                case "getMousePosition":
                    return self._get_mouse_position()
                case "subscribe" | "unsubscribe":
                    pass  # subscription not implemented
                case "license":
                    pass  # not needed for open-source listener
                case "processOSX" | "setWindowToForeground":
                    log.info("Unsupported platform command: %s", msg_type)
                case "keepAlive":
                    pass
                case _:
                    log.warning("Unknown command type: %s", msg_type)
        except Exception:
            log.exception("Error handling %s", msg_type)

        return None

    def _run_ydotool(self, args: list[str]):
        if not self.ydotool:
            log.error("ydotool not available")
            return
        cmd = [self.ydotool] + args
        log.debug("Running: %s", " ".join(cmd))
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def _press(self, msg: dict):
        keycode = resolve_keycode(msg.get("key", ""))
        if keycode is None:
            log.warning("Unknown key: %s", msg.get("key"))
            return
        # ydotool key: keycode:1 = down, keycode:0 = up
        # --key-delay adds ms between events to ensure the compositor registers them
        self._run_ydotool(["key", "--key-delay", "20", f"{keycode}:1", f"{keycode}:0"])

    def _combination(self, msg: dict):
        """Handle combination/trio/quartet — modifiers + key."""
        keycode = resolve_keycode(msg.get("key", ""))
        modifiers = msg.get("modifiers", [])
        if keycode is None:
            log.warning("Unknown key: %s", msg.get("key"))
            return

        # Build sequence: press all modifiers, press key, release key, release modifiers
        args = ["key"]
        mod_codes = []
        for mod in modifiers:
            mc = resolve_keycode(mod)
            if mc is not None:
                mod_codes.append(mc)
                args.append(f"{mc}:1")

        args.append(f"{keycode}:1")
        args.append(f"{keycode}:0")

        for mc in reversed(mod_codes):
            args.append(f"{mc}:0")

        self._run_ydotool(args)

    def _key_down(self, msg: dict):
        keycode = resolve_keycode(msg.get("key", ""))
        if keycode is None:
            return
        self._run_ydotool(["key", f"{keycode}:1"])

    def _key_up(self, msg: dict):
        keycode = resolve_keycode(msg.get("key", ""))
        if keycode is None:
            return
        self._run_ydotool(["key", f"{keycode}:0"])

    def _type_string(self, msg: dict):
        text = msg.get("msg", "")
        if not text:
            return
        self._run_ydotool(["type", "--key-delay", "10", "--", text])

    def _shell(self, msg: dict):
        shell_cmd = msg.get("shell", "")
        if not shell_cmd:
            return
        log.info("Shell: %s", shell_cmd)
        subprocess.Popen(
            shell_cmd,
            shell=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

    def _open_file(self, msg: dict):
        path = msg.get("path", "")
        if not path:
            return
        log.info("Open file: %s", path)
        subprocess.Popen(
            ["xdg-open", path],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

    def _mouse_move(self, msg: dict):
        x = msg.get("x", 0)
        y = msg.get("y", 0)
        self._run_ydotool(["mousemove", "--absolute", "-x", str(x), "-y", str(y)])

    def _mouse_click(self, msg: dict):
        button = msg.get("button", "left")
        double = msg.get("double", "false")
        # ydotool click: 0xC0 = left, 0xC1 = right, 0xC2 = middle
        btn_map = {"left": "0xC0", "right": "0xC1", "middle": "0xC2"}
        btn_code = btn_map.get(button, "0xC0")
        if str(double).lower() == "true":
            self._run_ydotool(["click", btn_code, btn_code])
        else:
            self._run_ydotool(["click", btn_code])

    def _mouse_click_hold(self, msg: dict):
        button = msg.get("button", "left")
        # ydotool click --next-delay: 0xD0 = left down, 0xD1 = right down
        btn_map = {"left": "0xD0", "right": "0xD1"}
        btn_code = btn_map.get(button, "0xD0")
        self._run_ydotool(["click", btn_code])

    def _mouse_click_release(self, msg: dict):
        button = msg.get("button", "left")
        # ydotool click: 0xE0 = left up, 0xE1 = right up
        btn_map = {"left": "0xE0", "right": "0xE1"}
        btn_code = btn_map.get(button, "0xE0")
        self._run_ydotool(["click", btn_code])

    def _mouse_scroll(self, msg: dict):
        # Module sends x and y scroll amounts (-100 to 100)
        x = int(msg.get("x", 0))
        y = int(msg.get("y", 0))
        if x != 0 or y != 0:
            self._run_ydotool(["mousemove", "-w", "--", str(x), str(y)])

    def _get_mouse_position(self) -> str | None:
        # ydotool doesn't have a get-position command; return 0,0
        return json.dumps({"x": 0, "y": 0})


def handle_client(conn: socket.socket, addr, handler: VICREOHandler):
    log.info("Client connected: %s:%d", addr[0], addr[1])
    try:
        while True:
            data = conn.recv(4096)
            if not data:
                break
            text = data.decode("utf-8", errors="replace").strip()
            if not text:
                continue
            # Each recv may contain one or more JSON messages.
            # Try parsing as single message first (common case).
            try:
                json.loads(text)
                response = handler.handle_message(text)
                if response:
                    conn.sendall((response + "\n").encode())
                continue
            except json.JSONDecodeError:
                pass
            # Multiple messages: split by }{ boundary or newlines
            for chunk in text.replace("}{", "}\n{").split("\n"):
                chunk = chunk.strip()
                if chunk:
                    response = handler.handle_message(chunk)
                    if response:
                        conn.sendall((response + "\n").encode())
    except (ConnectionResetError, BrokenPipeError):
        pass
    except Exception:
        log.exception("Error with client %s", addr)
    finally:
        conn.close()
        log.info("Client disconnected: %s:%d", addr[0], addr[1])


def main():
    parser = argparse.ArgumentParser(description="VICREO-compatible hotkey listener")
    parser.add_argument("--port", type=int, default=10001, help="TCP listen port")
    parser.add_argument("--host", default="0.0.0.0", help="Listen address")
    parser.add_argument("--password", default="", help="Password (empty = no auth)")
    parser.add_argument("--debug", action="store_true", help="Debug logging")
    args = parser.parse_args()

    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)

    password_md5 = hashlib.md5(args.password.encode()).hexdigest()
    handler = VICREOHandler(password_md5)

    log.info("Tools: ydotool=%s", handler.ydotool or "MISSING")

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((args.host, args.port))
    server.listen(5)

    log.info("Listening on %s:%d (password=%s)", args.host, args.port, "set" if args.password else "none")

    try:
        while True:
            conn, addr = server.accept()
            thread = threading.Thread(target=handle_client, args=(conn, addr, handler), daemon=True)
            thread.start()
    except KeyboardInterrupt:
        log.info("Shutting down")
    finally:
        server.close()


if __name__ == "__main__":
    main()
