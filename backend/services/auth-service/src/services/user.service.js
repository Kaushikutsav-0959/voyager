import { pool } from "../config/db.js";

export async function createUser({ email, password_hash, name }) {
  const res = await pool.query(
    `
        INSERT INTO users (email, password_hash, name)
        VALUES($1,$2,$3)
        RETURNING id, email, name
    `,
    [email, password_hash, name]
  );

  return res.rows[0];
}

export async function findUserByEmail(email) {
  const res = await pool.query(
    `
        SELECT id, email, password_hash, name FROM users WHERE email = $1
    `,
    [email]
  );

  return res.rows[0];
}

export async function assignRole(userId, roleName) {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const roleRes = await client.query(`SELECT id FROM roles WHERE name = $1`, [
      roleName,
    ]);

    if (roleRes.rowCount === 0) {
      throw new Error(`Role not found: ${roleName}`);
    }

    const roleId = roleRes.rows[0].id;

    await client.query(
      `
        INSERT INTO user_roles (user_id, role_id)
        VALUES ($1, $2)
        ON CONFLICT DO NOTHING
      `,
      [userId, roleId]
    );

    await client.query("COMMIT");
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}
