#!/usr/bin/env python3
import sys
import os
import urllib.request
import urllib.parse
import time

# Pollinations.ai API for video
# Model options: 'veo', 'seedance' (as per recent docs)
MODEL = "veo"

def generate_video(prompt, output_file):
    # Encode the prompt for URL
    encoded_prompt = urllib.parse.quote(prompt)
    url = f"https://gen.pollinations.ai/image/{encoded_prompt}?model={MODEL}&width=768&height=432"
    
    print(f"[generate_ai_video_pollinations] Requesting video from: {url}")
    
    try:
        # Some models might return a redirect to a video file or the video bytes directly
        # We'll try to download it
        headers = {
            "User-Agent": "Mozilla/5.0"
        }
        
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as response:
            content_type = response.headers.get('Content-Type', '')
            print(f"[generate_ai_video_pollinations] Received Content-Type: {content_type}")
            
            # If it's a video or stream
            content = response.read()
            with open(output_file, "wb") as f:
                f.write(content)
            
            # Check if file is valid (not just a small error message)
            if os.path.getsize(output_file) > 1000:
                print(f"[generate_ai_video_pollinations] Video saved to: {output_file}")
                return True
            else:
                print(f"[generate_ai_video_pollinations] Error: Generated file is too small (likely an error message).")
                # Try printing the content if it's text
                try:
                    print(content.decode('utf-8'))
                except:
                    pass
                return False
                
    except Exception as e:
        print(f"[generate_ai_video_gradio] Error: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: generate_ai_video_pollinations.py <prompt> <output_mp4>")
        sys.exit(1)
        
    prompt = sys.argv[1]
    output_file = sys.argv[2]
    
    success = generate_video(prompt, output_file)
    if not success:
        sys.exit(1)
