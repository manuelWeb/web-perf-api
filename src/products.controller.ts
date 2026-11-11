import {
  BadRequestException,
  Controller,
  Get,
  NotFoundException,
  Param,
  Query,
} from '@nestjs/common';
import { DatabaseService } from './database.service';

interface Product {
  id: number;
  sku: string;
  name: string;
  price_cents: number;
}

function positiveInteger(
  value: unknown,
  maximum: number,
  field: string,
): number {
  if (
    typeof value !== 'string' ||
    !/^[1-9][0-9]*$/.test(value) ||
    Number(value) > maximum
  ) {
    throw new BadRequestException(
      `${field} must be an integer between 1 and ${maximum}`,
    );
  }
  return Number(value);
}

@Controller('products')
export class ProductsController {
  constructor(private readonly database: DatabaseService) {}

  @Get()
  async list(@Query('limit') rawLimit?: string): Promise<Product[]> {
    const limit = positiveInteger(rawLimit ?? '20', 100, 'limit');
    const result = await this.database.query<Product>(
      'SELECT id, sku, name, price_cents FROM products ORDER BY id LIMIT $1',
      [limit],
    );
    return result.rows;
  }

  @Get(':id')
  async get(@Param('id') rawId: string): Promise<Product> {
    const id = positiveInteger(rawId, 2_147_483_647, 'id');
    const result = await this.database.query<Product>(
      'SELECT id, sku, name, price_cents FROM products WHERE id = $1',
      [id],
    );
    if (!result.rows[0]) {
      throw new NotFoundException('Product not found');
    }
    return result.rows[0];
  }
}
