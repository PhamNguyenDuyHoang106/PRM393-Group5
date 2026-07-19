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
exports.ProjectsRepository = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let ProjectsRepository = class ProjectsRepository {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async create(data) {
        return this.prisma.project.create({ data });
    }
    async findAll(userId) {
        return this.prisma.project.findMany({
            where: {
                OR: [
                    { ownerId: userId },
                    { members: { some: { userId } } },
                ],
            },
            include: {
                owner: { select: { id: true, name: true, email: true, role: true } },
                members: {
                    include: {
                        user: { select: { id: true, name: true, email: true, role: true } },
                    },
                },
                _count: { select: { tasks: true } },
            },
            orderBy: { createdAt: 'desc' },
        });
    }
    async findOne(id) {
        return this.prisma.project.findUnique({
            where: { id },
            include: {
                owner: { select: { id: true, name: true, email: true, role: true } },
                members: {
                    include: {
                        user: { select: { id: true, name: true, email: true, role: true } },
                    },
                },
                tasks: {
                    orderBy: { createdAt: 'desc' },
                },
                _count: { select: { tasks: true, members: true } },
            },
        });
    }
    async update(id, data) {
        return this.prisma.project.update({ where: { id }, data });
    }
    async delete(id) {
        return this.prisma.project.delete({ where: { id } });
    }
    async addMember(projectId, userId) {
        return this.prisma.projectMember.create({
            data: { projectId, userId },
        });
    }
    async removeMember(projectId, userId) {
        return this.prisma.projectMember.delete({
            where: { projectId_userId: { projectId, userId } },
        });
    }
    async listMembers(projectId) {
        return this.prisma.projectMember.findMany({
            where: { projectId },
            include: {
                user: { select: { id: true, name: true, email: true, role: true } },
            },
        });
    }
    async isMember(projectId, userId) {
        const record = await this.prisma.projectMember.findUnique({
            where: { projectId_userId: { projectId, userId } },
        });
        return !!record;
    }
    async isOwner(projectId, userId) {
        const project = await this.prisma.project.findUnique({
            where: { id: projectId },
            select: { ownerId: true },
        });
        return project?.ownerId === userId;
    }
};
exports.ProjectsRepository = ProjectsRepository;
exports.ProjectsRepository = ProjectsRepository = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], ProjectsRepository);
//# sourceMappingURL=projects.repository.js.map