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
    findByProjectIds(projectIds: string[]): Promise<({
        project: {
            id: string;
            name: string;
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
}
