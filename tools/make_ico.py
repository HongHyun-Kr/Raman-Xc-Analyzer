"""mac/icon_1024.png -> win/icon.ico   (needs: pip install pillow)"""
from PIL import Image
im = Image.open("mac/icon_1024.png").convert("RGBA")
im.save("win/icon.ico", sizes=[(s, s) for s in (16, 24, 32, 48, 64, 128, 256)])
print("win/icon.ico written")
