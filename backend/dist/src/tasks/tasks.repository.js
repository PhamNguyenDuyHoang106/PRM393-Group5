"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TasksRepository = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let TasksRepository = class TasksRepository {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async create(data) {
        return this.prisma.task.create({ data });
    }
    async findAll(projectId) {
        return this.prisma.task.findMany({
            where: { projectId },
            include: {
                assignee: { select: { id: true, name: true, email: true } },
            },
            orderBy: { createdAt: 'desc' },
        });
    }
    async findOne(id) {
        return this.prisma.task.findUnique({
            where: { id },
            include: {
                assignee: { select: { id: true, name: true, email: true } },
                project: { select: { id: true, name: true, ownerId: true } },
            },
        });
    }
    async findByAssignee(userId) {
        return this.prisma.task.findMany({
            where: { assignedTo: userId },
            include: {
                project: { select: { id: true, name: true } },
            },
            orderBy: { updatedAt: 'desc' },
        });
    }
    async findByProjectIds(projectIds) {
        return this.prisma.task.findMany({
            where: { projectId: { in: projectIds } },
            include: {
                assignee: { select: { id: true, name: true, email: true } },
                project: { select: { id: true, name: true } },
            },
            orderBy: { updatedAt: 'desc' },
        });
    }
    async update(id, data) {
        return this.prisma.task.update({ where: { id }, data });
    }
    async delete(id) {
        return this.prisma.task.delete({ where: { id } });
    }
    async countByStatus(projectId) {
        return this.prisma.task.groupBy({
            by: ['status'],
            where: { projectId },
            _count: { status: true },
        });
    }
    async countByPriority(projectId) {
        return this.prisma.task.groupBy({
            by: ['priority'],
            where: { projectId },
            _count: { priority: true },
        });
    }
    async createChecklist(data) {
        return this.prisma.taskChecklist.create({ data });
    }
    async findChecklists(taskId) {
        return this.prisma.taskChecklist.findMany({
            where: { taskId },
            orderBy: { createdAt: 'asc' },
        });
    }
    async findChecklistOne(id) {
        return this.prisma.taskChecklist.findUnique({
            where: { id },
            include: { task: { include: { project: true } } },
        });
    }
    async updateChecklist(id, data) {
        return this.prisma.taskChecklist.update({ where: { id }, data });
    }
    async deleteChecklist(id) {
        return this.prisma.taskChecklist.delete({ where: { id } });
    }
    async createComment(data) {
        return this.prisma.taskComment.create({
            data,
            include: {
                user: { select: { id: true, name: true, avatarUrl: true } },
            },
        });
    }
    async findComments(taskId) {
        return this.prisma.taskComment.findMany({
            where: { taskId },
            include: {
                user: { select: { id: true, name: true, avatarUrl: true } },
            },
            orderBy: { createdAt: 'asc' },
        });
    }
    async findCommentOne(id) {
        return this.prisma.taskComment.findUnique({
            where: { id },
            include: { task: { include: { project: true } } },
        });
    }
    async deleteComment(id) {
        return this.prisma.taskComment.delete({ where: { id } });
    }
    async createAuditLog(data) {
        return this.prisma.auditLog.create({ data });
    }
    async findAuditLogs(taskId) {
        return this.prisma.auditLog.findMany({
            where: { entity: 'Task', entityId: taskId },
            include: {
                user: { select: { id: true, name: true } },
            },
            orderBy: { createdAt: 'desc' },
        });
    }
};
exports.TasksRepository = TasksRepository;
exports.TasksRepository = TasksRepository = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], TasksRepository);
//# sourceMappingURL=tasks.repository.js.map