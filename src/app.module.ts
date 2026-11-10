import { Controller, Get, Module } from '@nestjs/common';
import { DatabaseService } from './database.service';
import { ProductsController } from './products.controller';

@Controller()
class HealthController {
  @Get('health')
  health(): { status: 'ok' } {
    return { status: 'ok' };
  }
}

@Module({ controllers: [HealthController, ProductsController], providers: [DatabaseService] })
export class AppModule {}
