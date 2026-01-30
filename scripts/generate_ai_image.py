#!/usr/bin/env python3
import sys
import os
import httpx
import asyncio
import time

async def generate_image(prompt, output_file):
    encoded_prompt = prompt.replace(" ", "%20")
    # Using a slightly different seed to avoid cache
    url = f"https://image.pollinations.ai/prompt/{encoded_prompt}?width=1920&height=1080&nologo=true&seed={int(time.time())}"
    
    print(f"[generate_ai_image] Requesting image from: {url}")
    
    try:
        # Increased timeout to 60 seconds
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.get(url, follow_redirects=True)
            if response.status_code == 200:
                with open(output_file, "wb") as f:
                    f.write(response.content)
                print(f"[generate_ai_image] Image saved to: {output_file}")
                return True
            else:
                print(f"[generate_ai_image] Failed: Status {response.status_code}")
        return False
    except Exception as e:
        print(f"[generate_ai_image] Error: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(1)
        
    prompt = sys.argv[1]
    output_file = sys.argv[2]
    
    try:
        asyncio.run(generate_image(prompt, output_file))
    except KeyboardInterrupt:
        print("[generate_ai_image] Interrupted by user.")
        sys.exit(1)
    except Exception as e:
        print(f"[generate_ai_image] Failed with error: {e}")
        sys.exit(1)
    sys.exit(0)
