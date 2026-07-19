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
exports.StatisticsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let StatisticsService = class StatisticsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getDashboard(userId, role) {
        const projectFilter = role === 'manager'
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
        const [tasksByStatus, tasksByPriority, myTaskCount, totalTasks] = await Promise.all([
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
        const projectStats = await this._getProjectStats(projectIds);
        return {
            totalProjects: projectIds.length,
            totalTasks,
            myTasks: myTaskCount,
            completedTasks: doneCount,
            overallCompletionRate: totalTasks > 0 ? Math.round((doneCount / totalTasks) * 100) : 0,
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
    async getProjectStats(projectId) {
        const stats = await this._getProjectStats([projectId]);
        return stats[0] ?? this._emptyProjectStats(projectId);
    }
    async _getProjectStats(projectIds) {
        const projects = await this.prisma.project.findMany({
            where: { id: { in: projectIds } },
            select: { id: true, name: true },
        });
        const results = [];
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
    _toMap(groups, key) {
        return groups.reduce((acc, g) => {
            const value = g[key];
            acc[value] = g._count[key];
            return acc;
        }, {});
    }
    _emptyStats() {
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
    _emptyProjectStats(projectId) {
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
};
exports.StatisticsService = StatisticsService;
exports.StatisticsService = StatisticsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], StatisticsService);
//# sourceMappingURL=statistics.service.js.map