import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
// supabase-config.js is loaded as a classic script before app.js in index.html.
// This makes configuration available to the legacy frontend before demo rendering.

const cfg = window.NEXVORA_SUPABASE || {};
const configured = Boolean(
  typeof cfg.url === 'string' &&
  cfg.url.startsWith('https://') &&
  typeof cfg.anonKey === 'string' &&
  cfg.anonKey.trim().length > 0
);
// Capture safe transport metadata so opaque browser/network failures do not collapse to UNKNOWN.
const diagnosticTransport = { lastRequest: null };
const diagnosticFetch = async (input, init = {}) => {
  const rawUrl = typeof input === 'string' ? input : (input?.url || '');
  const headers = new Headers(init.headers || (input instanceof Request ? input.headers : undefined));
  diagnosticTransport.lastRequest = {
    endpoint: (() => { try { const u = new URL(rawUrl); return `${u.origin}${u.pathname}`; } catch { return 'unresolved endpoint'; } })(),
    apikeyHeaderPresent: headers.has('apikey'),
    authorizationHeaderPresent: headers.has('authorization'),
    startedAt: new Date().toISOString()
  };
  try {
    const response = await fetch(input, init);
    let body = '';
    try { body = await response.clone().text(); } catch (_) {}
    let parsed = null;
    try { parsed = body ? JSON.parse(body) : null; } catch (_) {}
    diagnosticTransport.lastRequest = {
      ...diagnosticTransport.lastRequest,
      httpStatus: response.status,
      httpStatusText: response.statusText,
      responseBody: parsed ? JSON.stringify(parsed).slice(0, 1800) : body.slice(0, 1800),
      completedAt: new Date().toISOString()
    };
    return response;
  } catch (cause) {
    diagnosticTransport.lastRequest = {
      ...diagnosticTransport.lastRequest,
      networkError: safeValue(cause),
      completedAt: new Date().toISOString()
    };
    throw cause;
  }
};
const supabase = configured ? createClient(cfg.url, cfg.anonKey, {
  auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true },
  global: { fetch: diagnosticFetch }
}) : null;
window.NEXVORA = { configured, supabase, mode: configured ? 'connecting' : 'demo' };

function setBackendStatus(mode, message) {
  window.NEXVORA.mode = mode;
  if (mode === 'live' || mode === 'error' || mode === 'demo') {
    clearTimeout(window.__nexvoraBackendWatchdog);
  }
  let badge = document.getElementById('backendStatus');
  if (!badge) { badge = document.createElement('div'); badge.id = 'backendStatus'; badge.setAttribute('role','status'); badge.style.cssText = 'position:fixed;right:14px;bottom:14px;z-index:9998;padding:8px 12px;border-radius:999px;font:600 11px/1.2 system-ui;letter-spacing:.02em;background:#17231f;color:#fff;box-shadow:0 4px 18px #0002'; document.body.appendChild(badge); }
  badge.textContent = message;
  badge.title = mode === 'live' ? 'Connected to Supabase; marketplace data is from the database.' : mode === 'error' ? 'Supabase configuration exists but a live request failed. No demo listings are substituted.' : 'Supabase is not configured. Live data is unavailable; no sample listings are substituted.';
  badge.style.background = mode === 'live' ? '#176b4b' : mode === 'error' ? '#9a4b16' : '#35445b';
}

