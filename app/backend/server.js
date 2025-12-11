// server.js
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import mysql from "mysql2/promise";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

// ---------------------------------------------
// ⭐ FIX: MySQL auto-retry connection function
// ---------------------------------------------
let connection;

async function connectDB() {
  while (true) {
    try {
      connection = await mysql.createConnection({
        host: process.env.DB_HOST,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME,
        port: process.env.DB_PORT,
      });
      console.log("✅ Connected to MySQL!");
      break;
    } catch (error) {
      console.log("❌ MySQL not ready, retrying in 5 seconds...", error.message);
      await new Promise((res) => setTimeout(res, 5000));
    }
  }
}

// ---------------------------------------------
// ⭐ Wrap server start inside async function
// ---------------------------------------------
async function startServer() {
  await connectDB(); // connect MySQL first

  // ---------------------------------------------
  // ⭐ ROUTES – FULL API SET
  // ---------------------------------------------

  // Test backend
  app.get("/", (req, res) => {
    res.send("Backend running successfully! 🎉");
  });

  // Get all users
  app.get("/api/users", async (req, res) => {
    const [rows] = await connection.query("SELECT * FROM users");
    res.json(rows);
  });

  // Get birthday wish (GET)
  app.get("/api/wish", async (req, res) => {
    const name = req.query.name;
    if (!name) return res.status(400).json({ error: "Name is required" });

    res.json({ message: `🎉 Happy Birthday, ${name}! 🎂` });
  });

  // Birthday wish (POST)
  app.post("/api/wish", async (req, res) => {
    const { name } = req.body;
    if (!name) return res.status(400).json({ error: "Name is required" });

    res.json({ message: `🎉 Happy Birthday, ${name}! 🎂` });
  });

  // Add user
  app.post("/api/user", async (req, res) => {
    const { name } = req.body;

    if (!name) return res.status(400).json({ error: "Name is required" });

    await connection.query("INSERT INTO users (name) VALUES (?)", [name]);

    res.json({ message: "User added successfully!" });
  });

  // Get user by ID
  app.get("/api/user/:id", async (req, res) => {
    const { id } = req.params;

    const [rows] = await connection.query("SELECT * FROM users WHERE id = ?", [
      id,
    ]);

    if (rows.length === 0)
      return res.status(404).json({ error: "User not found" });

    res.json(rows[0]);
  });

  // Delete user
  app.delete("/api/user/:id", async (req, res) => {
    const { id } = req.params;

    await connection.query("DELETE FROM users WHERE id = ?", [id]);

    res.json({ message: "User deleted successfully!" });
  });

  // ---------------------------------------------
  // ⭐ Start express server
  // ---------------------------------------------
  app.listen(PORT, () =>
    console.log(`🚀 Backend running on port ${PORT}`)
  );
}

// Run everything
startServer();
