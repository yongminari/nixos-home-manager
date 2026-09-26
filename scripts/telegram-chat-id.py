#!/usr/bin/env python3
"""Look up private chat IDs after the user presses Start on their new bot."""

from getpass import getpass
import json
import re
import sys
from urllib.request import Request, urlopen


def main():
    token = getpass("Telegram bot token (hidden): ").strip()
    if not re.fullmatch(r"[0-9]+:[A-Za-z0-9_-]+", token):
        raise SystemExit("Invalid bot token")
    try:
        request = Request(
            f"https://api.telegram.org/bot{token}/getUpdates",
            data=b"{}", headers={"Content-Type": "application/json"}, method="POST",
        )
        with urlopen(request, timeout=10) as response:
            result = json.load(response)
        if not result.get("ok"):
            raise ValueError("Request failed")
        chats = {
            message["chat"]["id"]
            for update in result["result"]
            if (message := update.get("message")) and message["chat"]["type"] == "private"
        }
    except Exception:
        raise SystemExit("Lookup failed; check the bot token, network and existing webhook") from None
    if not chats:
        raise SystemExit("Send /start to your new bot, then run this command again")
    print("Private chat IDs (use your own chat):")
    for chat in sorted(chats):
        print(chat)
    return 0


if __name__ == "__main__":
    sys.exit(main())
