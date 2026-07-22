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
exports.TasksService = void 0;
const common_1 = require("@nestjs/common");
const tasks_repository_1 = require("./tasks.repository");
const projects_repository_1 = require("../projects/projects.repository");
const notifications_service_1 = require("../notifications/notifications.service");
let TasksService = class TasksService {
    tasksRepo;
    projectsRepo;
    notificationsService;
    constructor(tasksRepo, projectsRepo, notificationsService) {
        this.tasksRepo = tasksRepo;
        this.projectsRepo = projectsRepo;
        this.notificationsService = notificationsService;
    }
    async create(projectId, dto, requesterId) {
        const project = await this.projectsRepo.findOne(projectId);
        if (!project)
            throw new common_1.NotFoundException(`Project ${projectId} not found.`);
        if (project.ownerId !== requesterId) {
            throw new common_1.ForbiddenException('Only project owners can create tasks.');
        }
        const task = await this.tasksRepo.create({
            id: dto.id || crypto.randomUUID(),
            projectId,
            title: dto.title,
            description: dto.description,
            priority: dto.priority,
            status: 'TODO',
            assignedTo: dto.assignedTo ?? null,
            dueDate: dto.dueDate ? new Date(dto.dueDate) : null,
        });
        if (dto.assignedTo) {
            await this.notificationsService.create({
                userId: dto.assignedTo,
                title: 'Task Assigned',
                message: `You have been assigned to task "${task.title}" in project "${project.name}".`,
                type: 'TASK_ASSIGNED',
                createdBy: requesterId,
            });
        }
        await this._createAuditLog(requesterId, 'TASK_CREATED', 'Task', task.id, null, {
            title: task.title,
            priority: task.priority,
            status: task.status,
        });
        return task;
    }
    async findAll(projectId, requesterId) {
        const project = await this.projectsRepo.findOne(projectId);
        if (!project)
            throw new common_1.NotFoundException(`Project ${projectId} not found.`);
        const isOwner = project.ownerId === requesterId;
        const isMember = await this.projectsRepo.isMember(projectId, requesterId);
        if (!isOwner && !isMember) {
            throw new common_1.ForbiddenException('You do not have access to this project.');
        }
        return this.tasksRepo.findAll(projectId);
    }
    async findOne(id, requesterId) {
        const task = await this.tasksRepo.findOne(id);
        if (!task)
            throw new common_1.NotFoundException(`Task ${id} not found.`);
        const isOwner = task.project.ownerId === requesterId;
        const isMember = await this.projectsRepo.isMember(task.projectId, requesterId);
        if (!isOwner && !isMember) {
            throw new common_1.ForbiddenException('You do not have access to this task.');
        }
        return task;
    }
    async findMyTasks(userId, role) {
        if (role?.toLowerCase() !== 'manager') {
            return this.tasksRepo.findByAssignee(userId);
        }
        const projects = await this.projectsRepo.findAll(userId);
        const projectIds = projects.map((project) => project.id);
        if (projectIds.length === 0)
            return [];
        return this.tasksRepo.findByProjectIds(projectIds);
    }
    async update(id, dto, requesterId, requesterRole) {
        const task = await this.tasksRepo.findOne(id);
        if (!task)
            throw new common_1.NotFoundException(`Task ${id} not found.`);
        const isOwner = task.project.ownerId === requesterId;
        if (requesterRole !== 'manager') {
            if (task.assignedTo !== requesterId) {
                throw new common_1.ForbiddenException('Members can only update tasks assigned to them.');
            }
            const allowedKeys = ['status'];
            const attempted = Object.keys(dto).filter(k => !allowedKeys.includes(k));
            if (attempted.length > 0) {
                throw new common_1.ForbiddenException(`Members may only update: status. Attempted: ${attempted.join(', ')}`);
            }
        }
        else if (!isOwner) {
            throw new common_1.ForbiddenException('Only the project owner can fully update tasks.');
        }
        const previousAssignee = task.assignedTo;
        const previousStatus = task.status;
        const previousPriority = task.priority;
        const updated = await this.tasksRepo.update(id, {
            ...dto,
            dueDate: dto.dueDate ? new Date(dto.dueDate) : undefined,
        });
        if (dto.status && dto.status !== previousStatus) {
            await this._createAuditLog(requesterId, 'STATUS_CHANGED', 'Task', id, previousStatus, dto.status);
        }
        if (dto.priority && dto.priority !== previousPriority) {
            await this._createAuditLog(requesterId, 'PRIORITY_CHANGED', 'Task', id, previousPriority, dto.priority);
        }
        if (dto.assignedTo && dto.assignedTo !== previousAssignee) {
            await this._createAuditLog(requesterId, 'ASSIGNEE_CHANGED', 'Task', id, previousAssignee, dto.assignedTo);
        }
        await this._createAuditLog(requesterId, 'TASK_UPDATED', 'Task', id, null, updated.title);
        if (dto.assignedTo && dto.assignedTo !== previousAssignee) {
            await this.notificationsService.create({
                userId: dto.assignedTo,
                title: 'Task Assigned',
                message: `You have been assigned to task "${task.title}".`,
                type: 'TASK_ASSIGNED',
                createdBy: requesterId,
            });
        }
        if (dto.status === 'DONE' && task.project.ownerId !== requesterId) {
            await this.notificationsService.create({
                userId: task.project.ownerId,
                title: 'Task Completed',
                message: `Task "${task.title}" has been marked as completed.`,
                type: 'TASK_UPDATED',
                createdBy: requesterId,
            });
        }
        return updated;
    }
    async updateStatus(id, dto, requesterId) {
        const task = await this.tasksRepo.findOne(id);
        if (!task)
            throw new common_1.NotFoundException(`Task ${id} not found.`);
        if (task.assignedTo !== requesterId && task.project.ownerId !== requesterId) {
            throw new common_1.ForbiddenException('You can only update status for tasks assigned to you.');
        }
        const previousStatus = task.status;
        const updated = await this.tasksRepo.update(id, { status: dto.status });
        if (dto.status !== previousStatus) {
            await this._createAuditLog(requesterId, 'STATUS_CHANGED', 'Task', id, previousStatus, dto.status);
        }
        if (dto.status === 'DONE' && task.project.ownerId !== requesterId) {
            await this.notificationsService.create({
                userId: task.project.ownerId,
                title: 'Task Completed',
                message: `Task "${task.title}" has been marked as completed.`,
                type: 'TASK_UPDATED',
                createdBy: requesterId,
            });
        }
        return updated;
    }
    async delete(id, requesterId) {
        const task = await this.tasksRepo.findOne(id);
        if (!task)
            throw new common_1.NotFoundException(`Task ${id} not found.`);
        if (task.project.ownerId !== requesterId) {
            throw new common_1.ForbiddenException('Only the project owner can delete tasks.');
        }
        await this.tasksRepo.delete(id);
    }
    async createChecklist(taskId, title, requesterId, customId) {
        const task = await this.tasksRepo.findOne(taskId);
        if (!task)
            throw new common_1.NotFoundException(`Task ${taskId} not found.`);
        await this._requireProjectAccess(task.projectId, requesterId);
        const checklist = await this.tasksRepo.createChecklist({
            id: customId || crypto.randomUUID(),
            taskId,
            title: title.trim(),
            isDone: false,
        });
        return checklist;
    }
    async findChecklists(taskId, requesterId) {
        const task = await this.tasksRepo.findOne(taskId);
        if (!task)
            throw new common_1.NotFoundException(`Task ${taskId} not found.`);
        await this._requireProjectAccess(task.projectId, requesterId);
        return this.tasksRepo.findChecklists(taskId);
    }
    async updateChecklist(id, dto, requesterId) {
        const checklist = await this.tasksRepo.findChecklistOne(id);
        if (!checklist)
            throw new common_1.NotFoundException(`Checklist ${id} not found.`);
        await this._requireProjectAccess(checklist.task.projectId, requesterId);
        const previousIsDone = checklist.isDone;
        const updated = await this.tasksRepo.updateChecklist(id, dto);
        if (dto.isDone === true && previousIsDone === false) {
            await this._createAuditLog(requesterId, 'CHECKLIST_COMPLETED', 'Task', checklist.taskId, null, `Completed checklist item "${updated.title}"`);
        }
        return updated;
    }
    async deleteChecklist(id, requesterId) {
        const checklist = await this.tasksRepo.findChecklistOne(id);
        if (!checklist)
            throw new common_1.NotFoundException(`Checklist ${id} not found.`);
        await this._requireProjectAccess(checklist.task.projectId, requesterId);
        await this.tasksRepo.deleteChecklist(id);
    }
    async createComment(taskId, content, requesterId, customId) {
        const task = await this.tasksRepo.findOne(taskId);
        if (!task)
            throw new common_1.NotFoundException(`Task ${taskId} not found.`);
        await this._requireProjectAccess(task.projectId, requesterId);
        const trimmed = content.trim();
        if (!trimmed) {
            throw new common_1.ForbiddenException('Comment content cannot be empty or whitespace only.');
        }
        const comment = await this.tasksRepo.createComment({
            id: customId || crypto.randomUUID(),
            taskId,
            userId: requesterId,
            content: trimmed,
        });
        await this._createAuditLog(requesterId, 'COMMENT_ADDED', 'Task', taskId, null, trimmed);
        const notifyTarget = task.assignedTo && task.assignedTo !== requesterId
            ? task.assignedTo
            : (task.project.ownerId !== requesterId ? task.project.ownerId : null);
        if (notifyTarget) {
            await this.notificationsService.create({
                userId: notifyTarget,
                title: 'New Comment',
                message: `New comment on task "${task.title}": ${trimmed.substring(0, 50)}...`,
                type: 'TASK_COMMENT',
                createdBy: requesterId,
            });
        }
        return comment;
    }
    async findComments(taskId, requesterId) {
        const task = await this.tasksRepo.findOne(taskId);
        if (!task)
            throw new common_1.NotFoundException(`Task ${taskId} not found.`);
        await this._requireProjectAccess(task.projectId, requesterId);
        return this.tasksRepo.findComments(taskId);
    }
    async deleteComment(id, requesterId, requesterRole) {
        const comment = await this.tasksRepo.findCommentOne(id);
        if (!comment)
            throw new common_1.NotFoundException(`Comment ${id} not found.`);
        const isAuthor = comment.userId === requesterId;
        const isOwner = comment.task.project.ownerId === requesterId;
        const isManager = requesterRole === 'manager';
        if (!isAuthor && !isOwner && !isManager) {
            throw new common_1.ForbiddenException('Only the author or project manager can delete this comment.');
        }
        await this.tasksRepo.deleteComment(id);
    }
    async findActivities(taskId, requesterId) {
        const task = await this.tasksRepo.findOne(taskId);
        if (!task)
            throw new common_1.NotFoundException(`Task ${taskId} not found.`);
        await this._requireProjectAccess(task.projectId, requesterId);
        return this.tasksRepo.findAuditLogs(taskId);
    }
    async _requireProjectAccess(projectId, userId) {
        const project = await this.projectsRepo.findOne(projectId);
        if (!project)
            throw new common_1.NotFoundException(`Project ${projectId} not found.`);
        const isOwner = project.ownerId === userId;
        const isMember = await this.projectsRepo.isMember(projectId, userId);
        if (!isOwner && !isMember) {
            throw new common_1.ForbiddenException('You do not have access to this project.');
        }
    }
    async _createAuditLog(userId, action, entity, entityId, oldData, newData) {
        try {
            await this.tasksRepo.createAuditLog({
                userId,
                action,
                entity,
                entityId,
                oldData: oldData ? JSON.stringify(oldData) : null,
                newData: newData ? JSON.stringify(newData) : null,
            });
        }
        catch (_) { }
    }
};
exports.TasksService = TasksService;
exports.TasksService = TasksService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [tasks_repository_1.TasksRepository,
        projects_repository_1.ProjectsRepository,
        notifications_service_1.NotificationsService])
], TasksService);
//# sourceMappingURL=tasks.service.js.map