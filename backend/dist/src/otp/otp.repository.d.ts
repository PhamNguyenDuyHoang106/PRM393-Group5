import { PrismaService } from '../prisma/prisma.service';
import { ForgotPasswordHistory, Prisma } from '@prisma/client';
export declare class OtpRepository {
    private readonly prisma;
    constructor(prisma: PrismaService);
    findLatestByEmail(email: string): Promise<ForgotPasswordHistory | null>;
    create(data: Prisma.ForgotPasswordHistoryCreateInput): Promise<ForgotPasswordHistory>;
    update(id: number, data: Prisma.ForgotPasswordHistoryUpdateInput): Promise<ForgotPasswordHistory>;
}
