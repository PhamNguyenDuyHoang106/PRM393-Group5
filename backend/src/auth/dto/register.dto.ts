import { IsString, IsEmail, MinLength, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class RegisterDto {
  @ApiProperty({ example: 'Hoang Manager', description: 'User display name' })
  @IsString()
  @MinLength(3)
  name: string;

  @ApiProperty({ example: 'manager@gmail.com', description: 'User email address' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'Secure123Password', description: 'Account password (min 6 characters)' })
  @IsString()
  @MinLength(6)
  password: string;

  @ApiPropertyOptional({ example: 'member', description: 'User role: manager or member' })
  @IsOptional()
  @IsString()
  role?: string;
}
