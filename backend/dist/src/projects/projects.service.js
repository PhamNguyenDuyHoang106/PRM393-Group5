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
exports.ProjectsService = void 0;
const common_1 = require("@nestjs/common");
const projects_repository_1 = require("./projects.repository");
const notifications_service_1 = require("../notifications/notifications.service");
const users_service_1 = require("../users/users.service");
let ProjectsService = class ProjectsService {
    projectsRepo;
    notificationsService;
    usersService;
    constructor(projectsRepo, notificationsService, usersService) {
        this.projectsRepo = projectsRepo;
        this.notificationsService = notificationsService;
        this.usersService = usersService;
    }
    async create(dto, ownerId) {
        const project = await this.projectsRepo.create({
            id: crypto.randomUUID(),
            name: dto.name,
            description: dto.description,
            owner: { connect: { id: ownerId } },
        });
        await this.notificationsService.create({
            userId: ownerId,
            title: 'Project Created',
            message: `Your project "${project.name}" has been created successfully.`,
            type: 'PROJECT_CREATED',
            createdBy: ownerId,
        });
        return project;
    }
    async findAll(userId) {
        return this.projectsRepo.findAll(userId);
    }
    async findOne(id, userId) {
        const project = await this.projectsRepo.findOne(id);
        if (!project)
            throw new common_1.NotFoundException(`Project ${id} not found.`);
        const isOwner = project.ownerId === userId;
        const isMember = await this.projectsRepo.isMember(id, userId);
        if (!isOwner && !isMember) {
            throw new common_1.ForbiddenException('You do not have access to this project.');
        }
        return project;
    }
    async update(id, dto, userId) {
        await this._requireOwner(id, userId);
        return this.projectsRepo.update(id, dto);
    }
    async delete(id, userId) {
        await this._requireOwner(id, userId);
        await this.projectsRepo.delete(id);
    }
    async addMember(projectId, dto, requesterId) {
        await this._requireOwner(projectId, requesterId);
        const user = await this.usersService.findByEmail(dto.email);
        const already = await this.projectsRepo.isMember(projectId, user.id);
        if (already)
            throw new common_1.ConflictException('User is already a member of this project.');
        const result = await this.projectsRepo.addMember(projectId, user.id);
        const project = await this.projectsRepo.findOne(projectId);
        await this.notificationsService.create({
            userId: user.id,
            title: 'Added to Project',
            message: `You have been added to the project "${project?.name}".`,
            type: 'PROJECT_CREATED',
            createdBy: requesterId,
        });
        return result;
    }
    async removeMember(projectId, userId, requesterId) {
        await this._requireOwner(projectId, requesterId);
        const isMember = await this.projectsRepo.isMember(projectId, userId);
        if (!isMember)
            throw new common_1.NotFoundException('User is not a member of this project.');
        return this.projectsRepo.removeMember(projectId, userId);
    }
    async listMembers(projectId, requesterId) {
        const isOwner = await this.projectsRepo.isOwner(projectId, requesterId);
        const isMember = await this.projectsRepo.isMember(projectId, requesterId);
        if (!isOwner && !isMember) {
            throw new common_1.ForbiddenException('You do not have access to this project.');
        }
        return this.projectsRepo.listMembers(projectId);
    }
    async _requireOwner(projectId, userId) {
        const project = await this.projectsRepo.findOne(projectId);
        if (!project)
            throw new common_1.NotFoundException(`Project ${projectId} not found.`);
        if (project.ownerId !== userId) {
            throw new common_1.ForbiddenException('Only the project owner can perform this action.');
        }
        return project;
    }
};
exports.ProjectsService = ProjectsService;
exports.ProjectsService = ProjectsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [projects_repository_1.ProjectsRepository,
        notifications_service_1.NotificationsService,
        users_service_1.UsersService])
], ProjectsService);
//# sourceMappingURL=projects.service.js.map