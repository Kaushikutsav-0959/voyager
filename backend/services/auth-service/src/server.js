import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import authRoutes from "./routes/auth.routes.js";
dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());
app.use("/auth", authRoutes);

app.listen(process.env.PORT, () => {
  console.log(`Auth service running on PORT ${process.env.PORT}`);
});
