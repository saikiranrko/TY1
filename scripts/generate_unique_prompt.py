#!/usr/bin/env python3
import random
import json
import sys

def generate_prompt():
    themes = [
        "Thunderstorm with Heavy Rain", "Soft Forest Rain", "Rain on a Window", 
        "Rumbling Thunder in Clouds", "Windy Rain", "Rainy City Night",
        "Crackling Log Fire", "Rustic Fireplace", "Cozy Hearth",
        "Gentle Ocean Waves", "Stormy Sea at Night", "Deep Sea Rhythms",
        "Deep Forest Birds", "Morning Birdsong", "Summer Night Crickets",
        "Howling Wind in Pine Trees", "Breezy Mountain Peak"
    ]
    locations = [
        "in a dense dark forest", "outside a secluded cozy cabin", "near a jagged mountain cliff",
        "on a desolate beach", "down a neon city street", "over a quiet medieval village",
        "inside a dimly lit library", "within a foggy valley"
    ]
    times = ["at the stroke of midnight", "during a golden dawn", "under a brilliant full moon", "in the absolute pitch black", "at a rainy twilight"]
    adjectives = ["unsettling", "therapeutic", "haunting", "majestic", "eerie", "harmonious", "gritty"]

    theme = random.choice(themes)
    location = random.choice(locations)
    time = random.choice(times)
    adj = random.choice(adjectives)

    prompt = f"A {adj} {theme} {location} {time}, high quality, realistic, cinematic lighting."
    
    # Map to existing ffmpeg themes
    ffmpeg_theme = "rain" # Default
    if "Wind" in theme or "Breezy" in theme:
        ffmpeg_theme = "wind"
    elif "Fireplace" in theme or "Hearth" in theme or "Fire" in theme:
        ffmpeg_theme = "fireplace"
    elif "Ocean" in theme or "Sea" in theme:
        ffmpeg_theme = "ocean"
    elif "Bird" in theme or "Crickets" in theme or "Forest" in theme:
        # If it's forest and not rain
        if "Rain" not in theme:
            ffmpeg_theme = "forest"
    
    params = {
        "prompt": prompt,
        "ffmpeg_theme": ffmpeg_theme,
        "rain_intensity": round(random.uniform(0.1, 0.4), 2),
        "wind_speed": round(random.uniform(0.05, 0.2), 2),
        "color_shift": random.choice(["#1a2a3a", "#2a1a3a", "#1a3a2a", "#3a3a3a"]),
        "random_seed": random.randint(0, 10000)
    }
    
    return params

if __name__ == "__main__":
    data = generate_prompt()
    print(f"export GENERATED_PROMPT='{data['prompt']}'")
    print(f"export COMPUTED_THEME='{data['ffmpeg_theme']}'")
    print(f"export RAIN_INTENSITY='{data['rain_intensity']}'")
    print(f"export WIND_SPEED='{data['wind_speed']}'")
    print(f"export COLOR_SHIFT='{data['color_shift']}'")
    print(f"export PROMPT_SEED='{data['random_seed']}'")
