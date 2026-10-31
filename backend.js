import { createClient } from 'https://esm.sh/@neondatabase/neon-js@0.8.0-beta';

const config = window.KVK_CONFIG;
const ADMIN_TOKEN_KEY = 'kvkAdminJwt';

export const backend = createClient({
  auth: { url: config.neonAuthUrl, allowAnonymous: true },
  dataApi: { url: config.neonDataApiUrl }
});

export function setAdminJwt(token){
  if(typeof token === 'string' && token.split('.').length === 3){
    sessionStorage.setItem(ADMIN_TOKEN_KEY, token);
    return true;
  }
  return false;
}

export function clearAdminJwt(){
  sessionStorage.removeItem(ADMIN_TOKEN_KEY);
}

export function getAdminJwt(){
  return sessionStorage.getItem(ADMIN_TOKEN_KEY);
}

// Admin database requests use the JWT returned directly by Neon sign-in.
// This deliberately does not depend on Neon Auth's cross-site session cookie.
export const adminBackend = createClient({
  dataApi: {
    url: config.neonDataApiUrl,
    getToken: async () => getAdminJwt()
  }
});

export async function directAdminSignIn(email, password){
  const response = await fetch(`${config.neonAuthUrl}/sign-in/email`, {
    method: 'POST',
    mode: 'cors',
    credentials: 'omit',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    },
    body: JSON.stringify({ email, password })
  });

  let body = null;
  try { body = await response.json(); } catch(_) {}

  if(!response.ok){
    const message = body?.message || body?.error?.message || body?.error || 'Login failed';
    throw new Error(message);
  }

  const headerToken = response.headers.get('set-auth-jwt');
  const token =
    body?.session?.access_token ||
    body?.session?.accessToken ||
    body?.access_token ||
    body?.accessToken ||
    body?.token ||
    headerToken ||
    null;

  if(!setAdminJwt(token)){
    throw new Error('Login succeeded, but Neon did not return an admin JWT.');
  }

  return body;
}

// A private device capability keeps Player ID access available without an email account.
export function playerDeviceId() {
  let id = localStorage.getItem('kvkNeonDeviceId');
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(id || '')) {
    id = crypto.randomUUID();
    localStorage.setItem('kvkNeonDeviceId', id);
  }
  return id;
}

export function playerRpc(name, params = {}) {
  const names = {
    claim_player_profile: 'player_claim_profile',
    save_player_profile: 'player_save_profile',
    submit_slot_requests: 'player_submit_requests'
  };
  return backend.rpc(names[name] || name, { ...params, p_device_id: playerDeviceId() });
}
