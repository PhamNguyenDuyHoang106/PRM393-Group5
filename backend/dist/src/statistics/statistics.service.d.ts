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
export interface MemberTaskDistribution {
    userId: string;
    userName: string;
    count: number;
}
export interface TaskSummaryItem {
    id: string;
    title: string;
    projectId: string;
    status: string;
    priority: string;
    dueDate: Date | null;
}
export interface DashboardStats {
    totalProjects: number;
    totalTasks: number;
    myTasks: number;
    completedTasks: number;
    inProgressTasks: number;
    overdueTasks: number;
    overallCompletionRate: number;
    tasksByStatus: Record<string, number>;
    tasksByPriority: Record<string, number>;
    tasksByMember: MemberTaskDistribution[];
    upcomingTasksList: TaskSummaryItem[];
    overdueTasksList: TaskSummaryItem[];
    projectStats: ProjectStats[];
}
export declare class StatisticsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    getDashboard(userId: string, role: string, range?: string): Promise<DashboardStats>;
    getProjectStats(projectId: string): Promise<ProjectStats>;
    private _getProjectStats;
    private _resolveRangeStart;
    private _toMap;
    private _emptyStats;
    private _emptyProjectStats;
}
