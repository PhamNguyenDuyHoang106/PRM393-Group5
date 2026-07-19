import { IsString, IsEmail, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class LoginDto {
  @ApiProperty({ example: 'manager@gmail.com', description: 'Account email address' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'Secure123Password', description: 'Account password' })
  @IsString()
  @MinLength(6)
  password: string;
}
