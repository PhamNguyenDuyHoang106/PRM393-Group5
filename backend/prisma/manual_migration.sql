-- ============================================================
-- PRM393-Group5 — Manual Migration Script
-- Generated from: prisma/schema.prisma
-- Apply using: psql, pgAdmin, DBeaver, or any PostgreSQL client
--
-- Usage:
--   psql -U postgres -d smart_task -f prisma/manual_migration.sql
-- ============================================================

-- Create database if not exists (run separately if needed):
-- CREATE DATABASE smart_task;

-- ─── Users ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "User" (
    "id"        TEXT        NOT NULL,
    "name"      TEXT        NOT NULL,
    "email"     TEXT        NOT NULL,
    "role"      TEXT        NOT NULL DEFAULT 'member',
    "avatarUrl" TEXT,
    "isActive"  BOOLEAN     NOT NULL DEFAULT true,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "User_email_key" ON "User"("email");

-- ─── ForgotPasswordHistory ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "ForgotPasswordHistory" (
    "id"             SERIAL      NOT NULL,
    "userId"         TEXT,
    "email"          TEXT        NOT NULL,
    "otpHash"        TEXT        NOT NULL,
    "expiresAt"      TIMESTAMP(3) NOT NULL,
    "verified"       BOOLEAN     NOT NULL DEFAULT false,
    "resetCompleted" BOOLEAN     NOT NULL DEFAULT false,
    "attemptCount"   INTEGER     NOT NULL DEFAULT 0,
    "lastAttempt"    TIMESTAMP(3),
    "lockedUntil"    TIMESTAMP(3),
    "requestedAt"    TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ForgotPasswordHistory_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "ForgotPasswordHistory_email_idx" ON "ForgotPasswordHistory"("email");

-- ─── Project ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "Project" (
    "id"          TEXT        NOT NULL,
    "name"        TEXT        NOT NULL,
    "description" TEXT,
    "ownerId"     TEXT        NOT NULL,
    "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Project_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Project_ownerId_fkey" FOREIGN KEY ("ownerId")
        REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- ─── ProjectMember ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "ProjectMember" (
    "projectId" TEXT NOT NULL,
    "userId"    TEXT NOT NULL,

    CONSTRAINT "ProjectMember_pkey" PRIMARY KEY ("projectId", "userId"),
    CONSTRAINT "ProjectMember_projectId_fkey" FOREIGN KEY ("projectId")
        REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "ProjectMember_userId_fkey" FOREIGN KEY ("userId")
        REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- ─── Task ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "Task" (
    "id"          TEXT        NOT NULL,
    "projectId"   TEXT        NOT NULL,
    "title"       TEXT        NOT NULL,
    "description" TEXT,
    "priority"    TEXT        NOT NULL DEFAULT 'MEDIUM',
    "status"      TEXT        NOT NULL DEFAULT 'TODO',
    "assignedTo"  TEXT,
    "dueDate"     TIMESTAMP(3),
    "updatedAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Task_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Task_projectId_fkey" FOREIGN KEY ("projectId")
        REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Task_assignedTo_fkey" FOREIGN KEY ("assignedTo")
        REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- ─── Notification ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "Notification" (
    "id"         TEXT        NOT NULL,
    "userId"     TEXT        NOT NULL,
    "title"      TEXT        NOT NULL,
    "message"    TEXT        NOT NULL,
    "type"       TEXT        NOT NULL DEFAULT 'SYSTEM',
    "readStatus" BOOLEAN     NOT NULL DEFAULT false,
    "createdBy"  TEXT,
    "createdAt"  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Notification_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Notification_userId_fkey" FOREIGN KEY ("userId")
        REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Notification_createdBy_fkey" FOREIGN KEY ("createdBy")
        REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- ─── AuditLog ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "AuditLog" (
    "id"        TEXT        NOT NULL,
    "userId"    TEXT,
    "action"    TEXT        NOT NULL,
    "entity"    TEXT        NOT NULL,
    "entityId"  TEXT        NOT NULL,
    "ip"        TEXT,
    "userAgent" TEXT,
    "oldData"   TEXT,
    "newData"   TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "AuditLog_userId_fkey" FOREIGN KEY ("userId")
        REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- ─── Prisma Migrations Table (required by Prisma to track migration state) ────
CREATE TABLE IF NOT EXISTS "_prisma_migrations" (
    "id"                    VARCHAR(36)  NOT NULL,
    "checksum"              VARCHAR(64)  NOT NULL,
    "finished_at"           TIMESTAMPTZ,
    "migration_name"        VARCHAR(255) NOT NULL,
    "logs"                  TEXT,
    "rolled_back_at"        TIMESTAMPTZ,
    "started_at"            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    "applied_steps_count"   INTEGER      NOT NULL DEFAULT 0,

    CONSTRAINT "_prisma_migrations_pkey" PRIMARY KEY ("id")
);

-- ─── Verification queries ─────────────────────────────────────────────────────
-- Run these after applying to confirm all tables exist:
--
-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema = 'public'
-- ORDER BY table_name;
--
-- Expected output:
--   AuditLog
--   ForgotPasswordHistory
--   Notification
--   Project
--   ProjectMember
--   Task
--   User
--   _prisma_migrations
