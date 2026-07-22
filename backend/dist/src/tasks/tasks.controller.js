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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TasksController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const tasks_service_1 = require("./tasks.service");
const task_dto_1 = require("./dto/task.dto");
const checklist_dto_1 = require("./dto/checklist.dto");
const comment_dto_1 = require("./dto/comment.dto");
const auth_guard_1 = require("../guards/auth.guard");
const user_decorator_1 = require("../decorators/user.decorator");
let TasksController = class TasksController {
    tasksService;
    constructor(tasksService) {
        this.tasksService = tasksService;
    }
    async create(projectId, dto, user) {
        return this.tasksService.create(projectId, dto, user.id);
    }
    async findAll(projectId, user) {
        return this.tasksService.findAll(projectId, user.id);
    }
    async findMyTasks(user) {
        return this.tasksService.findMyTasks(user.id, user.role);
    }
    async findOne(id, user) {
        return this.tasksService.findOne(id, user.id);
    }
    async update(id, dto, user) {
        return this.tasksService.update(id, dto, user.id, user.role);
    }
    async updateStatus(id, dto, user) {
        return this.tasksService.updateStatus(id, dto, user.id);
    }
    async delete(id, user) {
        await this.tasksService.delete(id, user.id);
    }
    async findChecklists(taskId, user) {
        return this.tasksService.findChecklists(taskId, user.id);
    }
    async createChecklist(taskId, dto, user) {
        return this.tasksService.createChecklist(taskId, dto.title, user.id, dto.id);
    }
    async updateChecklist(id, dto, user) {
        return this.tasksService.updateChecklist(id, dto, user.id);
    }
    async deleteChecklist(id, user) {
        await this.tasksService.deleteChecklist(id, user.id);
    }
    async findComments(taskId, user) {
        return this.tasksService.findComments(taskId, user.id);
    }
    async createComment(taskId, dto, user) {
        return this.tasksService.createComment(taskId, dto.content, user.id, dto.id);
    }
    async deleteComment(id, user) {
        await this.tasksService.deleteComment(id, user.id, user.role);
    }
    async findActivities(taskId, user) {
        return this.tasksService.findActivities(taskId, user.id);
    }
};
exports.TasksController = TasksController;
__decorate([
    (0, swagger_1.ApiOperation)({ summary: 'Create a task in a project (Project owner only)' }),
    (0, swagger_1.ApiResponse)({ status: 201, description: 'Task created.' }),
    (0, common_1.Post)('projects/:projectId/tasks'),
    __param(0, (0, common_1.Param)('projectId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, task_dto_1.CreateTaskDto, Object]),
    __metadata("design:returntype", Promise)
], TasksController.prototype, "create", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: 'List all tasks in a project' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Task list returned.' }),
    (0, common_1.Get)('projects/:projectId/tasks'),
    __param(0, (0, common_1.Param)('projectId')),
    __param(1, (0, user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], TasksController.prototype, "findAll", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: 'Get all tasks assigned to the current user' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'My tasks returned.' }),
    (0, common_1.Get)('tasks/my'),
    __param(0, (0, user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], TasksController.prototype, "findMyTasks", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: 'Get a task by ID' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Task returned.' }),
    (0, common_1.Get)('tasks/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], TasksController.prototype, "findOne", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: 'Update a task fully (Project owner only)' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Task updated.' }),
    (0, common_1.Put)('tasks/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, task_dto_1.UpdateTaskDto, Object]),
    __metadata("design:returntype", Promise)
], TasksController.prototype, "update", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: 'Update task status (Assigned member or owner)' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Task status updated.' }),
    (0, common_1.Patch)('tasks/:id/status'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, task_dto_1.UpdateTaskStatusDto, Object]),
    __metadata("design:returntype", Promise)
], TasksController.prototype, "updateStatus", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: 'Delete a task (Project owner only)' }),
    (0, swagger_1.ApiResponse)({ status: 204, description: 'Task deleted.' }),
    (0, common_1.HttpCode)(common_1.HttpStatus.NO_CONTENT),
    (0, common_1.Delete)('tasks/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], TasksController.prototype, "delete", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: 'List checklist items for a task' }),
    (0, common_1.Get)('tasks/:taskId/checklists'),
    __param(0, (0, common_1.Param)('taskId')),
    __param(1, (0, user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], TasksController.prototype, "findChecklists", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: 'Add a checklist item to a task' }),
    (0, common_1.Post)('tasks/:taskId/checklists'),
    __param(0, (0, common_1.Param)('taskId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, checklist_dto_1.CreateChecklistDto, Object]),
    __metadata("design:returntype", Promise)
], TasksController.prototype, "createChecklist", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: 'Update/Toggle a checklist item' }),
    (0, common_1.Patch)('tasks/checklists/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, checklist_dto_1.UpdateChecklistDto, Object]),
    __metadata("design:returntype", Promise)
], TasksController.prototype, "updateChecklist", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: 'Delete a checklist item' }),
    (0, common_1.HttpCode)(common_1.HttpStatus.NO_CONTENT),
    (0, common_1.Delete)('tasks/checklists/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], TasksController.prototype, "deleteChecklist", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: 'List comments for a task' }),
    (0, common_1.Get)('tasks/:taskId/comments'),
    __param(0, (0, common_1.Param)('taskId')),
    __param(1, (0, user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], TasksController.prototype, "findComments", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: 'Add a comment to a task' }),
    (0, common_1.Post)('tasks/:taskId/comments'),
    __param(0, (0, common_1.Param)('taskId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, comment_dto_1.CreateCommentDto, Object]),
    __metadata("design:returntype", Promise)
], TasksController.prototype, "createComment", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: 'Delete a comment (Author or Manager only)' }),
    (0, common_1.HttpCode)(common_1.HttpStatus.NO_CONTENT),
    (0, common_1.Delete)('tasks/comments/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], TasksController.prototype, "deleteComment", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: 'Get activity history (AuditLog) for a task' }),
    (0, common_1.Get)('tasks/:taskId/activities'),
    __param(0, (0, common_1.Param)('taskId')),
    __param(1, (0, user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], TasksController.prototype, "findActivities", null);
exports.TasksController = TasksController = __decorate([
    (0, swagger_1.ApiTags)('Tasks'),
    (0, swagger_1.ApiBearerAuth)(),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    (0, common_1.Controller)(),
    __metadata("design:paramtypes", [tasks_service_1.TasksService])
], TasksController);
//# sourceMappingURL=tasks.controller.js.map