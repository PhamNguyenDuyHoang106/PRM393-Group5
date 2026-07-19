import { PrismaService } from '../prisma/prisma.service';
import { Prisma } from '@prisma/client';
export declare class ProjectsRepository {
    private readonly prisma;
    constructor(prisma: PrismaService);
    create(data: Prisma.ProjectCreateInput): Promise<{
        id: string;
        name: string;
        createdAt: Date;
        description: string | null;
        ownerId: string;
    }>;
    findAll(userId: string): Promise<({
        owner: {
            id: string;
            email: string;
            name: string;
            role: string;
        };
        members: ({
            user: {
                id: string;
                email: string;
                name: string;
                role: string;
            };
        } & {
            projectId: string;
            userId: string;
        })[];
        _count: {
            tasks: number;
        };
    } & {
        id: string;
        name: string;
        createdAt: Date;
        description: string | null;
        ownerId: string;
    })[]>;
    findOne(id: string): Promise<({
        owner: {
            id: string;
            email: string;
            name: string;
            role: string;
        };
        members: ({
            user: {
                id: string;
                email: string;
                name: string;
                role: string;
            };
        } & {
            projectId: string;
            userId: string;
        })[];
        tasks: {
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
        }[];
        _count: {
            members: number;
            tasks: number;
        };
    } & {
        id: string;
        name: string;
        createdAt: Date;
        description: string | null;
        ownerId: string;
    }) | null>;
    update(id: string, data: Prisma.ProjectUpdateInput): Promise<{
        id: string;
        name: string;
        createdAt: Date;
        description: string | null;
        ownerId: string;
    }>;
    delete(id: string): Promise<{
        id: string;
        name: string;
        createdAt: Date;
        description: string | null;
        ownerId: string;
    }>;
    addMember(projectId: string, userId: string): Promise<{
        projectId: string;
        userId: string;
    }>;
    removeMember(projectId: string, userId: string): Promise<{
        projectId: string;
        userId: string;
    }>;
    listMembers(projectId: string): Promise<({
        user: {
            id: string;
            email: string;
            name: string;
            role: string;
        };
    } & {
        projectId: string;
        userId: string;
    })[]>;
    isMember(projectId: string, userId: string): Promise<boolean>;
    isOwner(projectId: string, userId: string): Promise<boolean>;
}