function safeValue(value) {
  try {
    if (value === null) return 'null';
    if (value === undefined) return 'undefined';
    if (typeof value === 'string') return value.slice(0, 1800);
    if (typeof value !== 'object') return String(value);
    const parts = {};
    for (const key of ['name','message','code','status','statusCode','details','hint','cause','type']) {
      if (value[key] !== undefined) parts[key] = typeof value[key] === 'string' ? value[key].slice(0, 1800) : String(value[key]);
    }
    if (!Object.keys(parts).length) parts.serialized = JSON.stringify(value, Object.getOwnPropertyNames(value)).slice(0, 1800);
    return JSON.stringify(parts);
  } catch (_) { return String(value); }
}
const form = document.getElementById('leadForm');
const note = document.getElementById('authFormNote');
const modalTitle = document.getElementById('modalTitle');
const modalDescription = document.getElementById('modalDescription');
let authMode = 'signup';
const toast = (message) => {
  const el = document.getElementById('toast'); if (!el) return;
  el.textContent = message; el.classList.add('show');
  clearTimeout(window.__nexvoraToastTimer);
  window.__nexvoraToastTimer = setTimeout(() => el.classList.remove('show'), 4200);
};
const field = (name) => form?.elements.namedItem(name);
function setFieldVisible(name, visible) {
  const input = field(name); if (!input) return;
  const label = input.closest('label'); if (label) label.hidden = !visible;
  input.required = visible && ['name','email','password','company'].includes(name);
}
function configureAuthForm(mode) {
  authMode = mode;
  const login = mode === 'login';
  const reset = mode === 'reset';
  modalTitle.textContent = reset ? 'Reset your password.' : login ? 'Welcome back to ZELQENTRA.' : 'Create your business presence.';
  modalDescription.textContent = reset ? 'We will email you a secure password reset link.' : login ? 'Sign in to continue to your business workspace.' : 'Create an account to start building your business presence.';
  setFieldVisible('name', !login && !reset);
  setFieldVisible('company', !login && !reset);
  setFieldVisible('role', !login && !reset);
  setFieldVisible('password', !reset);
  const consent = field('legal_consent');
  if (consent) { const label = consent.closest('label'); if (label) label.hidden = login || reset; consent.required = !login && !reset; consent.checked = false; }
  setFieldVisible('email', true);
  const role = field('role'); if (role) role.innerHTML = '<option value="buyer">Buyer</option><option value="supplier">Supplier</option>';
  const password = field('password'); if (password) { password.autocomplete = login ? 'current-password' : 'new-password'; password.minLength = 8; }
  const submit = form.querySelector('button[type="submit"]'); submit.innerHTML = reset ? 'Send reset link <span>→</span>' : login ? 'Log in <span>→</span>' : 'Create account <span>→</span>';
  note.textContent = configured ? 'Your account is protected by Supabase authentication.' : 'Backend is not connected yet. Configure supabase-config.js and apply the database migration.';
  if (!configured) note.textContent += ' Demo interactions remain available.';
}

// Capture the existing frontend modal triggers without replacing the existing UI.
document.querySelectorAll('[data-action]').forEach(el => el.addEventListener('click', () => {
  configureAuthForm(el.dataset.action === 'login' ? 'login' : 'signup');
}, true));
document.addEventListener('click', async (event) => {
  const action = event.target.closest('[data-action]')?.dataset.action;
  if (action === 'account') {
    event.preventDefault(); event.stopImmediatePropagation();
    if (confirm('Sign out of your ZELQENTRA account?')) { try { await window.NEXVORA_API.signOut(); } catch (err) { toast(err.message); } }
  }
}, true);
form?.addEventListener('submit', async (event) => {
  event.preventDefault(); event.stopImmediatePropagation();
  if (!configured) { toast('Supabase is not configured. Follow BACKEND_SETUP.md to connect the backend.'); return; }
  const email = field('email').value.trim();
  try {
    if (authMode === 'reset') {
      const { error } = await supabase.auth.resetPasswordForEmail(email, { redirectTo: new URL('/', window.location.origin).toString() });
      if (error) throw error;
      toast('Password reset instructions have been sent if the account exists.');
    } else if (authMode === 'login') {
      const { error } = await supabase.auth.signInWithPassword({ email, password: field('password').value });
      if (error) throw error;
      const { data: userData, error: userError } = await supabase.auth.getUser();
      if (userError) throw userError;
      await ensureCompanyWorkspace(userData.user);
      toast('Signed in successfully.');
      await refreshSessionUI();
    } else {
      const { data, error } = await supabase.auth.signUp({
        email, password: field('password').value,
        options: { emailRedirectTo: new URL('/', window.location.origin).toString(), data: { full_name: field('name').value.trim(), account_type: field('role').value, company_name: field('company').value.trim() } }
      });
      if (error) throw error;
      if (data.session) {
        await ensureCompanyWorkspace(data.user);
        toast('Account created. Your company workspace is ready.');
      } else {
        toast('Check your email to confirm your account. Your company workspace will be created after your first confirmed login.');
      }
      await refreshSessionUI();
    }
    document.getElementById('modalBackdrop').hidden = true;
    document.body.style.overflow = '';
    form.reset();
  } catch (err) {
    console.error('[ZELQENTRA auth]', err);
    toast(err.message || 'Authentication failed. Please try again.');
  }
}, true);

async function ensureCompanyWorkspace(user) {
  const companyName = user?.user_metadata?.company_name;
  if (!companyName || !supabase) return null;
  const { data, error } = await supabase.rpc('create_company_workspace', { p_company_name: companyName });
  if (error) throw error;
  return data;
}

