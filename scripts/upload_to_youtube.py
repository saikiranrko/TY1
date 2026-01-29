#!/usr/bin/env python3
import datetime
import os
import sys
from typing import List

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload


def get_env(name: str, required: bool = True, default: str = "") -> str:
    value = os.getenv(name, default)
    if required and not value:
        raise SystemExit(f"[upload_to_youtube] Missing required environment variable: {name}")
    return value


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit("Usage: upload_to_youtube.py <video_path>")

    video_path = sys.argv[1]
    if not os.path.isfile(video_path):
        raise SystemExit(f"[upload_to_youtube] Video file not found: {video_path}")

    client_id = get_env("YOUTUBE_CLIENT_ID")
    client_secret = get_env("YOUTUBE_CLIENT_SECRET")
    refresh_token = get_env("YOUTUBE_REFRESH_TOKEN")

    # Metadata templates
    now = datetime.datetime.utcnow()
    date_str = now.strftime("%Y-%m-%d %H:%M UTC")

    title_template = os.getenv("YT_TITLE_TEMPLATE", "Cozy 12-Hour Random Stream - {date}")
    title = title_template.format(date=date_str)

    description = os.getenv(
        "YT_DESCRIPTION",
        "Automatically generated cozy background stream using GitHub Actions and FFmpeg.\n"
        f"Generated at {date_str}.",
    )

    tags_raw = os.getenv("YT_TAGS", "cozy,lofi,study,relax,sleep")
    tags: List[str] = [t.strip() for t in tags_raw.split(",") if t.strip()]

    privacy_status = os.getenv("YT_PRIVACY_STATUS", "unlisted").lower()
    if privacy_status not in {"public", "unlisted", "private"}:
        raise SystemExit(
            f"[upload_to_youtube] Invalid YT_PRIVACY_STATUS: {privacy_status} "
            "(must be public, unlisted, or private)"
        )

    print("[upload_to_youtube] Preparing credentials...")
    creds = Credentials(
        None,
        refresh_token=refresh_token,
        token_uri="https://oauth2.googleapis.com/token",
        client_id=client_id,
        client_secret=client_secret,
        scopes=["https://www.googleapis.com/auth/youtube.upload"],
    )

    creds.refresh(Request())
    youtube = build("youtube", "v3", credentials=creds)

    body = {
        "snippet": {
            "title": title,
            "description": description,
            "tags": tags,
            # 10 = Music, 22 = People & Blogs, etc. Adjust if you like.
            "categoryId": "10",
        },
        "status": {
            "privacyStatus": privacy_status,
            "selfDeclaredMadeForKids": False,
        },
    }

    print(f"[upload_to_youtube] Uploading '{video_path}' with title: {title}")

    media = MediaFileUpload(video_path, chunksize=-1, resumable=True)
    request = youtube.videos().insert(
        part="snippet,status",
        body=body,
        media_body=media,
    )

    response = None
    while response is None:
        status, response = request.next_chunk()
        if status:
            print(f"[upload_to_youtube] Upload progress: {int(status.progress() * 100)}%", flush=True)

    video_id = response.get("id")
    print(f"[upload_to_youtube] Upload complete. Video ID: {video_id}")


if __name__ == "__main__":
    main()

