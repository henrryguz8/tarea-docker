import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

// GET /api/status -> consulta el backend Laravel por la red interna de Docker
export async function GET() {
  const base = process.env.API_URL || "http://localhost:8000";
  try {
    const res = await fetch(`${base}/api/health`, { cache: "no-store" });
    const data = await res.json();
    return NextResponse.json({ frontend: "ok", backend: data });
  } catch {
    return NextResponse.json(
      { frontend: "ok", backend: "no disponible" },
      { status: 502 }
    );
  }
}
