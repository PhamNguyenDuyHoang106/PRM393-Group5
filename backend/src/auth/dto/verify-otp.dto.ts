import { IsEmail, IsString, Length, IsNumberString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class VerifyOtpDto {
  @ApiProperty({ example: 'member@gmail.com', description: 'Account email address' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: '123456', description: '6-digit numeric verification OTP code' })
  @IsString()
  @Length(6, 6)
  @IsNumberString()
  otp: string;
}
