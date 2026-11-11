const { Client } = require('pg');

async function seed() {
  if (process.env.NODE_ENV !== 'development') {
    throw new Error('Seed requires NODE_ENV=development');
  }

  const client = new Client();
  try {
    await client.connect();
    await client.query(
      `INSERT INTO products (sku, name, price_cents)
       VALUES ($1, $2, $3), ($4, $5, $6)
       ON CONFLICT (sku) DO NOTHING`,
      ['demo-notebook', 'Carnet démo', 690, 'demo-mug', 'Tasse démo', 1290],
    );
  } finally {
    await client.end();
  }
}

seed().catch(() => {
  console.error('Development seed failed');
  process.exitCode = 1;
});
