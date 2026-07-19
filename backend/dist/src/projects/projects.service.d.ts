import { ProjectsRepository } from './projects.repository';
import { CreateProjectDto, UpdateProjectDto, AddMemberDto } from './dto/project.dto';
import { NotificationsService } from '../notifications/notifications.service';
import { UsersService } from '../users/users.service';
export declare class ProjectsService {
    private readonly projectsRepo;
    private readonly notificationsService;
    private readonly usersService;
    constructor(projectsRepo: ProjectsRepository, notificationsService: NotificationsService, usersService: UsersService);
    create(dto: CreateProjectDto, ownerId: string): Promise<{
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
    findOne(id: string, userId: string): Promise<{
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
    }>;
    update(id: string, dto: UpdateProjectDto, userId: string): Promise<{
        id: string;
        name: string;
        createdAt: Date;
        description: string | null;
        ownerId: string;
    }>;
    delete(id: string, userId: string): Promise<void>;
    addMember(projectId: string, dto: AddMemberDto, requesterId: string): Promise<{
        projectId: string;
        userId: string;
    }>;
    removeMember(projectId: string, userId: string, requesterId: string): Promise<{
        projectId: string;
        userId: string;
    }>;
    listMembers(projectId: string, requesterId: string): Promise<({
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
    private _requireOwner;
}
