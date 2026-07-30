import { createClient } from 'npm:@supabase/supabase-js@2';
import { importPKCS8, SignJWT } from 'npm:jose@5';

type FirebaseServiceAccount = {
  client_email: string;
  private_key: string;
  private_key_id?: string;
  project_id: string;
};

type DatabaseWebhook = {
  type?: string;
  table?: string;
  record?: Record<string, unknown>;
};

type PushTarget = {
  userId: string;
  title: string;
  body: string;
  kind: 'umbrella' | 'thanks';
};

let cachedAccessToken: { value: string; expiresAt: number } | null = null;

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return Response.json({ error: 'Method not allowed.' }, { status: 405 });
  }

  const webhookSecret = Deno.env.get('PUSH_WEBHOOK_SECRET');
  if (
    !webhookSecret ||
    request.headers.get('x-push-webhook-secret') !== webhookSecret
  ) {
    return Response.json({ error: 'Unauthorized.' }, { status: 401 });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
  if (!supabaseUrl || !serviceRoleKey || !serviceAccountJson) {
    console.error('Push notification secrets are incomplete.');
    return Response.json({ error: 'Server configuration is incomplete.' }, {
      status: 500,
    });
  }

  let event: DatabaseWebhook;
  let serviceAccount: FirebaseServiceAccount;
  try {
    event = await request.json();
    serviceAccount = JSON.parse(serviceAccountJson) as FirebaseServiceAccount;
  } catch (_) {
    return Response.json({ error: 'Invalid request or Firebase credential.' }, {
      status: 400,
    });
  }

  if (event.type !== 'INSERT' || !event.table || !event.record) {
    return Response.json({ ignored: true });
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  try {
    const target = await findPushTarget(admin, event);
    if (target == null) return Response.json({ ignored: true });

    const { data: devices, error } = await admin
      .from('device_push_tokens')
      .select('id,token')
      .eq('user_id', target.userId)
      .eq('enabled', true);
    if (error) throw error;
    if (!devices || devices.length === 0) {
      return Response.json({ sent: 0, reason: 'No opted-in devices.' });
    }

    const accessToken = await firebaseAccessToken(serviceAccount);
    const outcomes = await Promise.all(
      devices.map(async (device) => {
        const result = await sendFcmNotification({
          accessToken,
          projectId: serviceAccount.project_id,
          token: device.token,
          target,
        });
        if (result.invalidToken) {
          await admin.from('device_push_tokens').delete().eq('id', device.id);
        }
        return result.sent;
      }),
    );

    return Response.json({ sent: outcomes.where(Boolean).length });
  } catch (error) {
    console.error('Unable to send push notification.', error);
    return Response.json({ error: 'Push delivery failed.' }, { status: 500 });
  }
});

async function findPushTarget(
  admin: ReturnType<typeof createClient>,
  event: DatabaseWebhook,
): Promise<PushTarget | null> {
  const record = event.record!;

  if (event.table === 'umbrellas') {
    const storyId = stringValue(record.story_id);
    const senderId = stringValue(record.user_id);
    if (!storyId) return null;
    const { data: story, error } = await admin
      .from('stories')
      .select('author_id')
      .eq('id', storyId)
      .maybeSingle();
    if (error) throw error;
    const recipientId = stringValue(story?.author_id);
    if (!recipientId || recipientId === senderId) return null;
    return {
      userId: recipientId,
      kind: 'umbrella',
      title: 'A little support arrived',
      body: 'Someone opened an umbrella on one of your posts.',
    };
  }

  if (event.table === 'thanks') {
    const recipientId = stringValue(record.to_user);
    const senderId = stringValue(record.from_user);
    if (!recipientId || recipientId === senderId) return null;
    return {
      userId: recipientId,
      kind: 'thanks',
      title: 'You made a difference',
      body: 'Someone sent you a thank-you in Haven.',
    };
  }

  return null;
}

async function firebaseAccessToken(
  serviceAccount: FirebaseServiceAccount,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.expiresAt > now + 60) {
    return cachedAccessToken.value;
  }

  const key = await importPKCS8(serviceAccount.private_key, 'RS256');
  const assertion = await new SignJWT({
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  })
    .setProtectedHeader({
      alg: 'RS256',
      typ: 'JWT',
      kid: serviceAccount.private_key_id,
    })
    .setIssuer(serviceAccount.client_email)
    .setSubject(serviceAccount.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  const data = await response.json();
  if (!response.ok || typeof data.access_token !== 'string') {
    throw new Error('Google OAuth token request failed.');
  }

  cachedAccessToken = {
    value: data.access_token,
    expiresAt: now + Number(data.expires_in ?? 3600),
  };
  return cachedAccessToken.value;
}

async function sendFcmNotification({
  accessToken,
  projectId,
  token,
  target,
}: {
  accessToken: string;
  projectId: string;
  token: string;
  target: PushTarget;
}): Promise<{ sent: boolean; invalidToken: boolean }> {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title: target.title, body: target.body },
          data: { kind: target.kind, route: 'inbox' },
          android: {
            priority: 'high',
            notification: { channel_id: 'haven_support_updates' },
          },
          apns: {
            headers: { 'apns-priority': '10' },
            payload: { aps: { sound: 'default' } },
          },
        },
      }),
    },
  );

  if (response.ok) return { sent: true, invalidToken: false };
  const error = await response.json().catch(() => null);
  const fcmErrorCode = error?.error?.details?.find(
    (detail: Record<string, unknown>) =>
      detail['@type'] === 'type.googleapis.com/google.firebase.fcm.v1.FcmError',
  )?.errorCode;
  console.error('FCM delivery failed.', response.status, error);
  return {
    sent: false,
    invalidToken:
      fcmErrorCode === 'UNREGISTERED' || fcmErrorCode === 'INVALID_ARGUMENT',
  };
}

function stringValue(value: unknown): string | null {
  return typeof value === 'string' && value.isNotEmpty ? value : null;
}
