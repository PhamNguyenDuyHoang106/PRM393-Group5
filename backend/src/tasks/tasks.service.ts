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
    const updated = await this.tasksRepo.update(id, {
      ...dto,
      dueDate: dto.dueDate ? new Date(dto.dueDate) : undefined,
    });

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

    const updated = await this.tasksRepo.update(id, { status: dto.status });

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
}
