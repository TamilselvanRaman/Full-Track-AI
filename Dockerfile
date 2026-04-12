# This is a wrapper Dockerfile for Render to find the backend
FROM python:3.10-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the backend folder contents
COPY backend/requirements-cloud.txt .
RUN pip install --no-cache-dir -r requirements-cloud.txt

COPY backend/ .

# Run the backend
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "10000"]
