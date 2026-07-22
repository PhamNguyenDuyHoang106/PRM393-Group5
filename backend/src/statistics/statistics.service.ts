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

@Injectable()
export class StatisticsService {
  constructor(private readonly prisma: PrismaService) {}

  async getDashboard(userId: string, role: string): Promise<DashboardStats> {
    const isManager = role.toLowerCase() === 'manager';
    const now = new Date();
    const in3Days = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);

    const projectFilter = isManager
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

    const visibleTaskFilter = {
      projectId: { in: projectIds },
      ...(isManager ? {} : { assignedTo: userId }),
    };

    const [
      tasksByStatus,
      tasksByPriority,
      myTaskCount,
      totalTasks,
      overdueTaskCount,
      tasksByMemberGroup,
      upcomingTasks,
      overdueTasks,
    ] = await Promise.all([
      this.prisma.task.groupBy({
        by: ['status'],
        where: visibleTaskFilter,
        _count: { status: true },
      }),
      this.prisma.task.groupBy({
        by: ['priority'],
        where: visibleTaskFilter,
        _count: { priority: true },
      }),
      this.prisma.task.count({
        where: { projectId: { in: projectIds }, assignedTo: userId },
      }),
      this.prisma.task.count({
        where: visibleTaskFilter,
      }),
      this.prisma.task.count({
        where: {
          ...visibleTaskFilter,
          status: { not: 'DONE' },
          dueDate: { lt: now },
        },
      }),
      this.prisma.task.groupBy({
        by: ['assignedTo'],
        where: visibleTaskFilter,
        _count: { assignedTo: true },
      }),
      this.prisma.task.findMany({
        where: {
          ...visibleTaskFilter,
          status: { not: 'DONE' },
          dueDate: { gte: now, lte: in3Days },
        },
        select: {
          id: true,
          title: true,
          projectId: true,
          status: true,
          priority: true,
          dueDate: true,
        },
        orderBy: { dueDate: 'asc' },
        take: 5,
      }),
      this.prisma.task.findMany({
        where: {
          ...visibleTaskFilter,
          status: { not: 'DONE' },
          dueDate: { lt: now },
        },
        select: {
          id: true,
          title: true,
          projectId: true,
          status: true,
          priority: true,
          dueDate: true,
        },
        orderBy: { dueDate: 'asc' },
        take: 5,
      }),
    ]);

    const statusMap = this._toMap(tasksByStatus, 'status');
    const priorityMap = this._toMap(tasksByPriority, 'priority');
    const doneCount = statusMap['DONE'] ?? 0;
    const inProgressCount = statusMap['IN_PROGRESS'] ?? 0;

    // Resolve assignedTo member names
    const memberIds = tasksByMemberGroup
      .map((g) => g.assignedTo)
      .filter((id): id is string => id != null);
    
    const users = memberIds.length > 0
      ? await this.prisma.user.findMany({
          where: { id: { in: memberIds } },
          select: { id: true, name: true },
        })
      : [];
    
    const userNameMap = new Map(users.map((u) => [u.id, u.name]));
    
    const tasksByMember: MemberTaskDistribution[] = tasksByMemberGroup.map((g) => ({
      userId: g.assignedTo ?? 'Unassigned',
      userName: g.assignedTo ? (userNameMap.get(g.assignedTo) ?? 'Member') : 'Unassigned',
      count: g._count.assignedTo,
    }));

    const projectStats = await this._getProjectStats(
      projectIds,
      isManager ? undefined : userId,
    );

    return {
      totalProjects: projectIds.length,
      totalTasks,
      myTasks: myTaskCount,
      completedTasks: doneCount,
      inProgressTasks: inProgressCount,
      overdueTasks: overdueTaskCount,
      overallCompletionRate:
        totalTasks > 0 ? Math.round((doneCount / totalTasks) * 100) : 0,
      tasksByStatus: {
        TODO: statusMap['TODO'] ?? 0,
        IN_PROGRESS: inProgressCount,
        DONE: doneCount,
      },
      tasksByPriority: {
        LOW: priorityMap['LOW'] ?? 0,
        MEDIUM: priorityMap['MEDIUM'] ?? 0,
        HIGH: priorityMap['HIGH'] ?? 0,
      },
      tasksByMember,
      upcomingTasksList: upcomingTasks,
      overdueTasksList: overdueTasks,
      projectStats,
    };
  }

  async getProjectStats(projectId: string): Promise<ProjectStats> {
    const stats = await this._getProjectStats([projectId]);
    return stats[0] ?? this._emptyProjectStats(projectId);
  }

  private async _getProjectStats(
    projectIds: string[],
    assignedTo?: string,
  ): Promise<ProjectStats[]> {
    const projects = await this.prisma.project.findMany({
      where: { id: { in: projectIds } },
      select: { id: true, name: true },
    });

    const results: ProjectStats[] = [];

    for (const project of projects) {
      const taskFilter = {
        projectId: project.id,
        ...(assignedTo == null ? {} : { assignedTo }),
      };
      const [byStatus, byPriority] = await Promise.all([
        this.prisma.task.groupBy({
          by: ['status'],
          where: taskFilter,
          _count: { status: true },
        }),
        this.prisma.task.groupBy({
          by: ['priority'],
          where: taskFilter,
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
      inProgressTasks: 0,
      overdueTasks: 0,
      overallCompletionRate: 0,
      tasksByStatus: { TODO: 0, IN_PROGRESS: 0, DONE: 0 },
      tasksByPriority: { LOW: 0, MEDIUM: 0, HIGH: 0 },
      tasksByMember: [],
      upcomingTasksList: [],
      overdueTasksList: [],
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
