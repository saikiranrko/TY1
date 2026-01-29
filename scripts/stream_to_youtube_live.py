#!/usr/bin/env python3
"""
Create a YouTube Live broadcast and stream video content via RTMP.
"""
import datetime
import os
import subprocess
import sys
import time
from typing import List

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build


def get_env(name: str, required: bool = True, default: str = "") -> str:
    value = os.getenv(name, default)
    if required and not value:
        raise SystemExit(f"[stream_to_youtube_live] Missing required environment variable: {name}")
    return value


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit("Usage: stream_to_youtube_live.py <video_path> [duration_hours]")

    video_path = sys.argv[1]
    if not os.path.isfile(video_path):
        raise SystemExit(f"[stream_to_youtube_live] Video file not found: {video_path}")

    # Default to 6 hours (GitHub Actions free tier limit), but allow override
    duration_hours = float(sys.argv[2]) if len(sys.argv) > 2 else 6.0
    duration_seconds = int(duration_hours * 3600)

    client_id = get_env("YOUTUBE_CLIENT_ID")
    client_secret = get_env("YOUTUBE_CLIENT_SECRET")
    refresh_token = get_env("YOUTUBE_REFRESH_TOKEN")

    # Metadata templates
    now = datetime.datetime.utcnow()
    date_str = now.strftime("%Y-%m-%d %H:%M UTC")

    title_template = os.getenv("YT_TITLE_TEMPLATE", "🔴 Cozy Live Stream - {date}")
    title = title_template.format(date=date_str)

    description = os.getenv(
        "YT_DESCRIPTION",
        "🔴 LIVE: Automatically generated cozy background stream using GitHub Actions and FFmpeg.\n"
        f"Stream started at {date_str}.\n"
        "Perfect for studying, relaxing, or sleeping.",
    )

    tags_raw = os.getenv("YT_TAGS", "live,cozy,lofi,study,relax,sleep")
    tags: List[str] = [t.strip() for t in tags_raw.split(",") if t.strip()]

    privacy_status = os.getenv("YT_PRIVACY_STATUS", "unlisted").lower()
    if privacy_status not in {"public", "unlisted", "private"}:
        raise SystemExit(
            f"[stream_to_youtube_live] Invalid YT_PRIVACY_STATUS: {privacy_status} "
            "(must be public, unlisted, or private)"
        )

    print("[stream_to_youtube_live] Preparing credentials...")
    creds = Credentials(
        None,
        refresh_token=refresh_token,
        token_uri="https://oauth2.googleapis.com/token",
        client_id=client_id,
        client_secret=client_secret,
        # Need full YouTube scope for live streaming
        scopes=["https://www.googleapis.com/auth/youtube"],
    )

    creds.refresh(Request())
    youtube = build("youtube", "v3", credentials=creds)

    print("[stream_to_youtube_live] Creating live stream...")
    # Step 1: Create a live stream
    stream_body = {
        "snippet": {
            "title": f"Stream for {title}",
        },
        "cdn": {
            "format": "1080p",
            "ingestionType": "rtmp",
        },
    }

    stream_response = youtube.liveStreams().insert(
        part="snippet,cdn",
        body=stream_body,
    ).execute()

    stream_id = stream_response["id"]
    rtmp_url = stream_response["cdn"]["ingestionInfo"]["ingestionAddress"]
    stream_key = stream_response["cdn"]["ingestionInfo"]["streamName"]
    full_rtmp_url = f"{rtmp_url}/{stream_key}"

    print(f"[stream_to_youtube_live] Stream created. Stream ID: {stream_id}")
    print(f"[stream_to_youtube_live] RTMP URL: {full_rtmp_url}")

    print("[stream_to_youtube_live] Creating live broadcast...")
    # Step 2: Create a live broadcast
    broadcast_body = {
        "snippet": {
            "title": title,
            "description": description,
            "scheduledStartTime": now.isoformat() + "Z",
        },
        "status": {
            "privacyStatus": privacy_status,
            "selfDeclaredMadeForKids": False,
        },
        "contentDetails": {
            "enableAutoStart": True,
            "enableAutoStop": True,
        },
    }

    broadcast_response = youtube.liveBroadcasts().insert(
        part="snippet,status,contentDetails",
        body=broadcast_body,
    ).execute()

    broadcast_id = broadcast_response["id"]
    print(f"[stream_to_youtube_live] Broadcast created. Broadcast ID: {broadcast_id}")

    # Step 3: Bind stream to broadcast
    print("[stream_to_youtube_live] Binding stream to broadcast...")
    youtube.liveBroadcasts().bind(
        part="id,contentDetails",
        id=broadcast_id,
        streamId=stream_id,
    ).execute()

    print("[stream_to_youtube_live] Starting FFmpeg stream...")
    print(f"[stream_to_youtube_live] Streaming for {duration_hours} hours ({duration_seconds} seconds)")

    # Step 4: Stream video via FFmpeg to RTMP
    # Loop the video file and stream it continuously
    ffmpeg_cmd = [
        "ffmpeg",
        "-re",  # Read input at native frame rate
        "-stream_loop", "-1",  # Loop input infinitely
        "-i", video_path,
        "-c:v", "libx264",
        "-preset", "veryfast",  # Fast encoding for live streaming
        "-tune", "zerolatency",
        "-b:v", "2500k",  # Bitrate for 1080p
        "-maxrate", "2500k",
        "-bufsize", "5000k",
        "-g", "60",  # Keyframe interval (2 seconds at 30fps)
        "-c:a", "aac",
        "-b:a", "128k",
        "-ar", "44100",
        "-f", "flv",  # FLV format for RTMP
        "-t", str(duration_seconds),  # Limit to duration_hours
        full_rtmp_url,
    ]

    print(f"[stream_to_youtube_live] FFmpeg command: {' '.join(ffmpeg_cmd)}")
    print("[stream_to_youtube_live] Streaming started. Check your YouTube channel!")

    try:
        # Run FFmpeg and stream
        process = subprocess.Popen(
            ffmpeg_cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            universal_newlines=True,
            bufsize=1,
        )

        # Monitor FFmpeg output
        for line in process.stdout:
            print(f"[ffmpeg] {line.rstrip()}", flush=True)

        process.wait()

        if process.returncode != 0:
            print(f"[stream_to_youtube_live] FFmpeg exited with code {process.returncode}")
        else:
            print("[stream_to_youtube_live] Stream completed successfully")

    except KeyboardInterrupt:
        print("[stream_to_youtube_live] Stream interrupted by user")
        process.terminate()
        process.wait()
    except Exception as e:
        print(f"[stream_to_youtube_live] Error during streaming: {e}")
        if process.poll() is None:
            process.terminate()
            process.wait()
        raise

    print(f"[stream_to_youtube_live] Live stream finished. Broadcast ID: {broadcast_id}")
    print(f"[stream_to_youtube_live] View at: https://www.youtube.com/watch?v={broadcast_id}")


if __name__ == "__main__":
    main()
