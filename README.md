# SkillSwap 🔄
### A Peer-to-Peer Skill Exchange System

> **Learn by teaching. Grow by sharing.** SkillSwap connects students across India to exchange skills — teach what you know, learn what you want, completely free.

---

## 👥 Team

| Name | Enrollment |
|------|-----------|
| Jigyasa Srivastava | 2401030380 |
| Riddhima Bhatnagar | 2401030378 |
| Rajan Palta | 2401030383 |

**Batch:** B16, B.Tech. CSE — Jaypee Institute of Information Technology  
**Subject:** Database Management System (PBL)

---

## 📌 Project Overview

SkillSwap is a **barter-based learning platform** where users exchange skills instead of money. A user who knows Python teaches it to someone in exchange for learning Graphic Design from them — no fees, no hierarchy, just peer-to-peer knowledge sharing.

The project demonstrates a **complete database-backed system** using MySQL, covering:
- Normalized relational schema design
- Complex SQL queries (joins, subqueries, aggregations)
- Stored procedures, user-defined functions, cursors, triggers
- A REST API backend (Node.js + Express)
- A responsive frontend web interface (HTML/CSS/JS)

---

## 🗂️ Repository Structure

```
skillswap/
│
├── database/
│   └── skillswap_complete.sql     ← Full DB schema + seed data + procedures/triggers
│
├── backend/
│   ├── server.js                  ← Node.js + Express REST API
│   ├── package.json
│   └── .env.example               ← Environment variable template
│
├── frontend/
│   └── index.html                 ← Single-file React-style frontend (no build needed)
│
└── README.md
```

---

## 🗄️ Database Schema

### Tables (11 total)

| Table | Description |
|-------|-------------|
| `users` | Student profiles (name, email, college, location) |
| `skills` | Skill catalogue with categories |
| `user_skills` | Maps users to skills with role (teach/learn) and proficiency |
| `availability` | Time slots when users are free |
| `sessions` | Scheduled skill exchange sessions |
| `feedback` | Ratings and comments between users |
| `notifications` | System-generated alerts |
| `matches` | Match scores between learner-teacher pairs |
| `user_stats` | Aggregated stats per user (new) |
| `skill_requests` | Pending/accepted/declined match requests (new) |
| `admin_logs` | Audit trail for critical actions (new) |

### Entity Relationship Overview

```
users ──< user_skills >── skills
users ──< availability
users ──< sessions (as teacher)
users ──< sessions (as learner)
sessions ──< feedback
users ──< notifications
users ──< matches (as requester/candidate)
users ──< skill_requests
users ──  user_stats
sessions ──> admin_logs (via trigger)
```

### Views (6)

| View | Purpose |
|------|---------|
| `vw_session_details` | Full session info with names and duration |
| `vw_user_leaderboard` | Users ranked by average rating |
| `vw_popular_skills` | Skills ranked by learner demand |
| `vw_pending_requests` | Open skill exchange requests |
| `vw_unread_notifications` | Unread alerts with user info |
| `vw_skill_discovery` | Skill marketplace cards with teacher, learner, and community counts |

---

## ⚙️ SQL Features Implemented

### Stored Procedures (8)
- `count_completed_sessions(uid)` — Count completed sessions for a user
- `get_user_sessions(uid)` — All sessions with other party and skill
- `get_best_matches(uid)` — Top match candidates for a user
- `get_all_users()` — List all registered users
- `register_user(...)` — Register new user + initialise stats
- `book_session(...)` — Book a new session
- `get_user_dashboard(uid)` — Sessions, skills, and rating summary
- `search_users_by_skill(skill, role)` — Find teachers/learners by skill

### User-Defined Functions (7)
- `get_full_name(uid)` — Returns full name for a user ID
- `total_completed_sessions(uid)` — Count of completed sessions
- `avg_user_rating(uid)` — Average rating received
- `count_teaching_skills(uid)` — Number of skills being taught
- `best_match_score(uid)` — Highest match score for a requester
- `is_user_available(uid, date)` — Returns YES/NO for availability
- `get_session_duration(sid)` — Duration of a session in minutes

### Cursors (6)
- `cursor_list_users()` — Iterates and prints all usernames
- `cursor_user_sessions()` — Session count per user
- `cursor_avg_rating()` — Average rating per user
- `cursor_skill_learners()` — Learner count per skill
- `cursor_best_match()` — Best match score per requester
- `cursor_refresh_user_stats()` — Refreshes the `user_stats` table for all users

