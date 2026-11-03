const products = [
 {name:"Premium Cocopeat Blocks",category:"Agri & Food",supplier:"IndoGrow Export",location:"Indonesia",symbol:"✺",art:"art-coco",description:"Washed and compressed coconut coir growing medium."},
 {name:"Industrial CNC Equipment",category:"Industrial",supplier:"PrecisionWorks Ltd.",location:"Germany",symbol:"⚙",art:"art-machine",description:"Precision machinery for advanced manufacturing."},
 {name:"Sustainable Packaging",category:"Packaging",supplier:"EcoForm Solutions",location:"Netherlands",symbol:"▤",art:"art-package",description:"Reusable and recyclable packaging solutions."},
 {name:"Enterprise IoT Sensors",category:"Technology",supplier:"NexSense Systems",location:"Singapore",symbol:"⌁",art:"art-tech",description:"Connected monitoring solutions for industry."},
 {name:"Specialty Coffee Beans",category:"Agri & Food",supplier:"Origin Valley Co.",location:"Indonesia",symbol:"◉",art:"art-food",description:"Traceable specialty coffee from selected origins."},
 {name:"Stainless Steel Components",category:"Industrial",supplier:"MetalCore Manufacturing",location:"South Korea",symbol:"⬡",art:"art-metal",description:"Precision components for commercial applications."}
];
const grid=document.getElementById('productGrid');
const search=document.getElementById('marketSearch');
const category=document.getElementById('categoryFilter');
const resultCount=document.getElementById('resultCount');
function renderProducts(list){
 resultCount.textContent=`${list.length} ${list.length===1?'opportunity':'opportunities'} found`;
 if(!list.length){grid.innerHTML='<div class="empty-state">No matching products found. Try another keyword or category.</div>';return;}
 grid.innerHTML=list.map((p,i)=>`<article class="product-card"><div class="product-art ${p.art}"><span class="art-symbol">${p.symbol}</span><span class="art-label">ZELQENTRA MARKETPLACE / 0${i+1}</span></div><div class="product-info"><div class="product-top"><span class="category-pill">${p.category}</span><span class="verified-pill">✓ Listed supplier</span></div><h3>${p.name}</h3><p>${p.description}</p><div class="product-foot"><span>${p.supplier} · ${p.location}</span><button data-product="${p.name}">View details ↗</button></div></div></article>`).join('');
}
function applyFilters(){if(window.NEXVORA?.configured)return;const q=search.value.trim().toLowerCase();const c=category.value;renderProducts(products.filter(p=>(c==='All'||p.category===c)&&(!q||[p.name,p.category,p.supplier,p.location,p.description].join(' ').toLowerCase().includes(q))));}
document.getElementById('searchButton').addEventListener('click',applyFilters);
search.addEventListener('keydown',e=>{if(e.key==='Enter')applyFilters();});
category.addEventListener('change',applyFilters);
document.getElementById('clearFilters').addEventListener('click',()=>{search.value='';category.value='All';applyFilters();});
document.getElementById('showAllProducts').addEventListener('click',()=>{search.value='';category.value='All';applyFilters();if(!window.NEXVORA?.configured)showToast('You are viewing all sample marketplace listings.');});
grid.addEventListener('click',e=>{const btn=e.target.closest('[data-product]');if(btn)showToast(`${btn.dataset.product}: sample listing preview. Product detail pages will be connected in the backend phase.`);});
const backdrop=document.getElementById('modalBackdrop');
function openModal(mode){backdrop.hidden=false;document.body.style.overflow='hidden';}
function closeModal(){backdrop.hidden=true;document.body.style.overflow='';}
document.querySelectorAll('[data-action]').forEach(el=>el.addEventListener('click',e=>{e.preventDefault();openModal(el.dataset.action);}));
document.getElementById('modalClose').addEventListener('click',closeModal);
backdrop.addEventListener('click',e=>{if(e.target===backdrop)closeModal();});
document.addEventListener('keydown',e=>{if(e.key==='Escape')closeModal();});
document.getElementById('leadForm').addEventListener('submit',e=>{e.preventDefault();const data=Object.fromEntries(new FormData(e.target));showToast(`Thanks, ${data.name}. This is a demo form; no account has been created.`);e.target.reset();closeModal();});
let toastTimer;
function showToast(message){const toast=document.getElementById('toast');toast.textContent=message;toast.classList.add('show');clearTimeout(toastTimer);toastTimer=setTimeout(()=>toast.classList.remove('show'),3500);}
const mobileToggle = document.getElementById('mobileToggle');
const mainNav = document.getElementById('mainNav');
function setMobileNavOpen(open) {
 if (!mobileToggle || !mainNav) return;
 mainNav.classList.toggle('open', open);
 mobileToggle.setAttribute('aria-expanded', String(open));
 mobileToggle.setAttribute('aria-label', open ? 'Close navigation' : 'Open navigation');
}
mobileToggle?.addEventListener('click', () => setMobileNavOpen(!mainNav.classList.contains('open')));
mainNav?.querySelectorAll('a').forEach(a => a.addEventListener('click', () => setMobileNavOpen(false)));
document.addEventListener('keydown', event => { if (event.key === 'Escape') setMobileNavOpen(false); });
document.getElementById('year').textContent=new Date().getFullYear();
// Configuration is loaded before this script. Avoid flashing demo listings when
// a live Supabase configuration is present; backend.js must verify a real read.
const publicConfig = window.NEXVORA_SUPABASE || {};
const hasSupabaseConfig = Boolean(
 publicConfig.url && String(publicConfig.url).startsWith('https://') &&
 publicConfig.anonKey && String(publicConfig.anonKey).trim()
);
if (hasSupabaseConfig) {
 window.NEXVORA = { configured: true, mode: 'connecting', connection: { status: 'pending' } };
 resultCount.textContent = 'Connecting to Supabase…';
 grid.innerHTML = '<div class="empty-state">Connecting to the live marketplace…</div>';
 const badge = document.createElement('div');
 badge.id = 'backendStatus';
 badge.setAttribute('role','status');
 badge.style.cssText = 'position:fixed;right:14px;bottom:14px;z-index:9998;padding:8px 12px;border-radius:999px;font:600 11px/1.2 system-ui;letter-spacing:.02em;background:#35445b;color:#fff;box-shadow:0 4px 18px #0002';
 badge.textContent = 'CONNECTING · SUPABASE';
 badge.title = 'Waiting for a read-only database connectivity check.';
 document.body.appendChild(badge);
 // If the module/CDN fails before backend.js can run, do not leave a false
 // connecting state or silently fall back to sample data.
 window.__nexvoraBackendWatchdog = setTimeout(() => {
   if (window.NEXVORA?.mode === 'connecting') {
     window.NEXVORA.mode = 'error';
     const status = document.getElementById('backendStatus');
     if (status) {
       status.textContent = 'BACKEND ERROR · MODULE NOT READY';
       status.style.background = '#9a4b16';
       status.title = 'The backend module did not complete initialization. Check browser network access and module loading.';
     }
     grid.innerHTML = '<div class="empty-state">The backend module did not initialize. Check the browser connection and Supabase JavaScript module loading. Demo listings are not being substituted.</div>';
     resultCount.textContent = 'Backend unavailable';
   }
 }, 20000);
} else {
 renderProducts(products);
}