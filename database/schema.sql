-- E-Book Library — MySQL/MariaDB Schema
-- Run: mariadb -u root -p < database/schema.sql

CREATE DATABASE IF NOT EXISTS ebook_library
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE ebook_library;

-- ─── Genres ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS genres (
    genre_id INT AUTO_INCREMENT PRIMARY KEY,
    name     VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── Users ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS users (
    user_id       VARCHAR(32)  NOT NULL PRIMARY KEY,
    name          VARCHAR(255) NOT NULL,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password      VARCHAR(255) NOT NULL,
    role          VARCHAR(20)  NOT NULL DEFAULT 'viewer',
    auth_provider VARCHAR(20)  NOT NULL DEFAULT 'email',
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- ─── User Preferences ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS user_preferences (
    user_id  VARCHAR(32) NOT NULL,
    genre_id INT         NOT NULL,
    PRIMARY KEY (user_id, genre_id),
    FOREIGN KEY (user_id)  REFERENCES users(user_id)  ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES genres(genre_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── Books ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS books (
    book_id     INT AUTO_INCREMENT PRIMARY KEY,
    title       VARCHAR(255) NOT NULL,
    author      VARCHAR(255) NOT NULL,
    description TEXT,
    cover_url   VARCHAR(500),
    genre_id    INT,
    isbn        VARCHAR(20),
    year        INT,
    pages       INT,
    file_path   VARCHAR(500),
    file_size   BIGINT       DEFAULT 0,
    user_id     VARCHAR(32)  NOT NULL,
    status      VARCHAR(20)  NOT NULL DEFAULT 'pending',
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (genre_id) REFERENCES genres(genre_id) ON DELETE SET NULL,
    FOREIGN KEY (user_id)  REFERENCES users(user_id)   ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX IF NOT EXISTS idx_books_author ON books(author);
CREATE INDEX IF NOT EXISTS idx_books_genre  ON books(genre_id);
CREATE INDEX IF NOT EXISTS idx_books_status ON books(status);

-- ─── Activity Logs ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS activity_logs (
    log_id     INT AUTO_INCREMENT PRIMARY KEY,
    user_id    VARCHAR(32)  NOT NULL,
    book_id    INT          NOT NULL,
    event_type VARCHAR(30)  NOT NULL,
    weight     INT          NOT NULL DEFAULT 1,
    is_deleted TINYINT(1)   NOT NULL DEFAULT 0,
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX IF NOT EXISTS idx_activity_rec  ON activity_logs(user_id, book_id, event_type, created_at);
CREATE INDEX IF NOT EXISTS idx_activity_view ON activity_logs(user_id, event_type, is_deleted, created_at);
CREATE INDEX IF NOT EXISTS idx_activity_date ON activity_logs(created_at);

-- ─── Reviews ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS reviews (
    review_id  INT AUTO_INCREMENT PRIMARY KEY,
    user_id    VARCHAR(32) NOT NULL,
    book_id    INT         NOT NULL,
    rating     INT         NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment    TEXT,
    created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    UNIQUE KEY uq_review (user_id, book_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── Remember Tokens ───────────────────────────────────────────

CREATE TABLE IF NOT EXISTS remember_tokens (
    token_id   INT AUTO_INCREMENT PRIMARY KEY,
    user_id    VARCHAR(32) NOT NULL,
    token      VARCHAR(64) NOT NULL UNIQUE,
    expires_at DATETIME    NOT NULL,
    created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX IF NOT EXISTS idx_remember_token ON remember_tokens(token);

-- ─── Bookmarks ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS bookmarks (
    user_id    VARCHAR(32) NOT NULL,
    book_id    INT         NOT NULL,
    created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, book_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── Login Attempts (rate limiting) ────────────────────────────

CREATE TABLE IF NOT EXISTS login_attempts (
    attempt_id   INT AUTO_INCREMENT PRIMARY KEY,
    ip           VARCHAR(45) NOT NULL,
    attempt_time DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX IF NOT EXISTS idx_login_attempts_ip_time ON login_attempts(ip, attempt_time);

-- ─── Admin Audit Trail ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS audit_logs (
    log_id      INT AUTO_INCREMENT PRIMARY KEY,
    admin_id    VARCHAR(32)  NOT NULL,
    action      VARCHAR(50)  NOT NULL,
    target_type VARCHAR(50)  NOT NULL DEFAULT '',
    target_id   VARCHAR(255) NOT NULL DEFAULT '',
    details     JSON         NOT NULL DEFAULT ('{}'),
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (admin_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX IF NOT EXISTS idx_audit_logs_date  ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_admin ON audit_logs(admin_id);

-- ─── View: weighted recommendation scores ──────────────────────

CREATE OR REPLACE VIEW user_book_scores AS
SELECT
    a.user_id,
    a.book_id,
    SUM(a.weight) AS score
FROM activity_logs a
WHERE a.is_deleted = 0
  AND a.created_at >= NOW() - INTERVAL 180 DAY
GROUP BY a.user_id, a.book_id;

-- ─── Seed genres ──────────────────────────────────────────────

INSERT IGNORE INTO genres (name) VALUES
    ('Sci-Fi'),
    ('Fantasy'),
    ('Romance'),
    ('Non-Fiction'),
    ('Thriller');
