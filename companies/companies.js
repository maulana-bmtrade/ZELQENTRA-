import { supabase, escapeHtml, countryName, showState } from '../marketplace/marketplace-client.js';
const results=document.getElementById('companyResults'), search=document.getElementById('companySearch'), country=document.getElementById('countryFilter'), industry=document.getElementById('industryFilter'), count=document.getElementById('companyCount');
let companies=[];
document.getElementById('year').textContent=new Date().getFullYear();
const nav=document.getElementById('mainNav'), toggle=document.getElementById('mobileToggle');
toggle?.addEventListener('click',()=>{const open=!nav.classList.contains('open');nav.classList.toggle('open',open);toggle.setAttribute('aria-expanded',String(open));});
function render(){
 const q=search.value.trim().toLowerCase();
 const rows=companies.filter(c=>(!q||`${c.display_name||''} ${c.industry||''} ${c.country_code||''}`.toLowerCase().includes(q))&&(!country.value||c.country_code===country.value)&&(!industry.value||c.industry===industry.value));
 count.textContent=`${rows.length} public ${rows.length===1?'company':'companies'}`;
 if(!rows.length){results.innerHTML='<div class="directory-state">No public companies match these filters.</div>';return;}
 results.innerHTML=rows.map(c=>`<article class="company-card"><div class="company-avatar">${escapeHtml((c.display_name||'C').trim().charAt(0).toUpperCase())}</div><div class="company-card-copy"><h2>${escapeHtml(c.display_name||'Company')}</h2><p>${escapeHtml(c.industry||'Industry not specified')} · ${escapeHtml(countryName(c.country_code))}</p><a href="profile.html?id=${encodeURIComponent(c.id)}">View public profile ↗</a></div></article>`).join('');
}
async function init(){
 if(!supabase){showState(results,'Supabase configuration required','Configure the public Supabase URL and Publishable Key to load actual company profiles.','error');count.textContent='Directory unavailable';return;}
 try{
  const {data,error}=await supabase.from('public_company_directory').select('id,display_name,country_code,industry,logo_path').order('display_name').range(0,999);
  if(error)throw error;companies=data||[];
  [...new Set(companies.map(c=>c.country_code).filter(Boolean))].sort().forEach(v=>{const o=document.createElement('option');o.value=v;o.textContent=countryName(v);country.append(o);});
  [...new Set(companies.map(c=>c.industry).filter(Boolean))].sort().forEach(v=>{const o=document.createElement('option');o.value=v;o.textContent=v;industry.append(o);});
  render();
 }catch(e){showState(results,'Company directory unavailable',e.message||'Unable to load public company records.','error');count.textContent='Directory unavailable';}
}
[search,country,industry].forEach(el=>el.addEventListener(el===search?'input':'change',render));init();
