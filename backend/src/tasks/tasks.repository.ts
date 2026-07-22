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

  // ── Checklist Repository Methods ─────────────────────────────────────────
  async createChecklist(data: Prisma.TaskChecklistUncheckedCreateInput) {
    return this.prisma.taskChecklist.create({ data });
  }

  async findChecklists(taskId: string) {
    return this.prisma.taskChecklist.findMany({
      where: { taskId },
      orderBy: { createdAt: 'asc' },
    });
  }

  async findChecklistOne(id: string) {
    return this.prisma.taskChecklist.findUnique({
      where: { id },
      include: { task: { include: { project: true } } },
    });
  }

  async updateChecklist(id: string, data: Prisma.TaskChecklistUncheckedUpdateInput) {
    return this.prisma.taskChecklist.update({ where: { id }, data });
  }

  async deleteChecklist(id: string) {
    return this.prisma.taskChecklist.delete({ where: { id } });
  }

  // ── Comment Repository Methods ───────────────────────────────────────────
  async createComment(data: Prisma.TaskCommentUncheckedCreateInput) {
    return this.prisma.taskComment.create({
      data,
      include: {
        user: { select: { id: true, name: true, avatarUrl: true } },
      },
    });
  }

  async findComments(taskId: string) {
    return this.prisma.taskComment.findMany({
      where: { taskId },
      include: {
        user: { select: { id: true, name: true, avatarUrl: true } },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async findCommentOne(id: string) {
    return this.prisma.taskComment.findUnique({
      where: { id },
      include: { task: { include: { project: true } } },
    });
  }

  async deleteComment(id: string) {
    return this.prisma.taskComment.delete({ where: { id } });
  }

  // ── AuditLog Repository Methods ──────────────────────────────────────────
  async createAuditLog(data: Prisma.AuditLogUncheckedCreateInput) {
    return this.prisma.auditLog.create({ data });
  }

  async findAuditLogs(taskId: string) {
    return this.prisma.auditLog.findMany({
      where: { entity: 'Task', entityId: taskId },
      include: {
        user: { select: { id: true, name: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