async function refreshSessionUI() {
  if (!supabase) return;
  const { data: { session }, error } = await supabase.auth.getSession();
  if (error) { console.warn('[ZELQENTRA session]', error.message); }
  const loginButton = document.querySelector('.header-actions [data-action="login"], .header-actions [data-action="account"]');
  if (loginButton) {
    loginButton.textContent = session ? 'Account' : 'Log in';
    loginButton.dataset.action = session ? 'account' : 'login';
  }
}

async function loadLiveProducts() {
  if (!supabase) { setBackendStatus('setup', 'SETUP REQUIRED · SUPABASE NOT CONFIGURED'); return; }
  const grid = document.getElementById('productGrid');
  const category = document.getElementById('categoryFilter');
  const searchInput = document.getElementById('marketSearch');
  setBackendStatus('connecting', 'CONNECTING · SUPABASE DATABASE');
  grid.innerHTML = '<div class="empty-state">Loading live marketplace listings from Supabase…</div>';
  document.getElementById('resultCount').textContent = 'Connecting to database…';
  let diagnosticStage = 'client initialization';
  try {
    // Read-only connectivity probe. A successful response proves the configured
    // public key can reach PostgREST and read this table under its current RLS policy.
    diagnosticStage = 'products table connectivity probe';
    const probe = await supabase
  .from('products')
  .select('id')
  .limit(1);
    if (probe.error) throw probe.error;

    diagnosticStage = 'published products query and product_categories relationship';
    const { data, error } = await supabase.from('products')
      .select('id,name,description,origin_country,category_id,created_at,product_categories(name),company_id')
      .eq('status','published').order('created_at',{ascending:false}).range(0,59);
    if (error) throw error;
    const companyIds = [...new Set((data || []).map(p => p.company_id).filter(Boolean))];
    let companies = [];
    if (companyIds.length) {
      diagnosticStage = 'public_company_directory lookup';
      const result = await supabase.from('public_company_directory').select('id,display_name,country_code').in('id', companyIds);
      if (result.error) throw result.error;
      companies = result.data || [];
    }
    const byCompany = new Map(companies.map(c => [c.id,c]));
    const live = (data || []).map(p => ({...p, companies: byCompany.get(p.company_id) || null}));
    window.NEXVORA.connection = {
      status: 'verified',
      checkedAt: new Date().toISOString(),
      source: 'products + public_company_directory',
      readOnly: true
    };
    window.__nexvoraLiveProducts = live;
    if (!live.length) {
      setBackendStatus('live', 'LIVE DATABASE · 0 PUBLISHED LISTINGS');
      grid.innerHTML = '<div class="empty-state">No published database listings yet. Demo listings are not being substituted.</div>';
      document.getElementById('resultCount').textContent = '0 live database listings';
      return;
    }
    setBackendStatus('live', 'LIVE DATABASE · SUPABASE CONNECTED');
    const render = (items) => {
      document.getElementById('resultCount').textContent = `${items.length} live database listings`;
      grid.innerHTML = items.map((p,i) => `<article class="product-card"><div class="product-art ${['art-coco','art-machine','art-package','art-tech','art-food','art-metal'][i%6]}"><span class="art-symbol">◈</span><span class="art-label">LIVE LISTING / ${String(i+1).padStart(2,'0')}</span></div><div class="product-info"><div class="product-top"><span class="category-pill">${escapeHtml(p.product_categories?.name || 'Business')}</span><span class="verified-pill">● Published</span></div><h3>${escapeHtml(p.name)}</h3><p>${escapeHtml(p.description || '')}</p><div class="product-foot"><span>${escapeHtml(p.companies?.display_name || 'Supplier')} · ${escapeHtml(p.companies?.country_code || p.origin_country || '')}</span><button data-live-product="${p.id}">Request details ↗</button></div></div></article>`).join('');
    };
    const apply = () => {
      const q = searchInput.value.toLowerCase().trim(); const cat = category.value;
      render(live.filter(p => (!q || `${p.name} ${p.description} ${p.companies?.display_name || ''}`.toLowerCase().includes(q)) && (cat==='All' || p.product_categories?.name===cat)));
    };
    render(live);
    document.getElementById('searchButton').onclick = apply;
    searchInput.onkeydown = e => { if(e.key==='Enter') apply(); };
    category.onchange = apply;
    document.getElementById('clearFilters').onclick = () => { searchInput.value=''; category.value='All'; apply(); };
    document.getElementById('showAllProducts').onclick = () => {
      searchInput.value = '';
      category.value = 'All';
      apply();
    };
  } catch (error) {
    // Keep diagnostics useful without ever exposing the configured key or auth tokens.
    const transport = diagnosticTransport.lastRequest;
    const diagnostic = {
      stage: diagnosticStage,
      code: String(error?.code || error?.status || error?.statusCode || transport?.httpStatus || 'UNKNOWN'),
      message: String(error?.message || error?.error_description || safeValue(error) || 'No error message returned'),
      details: String(error?.details || ''),
      hint: String(error?.hint || ''),
      transport: transport || null
    };
    console.error('[ZELQENTRA read-only connection verification]', diagnostic);
    window.NEXVORA.connection = {
      status: 'failed',
      checkedAt: new Date().toISOString(),
      readOnly: true,
      diagnostic
    };
    setBackendStatus('error', 'BACKEND ERROR · DATABASE UNAVAILABLE');
    const reason = safeConnectionReason(error);
    const box = document.createElement('div');
    box.className = 'empty-state';
    const summary = document.createElement('p');
    summary.textContent = `Supabase could not be verified. ${reason} No demo listings are being substituted.`;
    const technical = document.createElement('pre');
    technical.style.cssText = 'white-space:pre-wrap;overflow-wrap:anywhere;text-align:left;font:12px/1.5 ui-monospace,monospace;margin:18px 0 0;padding:12px;border:1px solid #d9e1e8;border-radius:10px;background:#f7f9fc;color:#26364a';
    technical.textContent = [
      `Diagnostic stage: ${diagnostic.stage}`,
      `Error code/status: ${diagnostic.code}`,
      `Message: ${diagnostic.message}`,
      diagnostic.details ? `Details: ${diagnostic.details}` : '',
      diagnostic.hint ? `Hint: ${diagnostic.hint}` : '',
      diagnostic.transport ? `Request endpoint: ${diagnostic.transport.endpoint}` : '',
      diagnostic.transport ? `apikey header present: ${diagnostic.transport.apikeyHeaderPresent}` : '',
      diagnostic.transport?.httpStatus ? `HTTP response: ${diagnostic.transport.httpStatus} ${diagnostic.transport.httpStatusText || ''}` : '',
      diagnostic.transport?.responseBody ? `HTTP response body: ${diagnostic.transport.responseBody}` : '',
      diagnostic.transport?.networkError ? `Network exception: ${diagnostic.transport.networkError}` : ''
    ].filter(Boolean).join('\n');
    box.append(summary, technical);
    grid.replaceChildren(box);
    document.getElementById('resultCount').textContent = `Live data unavailable · ${diagnostic.code}`;
  }
}
function safeConnectionReason(error) {
  const code = String(error?.code || '');
  const message = String(error?.message || '').toLowerCase();
  if (code === '401' || code === '403' || code.startsWith('PGRST3') || message.includes('permission denied') || message.includes('row-level security')) {
    return 'The request was rejected. Check the Publishable Key, table permissions and Row Level Security policies.';
  }
  if (code === '42P01' || code === 'PGRST205' || message.includes('does not exist') || message.includes('schema cache')) {
    return 'The expected database table or relationship was not found. Check whether the required migrations have been applied.';
  }
  if (message.includes('failed to fetch') || message.includes('network') || message.includes('load failed')) {
    return 'A network request failed. Check the website connection, Supabase URL, DNS and browser network restrictions.';
  }
  return 'The database request failed. Check the Supabase project status, configuration and database policies.';
}
function escapeHtml(value) { return String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }

