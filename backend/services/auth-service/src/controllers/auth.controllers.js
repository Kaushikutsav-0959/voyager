import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import {
  createUser,
  findUserByEmail,
  assignRole,
} from "../services/user.service.js";

export async function register(req, res) {
  try {
    const { email, password, name } = req.body;

    if (!email || !password || !name) {
      return res.status(400).json({ error: "Missing credentials." });
    }

    const normalisedEmail = email.toLowerCase().trim();
    const existing = await findUserByEmail(normalisedEmail);

    if (existing) {
      return res.status(400).json({ message: "User already exists." });
    }

    const password_hash = await bcrypt.hash(password, 10);
    const user = await createUser({
      email: normalisedEmail,
      password_hash,
      name,
    });
    await assignRole(user.id, "traveler");

    res.json({
      id: user.id,
      email: user.email,
      name: user.name,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal Server Error" });
  }
}

export async function loginUser(req, res) {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: "Missing credentials." });
    }

    const normalisedEmail = email.toLowerCase().trim();
    const user = await findUserByEmail(normalisedEmail);

    if (!user) {
      return res.status(401).json({ error: "Invalid credentials." });
    }

    const ok = await bcrypt.compare(password, user.password_hash);

    if (!ok) {
      return res.status(401).json({ error: "Invalid credentials." });
    }

    const token = jwt.sign(
      { id: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );

    res.json({ token });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal Server Error" });
  }
}
