import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { StatisticsService } from './statistics.service';
import { AuthGuard } from '../guards/auth.guard';
import { CurrentUser } from '../decorators/user.decorator';

@ApiTags('Statistics')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller('statistics')
export class StatisticsController {
  constructor(private readonly statisticsService: StatisticsService) {}

  @ApiOperation({ summary: 'Get dashboard statistics for current user' })
  @ApiQuery({ name: 'range', required: false, enum: ['week', 'month'], description: 'Restrict counts to tasks created since the start of the current week/month.' })
  @ApiResponse({ status: 200, description: 'Dashboard stats returned.' })
  @Get('dashboard')
  async getDashboard(@CurrentUser() user: any, @Query('range') range?: string) {
    return this.statisticsService.getDashboard(user.id, user.role, range);
  }

  @ApiOperation({ summary: 'Get statistics for a specific project' })
  @ApiResponse({ status: 200, description: 'Project stats returned.' })
  @Get('projects/:projectId')
  async getProjectStats(@Param('projectId') projectId: string) {
    return this.statisticsService.getProjectStats(projectId);
  }
}
