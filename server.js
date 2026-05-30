// ============================================================
// SkillSwap API Server - server.js
// ============================================================

const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// DB Connection Pool
const pool = mysql.createPool({
  host:     process.env.DB_HOST     || 'localhost',
  user:     process.env.DB_USER     || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME     || 'dbmsProject',
  waitForConnections: true,
  connectionLimit: 10,
});

// ─── USERS ───────────────────────────────────────────────────

// GET all users
app.get('/api/users', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM users ORDER BY user_id');
    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// GET single user
app.get('/api/users/:id', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM users WHERE user_id = ?', [req.params.id]);
    if (!rows.length) return res.status(404).json({ success: false, error: 'User not found' });
    res.json({ success: true, data: rows[0] });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// GET user dashboard summary
app.get('/api/users/:id/dashboard', async (req, res) => {
  try {
    const uid = req.params.id;
    const [[sessions]] = await pool.query(
      `SELECT
        COUNT(CASE WHEN status='completed'  THEN 1 END) AS completed,
        COUNT(CASE WHEN status='scheduled'  THEN 1 END) AS upcoming,
        COUNT(CASE WHEN status='cancelled'  THEN 1 END) AS cancelled
       FROM sessions WHERE teacher_id=? OR learner_id=?`, [uid, uid]
    );
    const [[skills]] = await pool.query(
      `SELECT
        COUNT(CASE WHEN role='teach' THEN 1 END) AS teaching,
        COUNT(CASE WHEN role='learn' THEN 1 END) AS learning
       FROM user_skills WHERE user_id=?`, [uid]
    );
    const [[rating]] = await pool.query(
      `SELECT ROUND(AVG(rating),2) AS avg_rating, COUNT(*) AS total_reviews
       FROM feedback WHERE to_user_id=?`, [uid]
    );
    const [notifications] = await pool.query(
      `SELECT COUNT(*) AS unread FROM notifications WHERE user_id=? AND is_read=0`, [uid]
    );
    res.json({ success: true, data: { sessions, skills, rating, unread: notifications[0].unread } });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// POST register user
app.post('/api/users', async (req, res) => {
  try {
    const { user_id, user_name, full_name, email, phone, location, college_name } = req.body;
    await pool.query(
      `INSERT INTO users (user_id,user_name,full_name,email,phone,location,college_name)
       VALUES (?,?,?,?,?,?,?)`,
      [user_id, user_name, full_name, email, phone, location, college_name]
    );
    await pool.query(`INSERT INTO user_stats (user_id) VALUES (?)`, [user_id]);
    res.status(201).json({ success: true, message: 'User registered successfully' });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── SKILLS ──────────────────────────────────────────────────

// GET all skills
app.get('/api/skills', async (req, res) => {
  try {
    const { category } = req.query;
    let query = 'SELECT * FROM skills';
    const params = [];
    if (category) { query += ' WHERE category = ?'; params.push(category); }
    query += ' ORDER BY skill_name';
    const [rows] = await pool.query(query, params);
    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// GET popular skills (view)
app.get('/api/skills/popular', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM vw_popular_skills LIMIT 10');
    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// GET skill discovery cards with demand/supply counts
app.get('/api/skills/discover', async (req, res) => {
  try {
    const { q, category, role, sort = 'popular' } = req.query;
    const filters = [];
    const params = [];

    if (q) {
      filters.push('(s.skill_name LIKE ? OR s.skill_describe LIKE ?)');
      params.push(`%${q}%`, `%${q}%`);
    }

    if (category) {
      filters.push('s.category = ?');
      params.push(category);
    }

    if (role === 'teach' || role === 'learn') {
      filters.push(`EXISTS (
        SELECT 1 FROM user_skills role_filter
        WHERE role_filter.skill_id = s.skill_id AND role_filter.role = ?
      )`);
      params.push(role);
    }

    const orderBy = {
      popular: 'learners DESC, teachers DESC, s.skill_name ASC',
      supply: 'teachers DESC, learners DESC, s.skill_name ASC',
      newest: 's.skill_id DESC',
      name: 's.skill_name ASC',
    }[sort] || 'learners DESC, teachers DESC, s.skill_name ASC';

    const [rows] = await pool.query(
      `SELECT
         s.skill_id,
         s.skill_name,
         s.skill_describe,
         s.category,
         COUNT(CASE WHEN us.role = 'teach' THEN 1 END) AS teachers,
         COUNT(CASE WHEN us.role = 'learn' THEN 1 END) AS learners,
         COUNT(us.user_skill_id) AS community_count
       FROM skills s
       LEFT JOIN user_skills us ON s.skill_id = us.skill_id
       ${filters.length ? `WHERE ${filters.join(' AND ')}` : ''}
       GROUP BY s.skill_id, s.skill_name, s.skill_describe, s.category
       ORDER BY ${orderBy}`,
      params
    );

    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// GET users for a skill by role
app.get('/api/skills/:id/users', async (req, res) => {
  try {
    const { role } = req.query;
    let query = `SELECT u.user_id, u.full_name, u.college_name, us.role, us.proficiency
                 FROM users u JOIN user_skills us ON u.user_id=us.user_id
                 WHERE us.skill_id=?`;
    const params = [req.params.id];
    if (role) { query += ' AND us.role=?'; params.push(role); }
    const [rows] = await pool.query(query, params);
    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── SESSIONS ────────────────────────────────────────────────

// GET all sessions (with names)
app.get('/api/sessions', async (req, res) => {
  try {
    const { status } = req.query;
    let query = `SELECT s.session_id, u1.full_name AS teacher, u2.full_name AS learner,
                        sk.skill_name, sk.category, s.scheduled_start, s.scheduled_end, s.status
                 FROM sessions s
                 JOIN users u1  ON s.teacher_id = u1.user_id
                 JOIN users u2  ON s.learner_id = u2.user_id
                 JOIN skills sk ON s.skill_id   = sk.skill_id`;
    const params = [];
    if (status) { query += ' WHERE s.status=?'; params.push(status); }
    query += ' ORDER BY s.scheduled_start DESC';
    const [rows] = await pool.query(query, params);
    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// GET sessions for a specific user
app.get('/api/users/:id/sessions', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT s.session_id, u1.full_name AS teacher, u2.full_name AS learner,
              sk.skill_name, s.scheduled_start, s.scheduled_end, s.status
       FROM sessions s
       JOIN users u1  ON s.teacher_id = u1.user_id
       JOIN users u2  ON s.learner_id = u2.user_id
       JOIN skills sk ON s.skill_id   = sk.skill_id
       WHERE s.teacher_id=? OR s.learner_id=?
       ORDER BY s.scheduled_start DESC`, [req.params.id, req.params.id]
    );
    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// POST book a session
app.post('/api/sessions', async (req, res) => {
  try {
    const { session_id, teacher_id, learner_id, skill_id, scheduled_start, scheduled_end } = req.body;
    await pool.query(
      `INSERT INTO sessions (session_id,teacher_id,learner_id,skill_id,scheduled_start,scheduled_end,status)
       VALUES (?,?,?,?,?,?,'scheduled')`,
      [session_id, teacher_id, learner_id, skill_id, scheduled_start, scheduled_end]
    );
    res.status(201).json({ success: true, message: 'Session booked successfully' });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// PATCH update session status
app.patch('/api/sessions/:id/status', async (req, res) => {
  try {
    const { status } = req.body;
    await pool.query('UPDATE sessions SET status=? WHERE session_id=?', [status, req.params.id]);
    res.json({ success: true, message: 'Session status updated' });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── FEEDBACK ────────────────────────────────────────────────

// GET all feedback with names
app.get('/api/feedback', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT f.feedback_id, u1.full_name AS from_user, u2.full_name AS to_user,
              f.rating, f.comments, f.created_at
       FROM feedback f
       JOIN users u1 ON f.from_user_id = u1.user_id
       JOIN users u2 ON f.to_user_id   = u2.user_id
       ORDER BY f.created_at DESC`
    );
    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// POST submit feedback
app.post('/api/feedback', async (req, res) => {
  try {
    const { feedback_id, session_id, from_user_id, to_user_id, rating, comments } = req.body;
    await pool.query(
      `INSERT INTO feedback (feedback_id,session_id,from_user_id,to_user_id,rating,comments)
       VALUES (?,?,?,?,?,?)`,
      [feedback_id, session_id, from_user_id, to_user_id, rating, comments]
    );
    res.status(201).json({ success: true, message: 'Feedback submitted successfully' });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── NOTIFICATIONS ───────────────────────────────────────────

// GET notifications for a user
app.get('/api/users/:id/notifications', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT * FROM notifications WHERE user_id=? ORDER BY created_at DESC`, [req.params.id]
    );
    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// PATCH mark notification as read
app.patch('/api/notifications/:id/read', async (req, res) => {
  try {
    await pool.query('UPDATE notifications SET is_read=1 WHERE notif_id=?', [req.params.id]);
    res.json({ success: true, message: 'Notification marked as read' });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── MATCHES ─────────────────────────────────────────────────

// GET matches for a user
app.get('/api/users/:id/matches', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT m.match_id, u2.full_name AS candidate, u2.college_name,
              sk.skill_name, sk.category, m.score
       FROM matches m
       JOIN users  u2 ON m.candidate_id = u2.user_id
       JOIN skills sk ON m.skill_id     = sk.skill_id
       WHERE m.requester_id=?
       ORDER BY m.score DESC`, [req.params.id]
    );
    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── LEADERBOARD ─────────────────────────────────────────────

app.get('/api/leaderboard', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM vw_user_leaderboard LIMIT 20');
    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── STATS ───────────────────────────────────────────────────

app.get('/api/stats', async (req, res) => {
  try {
    const [[users]]    = await pool.query('SELECT COUNT(*) AS total FROM users');
    const [[skills]]   = await pool.query('SELECT COUNT(*) AS total FROM skills');
    const [[sessions]] = await pool.query('SELECT COUNT(*) AS total FROM sessions');
    const [[feedback]] = await pool.query('SELECT ROUND(AVG(rating),2) AS avg FROM feedback');
    res.json({
      success: true,
      data: {
        total_users:    users.total,
        total_skills:   skills.total,
        total_sessions: sessions.total,
        avg_rating:     feedback.avg,
      }
    });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── SKILL REQUESTS ──────────────────────────────────────────

app.get('/api/requests', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM vw_pending_requests');
    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

app.post('/api/requests', async (req, res) => {
  try {
    const { from_user_id, to_user_id, skill_id, message } = req.body;
    await pool.query(
      `INSERT INTO skill_requests (from_user_id,to_user_id,skill_id,message)
       VALUES (?,?,?,?)`,
      [from_user_id, to_user_id, skill_id, message]
    );
    res.status(201).json({ success: true, message: 'Request sent successfully' });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

app.patch('/api/requests/:id', async (req, res) => {
  try {
    const { status } = req.body;
    await pool.query('UPDATE skill_requests SET status=? WHERE request_id=?', [status, req.params.id]);
    res.json({ success: true, message: `Request ${status}` });
  } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// ─── START ───────────────────────────────────────────────────

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`SkillSwap API running on port ${PORT}`));
