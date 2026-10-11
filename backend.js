import { createClient } from 'https://esm.sh/@neondatabase/neon-js@0.7.0-beta';

const config = window.KVK_CONFIG;
export const backend = createClient({
  auth: { url: config.neonAuthUrl, allowAnonymous: true },
  dataApi: { url: config.neonDataApiUrl }
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
