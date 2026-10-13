// @ts-ignore
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// @ts-ignore
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
// @ts-ignore
import { GoogleAuth } from "https://esm.sh/google-auth-library@8.9.0";

declare const Deno: any;

serve(async (req: Request) => {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const now = Date.now();
    // Finestra 1 ora: tra 55 e 65 minuti da ora
    const oneHourStart = new Date(now + 55 * 60000).toISOString();
    const oneHourEnd = new Date(now + 65 * 60000).toISOString();
    
    // Finestra 24 ore: tra 23h 55m e 24h 5m da ora
    const oneDayStart = new Date(now + (24 * 60 - 5) * 60000).toISOString();
    const oneDayEnd = new Date(now + (24 * 60 + 5) * 60000).toISOString();

    const { data: events1h, error: e1 } = await supabase
      .from("events")
      .select("*")
      .gte("start_date", oneHourStart)
      .lte("start_date", oneHourEnd);

    const { data: events24h, error: e2 } = await supabase
      .from("events")
      .select("*")
      .gte("start_date", oneDayStart)
      .lte("start_date", oneDayEnd);

    const eventsToNotify = [
      ...(events1h || []).map((e: any) => ({ ...e, noticeType: '1 ora' })),
      ...(events24h || []).map((e: any) => ({ ...e, noticeType: '1 giorno' }))
    ];

    if (eventsToNotify.length === 0) {
      return new Response(JSON.stringify({ message: "Nessun evento imminente" }), { headers: { "Content-Type": "application/json" } });
    }

    const { data: profiles } = await supabase.from("profiles").select("*").not("fcm_token", "is", null);
    if (!profiles || profiles.length === 0) {
      return new Response(JSON.stringify({ message: "Nessun utente con token FCM" }), { headers: { "Content-Type": "application/json" } });
    }

    const auth = new GoogleAuth({
      credentials: JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!),
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });
    const accessToken = await auth.getAccessToken();
    const projectId = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!).project_id;

    let sentCount = 0;

    for (const event of eventsToNotify) {
      const targetedUsers = profiles.filter((user: any) => {
        const roles = event.target_roles || [];
        const branches = event.target_branches || [];
        const squads = event.target_squads || [];
        const users = event.target_users || [];

        if (roles.length === 0 && branches.length === 0 && squads.length === 0 && users.length === 0) return true;
        if (users.includes(user.id)) return true;
        if (user.branch && branches.includes(user.branch)) return true;
        if (user.role && roles.includes(user.role)) return true;
        if (user.squad_name && squads.includes(user.squad_name)) return true;
        return false;
      });

      for (const user of targetedUsers) {
        if (!user.fcm_token) continue;

        const startDateObj = new Date(event.start_date);
        const hours = startDateObj.getHours().toString().padStart(2, '0');
        const minutes = startDateObj.getMinutes().toString().padStart(2, '0');
        const startTime = `${hours}:${minutes}`;

        const titleMsg = event.noticeType === '1 ora' ? "Evento tra 1 ora" : "Evento domani";
        const bodyMsg = `${event.title} alle ${startTime}`;

        await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${accessToken}`,
          },
          body: JSON.stringify({
            message: {
              token: user.fcm_token,
              notification: {
                title: titleMsg,
                body: bodyMsg,
              },
              data: {
                event_id: event.id,
              },
            },
          }),
        });
        sentCount++;
      }
    }

    return new Response(JSON.stringify({ success: true, sentCount }), { headers: { "Content-Type": "application/json" } });
  } catch (err) {
    console.error("Errore:", err);
    return new Response(JSON.stringify({ error: err instanceof Error ? err.message : String(err) }), { status: 500 });
  }
});
