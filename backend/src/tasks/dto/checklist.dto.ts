import { IsString, IsNotEmpty, IsOptional, IsBoolean, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateChecklistDto {
  @ApiPropertyOptional({ example: 'chk_123', description: 'Optional ID for offline sync' })
  @IsString()
  @IsOptional()
  id?: string;

  @ApiProperty({ example: 'Complete unit tests', maxLength: 100 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  title: string;
}

export class UpdateChecklistDto {
  @ApiPropertyOptional({ example: 'Updated checklist item', maxLength: 100 })
  @IsString()
  @IsOptional()
  @MaxLength(100)
  title?: string;

  @ApiPropertyOptional({ example: true })
  @IsBoolean()
  @IsOptional()
  isDone?: boolean;
}
