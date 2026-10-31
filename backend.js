import { createClient } from 'https://esm.sh/@neondatabase/neon-js@0.8.0-beta';

const config = window.KVK_CONFIG;
const ADMIN_TOKEN_KEY = 'kvkPlannerAdminToken';

export function setAdminToken(token){
  if(typeof token === 'string' && token.length >= 32){
    sessionStorage.setItem(ADMIN_TOKEN_KEY, token);
    return true;
  }
  return false;
}

export function getAdminToken(){
  return sessionStorage.getItem(ADMIN_TOKEN_KEY);
}

export function clearAdminToken(){
  sessionStorage.removeItem(ADMIN_TOKEN_KEY);
}

function adminFetch(input, init = {}){
  const headers = new Headers(init.headers || {});
  const token = getAdminToken();
  if(token) headers.set('x-kvk-admin-token', token);
  return fetch(input, { ...init, headers });
}

export const backend = createClient({
  auth: { url: config.neonAuthUrl, allowAnonymous: true },
  dataApi: { url: config.neonDataApiUrl }
});

// Separate anonymous Data API client for the planner-admin session system.
// The real admin identity is carried in x-kvk-admin-token and validated in Postgres.
export const adminBackend = createClient({
  auth: { url: config.neonAuthUrl, allowAnonymous: true },
  dataApi: {
    url: config.neonDataApiUrl,
    options: {
      global: {
        fetch: adminFetch
      }
    }
  }
});

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
