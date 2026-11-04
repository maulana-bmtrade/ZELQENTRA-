import { supabase, escapeHtml, countryName, formatPrice, safeProductImage, placeholderMarkup, showState, supplierInitial } from './marketplace-client.js';
window.__zelqentraProductModuleReady = true;
const root = document.getElementById('productDetail');
document.getElementById('year').textContent = new Date().getFullYear();
const mobileToggle = document.getElementById('mobileToggle');
const mainNav = document.getElementById('mainNav');
mobileToggle?.addEventListener('click', () => { const open = !mainNav.classList.contains('open'); mainNav.classList.toggle('open', open); mobileToggle.setAttribute('aria-expanded', String(open)); mobileToggle.setAttribute('aria-label', open ? 'Close navigation' : 'Open navigation'); });
mainNav?.querySelectorAll('a').forEach(link => link.addEventListener('click', () => { mainNav.classList.remove('open'); mobileToggle?.setAttribute('aria-expanded', 'false'); }));

function specRows(specifications) {
  if (!specifications || typeof specifications !== 'object' || Array.isArray(specifications) || !Object.keys(specifications).length) return '<p class="detail-note">No additional specifications have been published for this product.</p>';
  return `<table class="spec-table"><tbody>${Object.entries(specifications).map(([key, value]) => `<tr><td>${escapeHtml(key.replace(/[_-]/g, ' '))}</td><td>${escapeHtml(typeof value === 'object' ? JSON.stringify(value) : value)}</td></tr>`).join('')}</tbody></table>`;
}
function priceHtml(product) {
  return `<div class="detail-price"><strong>${escapeHtml(formatPrice(product))}</strong><small>${product.price_min == null && product.price_max == null ? 'Contact the supplier for pricing information.' : 'Indicative listing price; final terms are agreed with the supplier.'}</small></div>`;
}
function renderProduct(product, supplier) {
  const category = product.product_categories?.name || 'Uncategorised';
  const supplierName = supplier?.display_name || 'Supplier details unavailable';
  const images = Array.isArray(product.image_paths) ? product.image_paths.map(safeProductImage).filter(Boolean) : [];
  const firstImage = images[0];
  const gallery = firstImage ? `<img id="mainProductImage" src="${escapeHtml(firstImage)}" alt="${escapeHtml(product.name)}" referrerpolicy="no-referrer">` : placeholderMarkup();
  const thumbs = images.length > 1 ? `<div class="detail-thumbnails">${images.map((src, i) => `<button class="detail-thumb" type="button" data-image-index="${i}" aria-pressed="${i === 0}" aria-label="Show product image ${i + 1}"><img src="${escapeHtml(src)}" alt="" loading="lazy" referrerpolicy="no-referrer"></button>`).join('')}</div>` : '';
  const moq = product.minimum_order_quantity == null ? 'Not specified' : `${Number(product.minimum_order_quantity).toLocaleString('en-US')}${product.unit ? ` ${escapeHtml(product.unit)}` : ''}`;
  root.className = '';
  root.innerHTML = `<article class="product-detail-layout">
    <section aria-label="Product image gallery"><div class="detail-gallery-main" id="detailGallery">${gallery}</div>${thumbs}</section>
    <section class="detail-summary"><div class="detail-kicker"><span class="category-chip">${escapeHtml(category)}</span><span class="status-chip"><i class="availability-dot"></i> Published listing</span></div>
      <h1>${escapeHtml(product.name)}</h1><p class="detail-description">${escapeHtml(product.description || 'No product description has been provided.')}</p>
      ${priceHtml(product)}
      <div class="detail-facts"><div class="detail-fact"><small>Minimum order quantity</small><strong>${moq}</strong></div><div class="detail-fact"><small>Country of origin</small><strong>${escapeHtml(countryName(product.origin_country))}</strong></div><div class="detail-fact"><small>Product category</small><strong>${escapeHtml(category)}</strong></div><div class="detail-fact"><small>Currency</small><strong>${escapeHtml(product.currency || 'Not specified')}</strong></div><div class="detail-fact"><small>Availability</small><strong>Published</strong></div><div class="detail-fact"><small>Listed</small><strong>${product.created_at ? new Date(product.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' }) : 'Not specified'}</strong></div></div>
      <section class="supplier-panel"><h2>Supplier information</h2><div class="supplier-panel-main"><span class="supplier-avatar">${escapeHtml(supplierInitial(supplierName))}</span><div><strong>${escapeHtml(supplierName)}</strong><small>${escapeHtml(supplier?.country_code ? countryName(supplier.country_code) : 'Location not specified')}</small></div></div>${supplier?.industry ? `<p class="supplier-industry">Industry: ${escapeHtml(supplier.industry)}</p>` : ''}<p class="detail-note">Supplier details are limited to information available in the public company directory.</p></section>
    </section></article>
    <div class="detail-sections"><section class="detail-section-card"><h2>Product specifications</h2>${specRows(product.specifications)}</section><section class="detail-section-card"><h2>Product information</h2><p class="detail-note">Product ID: ${escapeHtml(product.id)}</p><p class="detail-note">MOQ, pricing and specifications are displayed only when provided in the published product record. No additional stock quantity or certification data is present in the current public product schema.</p></section></div>`;
  root.querySelectorAll('[data-image-index]').forEach(button => button.addEventListener('click', () => {
    const src = images[Number(button.dataset.imageIndex)]; const galleryNode = root.querySelector('#detailGallery');
    galleryNode.innerHTML = `<img id="mainProductImage" src="${escapeHtml(src)}" alt="${escapeHtml(product.name)}" referrerpolicy="no-referrer">`;
    root.querySelectorAll('[data-image-index]').forEach(item => item.setAttribute('aria-pressed', String(item === button)));
  }));
  // Delegate image failure handling so it also covers every thumbnail selection.
  const galleryNode = root.querySelector('#detailGallery');
  galleryNode?.addEventListener('error', event => {
    if (event.target instanceof HTMLImageElement) galleryNode.innerHTML = placeholderMarkup();
  }, true);
}

