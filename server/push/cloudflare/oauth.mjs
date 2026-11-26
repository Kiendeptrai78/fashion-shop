let cached;
const bytes = text => new TextEncoder().encode(text);
function base64url(value) {
  const data = typeof value === 'string' ? bytes(value) : new Uint8Array(value);
  return btoa(String.fromCharCode(...data)).replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/, '');
}

export async function accessToken(rawCredential, fetcher = fetch) {
  const account = JSON.parse(rawCredential);
  if (cached?.email === account.client_email && cached.expires > Date.now() + 60000) return cached.token;
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({alg: 'RS256', typ: 'JWT'}));
  const claim = base64url(JSON.stringify({iss: account.client_email,
    scope: 'https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token', iat: now, exp: now + 3600}));
  const unsigned = `${header}.${claim}`;
  const pem = account.private_key.replace(/-----[^-]+-----/g, '').replace(/\s/g, '');
  const key = await crypto.subtle.importKey('pkcs8', Uint8Array.from(atob(pem), c => c.charCodeAt(0)),
    {name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256'}, false, ['sign']);
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, bytes(unsigned));
  const response = await fetcher('https://oauth2.googleapis.com/token', {method: 'POST',
    headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: `${unsigned}.${base64url(signature)}`})});
  const data = await response.json();
  if (!response.ok || !data.access_token) throw new Error('Service account authentication failed');
  cached = {email: account.client_email, token: data.access_token, expires: Date.now() + data.expires_in * 1000};
  return cached.token;
}
