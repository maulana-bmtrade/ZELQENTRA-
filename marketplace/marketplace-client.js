import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const config = window.NEXVORA_SUPABASE || {};
const isConfigured = typeof config.url === 'string' && config.url.startsWith('https://') &&
  typeof config.anonKey === 'string' && config.anonKey.trim().length > 0;
export const supabase = isConfigured ? createClient(config.url, config.anonKey, {
  auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
}) : null;
export const PAGE_SIZE = 9;

export function escapeHtml(value) {
  return String(value ?? '').replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
}
export function countryName(code) {
  if (!code) return 'Not specified';
  const value = String(code).trim().toUpperCase();
  try { return new Intl.DisplayNames(['en'], { type: 'region' }).of(value) || value; }
  catch { return value; }
}
export function formatPrice(product) {
  if (product.price_min == null && product.price_max == null) return 'Price on request';
  const currency = String(product.currency || '').trim().toUpperCase();
  const fmt = amount => {
    const n = Number(amount);
    return Number.isFinite(n) ? new Intl.NumberFormat('en-US', { maximumFractionDigits: 2 }).format(n) : '';
  };
  if (product.price_min != null && product.price_max != null && Number(product.price_min) !== Number(product.price_max))
    return `${currency ? currency + ' ' : ''}${fmt(product.price_min)} – ${fmt(product.price_max)}`;
  return `${currency ? currency + ' ' : ''}${fmt(product.price_min ?? product.price_max)}`;
}
// image_paths is a text[] field. The current supplied schema declares only the
// private company-verification bucket, not a public product-image bucket.
// Therefore only complete HTTPS URLs are rendered; storage paths are not guessed.
export function safeProductImage(value) {
  if (typeof value !== 'string' || !value.trim()) return null;
  try {
    const url = new URL(value.trim());
    if (url.protocol !== 'https:') return null;
    return url.href;
  } catch { return null; }
}
export function placeholderMarkup() {
  return '<div class="image-placeholder" aria-label="Product image unavailable"><span>◈</span></div>';
}
export function productImageMarkup(paths, className = '') {
  const first = Array.isArray(paths) ? paths.map(safeProductImage).find(Boolean) : null;
  return first
    ? `<img class="${className}" src="${escapeHtml(first)}" alt="Product image" loading="lazy" referrerpolicy="no-referrer" onerror="this.replaceWith(Object.assign(document.createElement('div'),{className:'image-placeholder',innerHTML:'<span>◈</span>'}))">`
    : placeholderMarkup();
}
export function showState(container, title, message, kind = 'empty', action = '') {
  container.innerHTML = `<div class="catalog-state ${kind}">${kind === 'loading' ? '<span class="loading-spinner"></span>' : ''}<strong>${escapeHtml(title)}</strong><p>${escapeHtml(message)}</p>${action}</div>`;
}
export function safeSearchTerm(value) {
  return String(value || '').trim().slice(0, 100).replace(/[,%()"'\\*_]/g, ' ').replace(/\s+/g, ' ').trim();
}
export function supplierInitial(name) {
  return String(name || 'S').trim().charAt(0).toUpperCase() || 'S';
}
