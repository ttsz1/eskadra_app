import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Brak Authorization header." }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const serviceClient = createClient(supabaseUrl, serviceRoleKey);

    const {
      data: { user },
      error: authError,
    } = await userClient.auth.getUser();

    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Nie udało się ustalić użytkownika." }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const { data: adminRow } = await serviceClient
      .from("app_admins")
      .select("user_id")
      .eq("user_id", user.id)
      .maybeSingle();

    if (!adminRow) {
      return new Response(JSON.stringify({ error: "Brak uprawnień administratora." }), {
        status: 403,
        headers: { "Content-Type": "application/json" },
      });
    }

    const body = await req.json();

    const email = String(body.email ?? "").trim();
    const password = String(body.password ?? "").trim();
    const fullName = String(body.full_name ?? "").trim();
    const orgUnit = body.org_unit ?? null;
    const orgFunction = body.org_function ?? null;
    const personnelType = body.personnel_type ?? null;
    const rankGroup = body.rank_group ?? null;
    const isActive = body.is_active ?? true;

    if (!email || !password || !fullName) {
      return new Response(
        JSON.stringify({ error: "Wymagane pola: email, password, full_name." }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const { data: created, error: createError } = await serviceClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name: fullName,
      },
    });

    if (createError || !created.user) {
      return new Response(
        JSON.stringify({ error: createError?.message ?? "Nie udało się utworzyć użytkownika." }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    const userId = created.user.id;

    const { error: profileError } = await serviceClient.from("profiles").upsert({
      id: userId,
      email,
      full_name: fullName,
      org_unit: orgUnit,
      org_function: orgFunction,
      personnel_type: personnelType,
      rank_group: rankGroup,
      is_active: isActive,
    });

    if (profileError) {
      await serviceClient.auth.admin.deleteUser(userId);

      return new Response(
        JSON.stringify({ error: profileError.message }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    return new Response(
      JSON.stringify({
        ok: true,
        user_id: userId,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Nieznany błąd.",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      },
    );
  }
});