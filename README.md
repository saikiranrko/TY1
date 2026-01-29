<<<<<<< HEAD
# TY1
=======
### Cozy 12-Hour Background Stream Generator

This repository automatically generates a **YouTube-style cozy long video** using **GitHub Actions** and **FFmpeg**.

- **Base video**: 1 hour, 1920x1080, 30fps  
- **Final video**: 12 hours (default), seamless looping feel  
- **Output file**: `output/cozy_12_hour_stream.mp4` (by default)

Everything runs inside **GitHub Actions** on an Ubuntu runner. No paid services or manual interaction are required.

---

### Randomization behavior

Each run of the generator introduces a bit of randomness:

- **Music / ambience**: a **new 1-hour ambient soundscape is generated on every run** (no external audio needed). Themes: `rain`, `wind`, `fireplace`, `ocean` (or `random`).
- **Background**: when `video/background.png` is auto-generated, a random color is chosen from a small cozy palette.

If you provide your own `background.png`, it will be used as-is. Audio is generated every run by default.

---

### Repository structure

```text
.
├── audio/
│   └── cozy_music.mp3        # placeholder or your own music
├── video/
│   └── background.png        # cozy aesthetic background
├── scripts/
│   ├── create_base_video.sh
│   ├── loop_video.sh
│   └── build_final_video.sh
├── output/                   # generated videos (created automatically)
├── .github/
│   └── workflows/
│       └── generate-video.yml
└── README.md
```

> Note: `audio/`, `video/`, and `output/` are created automatically by the scripts if they do not exist.

---

### How it works

#### 1. Assets

- `audio/cozy_music.mp3`
- `video/background.png`

If either file is **missing**, the scripts will **auto-generate placeholders**:

- `cozy_music.mp3`:
  - 1-hour soft sine tone (440 Hz).
  - Generated via FFmpeg, royalty-free placeholder.
- `background.png`:
  - 1920x1080 solid cozy color.
  - Generated via FFmpeg’s `color` source.

You can replace these files with your own assets at any time.

#### 2. Base 1-hour video

Script: `scripts/create_base_video.sh`

- Loops `video/background.png` as a still-image video at **30 fps**.
- Uses `audio/cozy_music.mp3` as the soundtrack.
- Produces `output/base_1h.mp4`:
  - 1920x1080  
  - 30 fps  
  - 1-hour duration  
  - H.264 video (`libx264`), AAC audio.

The audio is exactly 1 hour, with no silence gaps, and the background has no black frames.

#### 3. Looping to 12 hours (or more)

Script: `scripts/loop_video.sh`

- Takes `output/base_1h.mp4` as input.
- Loops it **N** times using `ffmpeg -stream_loop`, where **N** equals the number of hours.
- Re-encodes once with YouTube-friendly settings:
  - `libx264`, `high` profile, `level 4.1`  
  - `yuv420p` pixel format  
  - AAC audio, 128 kbps  
  - `-movflags +faststart` for faster streaming start.

The default is **12 hours**, and the output is:

- `output/cozy_12_hour_stream.mp4`

#### 4. Orchestration

Script: `scripts/build_final_video.sh`

- Calls:
  1. `scripts/create_base_video.sh`
  2. `scripts/loop_video.sh` with the desired total hours.
- Default behavior (no arguments):
  - Builds a 12-hour video as `output/cozy_12_hour_stream.mp4`.

---

### GitHub Actions Workflow

Workflow file: `.github/workflows/generate-video.yml`

- **Name**: `Generate Cozy Stream Video`
- **Trigger**: 
  - `workflow_dispatch` (manual run in GitHub UI)
  - `schedule`: Every 12 hours via cron
- **Job steps**:
  1. Checkout the repository.
  2. Install FFmpeg (`apt-get install ffmpeg`).
  3. `chmod +x` on all scripts.
  4. Run `./scripts/build_final_video.sh 12` to create the base video.
  5. **Stream to YouTube Live** using RTMP (true live streaming, not upload).

The workflow creates a **YouTube Live broadcast** and streams the cozy video content in real-time via RTMP.

---

### Automatic YouTube Live Streaming (every 12 hours)

The workflow `.github/workflows/generate-video.yml` is configured to:

- Run on demand (`workflow_dispatch`), and  
- Run automatically every 12 hours via a cron schedule.

After building `output/cozy_12_hour_stream.mp4`, it **creates a YouTube Live broadcast** and **streams the video in real-time** using the **YouTube Live Streaming API** and FFmpeg RTMP.

**Important**: GitHub Actions free tier has a **6-hour job limit**. The live stream will run for 6 hours by default. If you have a paid GitHub plan, you can increase `STREAM_DURATION_HOURS` in the workflow (up to 72 hours).

#### 1. Create OAuth credentials for YouTube Live Streaming

