import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(PrismaService.name);

  constructor(configService: ConfigService) {
    // Prefer DIRECT_URL (session mode) at runtime with the pg adapter.
    // PgBouncer transaction-mode URLs can hang Prisma findUnique/prepared statements.
    const connectionString =
      configService.get<string>('DIRECT_URL') ||
      configService.get<string>('DATABASE_URL') ||
      'postgresql://postgres:postgres@localhost:5432/smart_task?schema=public';
    const pool = new Pool({
      connectionString,
      max: 5,
      connectionTimeoutMillis: 8000,
      idleTimeoutMillis: 10000,
    });
    const adapter = new PrismaPg(pool);

    super({ adapter } as any);
  }

  async onModuleInit() {
    try {
      await this.$connect();
      this.logger.log('Successfully connected to PostgreSQL database.');
    } catch (error: any) {
      this.logger.error(`Database connection failed: ${error.message}`);
    }
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
