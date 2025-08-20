import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  @ApiOperation({ summary: 'Ana sayfa', description: 'API ana sayfası' })
  @ApiResponse({ status: 200, description: 'Hoş geldiniz mesajı' })
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('health')
  @ApiTags('Health Check')
  @ApiOperation({
    summary: 'API sağlık durumu',
    description: "API'nin çalışma durumunu ve uptime bilgisini döner",
  })
  @ApiResponse({
    status: 200,
    description: 'API sağlıklı',
    schema: {
      type: 'object',
      properties: {
        status: { type: 'string', example: 'ok' },
        timestamp: { type: 'string', example: '2025-08-20T18:49:31.456Z' },
        uptime: { type: 'number', example: 23.09 },
      },
    },
  })
  getHealth() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    };
  }
}
