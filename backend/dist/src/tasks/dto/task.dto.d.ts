export declare class CreateTaskDto {
    id?: string;
    title: string;
    description?: string;
    priority: string;
    assignedTo?: string;
    dueDate?: string;
}
export declare class UpdateTaskDto {
    title?: string;
    description?: string;
    priority?: string;
    status?: string;
    assignedTo?: string;
    dueDate?: string;
}
export declare class UpdateTaskStatusDto {
    status: string;
}
