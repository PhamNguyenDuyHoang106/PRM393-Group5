import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
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
import { ProjectsService } from './projects.service';
import { CreateProjectDto, UpdateProjectDto, AddMemberDto } from './dto/project.dto';
import { AuthGuard } from '../guards/auth.guard';
import { CurrentUser } from '../decorators/user.decorator';

@ApiTags('Projects')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller('projects')
export class ProjectsController {
  constructor(private readonly projectsService: ProjectsService) {}

  @ApiOperation({ summary: 'Create a new project (Manager only)' })
  @ApiResponse({ status: 201, description: 'Project created.' })
  @Post()
  async create(@Body() dto: CreateProjectDto, @CurrentUser() user: any) {
    if (user.role !== 'manager') {
      throw new Error('Only managers can create projects.');
    }
    return this.projectsService.create(dto, user.id);
  }

  @ApiOperation({ summary: 'List all projects accessible to current user' })
  @ApiResponse({ status: 200, description: 'Project list returned.' })
  @Get()
  async findAll(@CurrentUser() user: any) {
    return this.projectsService.findAll(user.id);
  }

  @ApiOperation({ summary: 'Get project details by ID' })
  @ApiResponse({ status: 200, description: 'Project details returned.' })
  @ApiResponse({ status: 404, description: 'Project not found.' })
  @Get(':id')
  async findOne(@Param('id') id: string, @CurrentUser() user: any) {
    return this.projectsService.findOne(id, user.id);
  }

  @ApiOperation({ summary: 'Update project (Owner only)' })
  @ApiResponse({ status: 200, description: 'Project updated.' })
  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateProjectDto,
    @CurrentUser() user: any,
  ) {
    return this.projectsService.update(id, dto, user.id);
  }

  @ApiOperation({ summary: 'Delete project (Owner only)' })
  @ApiResponse({ status: 204, description: 'Project deleted.' })
  @HttpCode(HttpStatus.NO_CONTENT)
  @Delete(':id')
  async delete(@Param('id') id: string, @CurrentUser() user: any) {
    await this.projectsService.delete(id, user.id);
  }

  @ApiOperation({ summary: 'List all members of a project' })
  @ApiResponse({ status: 200, description: 'Member list returned.' })
  @Get(':id/members')
  async listMembers(@Param('id') id: string, @CurrentUser() user: any) {
    return this.projectsService.listMembers(id, user.id);
  }

  @ApiOperation({ summary: 'Add a member to project (Owner only)' })
  @ApiResponse({ status: 201, description: 'Member added.' })
  @Post(':id/members')
  async addMember(
    @Param('id') id: string,
    @Body() dto: AddMemberDto,
    @CurrentUser() user: any,
  ) {
    return this.projectsService.addMember(id, dto, user.id);
  }

  @ApiOperation({ summary: 'Remove a member from project (Owner only)' })
  @ApiResponse({ status: 204, description: 'Member removed.' })
  @HttpCode(HttpStatus.NO_CONTENT)
  @Delete(':id/members/:userId')
  async removeMember(
    @Param('id') id: string,
    @Param('userId') userId: string,
    @CurrentUser() user: any,
  ) {
    await this.projectsService.removeMember(id, userId, user.id);
  }
}
