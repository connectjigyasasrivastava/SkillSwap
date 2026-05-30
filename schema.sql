-- ============================================================
-- SkillSwap: A Peer-to-Peer Skill Exchange System
-- DATABASE MANAGEMENT SYSTEM (PBL)
-- JIGYASA SRIVASTAVA | RIDDHIMA BHATNAGAR | RAJAN PALTA
-- Batch: B16, B.Tech. CSE
-- ============================================================


-- ============================================================
-- DATABASE CREATION
-- ============================================================

CREATE DATABASE IF NOT EXISTS dbmsProject;
USE dbmsProject;


-- ============================================================
-- TABLE CREATION
-- ============================================================

-- 1. USERS TABLE
CREATE TABLE users (
    user_id      INT PRIMARY KEY,
    user_name    VARCHAR(50) NOT NULL UNIQUE,
    full_name    VARCHAR(50),
    email        VARCHAR(50),
    phone        VARCHAR(10),
    location     VARCHAR(100),
    college_name VARCHAR(100),
    created_at   DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. SKILLS TABLE
CREATE TABLE skills (
    skill_id       INT PRIMARY KEY,
    skill_name     VARCHAR(100) NOT NULL UNIQUE,
    skill_describe TEXT,
    category       VARCHAR(50)
);

-- 3. USER_SKILLS TABLE
CREATE TABLE user_skills (
    user_skill_id INT PRIMARY KEY,
    user_id       INT,
    skill_id      INT,
    role          ENUM('teach','learn') NOT NULL,
    proficiency   ENUM('beginner','intermediate','advanced') DEFAULT 'beginner',
    FOREIGN KEY (user_id)  REFERENCES users(user_id)  ON DELETE CASCADE,
    FOREIGN KEY (skill_id) REFERENCES skills(skill_id) ON DELETE CASCADE,
    UNIQUE (user_id, skill_id, role)
);

-- 4. AVAILABILITY TABLE
CREATE TABLE availability (
    avail_id    INT PRIMARY KEY,
    user_id     INT NOT NULL,
    date_avail  DATE,
    start_time  TIME NOT NULL,
    end_time    TIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- 5. SESSIONS TABLE
CREATE TABLE sessions (
    session_id       INT PRIMARY KEY,
    teacher_id       INT NOT NULL,
    learner_id       INT NOT NULL,
    skill_id         INT NOT NULL,
    scheduled_start  DATETIME NOT NULL,
    scheduled_end    DATETIME NOT NULL,
    status           ENUM('scheduled','completed','cancelled','rescheduled') DEFAULT 'scheduled',
    created_at       DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_updated     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_teacher FOREIGN KEY (teacher_id) REFERENCES users(user_id)  ON DELETE CASCADE,
    CONSTRAINT fk_learner FOREIGN KEY (learner_id) REFERENCES users(user_id)  ON DELETE CASCADE,
    CONSTRAINT fk_skill   FOREIGN KEY (skill_id)   REFERENCES skills(skill_id) ON DELETE CASCADE,
    CHECK (scheduled_end > scheduled_start),
    INDEX idx_session_time  (scheduled_start, scheduled_end),
    INDEX idx_teacher_time  (teacher_id, scheduled_start, scheduled_end)
);

-- 6. FEEDBACK TABLE
CREATE TABLE feedback (
    feedback_id  INT PRIMARY KEY,
    session_id   INT NOT NULL,
    from_user_id INT NOT NULL,
    to_user_id   INT NOT NULL,
    rating       INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comments     TEXT,
    created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id)   REFERENCES sessions(session_id) ON DELETE CASCADE,
    FOREIGN KEY (from_user_id) REFERENCES users(user_id),
    FOREIGN KEY (to_user_id)   REFERENCES users(user_id)
);

-- 7. NOTIFICATIONS TABLE
CREATE TABLE notifications (
    notif_id   INT PRIMARY KEY AUTO_INCREMENT,
    user_id    INT NOT NULL,
    message    TEXT NOT NULL,
    is_read    TINYINT(1) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- 8. MATCHES TABLE
CREATE TABLE matches (
    match_id      INT PRIMARY KEY,
    requester_id  INT NOT NULL,
    candidate_id  INT NOT NULL,
    skill_id      INT NOT NULL,
    score         DECIMAL(5,2) DEFAULT 0,
    UNIQUE (requester_id, candidate_id, skill_id),
    FOREIGN KEY (requester_id) REFERENCES users(user_id)  ON DELETE CASCADE,
    FOREIGN KEY (candidate_id) REFERENCES users(user_id)  ON DELETE CASCADE,
    FOREIGN KEY (skill_id)     REFERENCES skills(skill_id) ON DELETE CASCADE
);

-- 9. USER_STATS TABLE (new — tracks aggregate stats per user)
CREATE TABLE user_stats (
    user_id          INT PRIMARY KEY,
    total_taught     INT DEFAULT 0,
    total_learned    INT DEFAULT 0,
    avg_rating       DECIMAL(5,2) DEFAULT 0.00,
    total_feedback   INT DEFAULT 0,
    last_active      DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- 10. SKILL_REQUESTS TABLE (new — pending match requests between users)
CREATE TABLE skill_requests (
    request_id    INT PRIMARY KEY AUTO_INCREMENT,
    from_user_id  INT NOT NULL,
    to_user_id    INT NOT NULL,
    skill_id      INT NOT NULL,
    message       TEXT,
    status        ENUM('pending','accepted','declined') DEFAULT 'pending',
    created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (to_user_id)   REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (skill_id)     REFERENCES skills(skill_id) ON DELETE CASCADE
);

-- 11. ADMIN_LOGS TABLE (new — audit trail for important actions)
CREATE TABLE admin_logs (
    log_id      INT PRIMARY KEY AUTO_INCREMENT,
    action_type VARCHAR(50) NOT NULL,
    table_name  VARCHAR(50) NOT NULL,
    record_id   INT,
    description TEXT,
    logged_at   DATETIME DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================
-- INDEXES & ALTERATIONS
-- ============================================================

CREATE INDEX idx_user_college_name ON users(college_name);
CREATE INDEX idx_skill_id          ON skills(skill_id);
CREATE INDEX idx_avail_user        ON availability(user_id);
CREATE INDEX idx_session_status    ON sessions(status);
CREATE INDEX idx_feedback_to_user  ON feedback(to_user_id);
CREATE INDEX idx_notif_user        ON notifications(user_id);

-- Update skill categories
UPDATE skills SET category = 'Technology'  WHERE skill_id IN (101,102,104,107,109,111,112,118,119,120);
UPDATE skills SET category = 'Creative'    WHERE skill_id IN (105,108,115,116,125);
UPDATE skills SET category = 'Business'    WHERE skill_id IN (103,106,113,114,117,122,124);
UPDATE skills SET category = 'Lifestyle'   WHERE skill_id IN (121,123);
UPDATE skills SET category = 'Design'      WHERE skill_id IN (110);


-- ============================================================
-- INSERTION
-- ============================================================

-- Users (50 records)
INSERT INTO users (user_id, user_name, full_name, email, phone, location, college_name) VALUES
(1,  'arjun_iyer',       'Arjun Iyer',       'arjun.iyer@iitm.ac.in',            '9876543210', 'chennai',   'iit madras'),
(2,  'priya_reddy',      'Priya Reddy',       'priya.reddy@iitm.ac.in',           '9876543211', 'chennai',   'iit madras'),
(3,  'rahul_verma',      'Rahul Verma',       'rahul.verma@iitd.ac.in',           '9876543212', 'new delhi', 'iit delhi'),
(4,  'aisha_khan',       'Aisha Khan',        'aisha.khan@iitd.ac.in',            '9876543213', 'new delhi', 'iit delhi'),
(5,  'rohan_mehta',      'Rohan Mehta',       'rohan.mehta@bits-pilani.ac.in',    '9876543214', 'pilani',    'bits pilani'),
(6,  'neha_sharma',      'Neha Sharma',       'neha.sharma@bits-pilani.ac.in',    '9876543215', 'pilani',    'bits pilani'),
(7,  'aditya_patel',     'Aditya Patel',      'aditya.patel@iitb.ac.in',         '9876543216', 'mumbai',    'iit bombay'),
(8,  'kavya_nair',       'Kavya Nair',        'kavya.nair@iitb.ac.in',           '9876543217', 'mumbai',    'iit bombay'),
(9,  'amit_singh',       'Amit Singh',        'amit.singh@jiit.ac.in',           '9876543218', 'noida',     'jiit-62'),
(10, 'riya_gupta',       'Riya Gupta',        'riya.gupta@jiit.ac.in',           '9876543219', 'noida',     'jiit-62'),
(11, 'tanmay_shukla',    'Tanmay Shukla',     'tanmay.shukla@jiit.ac.in',        '9876543220', 'noida',     'jiit-128'),
(12, 'isha_agarwal',     'Isha Agarwal',      'isha.agarwal@jiit.ac.in',         '9876543221', 'noida',     'jiit-128'),
(13, 'siddharth_jain',   'Siddharth Jain',    'siddharth.jain@thapar.edu',       '9876543222', 'patiala',   'thapar'),
(14, 'simran_bhalla',    'Simran Bhalla',     'simran.bhalla@thapar.edu',        '9876543223', 'patiala',   'thapar'),
(15, 'karan_malhotra',   'Karan Malhotra',    'karan.malhotra@du.ac.in',         '9876543224', 'new delhi', 'du'),
(16, 'megha_bansal',     'Megha Bansal',      'megha.bansal@du.ac.in',           '9876543225', 'new delhi', 'du'),
(17, 'vishal_shetty',    'Vishal Shetty',     'vishal.shetty@vit.ac.in',         '9876543226', 'vellore',   'vit'),
(18, 'ananya_menon',     'Ananya Menon',      'ananya.menon@vit.ac.in',          '9876543227', 'vellore',   'vit'),
(19, 'sourabh_raj',      'Sourabh Raj',       'sourabh.raj@nitw.ac.in',          '9876543228', 'marangal',  'nit'),
(20, 'tanya_kapoor',     'Tanya Kapoor',      'tanya.kapoor@nitw.ac.in',         '9876543229', 'marangal',  'nit'),
(21, 'manish_pandey',    'Manish Pandey',     'manish.pandey@mnnit.ac.in',       '9876543230', 'allahabad', 'mnnit'),
(22, 'sakshi_mishra',    'Sakshi Mishra',     'sakshi.mishra@mnnit.ac.in',       '9876543231', 'allahabad', 'mnnit'),
(23, 'deepak_yadav',     'Deepak Yadav',      'deepak.yadav@iiitd.ac.in',        '9876543232', 'delhi',     'iiit'),
(24, 'shruti_rajput',    'Shruti Rajput',     'shruti.rajput@iiitd.ac.in',       '9876543233', 'delhi',     'iiit'),
(25, 'naman_bhargava',   'Naman Bhargava',    'naman.bhargava@iitk.ac.in',       '9876543234', 'kanpur',    'iit kanpur'),
(26, 'pooja_tiwari',     'Pooja Tiwari',      'pooja.tiwari@iitk.ac.in',         '9876543235', 'kanpur',    'iit kanpur'),
(27, 'harshita_rana',    'Harshita Rana',     'harshita.rana@iitkgp.ac.in',      '9876543236', 'kolkata',   'iit kharagpur'),
(28, 'rajat_das',        'Rajat Das',         'rajat.das@iitkgp.ac.in',          '9876543237', 'kolkata',   'iit kharagpur'),
(29, 'alok_sen',         'Alok Sen',          'alok.sen@iitg.ac.in',             '9876543238', 'guwahati',  'iit guwahati'),
(30, 'riya_dutta',       'Riya Dutta',        'riya.dutta@iitg.ac.in',           '9876543239', 'guwahati',  'iit guwahati'),
(31, 'rakesh_kumar',     'Rakesh Kumar',      'rakesh.kumar@nitk.ac.in',         '9876543240', 'surathkal', 'nit'),
(32, 'shreya_pillai',    'Shreya Pillai',     'shreya.pillai@nitk.ac.in',        '9876543241', 'surathkal', 'nit'),
(33, 'devansh_arora',    'Devansh Arora',     'devansh.arora@iitroorkee.ac.in',  '9876543242', 'roorkee',   'iit roorkee'),
(34, 'tanya_joseph',     'Tanya Joseph',      'tanya.joseph@iitroorkee.ac.in',   '9876543243', 'roorkee',   'iit roorkee'),
(35, 'abhishek_rout',    'Abhishek Rout',     'abhishek.rout@iiith.ac.in',       '9876543244', 'hyderabad', 'iiit'),
(36, 'divya_reddy',      'Divya Reddy',       'divya.reddy@iiith.ac.in',         '9876543245', 'hyderabad', 'iiit'),
(37, 'vivek_naidu',      'Vivek Naidu',       'vivek.naidu@vit.ac.in',           '9876543246', 'vellore',   'vit'),
(38, 'aarushi_kaur',     'Aarushi Kaur',      'aarushi.kaur@vit.ac.in',          '9876543247', 'vellore',   'vit'),
(39, 'sandeep_patel',    'Sandeep Patel',     'sandeep.patel@mnnit.ac.in',       '9876543248', 'allahabad', 'mnnit'),
(40, 'nikita_jain',      'Nikita Jain',       'nikita.jain@mnnit.ac.in',         '9876543249', 'allahabad', 'mnnit'),
(41, 'rishabh_saxena',   'Rishabh Saxena',    'rishabh.saxena@jiit.ac.in',       '9876543250', 'noida',     'jiit-62'),
(42, 'anushka_goyal',    'Anushka Goyal',     'anushka.goyal@jiit.ac.in',        '9876543251', 'noida',     'jiit-62'),
(43, 'ujjwal_chowdhury', 'Ujjwal Chowdhury',  'ujjwal.chowdhury@jiit.ac.in',     '9876543252', 'noida',     'jiit-128'),
(44, 'nandini_arora',    'Nandini Arora',     'nandini.arora@jiit.ac.in',        '9876543253', 'noida',     'jiit-128'),
(45, 'rajiv_reddy',      'Rajiv Reddy',       'rajiv.reddy@thapar.edu',          '9876543254', 'patiala',   'thapar'),
(46, 'meera_sodhi',      'Meera Sodhi',       'meera.sodhi@thapar.edu',          '9876543255', 'patiala',   'thapar'),
(47, 'kunal_nayak',      'Kunal Nayak',       'kunal.nayak@du.ac.in',            '9876543256', 'new delhi', 'du'),
(48, 'shweta_pandey',    'Shweta Pandey',     'shweta.pandey@du.ac.in',          '9876543257', 'new delhi', 'du'),
(49, 'rahul_iyer',       'Rahul Iyer',        'rahul.iyer@iitb.ac.in',           '9876543258', 'mumbai',    'iit bombay'),
(50, 'isha_singla',      'Isha Singla',       'isha.singla@iitb.ac.in',          '9876543259', 'mumbai',    'iit bombay');

-- Seed user_stats for all 50 users
INSERT INTO user_stats (user_id) SELECT user_id FROM users;

-- Skills (25 records)
INSERT INTO skills (skill_id, skill_name, skill_describe, category) VALUES
(101, 'python programming',          'learn to code in python from basics to advanced with projects.',                   'Technology'),
(102, 'data analysis',               'analyze datasets using excel, sql, and python for insights.',                      'Technology'),
(103, 'public speaking',             'build confidence and communication skills for effective speaking.',                'Business'),
(104, 'machine learning',            'understand ml algorithms and build predictive models.',                            'Technology'),
(105, 'graphic design',              'create visuals using adobe photoshop, illustrator, and canva.',                    'Creative'),
(106, 'digital marketing',           'learn seo, social media, and content marketing strategies.',                       'Business'),
(107, 'web development',             'develop responsive websites using html, css, and javascript.',                     'Technology'),
(108, 'content writing',             'write engaging and seo-friendly blogs, articles, and posts.',                      'Creative'),
(109, 'video editing',               'edit videos using premiere pro and capcut for social media.',                      'Creative'),
(110, 'ui/ux design',                'design user-friendly interfaces and wireframes using figma.',                      'Design'),
(111, 'android development',         'build mobile apps using kotlin and android studio.',                               'Technology'),
(112, 'data visualization',          'create dashboards using tableau, power bi, and matplotlib.',                       'Technology'),
(113, 'english communication',       'improve spoken and written english for work and more.',                            'Business'),
(114, 'leadership skills',           'learn to lead teams, manage conflicts, and delegate tasks.',                       'Business'),
(115, 'creative writing',            'develop storytelling, poetry, and narrative writing skills.',                      'Creative'),
(116, 'photography',                 'capture portraits and landscapes using dslr and smartphone.',                      'Creative'),
(117, 'financial literacy',          'learn personal finance, budgeting, and investment basics.',                        'Business'),
(118, 'java programming',            'understand object-oriented concepts using java.',                                   'Technology'),
(119, 'sql and databases',           'design and query relational databases like mysql and postgresql.',                 'Technology'),
(120, 'cybersecurity basics',        'learn ethical hacking and protection against digital threats.',                    'Technology'),
(121, 'yoga and meditation',         'practice yoga asanas and mindfulness for focus and health.',                       'Lifestyle'),
(122, 'entrepreneurship',            'understand how to start and scale a business or startup.',                         'Business'),
(123, 'foreign language - french',   'learn basic french for conversation and travel.',                                  'Lifestyle'),
(124, 'event management',            'plan and organize college and cultural events effectively.',                        'Business'),
(125, 'social media content creation','create instagram reels and youtube videos that engage audiences.',                'Creative');

-- User Skills (40 records)
INSERT INTO user_skills (user_skill_id, user_id, skill_id, role, proficiency) VALUES
(201, 1,  101, 'teach', 'advanced'),
(202, 1,  104, 'teach', 'advanced'),
(203, 2,  101, 'learn', 'beginner'),
(204, 2,  103, 'learn', 'intermediate'),
(205, 3,  102, 'teach', 'advanced'),
(206, 3,  104, 'teach', 'intermediate'),
(207, 4,  101, 'learn', 'beginner'),
(208, 4,  105, 'learn', 'beginner'),
(209, 5,  106, 'teach', 'advanced'),
(210, 5,  107, 'teach', 'intermediate'),
(211, 6,  107, 'learn', 'beginner'),
(212, 6,  109, 'learn', 'intermediate'),
(213, 7,  110, 'teach', 'advanced'),
(214, 7,  102, 'teach', 'advanced'),
(215, 8,  101, 'learn', 'intermediate'),
(216, 8,  111, 'learn', 'intermediate'),
(217, 9,  112, 'teach', 'advanced'),
(218, 9,  113, 'teach', 'intermediate'),
(219, 10, 114, 'learn', 'beginner'),
(220, 10, 115, 'learn', 'intermediate'),
(221, 11, 116, 'teach', 'advanced'),
(222, 11, 117, 'teach', 'intermediate'),
(223, 12, 118, 'learn', 'beginner'),
(224, 12, 119, 'learn', 'intermediate'),
(225, 13, 120, 'teach', 'advanced'),
(226, 13, 121, 'teach', 'advanced'),
(227, 14, 122, 'learn', 'beginner'),
(228, 14, 123, 'learn', 'intermediate'),
(229, 15, 124, 'teach', 'advanced'),
(230, 15, 125, 'teach', 'intermediate'),
(231, 16, 101, 'learn', 'beginner'),
(232, 16, 107, 'learn', 'intermediate'),
(233, 17, 104, 'teach', 'advanced'),
(234, 17, 105, 'teach', 'intermediate'),
(235, 18, 109, 'learn', 'beginner'),
(236, 18, 110, 'learn', 'intermediate'),
(237, 19, 111, 'teach', 'advanced'),
(238, 19, 112, 'teach', 'intermediate'),
(239, 20, 113, 'learn', 'beginner'),
(240, 20, 114, 'learn', 'beginner');

-- Availability (50 records)
INSERT INTO availability (avail_id, user_id, date_avail, start_time, end_time) VALUES
(301, 1,  '2025-11-12', '09:00:00', '11:00:00'),
(302, 2,  '2025-11-12', '10:00:00', '12:00:00'),
(303, 3,  '2025-11-12', '11:00:00', '13:00:00'),
(304, 4,  '2025-11-12', '14:00:00', '16:00:00'),
(305, 5,  '2025-11-13', '09:00:00', '11:00:00'),
(306, 6,  '2025-11-13', '11:00:00', '13:00:00'),
(307, 7,  '2025-11-13', '15:00:00', '17:00:00'),
(308, 8,  '2025-11-13', '16:00:00', '18:00:00'),
(309, 9,  '2025-11-14', '09:30:00', '11:30:00'),
(310, 10, '2025-11-14', '10:30:00', '12:30:00'),
(311, 11, '2025-11-14', '14:00:00', '16:00:00'),
(312, 12, '2025-11-14', '15:00:00', '17:00:00'),
(313, 13, '2025-11-15', '08:00:00', '10:00:00'),
(314, 14, '2025-11-15', '09:00:00', '11:00:00'),
(315, 15, '2025-11-15', '11:00:00', '13:00:00'),
(316, 16, '2025-11-15', '13:00:00', '15:00:00'),
(317, 17, '2025-11-16', '09:30:00', '11:30:00'),
(318, 18, '2025-11-16', '11:00:00', '13:00:00'),
(319, 19, '2025-11-16', '14:00:00', '16:00:00'),
(320, 20, '2025-11-16', '16:00:00', '18:00:00'),
(321, 21, '2025-11-17', '09:30:00', '11:30:00'),
(322, 22, '2025-11-17', '10:30:00', '12:30:00'),
(323, 23, '2025-11-17', '13:00:00', '15:00:00'),
(324, 24, '2025-11-17', '15:00:00', '17:00:00'),
(325, 25, '2025-11-18', '09:00:00', '11:00:00'),
(326, 26, '2025-11-18', '11:00:00', '13:00:00'),
(327, 27, '2025-11-18', '13:00:00', '15:00:00'),
(328, 28, '2025-11-18', '15:00:00', '17:00:00'),
(329, 29, '2025-11-19', '09:00:00', '11:00:00'),
(330, 30, '2025-11-19', '10:30:00', '12:30:00'),
(331, 31, '2025-11-19', '14:00:00', '16:00:00'),
(332, 32, '2025-11-19', '16:00:00', '18:00:00'),
(333, 33, '2025-11-20', '08:00:00', '10:00:00'),
(334, 34, '2025-11-20', '09:30:00', '11:30:00'),
(335, 35, '2025-11-20', '12:00:00', '14:00:00'),
(336, 36, '2025-11-20', '14:30:00', '16:30:00'),
(337, 37, '2025-11-21', '09:00:00', '11:00:00'),
(338, 38, '2025-11-21', '11:00:00', '13:00:00'),
(339, 39, '2025-11-21', '13:00:00', '15:00:00'),
(340, 40, '2025-11-21', '15:00:00', '17:00:00'),
(341, 41, '2025-11-22', '09:30:00', '11:30:00'),
(342, 42, '2025-11-22', '11:30:00', '13:30:00'),
(343, 43, '2025-11-22', '14:00:00', '16:00:00'),
(344, 44, '2025-11-22', '16:00:00', '18:00:00'),
(345, 45, '2025-11-23', '08:00:00', '10:00:00'),
(346, 46, '2025-11-23', '10:00:00', '12:00:00'),
(347, 47, '2025-11-23', '13:00:00', '15:00:00'),
(348, 48, '2025-11-23', '15:00:00', '17:00:00'),
(349, 49, '2025-11-24', '09:00:00', '11:00:00'),
(350, 50, '2025-11-24', '11:00:00', '13:00:00');

-- Sessions (20 records)
INSERT INTO sessions (session_id, teacher_id, learner_id, skill_id, scheduled_start, scheduled_end, status) VALUES
(401, 1,  2,  101, '2025-11-12 10:30:00', '2025-11-12 11:30:00', 'completed'),
(402, 3,  4,  104, '2025-11-13 15:30:00', '2025-11-13 16:30:00', 'completed'),
(403, 5,  6,  105, '2025-11-14 09:30:00', '2025-11-14 10:30:00', 'completed'),
(404, 7,  8,  106, '2025-11-15 16:30:00', '2025-11-15 17:30:00', 'scheduled'),
(405, 9,  10, 107, '2025-11-14 10:30:00', '2025-11-14 11:30:00', 'completed'),
(406, 11, 12, 108, '2025-11-14 15:30:00', '2025-11-14 16:30:00', 'completed'),
(407, 13, 14, 109, '2025-11-15 09:30:00', '2025-11-15 10:30:00', 'scheduled'),
(408, 15, 16, 110, '2025-11-13 13:30:00', '2025-11-13 14:30:00', 'scheduled'),
(409, 17, 18, 111, '2025-11-16 10:30:00', '2025-11-16 11:30:00', 'scheduled'),
(410, 19, 20, 112, '2025-11-16 14:30:00', '2025-11-16 15:30:00', 'completed'),
(411, 21, 22, 113, '2025-11-17 10:30:00', '2025-11-17 11:30:00', 'scheduled'),
(412, 23, 24, 114, '2025-11-17 15:30:00', '2025-11-17 16:30:00', 'scheduled'),
(413, 25, 26, 115, '2025-11-18 09:30:00', '2025-11-18 10:30:00', 'completed'),
(414, 27, 28, 118, '2025-11-18 14:30:00', '2025-11-18 15:30:00', 'scheduled'),
(415, 29, 30, 117, '2025-11-19 09:30:00', '2025-11-19 10:30:00', 'cancelled'),
(416, 31, 32, 118, '2025-11-19 15:30:00', '2025-11-19 16:30:00', 'completed'),
(417, 33, 34, 119, '2025-11-20 09:30:00', '2025-11-20 10:30:00', 'completed'),
(418, 35, 36, 120, '2025-11-20 13:30:00', '2025-11-20 14:30:00', 'rescheduled'),
(419, 37, 38, 121, '2025-11-21 11:30:00', '2025-11-21 12:30:00', 'scheduled'),
(420, 39, 40, 122, '2025-11-21 15:30:00', '2025-11-21 16:30:00', 'completed');

-- Feedback (12 records)
INSERT INTO feedback (feedback_id, session_id, from_user_id, to_user_id, rating, comments) VALUES
(501, 401, 2,  1,  5, 'arjun explained python basics very clearly. great session!'),
(502, 402, 3,  4,  4, 'aisha was great at explaining machine learning models.'),
(503, 403, 6,  5,  5, 'rohans graphic design session was really creative and fun.'),
(504, 405, 10, 9,  4, 'learned new web tricks from rahul. well prepared!'),
(505, 406, 12, 11, 5, 'nehas session on data analysis was excellent.'),
(506, 408, 16, 15, 5, 'rohit made c++ dsa concepts so easy to understand.'),
(507, 410, 20, 19, 4, 'good session on creative writing by manisha. could be longer.'),
(508, 412, 24, 23, 5, 'ravis public speaking workshop was inspiring!'),
(509, 413, 26, 25, 5, 'learnt a lot about python basics. awesome teaching!'),
(510, 416, 32, 31, 4, 'informative sql session by anjali. clear examples.'),
(511, 417, 34, 33, 5, 'krishna was fantastic at explaining leadership principles.'),
(512, 420, 40, 39, 5, 'deepaks photography session was insightful and hands-on.');

-- Notifications (20 records)
INSERT INTO notifications (notif_id, user_id, message, is_read) VALUES
(601, 2,  'your python session with arjun iyer has been completed.', 1),
(602, 3,  'machine learning session with aisha khan completed successfully.', 1),
(603, 6,  'graphic design session with rohan mehta completed successfully.', 1),
(604, 8,  'your c++ session with aditya patel is scheduled for 15th nov 2025.', 0),
(605, 10, 'web development session with rahul verma completed successfully.', 1),
(606, 12, 'data analysis session with neha sharma completed successfully.', 1),
(607, 14, 'public speaking session with kavya nair scheduled for 15th nov 2025.', 0),
(608, 16, 'your c++ dsa session with rohit singh completed successfully.', 1),
(609, 18, 'digital marketing session with sneha joshi is scheduled tomorrow.', 0),
(610, 20, 'creative writing session with manisha das completed successfully.', 1),
(611, 22, 'leadership workshop with vivek kumar scheduled for 17th nov 2025.', 0),
(612, 24, 'public speaking session with ravi rao completed successfully.', 1),
(613, 26, 'python basics session with arjun iyer completed successfully.', 1),
(614, 28, 'web design session with kavita singh rescheduled to 18th nov.', 0),
(615, 30, 'data visualization session with amit patel cancelled.', 1),
(616, 32, 'sql and database design session with anjali sharma completed.', 1),
(617, 34, 'leadership principles workshop with krishna reddy completed.', 1),
(618, 36, 'communication skills session with meena kumari rescheduled.', 0),
(619, 38, 'career guidance session with arnav bansal scheduled for 21st nov.', 0),
(620, 40, 'photography session with deepak sharma completed successfully.', 1);

-- Matches (25 records)
INSERT INTO matches (match_id, requester_id, candidate_id, skill_id, score) VALUES
(701, 2,  1,  101, 92.50),
(702, 3,  4,  104, 88.00),
(703, 6,  5,  105, 95.00),
(704, 8,  7,  106, 89.50),
(705, 10, 9,  107, 90.00),
(706, 12, 11, 108, 91.50),
(707, 14, 13, 109, 93.00),
(708, 16, 15, 110, 85.50),
(709, 18, 17, 111, 87.00),
(710, 20, 19, 112, 94.50),
(711, 22, 21, 113, 89.00),
(712, 24, 23, 114, 92.00),
(713, 26, 25, 115, 95.50),
(714, 28, 27, 116, 84.50),
(715, 30, 29, 117, 88.50),
(716, 32, 31, 118, 91.00),
(717, 34, 33, 119, 90.50),
(718, 36, 35, 120, 86.50),
(719, 38, 37, 121, 93.50),
(720, 40, 39, 122, 94.00),
(721, 42, 41, 123, 89.00),
(722, 44, 43, 124, 92.00),
(723, 46, 45, 125, 88.50),
(724, 48, 47, 101, 91.50),
(725, 50, 49, 102, 90.00);

-- Skill Requests (sample)
INSERT INTO skill_requests (from_user_id, to_user_id, skill_id, message, status) VALUES
(2,  1,  101, 'Hi! I would love to learn python from you. Available on weekends.', 'accepted'),
(4,  3,  104, 'Can you teach me machine learning? I am a beginner.', 'accepted'),
(6,  5,  105, 'I want to learn graphic design for my college projects.', 'accepted'),
(8,  7,  106, 'Interested in learning digital marketing strategies.', 'pending'),
(10, 9,  107, 'Would love to learn web development from you.', 'pending'),
(12, 11, 108, 'Need help with content writing for my blog.', 'pending'),
(14, 13, 109, 'Can I learn video editing from you?', 'declined'),
(16, 15, 110, 'I am interested in ui/ux design. Can you help?', 'pending');


-- ============================================================
-- VIEWS
-- ============================================================

-- View 1: Full session details
CREATE VIEW vw_session_details AS
SELECT
    s.session_id,
    u1.full_name  AS teacher_name,
    u2.full_name  AS learner_name,
    sk.skill_name,
    sk.category,
    s.scheduled_start,
    s.scheduled_end,
    s.status,
    TIMESTAMPDIFF(MINUTE, s.scheduled_start, s.scheduled_end) AS duration_minutes
FROM sessions s
JOIN users  u1 ON s.teacher_id = u1.user_id
JOIN users  u2 ON s.learner_id = u2.user_id
JOIN skills sk ON s.skill_id   = sk.skill_id;

-- View 2: User leaderboard by average rating
CREATE VIEW vw_user_leaderboard AS
SELECT
    u.user_id,
    u.full_name,
    u.college_name,
    ROUND(AVG(f.rating), 2)  AS avg_rating,
    COUNT(f.feedback_id)     AS total_reviews,
    COUNT(DISTINCT s.session_id) AS sessions_taught
FROM users u
LEFT JOIN feedback f ON f.to_user_id = u.user_id
LEFT JOIN sessions s ON s.teacher_id = u.user_id AND s.status = 'completed'
GROUP BY u.user_id, u.full_name, u.college_name
ORDER BY avg_rating DESC;

-- View 3: Popular skills
CREATE VIEW vw_popular_skills AS
SELECT
    sk.skill_id,
    sk.skill_name,
    sk.category,
    COUNT(CASE WHEN us.role = 'learn' THEN 1 END) AS learner_count,
    COUNT(CASE WHEN us.role = 'teach' THEN 1 END) AS teacher_count,
    COUNT(s.session_id) AS total_sessions
FROM skills sk
LEFT JOIN user_skills us ON us.skill_id  = sk.skill_id
LEFT JOIN sessions    s  ON s.skill_id   = sk.skill_id
GROUP BY sk.skill_id, sk.skill_name, sk.category
ORDER BY learner_count DESC;

-- View 4: Pending skill requests with user details
CREATE VIEW vw_pending_requests AS
SELECT
    sr.request_id,
    u1.full_name    AS requester_name,
    u1.college_name AS requester_college,
    u2.full_name    AS target_name,
    sk.skill_name,
    sr.message,
    sr.created_at
FROM skill_requests sr
JOIN users  u1 ON sr.from_user_id = u1.user_id
JOIN users  u2 ON sr.to_user_id   = u2.user_id
JOIN skills sk ON sr.skill_id     = sk.skill_id
WHERE sr.status = 'pending';

-- View 5: Unread notifications with user info
CREATE VIEW vw_unread_notifications AS
SELECT
    n.notif_id,
    u.full_name,
    u.email,
    n.message,
    n.created_at
FROM notifications n
JOIN users u ON n.user_id = u.user_id
WHERE n.is_read = 0
ORDER BY n.created_at DESC;

-- View 6: Skill discovery marketplace cards
CREATE VIEW vw_skill_discovery AS
SELECT
    sk.skill_id,
    sk.skill_name,
    sk.skill_describe,
    sk.category,
    COUNT(CASE WHEN us.role = 'teach' THEN 1 END) AS teacher_count,
    COUNT(CASE WHEN us.role = 'learn' THEN 1 END) AS learner_count,
    COUNT(us.user_skill_id) AS community_count
FROM skills sk
LEFT JOIN user_skills us ON us.skill_id = sk.skill_id
GROUP BY sk.skill_id, sk.skill_name, sk.skill_describe, sk.category
ORDER BY learner_count DESC, teacher_count DESC, sk.skill_name;


-- ============================================================
-- QUERIES - LEVEL 01
-- ============================================================

-- Completed sessions
SELECT * FROM sessions WHERE status = 'completed';

-- Unread notifications
SELECT * FROM notifications WHERE is_read = 0;

-- Users currently teaching
SELECT * FROM user_skills WHERE role = 'teach';

-- Users available on a specific date
SELECT user_id FROM availability WHERE date_avail = '2025-11-14';

-- All user skills ordered by skill_id descending
SELECT * FROM user_skills ORDER BY skill_id DESC;


-- ============================================================
-- QUERIES - LEVEL 02 (Aggregation)
-- ============================================================

-- Total users
SELECT COUNT(*) AS total_users FROM users;

-- Total skills
SELECT COUNT(*) AS total_skills FROM skills;

-- Average rating across all feedback
SELECT ROUND(AVG(rating), 2) AS avg_rating FROM feedback;

-- Sessions grouped by status
SELECT status, COUNT(*) AS total FROM sessions GROUP BY status;

-- Top 5 matches by score
SELECT * FROM matches ORDER BY score DESC LIMIT 5;

-- Distinct users who gave feedback
SELECT DISTINCT from_user_id FROM feedback;

-- Distinct users who received feedback
SELECT DISTINCT to_user_id FROM feedback;

-- Notification count per user
SELECT user_id, COUNT(*) AS notif_count FROM notifications GROUP BY user_id;

-- Users available per date
SELECT date_avail, COUNT(user_id) AS total_users FROM availability GROUP BY date_avail;

-- Earliest session
SELECT MIN(scheduled_start) AS first_session FROM sessions;

-- Skills by category count
SELECT category, COUNT(*) AS skill_count FROM skills GROUP BY category ORDER BY skill_count DESC;

-- Colleges with most users
SELECT college_name, COUNT(*) AS student_count FROM users GROUP BY college_name ORDER BY student_count DESC LIMIT 5;


-- ============================================================
-- JOINS
-- ============================================================

-- Feedback with full names of sender and receiver
SELECT f.feedback_id, u1.full_name AS from_user, u2.full_name AS to_user, f.rating, f.comments
FROM feedback f
JOIN users u1 ON f.from_user_id = u1.user_id
JOIN users u2 ON f.to_user_id   = u2.user_id;

-- Sessions with teacher, learner and skill names
SELECT s.session_id, u1.full_name AS teacher, u2.full_name AS learner, sk.skill_name, s.status
FROM sessions s
JOIN users  u1 ON s.teacher_id = u1.user_id
JOIN users  u2 ON s.learner_id = u2.user_id
JOIN skills sk ON s.skill_id   = sk.skill_id;

-- User skills with skill names
SELECT us.user_id, u.full_name, sk.skill_name, us.role, us.proficiency
FROM user_skills us
JOIN users  u  ON us.user_id  = u.user_id
JOIN skills sk ON us.skill_id = sk.skill_id;

-- Notifications with user full names
SELECT n.notif_id, u.full_name, n.message, n.is_read, n.created_at
FROM notifications n
JOIN users u ON n.user_id = u.user_id;

-- Matches with requester, candidate and skill names
SELECT m.match_id, u1.full_name AS requester, u2.full_name AS candidate, sk.skill_name, m.score
FROM matches m
JOIN users  u1 ON m.requester_id = u1.user_id
JOIN users  u2 ON m.candidate_id = u2.user_id
JOIN skills sk ON m.skill_id     = sk.skill_id;

-- Users grouped by college
SELECT college_name, GROUP_CONCAT(full_name SEPARATOR ', ') AS students
FROM users GROUP BY college_name;

-- Top 3 most active users (combined teacher + learner sessions)
SELECT user_id, COUNT(*) AS total_sessions
FROM (
    SELECT teacher_id AS user_id FROM sessions
    UNION ALL
    SELECT learner_id AS user_id FROM sessions
) AS all_sessions
GROUP BY user_id
ORDER BY total_sessions DESC
LIMIT 3;

-- Skill requests with full details
SELECT sr.request_id, u1.full_name AS from_user, u2.full_name AS to_user,
       sk.skill_name, sr.message, sr.status
FROM skill_requests sr
JOIN users  u1 ON sr.from_user_id = u1.user_id
JOIN users  u2 ON sr.to_user_id   = u2.user_id
JOIN skills sk ON sr.skill_id     = sk.skill_id;


-- ============================================================
-- SUBQUERIES
-- ============================================================

-- Teachers with completed sessions
SELECT DISTINCT teacher_id FROM sessions WHERE status = 'completed';

-- Users with no notifications
SELECT user_id FROM users
WHERE user_id NOT IN (SELECT user_id FROM notifications);

-- Top rated user (by average feedback received)
SELECT to_user_id, ROUND(AVG(rating), 2) AS avg_rating
FROM feedback GROUP BY to_user_id ORDER BY avg_rating DESC LIMIT 1;

-- Skills with more than 3 learners
SELECT skill_id, COUNT(user_id) AS learners
FROM user_skills WHERE role = 'learn'
GROUP BY skill_id HAVING COUNT(user_id) > 3;

-- Teaching skills count per user
SELECT user_id, COUNT(skill_id) AS total_skills
FROM user_skills WHERE role = 'teach' GROUP BY user_id;

-- Feedback received per user
SELECT to_user_id, COUNT(*) AS feedback_received
FROM feedback GROUP BY to_user_id;

-- Teacher count per skill
SELECT skill_id, COUNT(*) AS teachers
FROM user_skills WHERE role = 'teach' GROUP BY skill_id;

-- Users who have both taught and learned
SELECT DISTINCT us1.user_id
FROM user_skills us1
WHERE us1.role = 'teach'
  AND us1.user_id IN (SELECT us2.user_id FROM user_skills us2 WHERE us2.role = 'learn');

-- Sessions longer than 60 minutes
SELECT * FROM sessions
WHERE TIMESTAMPDIFF(MINUTE, scheduled_start, scheduled_end) > 60;


-- ============================================================
-- STORED PROCEDURES
-- ============================================================

DELIMITER $$

-- 1. Count completed sessions for a user
CREATE PROCEDURE count_completed_sessions(IN uid INT)
BEGIN
    SELECT COUNT(*) AS total_completed
    FROM sessions
    WHERE status = 'completed'
      AND (teacher_id = uid OR learner_id = uid);
END $$

-- 2. Get all sessions for a user with skill and other person
CREATE PROCEDURE get_user_sessions(IN uid INT)
BEGIN
    SELECT s.session_id, s.status, sk.skill_name, u2.user_name AS other_person
    FROM sessions s
    JOIN skills sk ON s.skill_id = sk.skill_id
    JOIN users u2 ON (
        CASE WHEN s.teacher_id = uid THEN s.learner_id ELSE s.teacher_id END
    ) = u2.user_id
    WHERE s.teacher_id = uid OR s.learner_id = uid;
END $$

-- 3. Get best matches for a user
CREATE PROCEDURE get_best_matches(IN uid INT)
BEGIN
    SELECT m.match_id, u2.user_name AS candidate, sk.skill_name, m.score
    FROM matches m
    JOIN users  u2 ON m.candidate_id = u2.user_id
    JOIN skills sk ON m.skill_id     = sk.skill_id
    WHERE m.requester_id = uid
    ORDER BY m.score DESC;
END $$

-- 4. Get all users
CREATE PROCEDURE get_all_users()
BEGIN
    SELECT user_id, user_name, full_name, email, college_name FROM users;
END $$

-- 5. Register a new user (NEW)
CREATE PROCEDURE register_user(
    IN p_user_id      INT,
    IN p_user_name    VARCHAR(50),
    IN p_full_name    VARCHAR(50),
    IN p_email        VARCHAR(50),
    IN p_phone        VARCHAR(10),
    IN p_location     VARCHAR(100),
    IN p_college_name VARCHAR(100)
)
BEGIN
    INSERT INTO users (user_id, user_name, full_name, email, phone, location, college_name)
    VALUES (p_user_id, p_user_name, p_full_name, p_email, p_phone, p_location, p_college_name);
    INSERT INTO user_stats (user_id) VALUES (p_user_id);
    SELECT 'User registered successfully' AS result;
END $$

-- 6. Book a session (NEW)
CREATE PROCEDURE book_session(
    IN p_session_id      INT,
    IN p_teacher_id      INT,
    IN p_learner_id      INT,
    IN p_skill_id        INT,
    IN p_scheduled_start DATETIME,
    IN p_scheduled_end   DATETIME
)
BEGIN
    INSERT INTO sessions (session_id, teacher_id, learner_id, skill_id, scheduled_start, scheduled_end, status)
    VALUES (p_session_id, p_teacher_id, p_learner_id, p_skill_id, p_scheduled_start, p_scheduled_end, 'scheduled');
    SELECT 'Session booked successfully' AS result;
END $$

-- 7. Get dashboard summary for a user (NEW)
CREATE PROCEDURE get_user_dashboard(IN uid INT)
BEGIN
    -- Sessions summary
    SELECT
        COUNT(CASE WHEN status = 'completed' THEN 1 END)  AS completed,
        COUNT(CASE WHEN status = 'scheduled' THEN 1 END)  AS upcoming,
        COUNT(CASE WHEN status = 'cancelled' THEN 1 END)  AS cancelled
    FROM sessions
    WHERE teacher_id = uid OR learner_id = uid;

    -- Skills summary
    SELECT
        COUNT(CASE WHEN role = 'teach' THEN 1 END) AS skills_teaching,
        COUNT(CASE WHEN role = 'learn' THEN 1 END) AS skills_learning
    FROM user_skills WHERE user_id = uid;

    -- Average rating
    SELECT ROUND(AVG(rating), 2) AS avg_rating,
           COUNT(*)              AS total_reviews
    FROM feedback WHERE to_user_id = uid;
END $$

-- 8. Search users by skill (NEW)
CREATE PROCEDURE search_users_by_skill(IN skill_name_param VARCHAR(100), IN role_param VARCHAR(10))
BEGIN
    SELECT u.user_id, u.full_name, u.college_name, us.proficiency
    FROM users u
    JOIN user_skills us ON u.user_id  = us.user_id
    JOIN skills sk      ON us.skill_id = sk.skill_id
    WHERE sk.skill_name LIKE CONCAT('%', skill_name_param, '%')
      AND us.role = role_param
    ORDER BY us.proficiency DESC;
END $$

DELIMITER ;

-- Sample calls
CALL count_completed_sessions(3);
CALL get_user_sessions(5);
CALL get_best_matches(8);
CALL get_all_users();
CALL get_user_dashboard(1);
CALL search_users_by_skill('python', 'teach');


-- ============================================================
-- FUNCTIONS
-- ============================================================

DELIMITER $$

-- 1. Get full name by user id
CREATE FUNCTION get_full_name(uid INT)
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    DECLARE fname VARCHAR(100);
    SELECT full_name INTO fname FROM users WHERE user_id = uid;
    RETURN fname;
END $$

-- 2. Count total completed sessions for a user
CREATE FUNCTION total_completed_sessions(uid INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total INT DEFAULT 0;
    SELECT COUNT(*) INTO total FROM sessions
    WHERE status = 'completed' AND (teacher_id = uid OR learner_id = uid);
    RETURN total;
END $$

-- 3. Get average rating for a user
CREATE FUNCTION avg_user_rating(uid INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE avg_rate DECIMAL(5,2);
    SELECT ROUND(AVG(rating), 2) INTO avg_rate FROM feedback WHERE to_user_id = uid;
    RETURN avg_rate;
END $$

-- 4. Count how many skills a user teaches
CREATE FUNCTION count_teaching_skills(uid INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total INT DEFAULT 0;
    SELECT COUNT(*) INTO total FROM user_skills WHERE user_id = uid AND role = 'teach';
    RETURN total;
END $$

-- 5. Get best match score for a user
CREATE FUNCTION best_match_score(uid INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE best_score DECIMAL(5,2);
    SELECT MAX(score) INTO best_score FROM matches WHERE requester_id = uid;
    RETURN best_score;
END $$

-- 6. Check if user is available on a date (NEW)
CREATE FUNCTION is_user_available(uid INT, check_date DATE)
RETURNS VARCHAR(3)
DETERMINISTIC
BEGIN
    DECLARE avail_count INT DEFAULT 0;
    SELECT COUNT(*) INTO avail_count FROM availability
    WHERE user_id = uid AND date_avail = check_date;
    IF avail_count > 0 THEN RETURN 'YES'; ELSE RETURN 'NO'; END IF;
END $$

-- 7. Get session duration in minutes (NEW)
CREATE FUNCTION get_session_duration(sid INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE dur INT DEFAULT 0;
    SELECT TIMESTAMPDIFF(MINUTE, scheduled_start, scheduled_end) INTO dur
    FROM sessions WHERE session_id = sid;
    RETURN dur;
END $$

DELIMITER ;

-- Sample calls
SELECT get_full_name(5);
SELECT total_completed_sessions(3);
SELECT avg_user_rating(4);
SELECT count_teaching_skills(2);
SELECT best_match_score(8);
SELECT is_user_available(1, '2025-11-12');
SELECT get_session_duration(401);


-- ============================================================
-- CURSORS (inside stored procedures)
-- ============================================================

DELIMITER $$

-- 1. List all users via cursor
CREATE PROCEDURE cursor_list_users()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE uname VARCHAR(50);
    DECLARE cur CURSOR FOR SELECT user_name FROM users;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO uname;
        IF done = 1 THEN LEAVE read_loop; END IF;
        SELECT CONCAT('user: ', uname) AS message;
    END LOOP;
    CLOSE cur;
END $$

-- 2. Count completed sessions per user via cursor
CREATE PROCEDURE cursor_user_sessions()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE uid INT;
    DECLARE sess_count INT;
    DECLARE cur CURSOR FOR SELECT user_id FROM users;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    OPEN cur;
    loop_label: LOOP
        FETCH cur INTO uid;
        IF done = 1 THEN LEAVE loop_label; END IF;
        SELECT COUNT(*) INTO sess_count FROM sessions
        WHERE status = 'completed' AND (teacher_id = uid OR learner_id = uid);
        SELECT CONCAT('user ', uid, ' completed ', sess_count, ' sessions') AS result;
    END LOOP;
    CLOSE cur;
END $$

-- 3. Average rating per user via cursor
CREATE PROCEDURE cursor_avg_rating()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE uid INT;
    DECLARE avg_rate DECIMAL(5,2);
    DECLARE cur CURSOR FOR SELECT user_id FROM users;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    OPEN cur;
    loop_label: LOOP
        FETCH cur INTO uid;
        IF done = 1 THEN LEAVE loop_label; END IF;
        SELECT ROUND(AVG(rating), 2) INTO avg_rate FROM feedback WHERE to_user_id = uid;
        SELECT CONCAT('user ', uid, ' avg rating: ', IFNULL(avg_rate, 0)) AS output;
    END LOOP;
    CLOSE cur;
END $$

-- 4. Learner count per skill via cursor
CREATE PROCEDURE cursor_skill_learners()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE sid INT;
    DECLARE learner_count INT;
    DECLARE cur CURSOR FOR SELECT skill_id FROM skills;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    OPEN cur;
    skill_loop: LOOP
        FETCH cur INTO sid;
        IF done = 1 THEN LEAVE skill_loop; END IF;
        SELECT COUNT(*) INTO learner_count FROM user_skills
        WHERE skill_id = sid AND role = 'learn';
        SELECT CONCAT('skill ', sid, ' has ', learner_count, ' learners') AS result;
    END LOOP;
    CLOSE cur;
END $$

-- 5. Best match score per requester via cursor
CREATE PROCEDURE cursor_best_match()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE uid INT;
    DECLARE best DECIMAL(5,2);
    DECLARE cur CURSOR FOR SELECT DISTINCT requester_id FROM matches;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    OPEN cur;
    user_loop: LOOP
        FETCH cur INTO uid;
        IF done = 1 THEN LEAVE user_loop; END IF;
        SELECT MAX(score) INTO best FROM matches WHERE requester_id = uid;
        SELECT CONCAT('requester ', uid, ' best score: ', best) AS output;
    END LOOP;
    CLOSE cur;
END $$

-- 6. Update user_stats for all users via cursor (NEW)
CREATE PROCEDURE cursor_refresh_user_stats()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE uid INT;
    DECLARE taught_count INT;
    DECLARE learned_count INT;
    DECLARE avg_rate DECIMAL(5,2);
    DECLARE feedback_count INT;
    DECLARE cur CURSOR FOR SELECT user_id FROM users;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    OPEN cur;
    stat_loop: LOOP
        FETCH cur INTO uid;
        IF done = 1 THEN LEAVE stat_loop; END IF;
        SELECT COUNT(*) INTO taught_count FROM sessions
        WHERE teacher_id = uid AND status = 'completed';
        SELECT COUNT(*) INTO learned_count FROM sessions
        WHERE learner_id = uid AND status = 'completed';
        SELECT ROUND(AVG(rating), 2) INTO avg_rate FROM feedback WHERE to_user_id = uid;
        SELECT COUNT(*) INTO feedback_count FROM feedback WHERE to_user_id = uid;
        UPDATE user_stats SET
            total_taught   = taught_count,
            total_learned  = learned_count,
            avg_rating     = IFNULL(avg_rate, 0),
            total_feedback = feedback_count,
            last_active    = NOW()
        WHERE user_id = uid;
    END LOOP;
    CLOSE cur;
    SELECT 'User stats refreshed successfully' AS result;
END $$

DELIMITER ;


-- ============================================================
-- TRIGGERS
-- ============================================================

DELIMITER $$

-- 1. After session insert → notify teacher & learner
CREATE TRIGGER trg_session_created
AFTER INSERT ON sessions FOR EACH ROW
BEGIN
    INSERT INTO notifications (user_id, message, is_read)
    VALUES (NEW.learner_id,
            CONCAT('your session for skill ', NEW.skill_id, ' is scheduled on ', NEW.scheduled_start), 0);
    INSERT INTO notifications (user_id, message, is_read)
    VALUES (NEW.teacher_id,
            CONCAT('a new session for skill ', NEW.skill_id, ' has been scheduled on ', NEW.scheduled_start), 0);
END $$

-- 2. Session rescheduled → notify learner
CREATE TRIGGER trg_session_rescheduled
AFTER UPDATE ON sessions FOR EACH ROW
BEGIN
    IF NEW.status = 'rescheduled' THEN
        INSERT INTO notifications (user_id, message, is_read)
        VALUES (NEW.learner_id,
                CONCAT('your session for skill ', NEW.skill_id, ' has been rescheduled to ', NEW.scheduled_start), 0);
    END IF;
END $$

-- 3. Session cancelled → notify teacher
CREATE TRIGGER trg_session_cancelled
AFTER UPDATE ON sessions FOR EACH ROW
BEGIN
    IF NEW.status = 'cancelled' THEN
        INSERT INTO notifications (user_id, message, is_read)
        VALUES (NEW.teacher_id,
                CONCAT('the session for skill ', NEW.skill_id, ' on ', OLD.scheduled_start, ' has been cancelled'), 0);
    END IF;
END $$

-- 4. New feedback → notify receiver
CREATE TRIGGER trg_feedback_submitted
AFTER INSERT ON feedback FOR EACH ROW
BEGIN
    INSERT INTO notifications (user_id, message, is_read)
    VALUES (NEW.to_user_id,
            CONCAT('you received new feedback with rating ', NEW.rating), 0);
END $$

-- 5. Validate feedback rating (1-5)
CREATE TRIGGER trg_feedback_rating_check
BEFORE INSERT ON feedback FOR EACH ROW
BEGIN
    IF NEW.rating < 1 OR NEW.rating > 5 THEN
        SIGNAL SQLSTATE '45000' SET message_text = 'rating must be between 1 and 5';
    END IF;
END $$

-- 6. Prevent overlapping sessions for the same teacher
CREATE TRIGGER trg_no_teacher_overlap
BEFORE INSERT ON sessions FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM sessions
        WHERE teacher_id = NEW.teacher_id
          AND (
              (NEW.scheduled_start BETWEEN scheduled_start AND scheduled_end) OR
              (NEW.scheduled_end   BETWEEN scheduled_start AND scheduled_end) OR
              (scheduled_start BETWEEN NEW.scheduled_start AND NEW.scheduled_end)
          )
    ) THEN
        SIGNAL SQLSTATE '45000' SET message_text = 'teacher already has a session in this time slot';
    END IF;
END $$

-- 7. Prevent overlapping sessions for the same learner
CREATE TRIGGER trg_no_learner_overlap
BEFORE INSERT ON sessions FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM sessions
        WHERE learner_id = NEW.learner_id
          AND (
              (NEW.scheduled_start BETWEEN scheduled_start AND scheduled_end) OR
              (NEW.scheduled_end   BETWEEN scheduled_start AND scheduled_end) OR
              (scheduled_start BETWEEN NEW.scheduled_start AND NEW.scheduled_end)
          )
    ) THEN
        SIGNAL SQLSTATE '45000' SET message_text = 'learner already has a session in this time slot';
    END IF;
END $$

-- 8. Prevent availability with invalid time
CREATE TRIGGER trg_check_availability_time
BEFORE INSERT ON availability FOR EACH ROW
BEGIN
    IF NEW.end_time <= NEW.start_time THEN
        SIGNAL SQLSTATE '45000' SET message_text = 'end time must be greater than start time';
    END IF;
END $$

-- 9. Notify user when availability is added
CREATE TRIGGER trg_availability_added
AFTER INSERT ON availability FOR EACH ROW
BEGIN
    INSERT INTO notifications (user_id, message, is_read)
    VALUES (NEW.user_id,
            CONCAT('availability added for ', NEW.date_avail, ' from ', NEW.start_time, ' to ', NEW.end_time), 0);
END $$

-- 10. Prevent giving feedback twice for the same session
CREATE TRIGGER trg_no_duplicate_feedback
BEFORE INSERT ON feedback FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM feedback
        WHERE session_id = NEW.session_id AND from_user_id = NEW.from_user_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET message_text = 'feedback already submitted for this session by this user';
    END IF;
END $$

-- 11. Auto update match score on new feedback
CREATE TRIGGER trg_update_match_score
AFTER INSERT ON feedback FOR EACH ROW
BEGIN
    UPDATE matches
    SET score = LEAST(score + (NEW.rating * 0.5), 100)
    WHERE requester_id = NEW.to_user_id OR candidate_id = NEW.to_user_id;
END $$

-- 12. Notify teacher when feedback is received
CREATE TRIGGER trg_notify_teacher_feedback
AFTER INSERT ON feedback FOR EACH ROW
BEGIN
    INSERT INTO notifications (user_id, message, is_read)
    VALUES (NEW.to_user_id,
            CONCAT('new feedback received with rating: ', NEW.rating), 0);
END $$

-- 13. Log admin actions when sessions are deleted (NEW)
CREATE TRIGGER trg_log_session_delete
BEFORE DELETE ON sessions FOR EACH ROW
BEGIN
    INSERT INTO admin_logs (action_type, table_name, record_id, description)
    VALUES ('DELETE', 'sessions', OLD.session_id,
            CONCAT('Session deleted: teacher_id=', OLD.teacher_id,
                   ', learner_id=', OLD.learner_id, ', status=', OLD.status));
END $$

-- 14. Auto set match score if null or 0 (NEW)
CREATE TRIGGER trg_auto_score
BEFORE INSERT ON matches FOR EACH ROW
BEGIN
    IF NEW.score IS NULL OR NEW.score = 0 THEN
        SET NEW.score = 50 + (RAND() * 50);
    END IF;
END $$

-- 15. Update user_stats when session is completed (NEW)
CREATE TRIGGER trg_update_stats_on_complete
AFTER UPDATE ON sessions FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        UPDATE user_stats SET total_taught  = total_taught + 1,  last_active = NOW() WHERE user_id = NEW.teacher_id;
        UPDATE user_stats SET total_learned = total_learned + 1, last_active = NOW() WHERE user_id = NEW.learner_id;
    END IF;
END $$

DELIMITER ;


-- ============================================================
-- SAMPLE QUERY USING VIEWS
-- ============================================================

-- Top 5 users on leaderboard
SELECT * FROM vw_user_leaderboard LIMIT 5;

-- Most popular skills
SELECT * FROM vw_popular_skills LIMIT 10;

-- All pending skill requests
SELECT * FROM vw_pending_requests;

-- All unread notifications
SELECT * FROM vw_unread_notifications;

-- Detailed session view
SELECT * FROM vw_session_details WHERE status = 'completed';

-- ============================================================
-- END OF SCRIPT
-- ============================================================
