import { IsEmail, IsString, Length, IsNumberString, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ResetPasswordDto {
  @ApiProperty({ example: 'member@gmail.com', description: 'Account email address' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: '123456', description: '6-digit numeric verification OTP code' })
  @IsString()
  @Length(6, 6)
  @IsNumberString()
  otp: string;

  @ApiProperty({ example: 'MyNewSecurePassword456', description: 'New account password (min 6 characters)' })
  @IsString()
  @MinLength(6)
  newPassword: string;
}
