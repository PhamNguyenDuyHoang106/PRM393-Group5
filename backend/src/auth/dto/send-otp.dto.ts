import { IsEmail } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class SendOtpDto {
  @ApiProperty({ example: 'member@gmail.com', description: 'Account email address for OTP delivery' })
  @IsEmail()
  email: string;
}
