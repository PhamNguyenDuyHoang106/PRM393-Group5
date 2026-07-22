import { StatisticsService } from './statistics.service';
export declare class StatisticsController {
    private readonly statisticsService;
    constructor(statisticsService: StatisticsService);
    getDashboard(user: any, range?: string): Promise<import("./statistics.service").DashboardStats>;
    getProjectStats(projectId: string): Promise<import("./statistics.service").ProjectStats>;
}
