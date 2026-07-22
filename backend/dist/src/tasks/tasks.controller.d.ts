import { TasksService } from './tasks.service';
import { CreateTaskDto, UpdateTaskDto, UpdateTaskStatusDto } from './dto/task.dto';
import { CreateChecklistDto, UpdateChecklistDto } from './dto/checklist.dto';
import { CreateCommentDto } from './dto/comment.dto';
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
    findChecklists(taskId: string, user: any): Promise<{
        id: string;
        createdAt: Date;
        title: string;
        taskId: string;
        isDone: boolean;
    }[]>;
    createChecklist(taskId: string, dto: CreateChecklistDto, user: any): Promise<{
        id: string;
        createdAt: Date;
        title: string;
        taskId: string;
        isDone: boolean;
    }>;
    updateChecklist(id: string, dto: UpdateChecklistDto, user: any): Promise<{
        id: string;
        createdAt: Date;
        title: string;
        taskId: string;
        isDone: boolean;
    }>;
    deleteChecklist(id: string, user: any): Promise<void>;
    findComments(taskId: string, user: any): Promise<({
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
    createComment(taskId: string, dto: CreateCommentDto, user: any): Promise<{
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
    deleteComment(id: string, user: any): Promise<void>;
    findActivities(taskId: string, user: any): Promise<({
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
