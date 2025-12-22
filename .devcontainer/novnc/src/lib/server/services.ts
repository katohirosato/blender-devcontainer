// cp novnc_setup/services.ts .devcontainer/novnc/src/lib/server/services.ts
import "server-only";
import { readFile } from "node:fs/promises";

type Service = {
    version: string;
    port: number;
    resources?: string;
}
type Services = Record<string, Service>;

export async function readServices() {
  const filePath = "/app/blender_services.json";
  const json = await readFile(filePath, "utf8");
  return JSON.parse(json) as Services;
}
