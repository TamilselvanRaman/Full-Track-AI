# Scalable AI-Powered Full-Stack System

## Overview
This is a production-ready, scalable, real-time full-stack system designed for high performance and maintainability. It features a FastAPI backend with PostgreSQL and Redis, and a React Native (Expo) mobile application.

## Technology Stack

### Backend
- **Language:** Python 3.11+
- **Framework:** FastAPI
- **Database:** PostgreSQL (Async)
- **Authentication:** JWT (OAuth2)
- **Real-time:** WebSockets
- **Deployment:** Docker & Docker Compose

### Mobile App
- **Framework:** React Native (Expo)
- **State Management:** Zustand
- **Navigation:** React Navigation
- **UI:** React Native Paper
- **API:** Axios

## Getting Started

### Prerequisites
- Docker & Docker Compose
- Node.js & npm
- generic application on iOS/Android (Expo Go) or Emulator

### 1. Start the Backend
```bash
docker-compose up -d --build
```
The API will be available at `http://localhost:8000`.
Documentation: `http://localhost:8000/docs`.

### 2. Start the Mobile App
```bash
cd mobile-app
npm install
npx expo start
```
- Scan the QR code with Expo Go (Android/iOS).
- Use `admin@example.com` / `password123` to login (if you created this user) or Register a new account.

## Features
- **Secure Auth:** Login, Register, JWT handling.
- **Video Analysis:** Record video, upload, and view trajectory results.
- **Real-time Dashboard:** WebSocket integration for live updates.
