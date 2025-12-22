//cp novnc_setup/route.ts .devcontainer/novnc/src/app/[slug]/route.ts

import { NextRequest, NextResponse } from "next/server";
import { readServices } from "@/lib/server/services";

export const dynamic = "force-dynamic";

type Service = {
  port: number;
  version: string;
  resources?: string;
}

export async function GET(request: NextRequest, { params }: { params: Promise<{ slug: string }> },) {
  const { slug } = await params;
  const services = await readServices();
  const service = (services as Record<string, Service>)[slug];
  if (!service) {
    return NextResponse.json({ error: "Invalid blender version" }, { status: 404 });
  }
  const vncport = service.port;
  let url: string;
  if (process.env.CODESPACE_NAME) {
    url = `https://${process.env.CODESPACE_NAME}-3000.${process.env.GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}/noVNC/vnc.html#path=wss://${process.env.CODESPACE_NAME}-${vncport}.${process.env.GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}/`;
  } else {
    url = `http://localhost:3000/noVNC/vnc.html#path=wss://localhost:${vncport}/`;
  }
  return NextResponse.redirect(url);
}