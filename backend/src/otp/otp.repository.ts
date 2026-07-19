import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ForgotPasswordHistory, Prisma } from '@prisma/client';

@Injectable()
export class OtpRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findLatestByEmail(email: string): Promise<ForgotPasswordHistory | null> {
    return this.prisma.forgotPasswordHistory.findFirst({
      where: { email },
      orderBy: { requestedAt: 'desc' },
    });
  }

  async create(data: Prisma.ForgotPasswordHistoryCreateInput): Promise<ForgotPasswordHistory> {
    return this.prisma.forgotPasswordHistory.create({
      data,
    });
  }

  async update(id: number, data: Prisma.ForgotPasswordHistoryUpdateInput): Promise<ForgotPasswordHistory> {
    return this.prisma.forgotPasswordHistory.update({
      where: { id },
      data,
    });
  }
}
