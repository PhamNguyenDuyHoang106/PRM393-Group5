import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  ConflictException,
} from '@nestjs/common';
import { ProjectsRepository } from './projects.repository';
import { CreateProjectDto, UpdateProjectDto, AddMemberDto } from './dto/project.dto';
import { NotificationsService } from '../notifications/notifications.service';
import { UsersService } from '../users/users.service';

@Injectable()
export class ProjectsService {
  constructor(
    private readonly projectsRepo: ProjectsRepository,
    private readonly notificationsService: NotificationsService,
    private readonly usersService: UsersService,
  ) {}

  async create(dto: CreateProjectDto, ownerId: string) {
    const project = await this.projectsRepo.create({
      id: dto.id || crypto.randomUUID(),
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

  async findAll(userId: string) {
    return this.projectsRepo.findAll(userId);
  }

  async findOne(id: string, userId: string) {
    const project = await this.projectsRepo.findOne(id);
    if (!project) throw new NotFoundException(`Project ${id} not found.`);

    const isOwner = project.ownerId === userId;
    const isMember = await this.projectsRepo.isMember(id, userId);
    if (!isOwner && !isMember) {
      throw new ForbiddenException('You do not have access to this project.');
    }

    return project;
  }

  async update(id: string, dto: UpdateProjectDto, userId: string) {
    await this._requireOwner(id, userId);
    return this.projectsRepo.update(id, dto);
  }

  async delete(id: string, userId: string) {
    await this._requireOwner(id, userId);
    await this.projectsRepo.delete(id);
  }

  async addMember(projectId: string, dto: AddMemberDto, requesterId: string) {
    await this._requireOwner(projectId, requesterId);

    const user = await this.usersService.findByEmail(dto.email);

    const already = await this.projectsRepo.isMember(projectId, user.id);
    if (already) throw new ConflictException('User is already a member of this project.');

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

  async removeMember(projectId: string, userId: string, requesterId: string) {
    await this._requireOwner(projectId, requesterId);

    const isMember = await this.projectsRepo.isMember(projectId, userId);
    if (!isMember) throw new NotFoundException('User is not a member of this project.');

    return this.projectsRepo.removeMember(projectId, userId);
  }

  async listMembers(projectId: string, requesterId: string) {
    const isOwner = await this.projectsRepo.isOwner(projectId, requesterId);
    const isMember = await this.projectsRepo.isMember(projectId, requesterId);
    if (!isOwner && !isMember) {
      throw new ForbiddenException('You do not have access to this project.');
    }
    return this.projectsRepo.listMembers(projectId);
  }

  private async _requireOwner(projectId: string, userId: string) {
    const project = await this.projectsRepo.findOne(projectId);
    if (!project) throw new NotFoundException(`Project ${projectId} not found.`);
    if (project.ownerId !== userId) {
      throw new ForbiddenException('Only the project owner can perform this action.');
    }
    return project;
  }
}
