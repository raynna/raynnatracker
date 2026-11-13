"""Create an original, fully opaque paper material without atlas padding.

Only the Python standard library is required. No external artwork is sampled.
"""
import math
import random
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
size = 256
rng = random.Random(83147)
pixels = bytearray()
for y in range(size):
    for x in range(size):
        grain = rng.uniform(-8, 8)
        mottling = 5 * math.sin(x / 27 + math.sin(y / 33)) + 4 * math.cos(y / 19 + x / 39)
        fibers = 1.5 * math.sin(y * 2.3 + x / 21)
        variation = grain + mottling + fibers
        red, green, blue = [max(0, min(255, round(base + variation))) for base in (191, 153, 96)]
        pixels.extend((blue, green, red, 255))
header = struct.pack('<BBBHHBHHHHBB', 0, 0, 2, 0, 0, 0, 0, 0, size, size, 32, 0x28)
destination = ROOT / 'RaynnaTracker/Media/RaynnaParchment.tga'
destination.parent.mkdir(parents=True, exist_ok=True)
destination.write_bytes(header + pixels)
print('Generated opaque parchment:', destination)
