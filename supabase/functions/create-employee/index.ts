import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type CreateEmployeePayload = {
  email?: string;
  password?: string;
  full_name?: string;
  phone?: string;
  role?: string;
};

const jsonResponse = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });

const normalizeRole = (value: string | undefined) =>
  value === "admin" ? "admin" : "employee";

const normalizeMessage = (value: unknown) =>
  typeof value === "string" ? value.toLowerCase() : "";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !supabaseAnonKey || !serviceRoleKey) {
    return jsonResponse(
      { error: "Missing Supabase function secrets." },
      500,
    );
  }

  const authorization = request.headers.get("Authorization");
  if (!authorization) {
    return jsonResponse({ error: "Missing authorization header." }, 401);
  }

  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: {
        Authorization: authorization,
      },
    },
  });

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  const {
    data: { user: requester },
    error: requesterError,
  } = await userClient.auth.getUser();

  if (requesterError || !requester) {
    return jsonResponse({ error: "Unauthorized request." }, 401);
  }

  const { data: requesterProfile, error: profileError } = await adminClient
    .from("profiles")
    .select("role, is_active")
    .eq("id", requester.id)
    .single();

  if (profileError) {
    return jsonResponse({ error: "Unable to verify requester profile." }, 403);
  }

  if (!requesterProfile.is_active || requesterProfile.role !== "admin") {
    return jsonResponse({ error: "Only admins can create users." }, 403);
  }

  let payload: CreateEmployeePayload;
  try {
    payload = await request.json();
  } catch (_) {
    return jsonResponse({ error: "Invalid JSON payload." }, 400);
  }

  const email = payload.email?.trim().toLowerCase();
  const password = payload.password?.trim();
  const fullName = payload.full_name?.trim();
  const phone = payload.phone?.trim() || null;
  const role = normalizeRole(payload.role);

  if (!email || !fullName || !password) {
    return jsonResponse(
      { error: "email, password, and full_name are required." },
      400,
    );
  }

  if (password.length < 6) {
    return jsonResponse(
      { error: "Password must be at least 6 characters long." },
      400,
    );
  }

  const { data: createdUser, error: createUserError } = await adminClient.auth
    .admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name: fullName,
        phone,
        role,
      },
    });

  if (createUserError || !createdUser.user) {
    const message = normalizeMessage(createUserError?.message);
    if (
      message.includes("already") ||
      message.includes("registered") ||
      message.includes("exists")
    ) {
      return jsonResponse({ error: "Email already exists." }, 409);
    }

    return jsonResponse(
      {
        error: createUserError?.message ?? "Failed to create auth user.",
      },
      500,
    );
  }

  const userId = createdUser.user.id;
  const { error: upsertProfileError } = await adminClient
    .from("profiles")
    .upsert(
      {
        id: userId,
        full_name: fullName,
        phone,
        role,
        is_active: true,
      },
      {
        onConflict: "id",
      },
    );

  if (upsertProfileError) {
    await adminClient.auth.admin.deleteUser(userId);
    return jsonResponse(
      { error: upsertProfileError.message || "Failed to save profile." },
      500,
    );
  }

  return jsonResponse(
    {
      message: "User created successfully.",
      user: {
        id: userId,
        email,
        full_name: fullName,
        phone,
        role,
      },
    },
    200,
  );
});
