import { createWebRlsClient } from "@/lib/supabase";

export const dynamic = "force-dynamic";

export default async function DashboardPage() {
  const supabase = await createWebRlsClient();
  const {
    data: { user }
  } = await supabase.auth.getUser();
  const claims = user?.app_metadata ?? {};

  return (
    <div className="shell">
      <header className="topbar">
        <div className="brand">Greenlight</div>
        <div className="session">
          {user ? `${user.email ?? "Signed in"} · ${claims.user_role ?? "role unknown"}` : "Signed out"}
        </div>
      </header>
      <main className="main">
        <section className="panel">
          <p className="eyebrow">Dashboard</p>
          <h1>Site activation workspace</h1>
          <p>
            This shell is intentionally empty. Later streams will fill in sponsor-facing study,
            site, document, finding, command-center, and IRB workflows.
          </p>
        </section>
      </main>
    </div>
  );
}
