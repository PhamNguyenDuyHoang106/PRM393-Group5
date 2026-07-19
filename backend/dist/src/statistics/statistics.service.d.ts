import { PrismaService } from '../prisma/prisma.service';
export interface ProjectStats {
    projectId: string;
    projectName: string;
    totalTasks: number;
    todoCount: number;
    inProgressCount: number;
    doneCount: number;
    completionRate: number;
    lowCount: number;
    mediumCount: number;
    highCount: number;
}
export interface DashboardStats {
    totalProjects: number;
    totalTasks: number;
    myTasks: number;
    completedTasks: number;
    overallCompletionRate: number;
    tasksByStatus: Record<string, number>;
    tasksByPriority: Record<string, number>;
    projectStats: ProjectStats[];
}
export declare class StatisticsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    getDashboard(userId: string, role: string): Promise<DashboardStats>;
    getProjectStats(projectId: string): Promise<ProjectStats>;
    private _getProjectStats;
    private _toMap;
    private _emptyStats;
    private _emptyProjectStats;
}