// Small browser-side service surface for the next dashboard iteration. RLS remains authoritative.
window.NEXVORA_API = {
  async getSession() { if (!supabase) throw new Error('Supabase is not configured'); return (await supabase.auth.getSession()).data.session; },
  async signOut() { if (!supabase) return; const {error}=await supabase.auth.signOut(); if(error) throw error; await refreshSessionUI(); toast('You have signed out.'); },
  async createCompany(input) { requireClient(); const name = String(input?.legal_name || input?.display_name || '').trim(); if (!name) throw new Error('Company name is required.'); const {data,error}=await supabase.rpc('create_company_workspace',{p_company_name:name}); if(error) throw error; return {id:data}; },
  async listMyCompanies() { requireClient(); const {data,error}=await supabase.from('company_members').select('role,companies(*)'); if(error) throw error; return data; },
  async createProduct(input) { requireClient(); const {data:{user}}=await supabase.auth.getUser(); const {data,error}=await supabase.from('products').insert({...input,created_by:user.id,status:'pending_review'}).select().single(); if(error) throw error; return data; },
  async updateProduct(id,input) { requireClient(); const {data,error}=await supabase.from('products').update(input).eq('id',id).select().single(); if(error) throw error; return data; },
  async deleteProduct(id) { requireClient(); const {error}=await supabase.from('products').delete().eq('id',id); if(error) throw error; },
  async createBuyerRequest(input) {
    requireClient();
    const companyId = input?.buyer_company_id || input?.company_id;
    if (!companyId) throw new Error('buyer_company_id is required.');
    const { data: requestId, error } = await supabase.rpc('publish_buyer_request_with_rfq', {
      p_company_id: companyId,
      p_title: input.title,
      p_description: input.description,
      p_category_id: input.product_category_id || null,
      p_quantity: input.quantity,
      p_unit: input.unit,
      p_destination_country: input.destination_country,
      p_target_delivery_date: input.target_delivery_date || null
    });
    if (error) throw error;
    const [{ data: request, error: requestError }, { data: rfq, error: rfqError }] = await Promise.all([
      supabase.from('buyer_requests').select('*').eq('id', requestId).single(),
      supabase.from('rfqs').select('*').eq('buyer_request_id', requestId).single()
    ]);
    if (requestError) throw requestError;
    if (rfqError) throw rfqError;
    return { request, rfq };
  },
  async submitQuotation(input) { requireClient(); const {data:{user}}=await supabase.auth.getUser(); const {data,error}=await supabase.from('quotations').insert({...input,submitted_by:user.id}).select().single(); if(error) throw error; return data; },
  async listOpenRFQs() { requireClient(); const {data,error}=await supabase.from('rfqs').select('*,buyer_requests!inner(*)').or(`expires_at.is.null,expires_at.gt.${new Date().toISOString()}`).eq('buyer_requests.status','open').order('created_at',{ascending:false}); if(error) throw error; return data; },
  async adminOverview() { requireClient(); const {data,error}=await supabase.rpc('nexvora_admin_overview'); if(error) throw error; return data; },
  async uploadVerificationDocument(companyId,file,documentType) {
    requireClient();
    const allowed=['application/pdf','image/jpeg','image/png'];
    if(!allowed.includes(file.type) || file.size>10*1024*1024) throw new Error('Only PDF/JPG/PNG files up to 10 MB are accepted.');
    const {data:{user}}=await supabase.auth.getUser();
    const safeName=file.name.replace(/[^a-zA-Z0-9._-]/g,'_'); const path=`${user.id}/${companyId}/${crypto.randomUUID()}-${safeName}`;
    const upload=await supabase.storage.from('company-verification').upload(path,file,{contentType:file.type,upsert:false}); if(upload.error) throw upload.error;
    const {data,error}=await supabase.from('verification_documents').insert({company_id:companyId,uploaded_by:user.id,document_type:documentType,storage_path:path,original_filename:file.name,mime_type:file.type,file_size_bytes:file.size}).select().single();
    if(error) { await supabase.storage.from('company-verification').remove([path]); throw error; } return data;
  }
};
function requireClient(){if(!supabase) throw new Error('Supabase is not configured.');}