async function init() {
  const id = new URLSearchParams(window.location.search).get('id');
  if (!id || !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(id)) {
    showState(root, 'Product not found', 'This product URL does not contain a valid product ID. Return to the marketplace to browse published listings.', 'not-found', '<a class="state-action" href="../">Back to Marketplace</a>'); return;
  }
  if (!supabase) { showState(root, 'Catalog connection unavailable', 'The Supabase project is not configured. Product details cannot be loaded.', 'error', '<a class="state-action" href="../">Back to Marketplace</a>'); return; }
  try {
    const { data: product, error } = await supabase.from('products').select('id,name,slug,description,specifications,minimum_order_quantity,unit,price_min,price_max,currency,origin_country,image_paths,status,created_at,category_id,company_id,product_categories(name)').eq('id', id).eq('status', 'published').maybeSingle();
    if (error) throw error;
    if (!product) { showState(root, 'Product unavailable', 'This listing may have been unpublished, removed, or is not publicly available.', 'not-found', '<a class="state-action" href="../">Back to Marketplace</a>'); return; }
    const { data: supplier, error: supplierError } = await supabase.from('public_company_directory').select('id,display_name,country_code,industry,logo_path').eq('id', product.company_id).maybeSingle();
    if (supplierError) throw supplierError;
    renderProduct(product, supplier);
    document.title = `${product.name} | ZELQENTRA`;
    const description = String(product.description || 'Explore this published product on ZELQENTRA.').replace(/\s+/g, ' ').slice(0, 155);
    document.querySelector('meta[name="description"]')?.setAttribute('content', description);
  } catch (error) {
    console.error('[ZELQENTRA product detail]', { code: error?.code || error?.status || 'UNKNOWN', message: error?.message || 'Request failed' });
    showState(root, 'Product details could not be loaded', error?.message || 'A database request failed. Please try again later.', 'error', '<a class="state-action" href="../">Back to Marketplace</a>');
  }
}
init();
