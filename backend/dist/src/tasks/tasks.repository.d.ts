import { PrismaService } from '../prisma/prisma.service';
import { Prisma } from '@prisma/client';
export declare class TasksRepository {
    private readonly prisma;
    constructor(prisma: PrismaService);
    create(data: Prisma.TaskUncheckedCreateInput): Promise<{
        id: string;
        updatedAt: Date;
        createdAt: Date;
        description: string | null;
        projectId: string;
        title: string;
        priority: string;
        status: string;
        assignedTo: string | null;
        dueDate: Date | null;
    }>;
    findAll(projectId: string): Promise<({
        assignee: {
            id: string;
            email: string;
            name: string;
        } | null;
    } & {
        id: string;
        updatedAt: Date;
        createdAt: Date;
        description: string | null;
        projectId: string;
        title: string;
        priority: string;
        status: string;
        assignedTo: string | null;
        dueDate: Date | null;
    })[]>;
    findOne(id: string): Promise<({
        project: {
            id: string;
            name: string;
            ownerId: string;
        };
        assignee: {
            id: string;
            email: string;
            name: string;
        } | null;
    } & {
        id: string;
        updatedAt: Date;
        createdAt: Date;
        description: string | null;
        projectId: string;
        title: string;
        priority: string;
        status: string;
        assignedTo: string | null;
        dueDate: Date | null;
    }) | null>;
    findByAssignee(userId: string): Promise<({
        project: {
            id: string;
            name: string;
        };
    } & {
        id: string;
        updatedAt: Date;
        createdAt: Date;
        description: string | null;
        projectId: string;
        title: string;
        priority: string;
        status: string;
        assignedTo: string | null;
        dueDate: Date | null;
    })[]>;
    update(id: string, data: Prisma.TaskUncheckedUpdateInput): Promise<{
        id: string;
        updatedAt: Date;
        createdAt: Date;
        description: string | null;
        projectId: string;
        title: string;
        priority: string;
        status: string;
        assignedTo: string | null;
        dueDate: Date | null;
    }>;
    delete(id: string): Promise<{
        id: string;
        updatedAt: Date;
        createdAt: Date;
        description: string | null;
        projectId: string;
        title: string;
        priority: string;
        status: string;
        assignedTo: string | null;
        dueDate: Date | null;
    }>;
    countByStatus(projectId: string): Promise<(Prisma.PickEnumerable<Prisma.TaskGroupByOutputType, "status"[]> & {
        _count: {
            status: number;
        };
    })[]>;
    countByPriority(projectId: string): Promise<(Prisma.PickEnumerable<Prisma.TaskGroupByOutputType, "priority"[]> & {
        _count: {
            priority: number;
        };
    })[]>;
    createChecklist(data: Prisma.TaskChecklistUncheckedCreateInput): Promise<{
        id: string;
        createdAt: Date;
        title: string;
        taskId: string;
        isDone: boolean;
    }>;
    findChecklists(taskId: string): Promise<{
        id: string;
        createdAt: Date;
        title: string;
        taskId: string;
        isDone: boolean;
    }[]>;
    findChecklistOne(id: string): Promise<({
        task: {
            project: {
                id: string;
                name: string;
                createdAt: Date;
                description: string | null;
                ownerId: string;
            };
        } & {
            id: string;
            updatedAt: Date;
            createdAt: Date;
            description: string | null;
            projectId: string;
            title: string;
            priority: string;
            status: string;
            assignedTo: string | null;
            dueDate: Date | null;
        };
    } & {
        id: string;
        createdAt: Date;
        title: string;
        taskId: string;
        isDone: boolean;
    }) | null>;
    updateChecklist(id: string, data: Prisma.TaskChecklistUncheckedUpdateInput): Promise<{
        id: string;
        createdAt: Date;
        title: string;
        taskId: string;
        isDone: boolean;
    }>;
    deleteChecklist(id: string): Promise<{
        id: string;
        createdAt: Date;
        title: string;
        taskId: string;
        isDone: boolean;
    }>;
    createComment(data: Prisma.TaskCommentUncheckedCreateInput): Promise<{
        user: {
            id: string;
            name: string;
            avatarUrl: string | null;
        };
    } & {
        id: string;
        createdAt: Date;
        userId: string;
        content: string;
        taskId: string;
    }>;
    findComments(taskId: string): Promise<({
        user: {
            id: string;
            name: string;
            avatarUrl: string | null;
        };
    } & {
        id: string;
        createdAt: Date;
        userId: string;
        content: string;
        taskId: string;
    })[]>;
    findCommentOne(id: string): Promise<({
        task: {
            project: {
                id: string;
                name: string;
                createdAt: Date;
                description: string | null;
                ownerId: string;
            };
        } & {
            id: string;
            updatedAt: Date;
            createdAt: Date;
            description: string | null;
            projectId: string;
            title: string;
            priority: string;
            status: string;
            assignedTo: string | null;
            dueDate: Date | null;
        };
    } & {
        id: string;
        createdAt: Date;
        userId: string;
        content: string;
        taskId: string;
    }) | null>;
    deleteComment(id: string): Promise<{
        id: string;
        createdAt: Date;
        userId: string;
        content: string;
        taskId: string;
    }>;
    createAuditLog(data: Prisma.AuditLogUncheckedCreateInput): Promise<{
        id: string;
        createdAt: Date;
        userId: string | null;
        action: string;
        entity: string;
        entityId: string;
        ip: string | null;
        userAgent: string | null;
        oldData: string | null;
        newData: string | null;
    }>;
    findAuditLogs(taskId: string): Promise<({
        user: {
            id: string;
            name: string;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        userId: string | null;
        action: string;
        entity: string;
        entityId: string;
        ip: string | null;
        userAgent: string | null;
        oldData: string | null;
        newData: string | null;
    })[]>;
}
