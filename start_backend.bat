@echo off
cd /d "s:\Project\intenship\Full Track AI\backend"
echo Starting Backend Server on 0.0.0.0:8000...
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
pause
