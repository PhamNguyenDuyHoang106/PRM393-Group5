import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Patch,
  Body,
  Param,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { TasksService } from './tasks.service';
import { CreateTaskDto, UpdateTaskDto, UpdateTaskStatusDto } from './dto/task.dto';
import { CreateChecklistDto, UpdateChecklistDto } from './dto/checklist.dto';
import { CreateCommentDto } from './dto/comment.dto';
import { AuthGuard } from '../guards/auth.guard';
import { CurrentUser } from '../decorators/user.decorator';

@ApiTags('Tasks')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller()
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  // ── Project-scoped task routes ───────────────────────────────────────────
  @ApiOperation({ summary: 'Create a task in a project (Project owner only)' })
  @ApiResponse({ status: 201, description: 'Task created.' })
  @Post('projects/:projectId/tasks')
  async create(
    @Param('projectId') projectId: string,
    @Body() dto: CreateTaskDto,
    @CurrentUser() user: any,
  ) {
    return this.tasksService.create(projectId, dto, user.id);
  }

  @ApiOperation({ summary: 'List all tasks in a project' })
  @ApiResponse({ status: 200, description: 'Task list returned.' })
  @Get('projects/:projectId/tasks')
  async findAll(
    @Param('projectId') projectId: string,
    @CurrentUser() user: any,
  ) {
    return this.tasksService.findAll(projectId, user.id);
  }

  // ── My tasks route ────────────────────────────────────────────────────────
  @ApiOperation({ summary: 'Get all tasks assigned to the current user' })
  @ApiResponse({ status: 200, description: 'My tasks returned.' })
  @Get('tasks/my')
  async findMyTasks(@CurrentUser() user: any) {
    return this.tasksService.findMyTasks(user.id);
  }

  // ── Individual task routes ────────────────────────────────────────────────
  @ApiOperation({ summary: 'Get a task by ID' })
  @ApiResponse({ status: 200, description: 'Task returned.' })
  @Get('tasks/:id')
  async findOne(@Param('id') id: string, @CurrentUser() user: any) {
    return this.tasksService.findOne(id, user.id);
  }

  @ApiOperation({ summary: 'Update a task fully (Project owner only)' })
  @ApiResponse({ status: 200, description: 'Task updated.' })
  @Put('tasks/:id')
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateTaskDto,
    @CurrentUser() user: any,
  ) {
    return this.tasksService.update(id, dto, user.id, user.role);
  }

  @ApiOperation({ summary: 'Update task status (Assigned member or owner)' })
  @ApiResponse({ status: 200, description: 'Task status updated.' })
  @Patch('tasks/:id/status')
  async updateStatus(
    @Param('id') id: string,
    @Body() dto: UpdateTaskStatusDto,
    @CurrentUser() user: any,
  ) {
    return this.tasksService.updateStatus(id, dto, user.id);
  }

  @ApiOperation({ summary: 'Delete a task (Project owner only)' })
  @ApiResponse({ status: 204, description: 'Task deleted.' })
  @HttpCode(HttpStatus.NO_CONTENT)
  @Delete('tasks/:id')
  async delete(@Param('id') id: string, @CurrentUser() user: any) {
    await this.tasksService.delete(id, user.id);
  }

  // ── Task Checklist routes ───────────────────────────────────────────────
  @ApiOperation({ summary: 'List checklist items for a task' })
  @Get('tasks/:taskId/checklists')
  async findChecklists(@Param('taskId') taskId: string, @CurrentUser() user: any) {
    return this.tasksService.findChecklists(taskId, user.id);
  }

  @ApiOperation({ summary: 'Add a checklist item to a task' })
  @Post('tasks/:taskId/checklists')
  async createChecklist(
    @Param('taskId') taskId: string,
    @Body() dto: CreateChecklistDto,
    @CurrentUser() user: any,
  ) {
    return this.tasksService.createChecklist(taskId, dto.title, user.id, dto.id);
  }

  @ApiOperation({ summary: 'Update/Toggle a checklist item' })
  @Patch('tasks/checklists/:id')
  async updateChecklist(
    @Param('id') id: string,
    @Body() dto: UpdateChecklistDto,
    @CurrentUser() user: any,
  ) {
    return this.tasksService.updateChecklist(id, dto, user.id);
  }

  @ApiOperation({ summary: 'Delete a checklist item' })
  @HttpCode(HttpStatus.NO_CONTENT)
  @Delete('tasks/checklists/:id')
  async deleteChecklist(@Param('id') id: string, @CurrentUser() user: any) {
    await this.tasksService.deleteChecklist(id, user.id);
  }

  // ── Task Comment routes ──────────────────────────────────────────────────
  @ApiOperation({ summary: 'List comments for a task' })
  @Get('tasks/:taskId/comments')
  async findComments(@Param('taskId') taskId: string, @CurrentUser() user: any) {
    return this.tasksService.findComments(taskId, user.id);
  }

  @ApiOperation({ summary: 'Add a comment to a task' })
  @Post('tasks/:taskId/comments')
  async createComment(
    @Param('taskId') taskId: string,
    @Body() dto: CreateCommentDto,
    @CurrentUser() user: any,
  ) {
    return this.tasksService.createComment(taskId, dto.content, user.id, dto.id);
  }

  @ApiOperation({ summary: 'Delete a comment (Author or Manager only)' })
  @HttpCode(HttpStatus.NO_CONTENT)
  @Delete('tasks/comments/:id')
  async deleteComment(@Param('id') id: string, @CurrentUser() user: any) {
    await this.tasksService.deleteComment(id, user.id, user.role);
  }

  // ── Task Activity History route ──────────────────────────────────────────
  @ApiOperation({ summary: 'Get activity history (AuditLog) for a task' })
  @Get('tasks/:taskId/activities')
  async findActivities(@Param('taskId') taskId: string, @CurrentUser() user: any) {
    return this.tasksService.findActivities(taskId, user.id);
  }
}
