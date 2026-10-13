// @ts-ignore
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// @ts-ignore
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
// @ts-ignore
import { GoogleAuth } from "https://esm.sh/google-auth-library@8.9.0";

// Dichiariamo "Deno" per rimuovere i finti errori di TypeScript su VS Code
declare const Deno: any;

// Interfaccia del payload ricevuto dal Webhook di Supabase
interface WebhookPayload {
  type: "INSERT";
  table: string;
  record: {
    id: string;
    user_id: string;
    title: string;
    message: string;
    is_read: boolean;
    created_at: string;
  };
  schema: "public";
}

serve(async (req: Request) => {
  try {
    const payload: WebhookPayload = await req.json();

    // 1. Inizializza Supabase Client per leggere il token
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 2. Recupera l'FCM token dell'utente dal database
    const { data: profile, error } = await supabase
      .from("profiles")
      .select("fcm_token")
      .eq("id", payload.record.user_id)
      .single();

    if (error || !profile?.fcm_token) {
      console.log("Nessun token trovato per l'utente:", payload.record.user_id);
      return new Response(JSON.stringify({ error: "Token non trovato" }), { status: 404 });
    }

    // 3. Invia la notifica push tramite Firebase HTTP v1 API
    const auth = new GoogleAuth({
      credentials: JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!),
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });

    const accessToken = await auth.getAccessToken();
    const projectId = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!).project_id;

    const fcmResponse = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token: profile.fcm_token,
          notification: {
            title: payload.record.title,
            body: payload.record.message,
          },
          data: {
            notification_id: payload.record.id,
          },
        },
      }),
    });

    const fcmResult = await fcmResponse.json();
    return new Response(JSON.stringify({ success: true, fcmResult }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("Errore:", err);
    const errorMessage = err instanceof Error ? err.message : String(err);
    return new Response(JSON.stringify({ error: errorMessage }), { status: 500 });
  }
});

