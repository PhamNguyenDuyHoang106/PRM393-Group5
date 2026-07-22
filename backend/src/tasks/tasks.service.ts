import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { TasksRepository } from './tasks.repository';
import { ProjectsRepository } from '../projects/projects.repository';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateTaskDto, UpdateTaskDto, UpdateTaskStatusDto } from './dto/task.dto';

@Injectable()
export class TasksService {
  constructor(
    private readonly tasksRepo: TasksRepository,
    private readonly projectsRepo: ProjectsRepository,
    private readonly notificationsService: NotificationsService,
  ) {}

  async create(projectId: string, dto: CreateTaskDto, requesterId: string) {
    const project = await this.projectsRepo.findOne(projectId);
    if (!project) throw new NotFoundException(`Project ${projectId} not found.`);
    if (project.ownerId !== requesterId) {
      throw new ForbiddenException('Only project owners can create tasks.');
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

    // Notify assignee
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

  async findAll(projectId: string, requesterId: string) {
    const project = await this.projectsRepo.findOne(projectId);
    if (!project) throw new NotFoundException(`Project ${projectId} not found.`);

    const isOwner = project.ownerId === requesterId;
    const isMember = await this.projectsRepo.isMember(projectId, requesterId);
    if (!isOwner && !isMember) {
      throw new ForbiddenException('You do not have access to this project.');
    }

    return this.tasksRepo.findAll(projectId);
  }

  async findOne(id: string, requesterId: string) {
    const task = await this.tasksRepo.findOne(id);
    if (!task) throw new NotFoundException(`Task ${id} not found.`);

    const isOwner = task.project.ownerId === requesterId;
    const isMember = await this.projectsRepo.isMember(task.projectId, requesterId);
    if (!isOwner && !isMember) {
      throw new ForbiddenException('You do not have access to this task.');
    }

    return task;
  }

  async findMyTasks(userId: string, role: string) {
    // Members only see tasks assigned to them. Managers see every task across
    // the projects they own or belong to, mirroring the dashboard aggregation
    // in StatisticsService.getDashboard — otherwise a manager who assigns work
    // to teammates (not themselves) would see an empty "My Tasks" list.
    if (role?.toLowerCase() !== 'manager') {
      return this.tasksRepo.findByAssignee(userId);
    }

    const projects = await this.projectsRepo.findAll(userId);
    const projectIds = projects.map((project) => project.id);
    if (projectIds.length === 0) return [];

    return this.tasksRepo.findByProjectIds(projectIds);
  }

  async update(id: string, dto: UpdateTaskDto, requesterId: string, requesterRole: string) {
    const task = await this.tasksRepo.findOne(id);
    if (!task) throw new NotFoundException(`Task ${id} not found.`);

    const isOwner = task.project.ownerId === requesterId;

    // Members can only update their own tasks' status
    if (requesterRole !== 'manager') {
      if (task.assignedTo !== requesterId) {
        throw new ForbiddenException('Members can only update tasks assigned to them.');
      }
      // Members cannot change anything except status
      const allowedKeys = ['status'];
      const attempted = Object.keys(dto).filter(k => !allowedKeys.includes(k));
      if (attempted.length > 0) {
        throw new ForbiddenException(`Members may only update: status. Attempted: ${attempted.join(', ')}`);
      }
    } else if (!isOwner) {
      throw new ForbiddenException('Only the project owner can fully update tasks.');
    }

    const previousAssignee = task.assignedTo;
    const previousStatus = task.status;
    const previousPriority = task.priority;

    const updated = await this.tasksRepo.update(id, {
      ...dto,
      dueDate: dto.dueDate ? new Date(dto.dueDate) : undefined,
    });

    // Audit logs for specific changes
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

    // Notify new assignee if assignment changed
    if (dto.assignedTo && dto.assignedTo !== previousAssignee) {
      await this.notificationsService.create({
        userId: dto.assignedTo,
        title: 'Task Assigned',
        message: `You have been assigned to task "${task.title}".`,
        type: 'TASK_ASSIGNED',
        createdBy: requesterId,
      });
    }

    // Notify project owner when status changes to DONE
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

  async updateStatus(id: string, dto: UpdateTaskStatusDto, requesterId: string) {
    const task = await this.tasksRepo.findOne(id);
    if (!task) throw new NotFoundException(`Task ${id} not found.`);

    if (task.assignedTo !== requesterId && task.project.ownerId !== requesterId) {
      throw new ForbiddenException('You can only update status for tasks assigned to you.');
    }

    const previousStatus = task.status;
    const updated = await this.tasksRepo.update(id, { status: dto.status });

    if (dto.status !== previousStatus) {
      await this._createAuditLog(requesterId, 'STATUS_CHANGED', 'Task', id, previousStatus, dto.status);
    }

    // Notify owner when task is completed
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

  async delete(id: string, requesterId: string) {
    const task = await this.tasksRepo.findOne(id);
    if (!task) throw new NotFoundException(`Task ${id} not found.`);
    if (task.project.ownerId !== requesterId) {
      throw new ForbiddenException('Only the project owner can delete tasks.');
    }
    await this.tasksRepo.delete(id);
  }

  // ── Checklist Service Methods ────────────────────────────────────────────
  async createChecklist(taskId: string, title: string, requesterId: string, customId?: string) {
    const task = await this.tasksRepo.findOne(taskId);
    if (!task) throw new NotFoundException(`Task ${taskId} not found.`);

    await this._requireProjectAccess(task.projectId, requesterId);

    const checklist = await this.tasksRepo.createChecklist({
      id: customId || crypto.randomUUID(),
      taskId,
      title: title.trim(),
      isDone: false,
    });

    return checklist;
  }

  async findChecklists(taskId: string, requesterId: string) {
    const task = await this.tasksRepo.findOne(taskId);
    if (!task) throw new NotFoundException(`Task ${taskId} not found.`);

    await this._requireProjectAccess(task.projectId, requesterId);
    return this.tasksRepo.findChecklists(taskId);
  }

  async updateChecklist(id: string, dto: { title?: string; isDone?: boolean }, requesterId: string) {
    const checklist = await this.tasksRepo.findChecklistOne(id);
    if (!checklist) throw new NotFoundException(`Checklist ${id} not found.`);

    await this._requireProjectAccess(checklist.task.projectId, requesterId);

    const previousIsDone = checklist.isDone;
    const updated = await this.tasksRepo.updateChecklist(id, dto);

    if (dto.isDone === true && previousIsDone === false) {
      await this._createAuditLog(
        requesterId,
        'CHECKLIST_COMPLETED',
        'Task',
        checklist.taskId,
        null,
        `Completed checklist item "${updated.title}"`,
      );
    }

    return updated;
  }

  async deleteChecklist(id: string, requesterId: string) {
    const checklist = await this.tasksRepo.findChecklistOne(id);
    if (!checklist) throw new NotFoundException(`Checklist ${id} not found.`);

    await this._requireProjectAccess(checklist.task.projectId, requesterId);
    await this.tasksRepo.deleteChecklist(id);
  }

  // ── Comment Service Methods ──────────────────────────────────────────────
  async createComment(taskId: string, content: string, requesterId: string, customId?: string) {
    const task = await this.tasksRepo.findOne(taskId);
    if (!task) throw new NotFoundException(`Task ${taskId} not found.`);

    await this._requireProjectAccess(task.projectId, requesterId);

    const trimmed = content.trim();
    if (!trimmed) {
      throw new ForbiddenException('Comment content cannot be empty or whitespace only.');
    }

    const comment = await this.tasksRepo.createComment({
      id: customId || crypto.randomUUID(),
      taskId,
      userId: requesterId,
      content: trimmed,
    });

    await this._createAuditLog(requesterId, 'COMMENT_ADDED', 'Task', taskId, null, trimmed);

    // Notify task assignee or owner
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

  async findComments(taskId: string, requesterId: string) {
    const task = await this.tasksRepo.findOne(taskId);
    if (!task) throw new NotFoundException(`Task ${taskId} not found.`);

    await this._requireProjectAccess(task.projectId, requesterId);
    return this.tasksRepo.findComments(taskId);
  }

  async deleteComment(id: string, requesterId: string, requesterRole: string) {
    const comment = await this.tasksRepo.findCommentOne(id);
    if (!comment) throw new NotFoundException(`Comment ${id} not found.`);

    const isAuthor = comment.userId === requesterId;
    const isOwner = comment.task.project.ownerId === requesterId;
    const isManager = requesterRole === 'manager';

    if (!isAuthor && !isOwner && !isManager) {
      throw new ForbiddenException('Only the author or project manager can delete this comment.');
    }

    await this.tasksRepo.deleteComment(id);
  }

  // ── Activity History Service Methods ─────────────────────────────────────
  async findActivities(taskId: string, requesterId: string) {
    const task = await this.tasksRepo.findOne(taskId);
    if (!task) throw new NotFoundException(`Task ${taskId} not found.`);

    await this._requireProjectAccess(task.projectId, requesterId);
    return this.tasksRepo.findAuditLogs(taskId);
  }

  // ── Internal Helpers ─────────────────────────────────────────────────────
  private async _requireProjectAccess(projectId: string, userId: string) {
    const project = await this.projectsRepo.findOne(projectId);
    if (!project) throw new NotFoundException(`Project ${projectId} not found.`);

    const isOwner = project.ownerId === userId;
    const isMember = await this.projectsRepo.isMember(projectId, userId);
    if (!isOwner && !isMember) {
      throw new ForbiddenException('You do not have access to this project.');
    }
  }

  private async _createAuditLog(
    userId: string,
    action: string,
    entity: string,
    entityId: string,
    oldData: any,
    newData: any,
  ) {
    try {
      await this.tasksRepo.createAuditLog({
        userId,
        action,
        entity,
        entityId,
        oldData: oldData ? JSON.stringify(oldData) : null,
        newData: newData ? JSON.stringify(newData) : null,
      });
    } catch (_) {}
  }
}
