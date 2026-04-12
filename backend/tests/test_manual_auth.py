import asyncio
import httpx

BASE_URL = "http://localhost:8000/api/v1"

async def test_auth():
    async with httpx.AsyncClient() as client:
        # 1. Register
        email = "test@example.com"
        password = "password123"
        print(f"Registering user {email}...")
        response = await client.post(f"{BASE_URL}/users/", json={
            "email": email,
            "password": password,
            "full_name": "Test User"
        })
        if response.status_code == 200:
            print("Registration successful:", response.json())
        elif response.status_code == 400 and "already exists" in response.text:
            print("User already exists, proceeding to login.")
        else:
            print("Registration failed:", response.status_code, response.text)
            return

        # 2. Login
        print("Logging in...")
        response = await client.post(f"{BASE_URL}/login/access-token", data={
            "username": email,
            "password": password
        })
        if response.status_code != 200:
            print("Login failed:", response.status_code, response.text)
            return
        
        token = response.json()
        print("Login successful. Token:", token)
        access_token = token["access_token"]

        # 3. Get Me
        print("Fetching current user profile...")
        response = await client.get(f"{BASE_URL}/users/me", headers={
            "Authorization": f"Bearer {access_token}"
        })
        if response.status_code == 200:
            print("Profile fetch successful:", response.json())
        else:
            print("Profile fetch failed:", response.status_code, response.text)

if __name__ == "__main__":
    asyncio.run(test_auth())
