import { IsString, IsNotEmpty, IsOptional, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';

export class CreateCommentDto {
  @ApiPropertyOptional({ example: 'cmt_123', description: 'Optional ID for offline sync' })
  @IsString()
  @IsOptional()
  id?: string;

  @ApiProperty({ example: 'Please review schema migrations.', maxLength: 1000 })
  @Transform(({ value }) => typeof value === 'string' ? value.trim() : value)
  @IsString()
  @IsNotEmpty({ message: 'Comment content cannot be empty or whitespace only.' })
  @MaxLength(1000)
  content: string;
}
