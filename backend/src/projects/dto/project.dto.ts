import { IsString, IsNotEmpty, IsOptional, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateProjectDto {
  @ApiPropertyOptional({ example: 'proj_abc123', description: 'Optional project ID (for offline sync)' })
  @IsString()
  @IsOptional()
  id?: string;

  @ApiProperty({ example: 'Smart Task PRM393' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  name: string;

  @ApiPropertyOptional({ example: 'University project for PRM393 course.' })
  @IsString()
  @IsOptional()
  @MaxLength(500)
  description?: string;
}

export class UpdateProjectDto {
  @ApiPropertyOptional({ example: 'Smart Task v2' })
  @IsString()
  @IsOptional()
  @MaxLength(100)
  name?: string;

  @ApiPropertyOptional({ example: 'Updated description.' })
  @IsString()
  @IsOptional()
  @MaxLength(500)
  description?: string;
}

export class AddMemberDto {
  @ApiProperty({ example: 'member@gmail.com', description: 'User email to add as project member' })
  @IsString()
  @IsNotEmpty()
  email: string;
}
