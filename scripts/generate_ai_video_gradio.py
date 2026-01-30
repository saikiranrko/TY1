#!/usr/bin/env python3
import sys
import os
import shutil
from gradio_client import Client

# Space identified as active and high quality
SPACE_ID = "zai-org/CogVideoX-2B-Space"

def generate_video(prompt, output_file):
    print(f"[generate_ai_video_gradio] Connecting to Space: {SPACE_ID}")
    try:
        client = Client(SPACE_ID)
        
        print(f"[generate_ai_video_gradio] Generating video for prompt: '{prompt}'")
        
        # prompt, num_inference_steps, guidance_scale
        result = client.predict(
            prompt=prompt,
            num_inference_steps=20,    # Lower steps for faster generation
            guidance_scale=6.0,
            api_name="/generate"
        )
        
        # result is a tuple: (cogvideox_generate_video, _download_video, _download_gif)
        # cogvideox_generate_video is a dict with 'video' key pointing to the path
        if result and len(result) > 0:
            video_info = result[0]
            if isinstance(video_info, dict) and 'video' in video_info:
                video_path = video_info['video']
                if os.path.exists(video_path):
                    print(f"[generate_ai_video_gradio] Success! Result file: {video_path}")
                    shutil.copy(video_path, output_file)
                    print(f"[generate_ai_video_gradio] Saved to: {output_file}")
                    return True
            # Fallback check for raw path
            elif isinstance(video_info, str) and os.path.exists(video_info):
                shutil.copy(video_info, output_file)
                return True
        
        print(f"[generate_ai_video_gradio] Error: Unexpected result format: {result}")
        return False
            
    except Exception as e:
        print(f"[generate_ai_video_gradio] Error: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: generate_ai_video_gradio.py <prompt> <output_mp4>")
        sys.exit(1)
        
    prompt = sys.argv[1]
    output_file = sys.argv[2]
    
    success = generate_video(prompt, output_file)
    if not success:
        sys.exit(1)
