import { IsString, IsOptional, IsUrl, MinLength } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateProfileDto {
  @ApiPropertyOptional({ example: 'Hoang Member', description: 'User full display name' })
  @IsOptional()
  @IsString()
  @MinLength(3)
  name?: string;

  @ApiPropertyOptional({ example: 'https://example.com/avatar.png', description: 'User profile picture URL' })
  @IsOptional()
  @IsString()
  @IsUrl()
  avatarUrl?: string;
}
