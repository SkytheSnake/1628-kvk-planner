import { createClient as createClientV07 } from 'https://esm.sh/@neondatabase/neon-js@0.7.0-beta';
import { createClient as createClientV08 } from 'https://esm.sh/@neondatabase/neon-js@0.8.0-beta';

const config = window.KVK_CONFIG;

const ADMIN_TOKEN_KEY = 'kvkAdminAccessToken';

function tokenExpiry(token) {
  try {
    const payload = token.split('.')[1];
    const padded = payload.replace(/-/g, '+').replace(/_/g, '/').padEnd(Math.ceil(payload.length / 4) * 4, '=');
    return Number(JSON.parse(atob(padded)).exp || 0);
  } catch {
    return 0;
  }
}

export function setAdminAccessToken(token) {
  if (typeof token === 'string' && token.split('.').length === 3) {
    sessionStorage.setItem(ADMIN_TOKEN_KEY, token);
  }
}

export function clearAdminAccessToken() {
  sessionStorage.removeItem(ADMIN_TOKEN_KEY);
}

export function getStoredAdminAccessToken() {
  const token = sessionStorage.getItem(ADMIN_TOKEN_KEY);
  if (!token) return null;
  const exp = tokenExpiry(token);
  if (!exp || exp <= Math.floor(Date.now() / 1000) + 15) {
    clearAdminAccessToken();
    return null;
  }
  return token;
}

export const backend = createClientV07({
  auth: { url: config.neonAuthUrl, allowAnonymous: true },
  dataApi: { url: config.neonDataApiUrl }
});

// Admin database traffic uses the JWT returned by sign-in directly.
// This avoids relying on cross-site auth cookies that mobile Safari can block.
export const adminBackend = createClientV08({
  dataApi: {
    url: config.neonDataApiUrl,
    getToken: async () => getStoredAdminAccessToken()
  }
});

// A private device capability keeps Player ID access available without an email account.
// Administrative permissions always use the signed-in Neon Auth identity instead.
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
