// Prisma v7 config — connection URLs belong here, NOT in schema.prisma
//
// IMPORTANT — two separate URL concerns:
//   prisma.config.ts  → used by Prisma CLI (migrate, push, studio)
//   PrismaService     → used at runtime via pg Pool (reads DATABASE_URL directly)
//
// Supabase PgBouncer (port 6543, ?pgbouncer=true) is INCOMPATIBLE with Prisma CLI
// because migrate/push requires DDL over a persistent session-mode connection.
// The CLI must use DIRECT_URL (port 5432, session-mode) instead.
import "dotenv/config";
import { defineConfig } from "prisma/config";

export default defineConfig({
  schema: "prisma/schema.prisma",
  migrations: {
    path: "prisma/migrations",
  },
  datasource: {
    // CLI uses DIRECT_URL (session-mode port 5432) — NOT PgBouncer
    url: process.env["DIRECT_URL"]!,
  },
});
