import { TasksService } from './tasks.service';
import { CreateTaskDto, UpdateTaskDto, UpdateTaskStatusDto } from './dto/task.dto';
export declare class TasksController {
    private readonly tasksService;
    constructor(tasksService: TasksService);
    create(projectId: string, dto: CreateTaskDto, user: any): Promise<{
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
    findAll(projectId: string, user: any): Promise<({
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
    findMyTasks(user: any): Promise<({
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
    findOne(id: string, user: any): Promise<{
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
    update(id: string, dto: UpdateTaskDto, user: any): Promise<{
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
    updateStatus(id: string, dto: UpdateTaskStatusDto, user: any): Promise<{
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
    delete(id: string, user: any): Promise<void>;
}