### Triggers (15)
| # | Trigger | Event | Purpose |
|---|---------|-------|---------|
| 1 | `trg_session_created` | AFTER INSERT on sessions | Notify teacher & learner |
| 2 | `trg_session_rescheduled` | AFTER UPDATE on sessions | Notify learner on reschedule |
| 3 | `trg_session_cancelled` | AFTER UPDATE on sessions | Notify teacher on cancel |
| 4 | `trg_feedback_submitted` | AFTER INSERT on feedback | Notify feedback receiver |
| 5 | `trg_feedback_rating_check` | BEFORE INSERT on feedback | Validate rating 1–5 |
| 6 | `trg_no_teacher_overlap` | BEFORE INSERT on sessions | Prevent double-booking (teacher) |
| 7 | `trg_no_learner_overlap` | BEFORE INSERT on sessions | Prevent double-booking (learner) |
| 8 | `trg_check_availability_time` | BEFORE INSERT on availability | Validate time range |
| 9 | `trg_availability_added` | AFTER INSERT on availability | Notify user |
| 10 | `trg_no_duplicate_feedback` | BEFORE INSERT on feedback | Prevent duplicate review |
| 11 | `trg_update_match_score` | AFTER INSERT on feedback | Auto-update match score |
| 12 | `trg_notify_teacher_feedback` | AFTER INSERT on feedback | Notify teacher |
| 13 | `trg_log_session_delete` | BEFORE DELETE on sessions | Log to admin_logs |
| 14 | `trg_auto_score` | BEFORE INSERT on matches | Auto-generate score if missing |
| 15 | `trg_update_stats_on_complete` | AFTER UPDATE on sessions | Update user_stats |

---

## 🚀 Setup & Installation

### Prerequisites
- MySQL 8.0+
- Node.js 18+ (for backend)
- Any modern browser (for frontend)

### Step 1 — Database Setup

```bash
# Log into MySQL
mysql -u root -p

# Run the complete SQL file
source /path/to/skillswap_complete.sql;
```

Or import via MySQL Workbench:
`File → Run SQL Script → select skillswap_complete.sql`

### Step 2 — Backend Setup (optional, for live API)

```bash
cd backend
npm install

# Copy env file and add your credentials
cp .env.example .env
# Edit .env with your DB credentials

npm run dev
# API runs at http://localhost:5000
```

### Step 3 — Frontend

No build step needed. Just open:

```bash
# Option A: Open directly
open frontend/index.html

# Option B: Serve locally
npx serve frontend/
```

---

## 🌐 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/users` | All users |
| GET | `/api/users/:id` | Single user |
| GET | `/api/users/:id/dashboard` | User dashboard stats |
| POST | `/api/users` | Register a new user |
| GET | `/api/skills` | All skills (filter by `?category=`) |
| GET | `/api/skills/popular` | Popular skills from view |
| GET | `/api/skills/discover` | Search/filter skills by `q`, `category`, `role`, and `sort` |
| GET | `/api/sessions` | All sessions (filter by `?status=`) |
| GET | `/api/users/:id/sessions` | Sessions for a user |
| POST | `/api/sessions` | Book a new session |
| PATCH | `/api/sessions/:id/status` | Update session status |
| GET | `/api/feedback` | All feedback with names |
| POST | `/api/feedback` | Submit feedback |
| GET | `/api/users/:id/notifications` | Notifications for a user |
| PATCH | `/api/notifications/:id/read` | Mark notification as read |
| GET | `/api/users/:id/matches` | Match suggestions for a user |
| GET | `/api/leaderboard` | Top users by rating |
| GET | `/api/stats` | Global platform statistics |
| GET | `/api/requests` | Pending skill requests |
| POST | `/api/requests` | Send a skill request |
| PATCH | `/api/requests/:id` | Accept/decline request |

---

## 📊 Sample Data Summary

| Entity | Count |
|--------|-------|
| Users | 50 |
| Skills | 25 |
| User-Skill mappings | 40 |
| Availability slots | 50 |
| Sessions | 20 |
| Feedback entries | 12 |
| Notifications | 20 |
| Match records | 25 |
| Skill requests | 8 |

---

## 🛠️ Technologies Used

| Layer | Technology |
|-------|-----------|
| Database | MySQL 8.0 |
| Query Tool | MySQL Workbench / CLI |
| Backend | Node.js, Express.js |
| DB Driver | mysql2 |
| Frontend | HTML5, CSS3, Vanilla JS |
| Fonts | Google Fonts (Syne + DM Sans) |
| Version Control | Git + GitHub |

---

## 🔮 Future Scope

- **Authentication** — JWT-based login/signup with bcrypt password hashing
- **Real-time Chat** — Socket.io for in-app messaging between matched users
- **AI Matching** — ML-based skill compatibility scoring
- **Mobile App** — React Native version for iOS and Android
- **Gamification** — Badges, XP points, streak tracking
- **Calendar Integration** — Session scheduling with Google Calendar sync
- **Verified Profiles** — College email verification via OTP

---

## 📄 References

- [MySQL Official Documentation](https://dev.mysql.com/doc/)
- [W3Schools SQL Tutorial](https://www.w3schools.com/sql/)
- [Express.js Documentation](https://expressjs.com/)
- [TutorialsPoint SQL](https://www.tutorialspoint.com/sql/)

---

<div align="center">
  Made with ❤️ at JIIT · B16 Batch · DBMS PBL 2024–25
</div>
