import { IsString, IsOptional, MinLength } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateProfileDto {
  @ApiPropertyOptional({ example: 'Hoang Member', description: 'User full display name' })
  @IsOptional()
  @IsString()
  @MinLength(3)
  name?: string;

  @ApiPropertyOptional({ example: 'data:image/png;base64,iVBORw0KGgo...', description: 'User profile picture URL or Base64 string' })
  @IsOptional()
  @IsString()
  avatarUrl?: string;
}
