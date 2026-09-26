#!/usr/bin/env python3
"""Send a fixed completion message without forwarding conversation content."""

import argparse
import json
from pathlib import Path
import re
import sys
from urllib.request import Request, urlopen


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", required=True)
    parser.add_argument("--token-file", required=True, type=Path)
    parser.add_argument("--chat-id-file", required=True, type=Path)
    parser.add_argument("event", help="Codex notification JSON")
    args = parser.parse_args()
    try:
        event = json.loads(args.event)
        if not isinstance(event, dict) or event.get("type") != "agent-turn-complete":
            return 0
        token = args.token_file.read_text().strip()
        chat_id = args.chat_id_file.read_text().strip()
        if not re.fullmatch(r"[0-9]+:[A-Za-z0-9_-]+", token):
            raise ValueError("Invalid token")
        if not re.fullmatch(r"-?[0-9]+", chat_id):
            raise ValueError("Invalid chat ID")
        payload = json.dumps({
            "chat_id": chat_id,
            "text": f"✅ {args.host}: Codex 응답 완료",
            "disable_notification": False,
        }).encode("utf-8")
        request = Request(
            f"https://api.telegram.org/bot{token}/sendMessage",
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urlopen(request, timeout=10) as response:
            if not json.load(response).get("ok"):
                raise ValueError("Telegram rejected notification")
    except Exception:
        # HTTP 예외에는 토큰을 포함한 URL이 들어갈 수 있으므로 내용을 출력하지 않습니다.
        print("codex-telegram: notification failed; check secrets and network", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
