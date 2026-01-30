#!/usr/bin/env python3
import os
import sys
from huggingface_hub import InferenceClient

# Using a popular model supported by Inference API. 
# Zeroscope is a good text-to-video candidate.
MODEL_ID = "damo-vilab/text-to-video-ms-1.7b"

def get_hf_token():
    token = os.getenv("HF_TOKEN")
    if not token:
        print("[generate_ai_video_hf] Error: HF_TOKEN environment variable not set.")
        sys.exit(1)
    return token

def generate_video(prompt, output_file):
    token = get_hf_token()
    
    print(f"[generate_ai_video_hf] Initializing InferenceClient for {MODEL_ID}...")
    client = InferenceClient(model=MODEL_ID, token=token)
    
    print(f"[generate_ai_video_hf] Generating video for prompt: '{prompt}'")
    
    try:
        # text_to_video is the method for video generation
        # It returns bytes of the video file
        video_bytes = client.text_to_video(prompt)
        
        with open(output_file, "wb") as f:
            f.write(video_bytes)
            
        print(f"[generate_ai_video_hf] Video saved successfully to: {output_file}")
        return True
        
    except StopIteration:
        print("[generate_ai_video_hf] Error: No free inference provider found for this model.")
        print("[generate_ai_video_hf] This usually means the model is too heavy for the free tier.")
        return False
    except Exception as e:
        print(f"[generate_ai_video_hf] Generation failed: {e}")
        # Print detailed traceback if available
        # import traceback
        # traceback.print_exc()
        return False

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: generate_ai_video_hf.py <prompt> <output_mp4>")
        sys.exit(1)
        
    prompt = sys.argv[1]
    output_file = sys.argv[2]
    
    success = generate_video(prompt, output_file)
    if not success:
        sys.exit(1)
