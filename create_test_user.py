import httpx

API_URL = "http://localhost:8000/api/v1"

def create_test_user():
    user_data = {
        "email": "testuser@example.com",
        "password": "password123",
        "full_name": "Test User",
        "is_superuser": False
    }
    try:
        response = httpx.post(f"{API_URL}/users/", json=user_data)
        if response.status_code == 200:
            print("User created successfully!")
            print(f"Email: {user_data['email']}")
            print(f"Password: {user_data['password']}")
        elif response.status_code == 400 and "already exists" in response.text:
             print("User already exists.")
             print(f"Email: {user_data['email']}")
             print(f"Password: {user_data['password']}")
        else:
            print(f"Failed to create user. Status: {response.status_code}")
            print(response.text)
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    create_test_user()
