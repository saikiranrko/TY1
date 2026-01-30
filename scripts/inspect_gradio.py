#!/usr/bin/env python3
import sys
from gradio_client import Client

SPACE_ID = "ByteDance/AnimateDiff-Lightning"

def inspect_space():
    try:
        print(f"Inspecting Space: {SPACE_ID}")
        client = Client(SPACE_ID)
        client.view_api()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    inspect_space()
