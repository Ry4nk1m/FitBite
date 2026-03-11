# FitBite

A calorie and macro tracking app built with **SwiftUI** (iOS) and **Flask** (Python backend).

## Project Structure

```
FitBite/
├── fitbite-backend/     # Flask API server
│   ├── app/
│   │   ├── models.py           # Database models
│   │   ├── routes_auth.py      # Auth (register/login)
│   │   ├── routes_diary.py     # Food diary CRUD
│   │   ├── routes_goals_foods.py  # Goals & food search
│   │   └── seed.py             # 50+ starter foods
│   ├── config.py
│   ├── run.py
│   └── requirements.txt
│
├── fitbite-ios/         # SwiftUI iOS app
│   ├── FitBiteApp.swift        # App entry point
│   ├── Services/
│   │   └── APIClient.swift     # Networking & auth
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift
│   │   ├── DiaryViewModel.swift
│   │   └── AnalyticsViewModel.swift
│   └── Views/
│       ├── AuthView.swift      # Login / Register
│       ├── MainTabView.swift   # Tab navigation
│       ├── DiaryView.swift     # Daily food diary
│       ├── AddFoodView.swift   # Search & add food
│       ├── AnalyticsView.swift # Weekly charts
│       └── SettingsView.swift  # Goals & logout
└── README.md

## Backend Setup

```bash
cd fitbite-backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
python run.py
```

Server runs at `http://localhost:5000`. Database auto-creates and seeds on first run.

## iOS Setup

1. Open Xcode → File → New → App (iOS, SwiftUI)
2. Name it "FitBite"
3. Delete default ContentView.swift and FitBiteApp.swift
4. Drag all files from `fitbite-ios/` into Xcode (Copy items + Create groups)
5. Set deployment target to iOS 17.0+
6. Run on simulator (⌘R)

**Note:** Flask server must be running for the app to work.

## Features

- Email authentication with JWT tokens
- Food diary with breakfast/lunch/dinner/snacks
- 50+ food database with search
- Custom food entry
- Daily calorie & macro goals
- Weekly analytics with charts
- Logging streak tracking

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/register` | POST | Create account |
| `/api/auth/login` | POST | Log in |
| `/api/auth/refresh` | POST | Refresh token |
| `/api/diary/entries` | GET/POST | Get/add food entries |
| `/api/diary/entries/:id` | PUT/DELETE | Edit/remove entry |
| `/api/diary/summary` | GET | Weekly stats |
| `/api/goals` | GET/PUT | Daily targets |
| `/api/foods/search` | GET | Search foods |
| `/api/foods/custom` | POST/DELETE | Custom foods |
