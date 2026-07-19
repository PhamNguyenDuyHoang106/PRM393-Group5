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
    findMyTasks(userId: string): Promise<({
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
}
