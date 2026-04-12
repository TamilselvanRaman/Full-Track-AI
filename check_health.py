
import requests
try:
    response = requests.get('http://10.179.24.76:8000/health', timeout=2)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.json()}")
except Exception as e:
    print(f"Error: {e}")
