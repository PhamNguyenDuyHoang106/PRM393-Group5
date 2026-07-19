import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Prisma } from '@prisma/client';

@Injectable()
export class TasksRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(data: Prisma.TaskUncheckedCreateInput) {
    return this.prisma.task.create({ data });
  }

  async findAll(projectId: string) {
    return this.prisma.task.findMany({
      where: { projectId },
      include: {
        assignee: { select: { id: true, name: true, email: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: string) {
    return this.prisma.task.findUnique({
      where: { id },
      include: {
        assignee: { select: { id: true, name: true, email: true } },
        project: { select: { id: true, name: true, ownerId: true } },
      },
    });
  }

  async findByAssignee(userId: string) {
    return this.prisma.task.findMany({
      where: { assignedTo: userId },
      include: {
        project: { select: { id: true, name: true } },
      },
      orderBy: { updatedAt: 'desc' },
    });
  }

  async update(id: string, data: Prisma.TaskUncheckedUpdateInput) {
    return this.prisma.task.update({ where: { id }, data });
  }

  async delete(id: string) {
    return this.prisma.task.delete({ where: { id } });
  }

  async countByStatus(projectId: string) {
    return this.prisma.task.groupBy({
      by: ['status'],
      where: { projectId },
      _count: { status: true },
    });
  }

  async countByPriority(projectId: string) {
    return this.prisma.task.groupBy({
      by: ['priority'],
      where: { projectId },
      _count: { priority: true },
    });
  }
}
