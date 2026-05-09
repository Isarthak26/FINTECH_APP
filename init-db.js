const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'fintech-dev2-pg.postgres.database.azure.com',
  user: process.env.DB_USER || 'pgadmin',
  password: process.env.DB_PASSWORD,
  database: 'fintech',
  port: 5432,
  ssl: { rejectUnauthorized: false }
});

const initDB = async () => {
  try {
    console.log('Creating users table...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('✓ users table created');

    // Insert sample data
    console.log('Inserting sample data...');
    await pool.query(`
      INSERT INTO users (name) VALUES 
      ('Alice'), 
      ('Bob'), 
      ('Charlie')
      ON CONFLICT DO NOTHING;
    `);
    console.log('✓ Sample data inserted');

    console.log('\nDatabase initialized successfully!');
    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
};

initDB();
