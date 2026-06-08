import express from "express";
import type { Express } from "express";
import PgBoss from "pg-boss";
import { getWorkerEnv } from "./env.js";
import { registerValidationWorker } from "./jobs/validation.js";

export function createApp(): Express {
  const app = express();
  app.use(express.json());

  app.get("/health", (_request, response) => {
    response.status(200).json({ ok: true });
  });

  return app;
}

export async function startWorker() {
  const env = getWorkerEnv();
  const app = createApp();
  const boss = new PgBoss({
    connectionString: env.databaseUrl
  });

  boss.on("error", (error) => {
    console.error("pg-boss error", error);
  });

  await boss.start();
  await registerValidationWorker(boss);

  const server = app.listen(env.port, () => {
    console.info(`greenlight worker listening on ${env.port}`);
  });

  const shutdown = async () => {
    server.close();
    await boss.stop();
  };

  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  startWorker().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}
