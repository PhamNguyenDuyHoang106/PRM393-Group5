import { Injectable } from '@nestjs/common';
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

@Injectable()
export class StatisticsService {
  constructor(private readonly prisma: PrismaService) {}

  async getDashboard(userId: string, role: string): Promise<DashboardStats> {
    // Determine which projects this user can see
    const projectFilter =
      role === 'manager'
        ? { OR: [{ ownerId: userId }, { members: { some: { userId } } }] }
        : { members: { some: { userId } } };

    const projects = await this.prisma.project.findMany({
      where: projectFilter,
      select: { id: true },
    });

    const projectIds = projects.map((p) => p.id);

    if (projectIds.length === 0) {
      return this._emptyStats();
    }

    // Aggregate tasks across all accessible projects
    const [tasksByStatus, tasksByPriority, myTaskCount, totalTasks] =
      await Promise.all([
        this.prisma.task.groupBy({
          by: ['status'],
          where: { projectId: { in: projectIds } },
          _count: { status: true },
        }),
        this.prisma.task.groupBy({
          by: ['priority'],
          where: { projectId: { in: projectIds } },
          _count: { priority: true },
        }),
        this.prisma.task.count({
          where: { projectId: { in: projectIds }, assignedTo: userId },
        }),
        this.prisma.task.count({
          where: { projectId: { in: projectIds } },
        }),
      ]);

    const statusMap = this._toMap(tasksByStatus, 'status');
    const priorityMap = this._toMap(tasksByPriority, 'priority');
    const doneCount = statusMap['DONE'] ?? 0;

    // Per-project breakdown
    const projectStats = await this._getProjectStats(projectIds);

    return {
      totalProjects: projectIds.length,
      totalTasks,
      myTasks: myTaskCount,
      completedTasks: doneCount,
      overallCompletionRate:
        totalTasks > 0 ? Math.round((doneCount / totalTasks) * 100) : 0,
      tasksByStatus: {
        TODO: statusMap['TODO'] ?? 0,
        IN_PROGRESS: statusMap['IN_PROGRESS'] ?? 0,
        DONE: doneCount,
      },
      tasksByPriority: {
        LOW: priorityMap['LOW'] ?? 0,
        MEDIUM: priorityMap['MEDIUM'] ?? 0,
        HIGH: priorityMap['HIGH'] ?? 0,
      },
      projectStats,
    };
  }

  async getProjectStats(projectId: string): Promise<ProjectStats> {
    const stats = await this._getProjectStats([projectId]);
    return stats[0] ?? this._emptyProjectStats(projectId);
  }

  private async _getProjectStats(projectIds: string[]): Promise<ProjectStats[]> {
    const projects = await this.prisma.project.findMany({
      where: { id: { in: projectIds } },
      select: { id: true, name: true },
    });

    const results: ProjectStats[] = [];

    for (const project of projects) {
      const [byStatus, byPriority] = await Promise.all([
        this.prisma.task.groupBy({
          by: ['status'],
          where: { projectId: project.id },
          _count: { status: true },
        }),
        this.prisma.task.groupBy({
          by: ['priority'],
          where: { projectId: project.id },
          _count: { priority: true },
        }),
      ]);

      const statusMap = this._toMap(byStatus, 'status');
      const priorityMap = this._toMap(byPriority, 'priority');
      const total = Object.values(statusMap).reduce((a, b) => a + b, 0);
      const done = statusMap['DONE'] ?? 0;

      results.push({
        projectId: project.id,
        projectName: project.name,
        totalTasks: total,
        todoCount: statusMap['TODO'] ?? 0,
        inProgressCount: statusMap['IN_PROGRESS'] ?? 0,
        doneCount: done,
        completionRate: total > 0 ? Math.round((done / total) * 100) : 0,
        lowCount: priorityMap['LOW'] ?? 0,
        mediumCount: priorityMap['MEDIUM'] ?? 0,
        highCount: priorityMap['HIGH'] ?? 0,
      });
    }

    return results;
  }

  private _toMap(
    groups: { _count: Record<string, number> }[],
    key: string,
  ): Record<string, number> {
    return groups.reduce(
      (acc, g) => {
        const value = (g as any)[key] as string;
        acc[value] = (g._count as any)[key] as number;
        return acc;
      },
      {} as Record<string, number>,
    );
  }

  private _emptyStats(): DashboardStats {
    return {
      totalProjects: 0,
      totalTasks: 0,
      myTasks: 0,
      completedTasks: 0,
      overallCompletionRate: 0,
      tasksByStatus: { TODO: 0, IN_PROGRESS: 0, DONE: 0 },
      tasksByPriority: { LOW: 0, MEDIUM: 0, HIGH: 0 },
      projectStats: [],
    };
  }

  private _emptyProjectStats(projectId: string): ProjectStats {
    return {
      projectId,
      projectName: 'Unknown',
      totalTasks: 0,
      todoCount: 0,
      inProgressCount: 0,
      doneCount: 0,
      completionRate: 0,
      lowCount: 0,
      mediumCount: 0,
      highCount: 0,
    };
  }
}
