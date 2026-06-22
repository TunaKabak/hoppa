import path from "path";
import { PrismaClient } from "@prisma/client";
import dotenv from "dotenv";

dotenv.config({ path: path.join(__dirname, "../../.env") });

// Helper to strip quotes
const cleanUrl = (url: string | undefined): string | undefined => {
  if (!url) return undefined;
  return url.replace(/^["']|["']$/g, "");
};

const databaseUrl = cleanUrl(process.env.DATABASE_URL);

if (!databaseUrl) {
  console.warn("[Prisma Warning] DATABASE_URL is not set or empty.");
}

export const prisma = new PrismaClient({
  datasources: {
    db: {
      url: databaseUrl,
    },
  },
});