configureAuthForm('signup');
if (supabase) {
  supabase.auth.onAuthStateChange((event) => {
    setTimeout(async () => {
      await refreshSessionUI();
      if (event === 'SIGNED_IN') {
        try {
          const { data, error } = await supabase.auth.getUser();
          if (!error && data.user) await ensureCompanyWorkspace(data.user);
        } catch (error) {
          console.warn('[ZELQENTRA workspace setup]', error.message);
          toast(`Company workspace setup needs attention: ${error.message}`);
        }
      } else if (event === 'PASSWORD_RECOVERY') {
        const nextPassword = window.prompt('Enter your new password (at least 8 characters):');
        if (nextPassword === null) {
          toast('Password update cancelled. Open the recovery link again to retry.');
          return;
        }
        if (nextPassword.length < 8) {
          toast('Password must contain at least 8 characters. Open the recovery link again to retry.');
          return;
        }
        const confirmation = window.prompt('Confirm your new password:');
        if (confirmation !== nextPassword) {
          toast('Passwords do not match. Open the recovery link again to retry.');
          return;
        }
        const { error } = await supabase.auth.updateUser({ password: nextPassword });
        if (error) toast(`Password update failed: ${error.message}`);
        else toast('Your password has been updated successfully.');
      }
    }, 0);
  });
  refreshSessionUI();
  loadLiveProducts();
} else {
  setBackendStatus('setup', 'SETUP REQUIRED · SUPABASE NOT CONFIGURED');
  console.info('[ZELQENTRA] Backend is in setup mode. No sample records are substituted.');
}
