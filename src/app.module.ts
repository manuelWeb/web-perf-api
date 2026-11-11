import { Controller, Get, Module } from '@nestjs/common';
import { ApmDemoController } from './apm-demo.controller';
import { DatabaseService } from './database.service';
import { ProductsController } from './products.controller';

@Controller()
class HealthController {
  @Get('health')
  health(): { status: 'ok' } {
    return { status: 'ok' };
  }
}

@Module({
  controllers: [
    HealthController,
    ProductsController,
    ...(process.env.APM_DEMO_ENABLED === 'true' ? [ApmDemoController] : []),
  ],
  providers: [DatabaseService],
})
export class AppModule {}
