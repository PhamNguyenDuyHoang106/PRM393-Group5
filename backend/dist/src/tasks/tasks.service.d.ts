import { TasksRepository } from './tasks.repository';
import { ProjectsRepository } from '../projects/projects.repository';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateTaskDto, UpdateTaskDto, UpdateTaskStatusDto } from './dto/task.dto';
export declare class TasksService {
    private readonly tasksRepo;
    private readonly projectsRepo;
    private readonly notificationsService;
    constructor(tasksRepo: TasksRepository, projectsRepo: ProjectsRepository, notificationsService: NotificationsService);
    create(projectId: string, dto: CreateTaskDto, requesterId: string): Promise<{
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
    findAll(projectId: string, requesterId: string): Promise<({
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
    findOne(id: string, requesterId: string): Promise<{
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
    }>;
    findMyTasks(userId: string, role: string): Promise<({
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
    update(id: string, dto: UpdateTaskDto, requesterId: string, requesterRole: string): Promise<{
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
    updateStatus(id: string, dto: UpdateTaskStatusDto, requesterId: string): Promise<{
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
    delete(id: string, requesterId: string): Promise<void>;
    createChecklist(taskId: string, title: string, requesterId: string, customId?: string): Promise<{
        id: string;
        createdAt: Date;
        title: string;
        taskId: string;
        isDone: boolean;
    }>;
    findChecklists(taskId: string, requesterId: string): Promise<{
        id: string;
        createdAt: Date;
        title: string;
        taskId: string;
        isDone: boolean;
    }[]>;
    updateChecklist(id: string, dto: {
        title?: string;
        isDone?: boolean;
    }, requesterId: string): Promise<{
        id: string;
        createdAt: Date;
        title: string;
        taskId: string;
        isDone: boolean;
    }>;
    deleteChecklist(id: string, requesterId: string): Promise<void>;
    createComment(taskId: string, content: string, requesterId: string, customId?: string): Promise<{
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
    findComments(taskId: string, requesterId: string): Promise<({
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
    deleteComment(id: string, requesterId: string, requesterRole: string): Promise<void>;
    findActivities(taskId: string, requesterId: string): Promise<({
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
    private _requireProjectAccess;
    private _createAuditLog;
}
