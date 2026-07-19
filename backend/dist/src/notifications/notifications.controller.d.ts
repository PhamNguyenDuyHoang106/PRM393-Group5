import { NotificationsService } from './notifications.service';
export declare class NotificationsController {
    private readonly notificationsService;
    constructor(notificationsService: NotificationsService);
    findAll(user: any): Promise<{
        id: string;
        createdAt: Date;
        userId: string;
        title: string;
        message: string;
        type: string;
        readStatus: boolean;
        createdBy: string | null;
    }[]>;
    unreadCount(user: any): Promise<{
        unreadCount: number;
    }>;
    markAsRead(id: string, user: any): Promise<void>;
    markAllAsRead(user: any): Promise<void>;
}
