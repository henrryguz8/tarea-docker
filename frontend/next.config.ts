import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Genera .next/standalone: solo lo mínimo para correr en producción (imagen ligera)
  output: "standalone",
};

export default nextConfig;
