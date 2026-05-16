<div align="center">

# 🏋️ FitLife — AI Fitness Coach

### *Train Smarter. Eat Better. Live Stronger.*

**Your personal AI-powered fitness coach, available 24/7**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![React](https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB)](https://reactjs.org)
[![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)

</div>

---

## 📖 Overview

**FitLife** is a cross-platform AI-powered fitness application available on both **web and mobile**. It provides personalized workout plans, daily nutrition tracking, real-time progress analytics, and smart reminders — all tailored to your fitness goals and available equipment.

Whether you're training at a full gym, at home with dumbbells, or with no equipment at all, FitLife adapts to you.

---

## ✨ Features

### 🚀 Onboarding
- 3-step personalized setup — gender, age, weight, height
- Fitness goal selection (Build Muscle, Lose Fat, Stay Active)
- Equipment selection — Full Gym, Home with Dumbbells, or No Equipment

### 🏠 Dashboard
- Personalized greeting with daily fitness overview
- Live stats — Weight, Height, Age, Daily Calories, BMI, Workouts done
- Today's Workout snapshot with sets, reps, and rest times
- Today's Meals with calorie breakdown per meal

### 💪 Workouts
- Full exercise library — browse by muscle group (Chest, Back, Shoulders, Legs, Arms, Core)
- Beginner / Intermediate / Advanced difficulty levels
- Tiered access — Beginner free, Member & Pro locked content
- Search exercises by name or muscle group

### 🥗 Diet Plan (Nutrition)
- Daily meal plan — Breakfast, Lunch, Snack, Dinner
- Calorie and protein tracking per meal
- Full food library with Member & Pro tier access
- Daily calorie goal vs consumed progress

### 📊 Progress
- Weekly workout bar chart
- Muscle focus donut chart (by percentage)
- Calories This Week tracker
- Body Metrics — current weight & BMI
- Log today's weight directly from the dashboard

### 🔔 Reminders
- Workout and meal reminders
- Customizable notification schedules

### 👤 Profile & Achievements
- Achievement badges — First Workout, Hydration Hero, Iron Will, and more
- Weekly workout streak tracker
- Average calories display
- Account settings and appearance preferences

### 🔐 Authentication
- Email & password login
- Continue with Google
- Guest mode — browse without signing up
- Secure JWT-based session management

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter · Dart · Provider / GetX |
| Web Frontend | React.js · Vite · Tailwind CSS |
| Backend | Node.js · Express.js · REST API |
| Database | Supabase (PostgreSQL) |
| Auth | JWT · Google OAuth |
| Hosting | Railway (backend) · Vercel (web) |

---

## 📱 Platforms

| Platform | Status |
|----------|--------|
| 🌐 Web | ✅ Live |
| 📱 Android | ✅ Available |
| 🍎 iOS | ✅ Available |

---

## 🎯 Membership Tiers

| Feature | Free | Member | Pro |
|---------|------|--------|-----|
| Beginner Exercises | ✅ | ✅ | ✅ |
| Intermediate Exercises | ❌ | ✅ | ✅ |
| Advanced Exercises | ❌ | ❌ | ✅ |
| Basic Meal Plans | ✅ | ✅ | ✅ |
| Full Meal Library | ❌ | ✅ | ✅ |
| Progress Analytics | ✅ | ✅ | ✅ |
| Priority Support | ❌ | ❌ | ✅ |

---

## 🗂️ Project Structure

```
fitlife/
├── mobile/                        # Flutter App
│   ├── lib/
│   │   ├── screens/
│   │   │   ├── onboarding/        # 3-step user setup
│   │   │   ├── dashboard/         # Home overview
│   │   │   ├── workouts/          # Exercise library
│   │   │   ├── diet/              # Nutrition & meal plans
│   │   │   ├── progress/          # Analytics & charts
│   │   │   ├── reminders/         # Notification management
│   │   │   └── profile/           # User profile & achievements
│   │   ├── models/
│   │   ├── providers/             # State management
│   │   └── services/              # API & auth services
│   └── pubspec.yaml
│
├── web/                           # React Web App
│   ├── src/
│   │   ├── pages/
│   │   │   ├── Login.jsx
│   │   │   ├── Signup.jsx
│   │   │   ├── Dashboard.jsx
│   │   │   ├── Workouts.jsx
│   │   │   ├── Diet.jsx
│   │   │   ├── Progress.jsx
│   │   │   └── Profile.jsx
│   │   └── App.jsx
│   └── package.json
│
└── backend/                       # Node.js API
    ├── routes/
    │   ├── authRoutes.js
    │   ├── workoutRoutes.js
    │   ├── dietRoutes.js
    │   └── progressRoutes.js
    ├── controllers/
    ├── middleware/
    │   └── authMiddleware.js
    └── server.js
```

---

## ⚙️ Local Setup

### Prerequisites
- Node.js v18+
- Flutter SDK
- Supabase account

### Backend
```bash
cd backend
npm install
# Create .env with:
# SUPABASE_URL=your_url
# SUPABASE_SERVICE_KEY=your_key
# JWT_SECRET=your_secret
npm run dev
# Runs on http://localhost:5000
```

### Web
```bash
cd web
npm install
# Create .env with:
# VITE_API_URL=http://localhost:5000
npm run dev
# Runs on http://localhost:5173
```

### Mobile
```bash
cd mobile
flutter pub get
# Update lib/services/api_service.dart with your backend URL
flutter run
```

---

## 🚀 Deployment

| Service | Platform |
|---------|----------|
| Backend | Railway |
| Web Frontend | Vercel |
| Database | Supabase (PostgreSQL) |

---

## 👨‍💻 Author

**Ahmad Abdullah**
- GitHub: [@AAbdullahRajput](https://github.com/AAbdullahRajput)
- Email: ahmadabdullah4972@gmail.com

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

<div align="center">

*Built with 💚 by Ahmad Abdullah*

</div>
