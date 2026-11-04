import { supabase, PAGE_SIZE, escapeHtml, countryName, formatPrice, productImageMarkup, showState, safeSearchTerm, supplierInitial } from './marketplace-client.js';
window.__zelqentraMarketplaceModuleReady = true;

const grid = document.getElementById('productResults');
const searchInput = document.getElementById('marketSearch');
const categoryFilter = document.getElementById('categoryFilter');
const countryFilter = document.getElementById('countryFilter');
const sortFilter = document.getElementById('sortFilter');
const countLabel = document.getElementById('resultCount');
const pagination = document.getElementById('pagination');
let currentPage = 0;
let requestSequence = 0;
let debounceTimer;

const mobileToggle = document.getElementById('mobileToggle');
const mainNav = document.getElementById('mainNav');
mobileToggle?.addEventListener('click', () => {
  const open = !mainNav.classList.contains('open');
  mainNav.classList.toggle('open', open);
  mobileToggle.setAttribute('aria-expanded', String(open));
  mobileToggle.setAttribute('aria-label', open ? 'Close navigation' : 'Open navigation');
});
mainNav?.querySelectorAll('a').forEach(link => link.addEventListener('click', () => {
  mainNav.classList.remove('open'); mobileToggle?.setAttribute('aria-expanded', 'false');
}));
document.getElementById('year').textContent = new Date().getFullYear();

function cardMarkup(product) {
  const company = product.supplier || {};
  const companyName = company.display_name || 'Supplier information unavailable';
  const category = product.product_categories?.name || 'Uncategorised';
  const origin = countryName(product.origin_country);
  const description = String(product.description || '').trim();
  const shortDescription = description.length > 116 ? `${description.slice(0, 113).trim()}…` : (description || 'No product description has been provided.');
  const moq = product.minimum_order_quantity == null ? 'MOQ not specified' : `MOQ ${Number(product.minimum_order_quantity).toLocaleString('en-US')}${product.unit ? ` ${escapeHtml(product.unit)}` : ''}`;
  return `<article class="catalog-card">
    <a class="catalog-card-media" href="product/?id=${encodeURIComponent(product.id)}" aria-label="View ${escapeHtml(product.name)}">${productImageMarkup(product.image_paths)}<span class="media-tag">PUBLISHED LISTING</span></a>
    <div class="catalog-card-body"><div class="catalog-card-meta"><span class="category-chip">${escapeHtml(category)}</span><span class="status-chip"><i class="availability-dot"></i> Published</span></div>
    <h3>${escapeHtml(product.name)}</h3><p class="catalog-card-desc">${escapeHtml(shortDescription)}</p>
    <div class="catalog-card-supplier"><span class="supplier-avatar">${escapeHtml(supplierInitial(companyName))}</span><div><strong>${escapeHtml(companyName)}</strong><small>${escapeHtml(company.country_code ? countryName(company.country_code) : 'Supplier')}</small></div></div>
    <div class="catalog-card-facts"><span>${escapeHtml(origin)}</span><b>${escapeHtml(moq)}</b></div>
    <div class="catalog-card-action"><span>${escapeHtml(formatPrice(product))}</span><a href="product/?id=${encodeURIComponent(product.id)}">View product ↗</a></div></div></article>`;
}

async function loadFilters() {
  if (!supabase) throw new Error('Supabase is not configured. Add the project URL and Publishable Key to supabase-config.js.');
  const [categoriesResult, countriesResult] = await Promise.all([
    supabase.from('product_categories').select('id,name').eq('is_active', true).order('sort_order', { ascending: true }).order('name'),
    supabase.from('products').select('origin_country').eq('status', 'published').not('origin_country', 'is', null).order('origin_country').range(0, 999)
  ]);
  if (categoriesResult.error) throw categoriesResult.error;
  if (countriesResult.error) throw countriesResult.error;
  for (const category of categoriesResult.data || []) {
    const option = document.createElement('option'); option.value = category.id; option.textContent = category.name; categoryFilter.append(option);
  }
  const params = new URLSearchParams(window.location.search);
  const initialQuery = params.get('q'); if (initialQuery) searchInput.value = initialQuery.slice(0, 100);
  const initialCategory = params.get('category');
  if (initialCategory) { const match = [...categoryFilter.options].find(option => option.textContent.toLowerCase() === initialCategory.toLowerCase()); if (match) categoryFilter.value = match.value; }
  const countries = [...new Set((countriesResult.data || []).map(row => row.origin_country).filter(Boolean))];
  countries.forEach(code => { const option = document.createElement('option'); option.value = code; option.textContent = countryName(code); countryFilter.append(option); });
}

