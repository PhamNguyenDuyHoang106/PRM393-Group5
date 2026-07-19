import { PrismaService } from '../prisma/prisma.service';
export interface CreateNotificationInput {
    userId: string;
    title: string;
    message: string;
    type: string;
    createdBy?: string;
}
export declare class NotificationsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    create(input: CreateNotificationInput): Promise<{
        id: string;
        createdAt: Date;
        userId: string;
        title: string;
        message: string;
        type: string;
        readStatus: boolean;
        createdBy: string | null;
    }>;
    findAllForUser(userId: string): Promise<{
        id: string;
        createdAt: Date;
        userId: string;
        title: string;
        message: string;
        type: string;
        readStatus: boolean;
        createdBy: string | null;
    }[]>;
    markAsRead(id: string, userId: string): Promise<import("@prisma/client").Prisma.BatchPayload>;
    markAllAsRead(userId: string): Promise<import("@prisma/client").Prisma.BatchPayload>;
    countUnread(userId: string): Promise<number>;
}
