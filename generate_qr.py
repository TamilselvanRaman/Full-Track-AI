
import qrcode
import sys

url = "exp://10.179.24.76:8081"
img = qrcode.make(url)
img.save("mobile-qr.png")
print(f"QR code generated for {url}")
