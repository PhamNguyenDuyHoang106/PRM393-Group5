import { PrismaService } from '../prisma/prisma.service';
import { StatisticsService } from './statistics.service';

describe('StatisticsService', () => {
  it('limits member dashboard statistics to tasks assigned to that member', async () => {
    const projectFindMany = jest
      .fn()
      .mockResolvedValueOnce([{ id: 'project-1' }])
      .mockResolvedValueOnce([{ id: 'project-1', name: 'Project One' }]);
    const taskGroupBy = jest
      .fn()
      .mockResolvedValueOnce([
        { status: 'TODO', _count: { status: 1 } },
        { status: 'DONE', _count: { status: 1 } },
      ])
      .mockResolvedValueOnce([{ priority: 'HIGH', _count: { priority: 2 } }])
      .mockResolvedValueOnce([
        { status: 'TODO', _count: { status: 1 } },
        { status: 'DONE', _count: { status: 1 } },
      ])
      .mockResolvedValueOnce([{ priority: 'HIGH', _count: { priority: 2 } }]);
    const taskCount = jest
      .fn()
      .mockResolvedValueOnce(2)
      .mockResolvedValueOnce(2);
    const prisma = {
      project: { findMany: projectFindMany },
      task: { groupBy: taskGroupBy, count: taskCount },
    } as unknown as PrismaService;
    const service = new StatisticsService(prisma);

    const result = await service.getDashboard('member-1', 'member');

    expect(result.totalProjects).toBe(1);
    expect(result.totalTasks).toBe(2);
    expect(result.myTasks).toBe(2);
    expect(result.completedTasks).toBe(1);
    expect(result.overallCompletionRate).toBe(50);
    for (const call of taskGroupBy.mock.calls) {
      expect(call[0].where.assignedTo).toBe('member-1');
    }
    expect(taskCount.mock.calls[1][0].where.assignedTo).toBe('member-1');
  });
});
