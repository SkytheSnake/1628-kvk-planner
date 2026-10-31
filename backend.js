import { createClient } from 'https://esm.sh/@neondatabase/neon-js@0.8.0-beta';

const config = window.KVK_CONFIG;

// One Neon client owns authentication, session state and Data API token injection.
// Keeping these together avoids cross-version/session mismatches.
export const backend = createClient({
  auth: { url: config.neonAuthUrl, allowAnonymous: true },
  dataApi: { url: config.neonDataApiUrl }
});

// Admin and player code intentionally share the same authenticated client.
export const adminBackend = backend;

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
