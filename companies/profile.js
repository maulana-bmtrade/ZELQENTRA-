import { supabase, escapeHtml, countryName, showState, PAGE_SIZE, formatPrice, productImageMarkup } from '../marketplace/marketplace-client.js';
const profile=document.getElementById('companyProfile'), products=document.getElementById('companyProducts');
document.getElementById('year').textContent=new Date().getFullYear();
function renderCompany(c){
 profile.className='company-profile';
 profile.innerHTML=`<div class="company-avatar large">${escapeHtml((c.display_name||'C').trim().charAt(0).toUpperCase())}</div><div><span class="eyebrow">PUBLIC COMPANY PROFILE</span><h1>${escapeHtml(c.display_name||'Company')}</h1><p>${escapeHtml(c.industry||'Industry not specified')} · ${escapeHtml(countryName(c.country_code))}</p><p class="public-note">This profile contains only fields exposed by public_company_directory. Private contact details, address, verification documents and internal company records are not displayed.</p></div>`;
}
function productCard(p){
 return `<article class="catalog-card"><a class="catalog-card-media" href="../marketplace/product/?id=${encodeURIComponent(p.id)}">${productImageMarkup(p.image_paths)}<span class="media-tag">PUBLISHED LISTING</span></a><div class="catalog-card-body"><h3>${escapeHtml(p.name)}</h3><p class="catalog-card-desc">${escapeHtml(p.description||'')}</p><div class="catalog-card-action"><span>${escapeHtml(formatPrice(p))}</span><a href="../marketplace/product/?id=${encodeURIComponent(p.id)}">View product ↗</a></div></div></article>`;
}
async function init(){
 const id=new URLSearchParams(location.search).get('id');
 if(!id||!/^[0-9a-f-]{36}$/i.test(id)){showState(profile,'Company not found','A valid company ID is required.','not-found');products.replaceChildren();return;}
 if(!supabase){showState(profile,'Supabase configuration required','Configure Supabase to load public company profiles.','error');return;}
 try{
  const {data:c,error}=await supabase.from('public_company_directory').select('id,display_name,country_code,industry,logo_path').eq('id',id).maybeSingle();
  if(error)throw error;if(!c){showState(profile,'Company not publicly available','This company is not listed in the public directory.','not-found');products.replaceChildren();return;}
  renderCompany(c);document.title=`${c.display_name} | ZELQENTRA`;
  const {data,error:productError}=await supabase.from('products').select('id,name,description,image_paths,price_min,price_max,currency,created_at').eq('company_id',id).eq('status','published').order('created_at',{ascending:false}).range(0,PAGE_SIZE-1);
  if(productError)throw productError;
  products.innerHTML=data?.length?data.map(productCard).join():'<div class="catalog-state"><strong>No published products</strong><p>This company has no currently published product listings.</p></div>';
 }catch(e){showState(profile,'Company profile unavailable',e.message||'Unable to load public company profile.','error');}
}
init();
