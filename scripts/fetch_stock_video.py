#!/usr/bin/env python3
import sys
import os
import httpx
import asyncio
import random
from pathlib import Path

# PEXELS_API_KEY should be set in environment
PEXELS_KEY = os.environ.get("PEXELS_API_KEY")

async def search_pexels_video(query: str, output_path: str) -> bool:
    if not PEXELS_KEY:
        print("[stock] ERROR: PEXELS_API_KEY not set.")
        return False
    
    url = "https://api.pexels.com/videos/search"
    headers = {"Authorization": PEXELS_KEY}
    params = {
        "query": query,
        "per_page": 15,
        "page": random.randint(1, 3),
        "orientation": "landscape",
        "min_width": 1280
    }
    
    print(f"[stock] Searching Pexels for: {query}")
    
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(url, headers=headers, params=params)
            
            if response.status_code == 200:
                data = response.json()
                videos = data.get('videos', [])
                if not videos:
                    print(f"[stock] No videos found for query: {query}")
                    return False
                
                # Pick a random video
                video = random.choice(videos)
                files = video.get('video_files', [])
                
                hd_file = None
                # Prioritize 1920x1080
                for f in files:
                    if f.get('width') == 1920 and f.get('height') == 1080:
                        hd_file = f
                        break
                
                if not hd_file:
                    # Fallback to any HD
                    hd_file = next((f for f in files if f.get('quality') == 'hd'), None)
                
                if not hd_file and files:
                    # Fallback to first available
                    hd_file = files[0]
                
                if hd_file:
                    video_url = hd_file['link']
                    print(f"[stock] Downloading video ({hd_file.get('width')}x{hd_file.get('height')}): {video_url}")
                    
                    video_resp = await client.get(video_url, follow_redirects=True)
                    if video_resp.status_code == 200:
                        with open(output_path, "wb") as f:
                            f.write(video_resp.content)
                        print(f"[stock] Saved video to: {output_path}")
                        return True
            else:
                print(f"[stock] API Error: {response.status_code}")
                return False
                
    except Exception as e:
        print(f"[stock] Exception during Pexels search: {e}")
        return False
    
    return False

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: fetch_stock_video.py <query> <output_path>")
        sys.exit(1)
        
    query = sys.argv[1]
    out_path = sys.argv[2]
    
    success = asyncio.run(search_pexels_video(query, out_path))
    if not success:
        sys.exit(1)
    sys.exit(0)
