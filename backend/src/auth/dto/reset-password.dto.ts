import { IsEmail, IsString, IsOptional, MinLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ResetPasswordDto {
  @ApiProperty({ example: 'member@gmail.com', description: 'Account email address' })
  @IsEmail()
  email: string;

  @ApiPropertyOptional({ example: '123456', description: 'Verification OTP code (optional)' })
  @IsString()
  @IsOptional()
  otp?: string;

  @ApiProperty({ example: 'MyNewSecurePassword456', description: 'New account password (min 6 characters)' })
  @IsString()
  @MinLength(6)
  newPassword: string;
}
