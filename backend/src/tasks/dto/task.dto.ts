import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsIn,
  IsDateString,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

const PRIORITIES = ['LOW', 'MEDIUM', 'HIGH'] as const;
const STATUSES = ['TODO', 'IN_PROGRESS', 'DONE'] as const;

export class CreateTaskDto {
  @ApiPropertyOptional({ example: 'task_abc123', description: 'Optional task ID (for offline sync)' })
  @IsString()
  @IsOptional()
  id?: string;

  @ApiProperty({ example: 'Setup Flutter project' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  title: string;

  @ApiPropertyOptional({ example: 'Initialize Flutter with Riverpod and GoRouter.' })
  @IsString()
  @IsOptional()
  @MaxLength(1000)
  description?: string;

  @ApiProperty({ enum: PRIORITIES, example: 'HIGH' })
  @IsIn(PRIORITIES)
  priority: string;

  @ApiPropertyOptional({ example: 'usr_abc123', description: 'User ID to assign the task to' })
  @IsString()
  @IsOptional()
  assignedTo?: string;

  @ApiPropertyOptional({ example: '2026-07-31T00:00:00.000Z' })
  @IsDateString()
  @IsOptional()
  dueDate?: string;
}

export class UpdateTaskDto {
  @ApiPropertyOptional({ example: 'Updated task title' })
  @IsString()
  @IsOptional()
  @MaxLength(150)
  title?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  @MaxLength(1000)
  description?: string;

  @ApiPropertyOptional({ enum: PRIORITIES })
  @IsIn(PRIORITIES)
  @IsOptional()
  priority?: string;

  @ApiPropertyOptional({ enum: STATUSES })
  @IsIn(STATUSES)
  @IsOptional()
  status?: string;

  @ApiPropertyOptional({ example: 'usr_abc123' })
  @IsString()
  @IsOptional()
  assignedTo?: string;

  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  dueDate?: string;
}

export class UpdateTaskStatusDto {
  @ApiProperty({ enum: STATUSES, example: 'IN_PROGRESS' })
  @IsIn(STATUSES)
  status: string;
}