1. Go to the [Google Cloud Console](https://console.cloud.google.com/) and create (or select) a project.
2. Enable **both** APIs:
   - **YouTube Data API v3**
   - **YouTube Live Streaming API** (if separate in your console)
3. Create an **OAuth 2.0 Client ID** (type: *Web application* for OAuth Playground, or *Desktop app*).
4. Note down:
   - Client ID
   - Client Secret

#### 2. Obtain a refresh token (one-time local step)

You need a **refresh token** with the `https://www.googleapis.com/auth/youtube` scope (full YouTube scope, not just upload). The easiest way is to use OAuth 2.0 Playground:

- Uses your Client ID / Secret  
- Opens a browser for you to log in to your YouTube account  
- Saves the refresh token after consent is granted.

**⚠️ Important**: Make sure you select the scope `https://www.googleapis.com/auth/youtube` (full YouTube scope) in OAuth Playground, **not just** `youtube.upload`. Live streaming requires the full YouTube scope.

> **If you already have a refresh token**: If your existing refresh token only has `youtube.upload` scope, you'll need to regenerate it with the full `youtube` scope. Delete the old token in OAuth Playground and go through the authorization flow again, selecting `https://www.googleapis.com/auth/youtube`.

Once you have:

- `YOUTUBE_CLIENT_ID`
- `YOUTUBE_CLIENT_SECRET`
- `YOUTUBE_REFRESH_TOKEN` (with full YouTube scope)

you do **not** need to repeat this step, as the workflow will use the refresh token to get fresh access tokens on each run.

> For security, **do not** paste secrets into code or commits. Store them as GitHub Secrets.

#### 3. Store credentials as GitHub Secrets

In your GitHub repository:

1. Go to **Settings → Secrets and variables → Actions → New repository secret**.
2. Add:
   - `YOUTUBE_CLIENT_ID`
   - `YOUTUBE_CLIENT_SECRET`
   - `YOUTUBE_REFRESH_TOKEN` (must have full `youtube` scope)

The workflow step:

```yaml
      - name: Stream video to YouTube Live
        env:
          YOUTUBE_CLIENT_ID: ${{ secrets.YOUTUBE_CLIENT_ID }}
          YOUTUBE_CLIENT_SECRET: ${{ secrets.YOUTUBE_CLIENT_SECRET }}
          YOUTUBE_REFRESH_TOKEN: ${{ secrets.YOUTUBE_REFRESH_TOKEN }}
          YT_TITLE_TEMPLATE: "🔴 Cozy Live Stream - {date}"
          YT_DESCRIPTION: "🔴 LIVE: Automatically generated cozy background stream..."
          YT_TAGS: "live,cozy,lofi,study,relax,sleep"
          YT_PRIVACY_STATUS: "unlisted"
          STREAM_DURATION_HOURS: "6"  # GitHub Actions free tier limit
        timeout-minutes: 360  # 6 hours max
        run: |
          python scripts/stream_to_youtube_live.py output/cozy_12_hour_stream.mp4 "${STREAM_DURATION_HOURS}"
```

will then:

- Authenticate as your YouTube account (via the refresh token),
- Create a YouTube Live broadcast,
- Get an RTMP stream URL/key,
- Stream `output/cozy_12_hour_stream.mp4` in real-time via FFmpeg RTMP,
- The stream will appear live on your YouTube channel.

You can adjust the metadata by changing the `YT_*` environment variables above:

- `YT_TITLE_TEMPLATE`: a Python-style template, supports `{date}` (UTC timestamp).
- `YT_DESCRIPTION`: free-form description text.
- `YT_TAGS`: comma-separated tags.
- `YT_PRIVACY_STATUS`: `public`, `unlisted`, or `private`.
- `STREAM_DURATION_HOURS`: How long to stream (default: 6 hours due to GitHub Actions free tier limit).

---

### How to change the music or background

#### Change the music

1. Replace `audio/cozy_music.mp3` with your own track:
   - Recommended: 1-hour loop-friendly track, but it can be shorter or longer.
   - The base video script limits to 1 hour, so if your track is longer, it will be truncated.
2. Run locally:
   ```bash
   ./scripts/build_final_video.sh 12
   ```
3. Or push and re-run the GitHub Actions workflow.

#### Change the background

1. Replace `video/background.png` with your own 1920x1080 image.
2. Run locally or via GitHub Actions as above.

> If you delete either file, the scripts will re-create the placeholder assets on the next run.

---

### How to change the total hours (e.g., 6h, 24h)

The **total duration** is controlled by the argument to `build_final_video.sh` and `loop_video.sh`.

#### Locally

- For **6 hours**:
  ```bash
  ./scripts/build_final_video.sh 6
  # Output: output/cozy_6_hour_stream.mp4
  ```

- For **24 hours**:
  ```bash
  ./scripts/build_final_video.sh 24
  # Output: output/cozy_24_hour_stream.mp4
  ```

#### In GitHub Actions

Edit `.github/workflows/generate-video.yml`:

```yaml
      - name: Build 12-hour cozy video
        env:
          TOTAL_HOURS: 12   # change this to 6, 24, etc.
        run: |
          ./scripts/build_final_video.sh "${TOTAL_HOURS}"
```

The artifact name will remain `cozy_12_hour_stream` unless you also change it, but the generated file name will be:

- `cozy_<TOTAL_HOURS>_hour_stream.mp4`

---

### How to run locally

#### Prerequisites

- **FFmpeg** installed and available on your `PATH`.
  - On macOS (Homebrew):
    ```bash
    brew install ffmpeg
    ```
  - On Ubuntu:
    ```bash
    sudo apt-get update && sudo apt-get install -y ffmpeg
    ```

#### Steps

1. From the `TY1` directory:
   ```bash
   cd TY1
   ```

2. Make scripts executable:
   ```bash
   chmod +x scripts/create_base_video.sh
   chmod +x scripts/loop_video.sh
   chmod +x scripts/build_final_video.sh
   ```

3. Build a 12-hour video:
   ```bash
   ./scripts/build_final_video.sh 12
   ```

4. Find your video:
   ```bash
   ls output/
   # cozy_12_hour_stream.mp4
   ```

You can then open the file in a video player or upload it to YouTube.

---

### Idempotency

- All scripts use `ffmpeg -y` to **overwrite existing outputs** safely.
- Missing input assets (`audio/cozy_music.mp3`, `video/background.png`) are automatically recreated.
- Re-running the scripts or workflow will simply **rebuild** the videos with the latest inputs.

>>>>>>> 1c8931c (Add cozy YouTube live stream generator with random soundscapes)