async function fetchProducts(sequence) {
  if (!supabase) throw new Error('Supabase is not configured.');
  let query = supabase.from('products').select('id,name,slug,description,specifications,minimum_order_quantity,unit,price_min,price_max,currency,origin_country,image_paths,status,created_at,category_id,company_id,product_categories(name)', { count: 'exact' }).eq('status', 'published');
  const term = safeSearchTerm(searchInput.value);
  if (term) {
    const supplierMatches = await supabase.from('public_company_directory').select('id').ilike('display_name', `%${term}%`).limit(100);
    if (supplierMatches.error) throw supplierMatches.error;
    const supplierIds = (supplierMatches.data || []).map(row => row.id).filter(Boolean);
    const clauses = [`name.ilike.%${term}%`, `description.ilike.%${term}%`];
    if (supplierIds.length) clauses.push(`company_id.in.(${supplierIds.join(',')})`);
    query = query.or(clauses.join(','));
  }
  if (categoryFilter.value) query = query.eq('category_id', categoryFilter.value);
  if (countryFilter.value) query = query.eq('origin_country', countryFilter.value);
  if (sortFilter.value === 'oldest') query = query.order('created_at', { ascending: true }).order('id', { ascending: true });
  else if (sortFilter.value === 'name') query = query.order('name', { ascending: true }).order('id', { ascending: true });
  else query = query.order('created_at', { ascending: false }).order('id', { ascending: true });
  const from = currentPage * PAGE_SIZE;
  const { data, error, count } = await query.range(from, from + PAGE_SIZE - 1);
  if (error) throw error;
  if (sequence !== requestSequence) return;
  const companyIds = [...new Set((data || []).map(row => row.company_id).filter(Boolean))];
  let suppliers = [];
  if (companyIds.length) {
    const supplierResult = await supabase.from('public_company_directory').select('id,display_name,country_code,industry,logo_path').in('id', companyIds);
    if (supplierResult.error) throw supplierResult.error;
    suppliers = supplierResult.data || [];
  }
  if (sequence !== requestSequence) return;
  const supplierMap = new Map(suppliers.map(company => [company.id, company]));
  return { rows: (data || []).map(row => ({ ...row, supplier: supplierMap.get(row.company_id) || null })), count: count || 0 };
}

function renderPagination(total) {
  const pages = Math.ceil(total / PAGE_SIZE);
  if (pages <= 1) { pagination.hidden = true; pagination.replaceChildren(); return; }
  pagination.hidden = false;
  const start = Math.max(0, Math.min(currentPage - 2, pages - 5));
  const end = Math.min(pages, start + 5);
  const buttons = [`<button type="button" data-page="${currentPage - 1}" ${currentPage === 0 ? 'disabled' : ''} aria-label="Previous page">‹</button>`];
  for (let i = start; i < end; i++) buttons.push(`<button type="button" data-page="${i}" ${i === currentPage ? 'aria-current="page"' : ''} aria-label="Page ${i + 1}">${i + 1}</button>`);
  buttons.push(`<button type="button" data-page="${currentPage + 1}" ${currentPage >= pages - 1 ? 'disabled' : ''} aria-label="Next page">›</button>`);
  pagination.innerHTML = buttons.join('');
}

async function refresh() {
  const sequence = ++requestSequence;
  showState(grid, 'Loading marketplace', 'Retrieving published products and public supplier details from Supabase.', 'loading');
  countLabel.textContent = 'Loading live listings…';
  try {
    const result = await fetchProducts(sequence);
    if (!result || sequence !== requestSequence) return;
    countLabel.textContent = `${result.count.toLocaleString('en-US')} published ${result.count === 1 ? 'product' : 'products'}`;
    if (!result.rows.length) {
      showState(grid, 'No products found', 'There are no published products matching these filters. Try another keyword or reset your filters.');
      pagination.hidden = true; pagination.replaceChildren(); return;
    }
    grid.innerHTML = result.rows.map(cardMarkup).join('');
    renderPagination(result.count);
  } catch (error) {
    if (sequence !== requestSequence) return;
    console.error('[ZELQENTRA marketplace]', { code: error?.code || error?.status || 'UNKNOWN', message: error?.message || 'Request failed' });
    countLabel.textContent = 'Live catalog unavailable';
    showState(grid, 'Marketplace could not be loaded', error?.message || 'A database request failed. Please try again later.', 'error', '<button class="button button-outline state-action" type="button" id="retryCatalog">Try again</button>');
    pagination.hidden = true;
    document.getElementById('retryCatalog')?.addEventListener('click', refresh, { once: true });
  }
}

function resetPageAndRefresh() { currentPage = 0; refresh(); }
document.getElementById('searchButton').addEventListener('click', resetPageAndRefresh);
searchInput.addEventListener('keydown', event => { if (event.key === 'Enter') resetPageAndRefresh(); });
searchInput.addEventListener('input', () => { clearTimeout(debounceTimer); debounceTimer = setTimeout(resetPageAndRefresh, 350); });
[categoryFilter, countryFilter, sortFilter].forEach(control => control.addEventListener('change', resetPageAndRefresh));
document.getElementById('clearFilters').addEventListener('click', () => { searchInput.value = ''; categoryFilter.value = ''; countryFilter.value = ''; sortFilter.value = 'newest'; resetPageAndRefresh(); });
pagination.addEventListener('click', event => { const button = event.target.closest('button[data-page]'); if (!button || button.disabled) return; currentPage = Number(button.dataset.page); refresh(); window.scrollTo({ top: document.querySelector('.market-results-head').offsetTop - 25, behavior: 'smooth' }); });

(async () => {
  if (!supabase) {
    countLabel.textContent = 'Supabase configuration required';
    showState(grid, 'Connect the live catalog', 'This marketplace intentionally does not display sample products. Configure the existing Supabase project URL and Publishable Key to load published listings.', 'error');
    return;
  }
  try { await loadFilters(); await refresh(); }
  catch (error) {
    console.error('[ZELQENTRA marketplace setup]', { code: error?.code || error?.status || 'UNKNOWN', message: error?.message || 'Request failed' });
    countLabel.textContent = 'Catalog setup unavailable';
    showState(grid, 'Marketplace could not be initialized', error?.message || 'Check Supabase connectivity and public read permissions.', 'error', '<button class="button button-outline state-action" type="button" id="retryCatalog">Try again</button>');
    document.getElementById('retryCatalog')?.addEventListener('click', async () => { try { await loadFilters(); await refresh(); } catch (e) { showState(grid, 'Still unavailable', e.message, 'error'); } }, { once: true });
  }
})();
