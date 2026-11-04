#!/usr/bin/env python3
"""Offline structural QA for the static ZELQENTRA Phase 2 package."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
class Page(HTMLParser):
    def __init__(self):
        super().__init__(); self.refs=[]; self.ids=[]
    def handle_starttag(self, tag, attrs):
        attrs=dict(attrs)
        if attrs.get('id'): self.ids.append(attrs['id'])
        for key in ('href','src'):
            if attrs.get(key): self.refs.append((key,attrs[key]))

errors=[]
for html in ROOT.rglob('*.html'):
    page=Page(); page.feed(html.read_text(errors='replace'))
    if len(page.ids)!=len(set(page.ids)): errors.append(f'duplicate HTML id: {html.relative_to(ROOT)}')
    for key,value in page.refs:
        if value.startswith(('#','//','http:','https:','mailto:','tel:','data:','javascript:')): continue
        path=urlparse(value).path
        if not path: continue
        target=(html.parent/path).resolve()
        if target.is_dir(): target=target/'index.html'
        if not target.exists(): errors.append(f'missing {key} {value} in {html.relative_to(ROOT)}')
for js in ROOT.rglob('*.js'):
    source=js.read_text(errors='replace')
    for rel in re.findall(r"(?:from\s*|import\s*)['\"](\.{1,2}/[^'\"]+)['\"]",source):
        if not (js.parent/rel).resolve().exists(): errors.append(f'missing import {rel} in {js.relative_to(ROOT)}')
for css in ROOT.rglob('*.css'):
    balance=0
    for char in css.read_text(errors='replace'):
        balance += (char=='{') - (char=='}')
        if balance < 0: break
    if balance: errors.append(f'unbalanced CSS braces: {css.relative_to(ROOT)}')
try: ET.parse(ROOT/'sitemap.xml')
except Exception as exc: errors.append(f'invalid sitemap XML: {exc}')
phase2=(ROOT/'supabase/migrations/202611040001_phase2_core.sql')
if not phase2.exists(): errors.append('Phase 2 migration missing')
else:
    sql=phase2.read_text(errors='replace')
    if sql.count('$$') % 2: errors.append('unbalanced SQL dollar quotes')
    if re.search(r'\b(drop\s+table|truncate\s+|disable\s+row\s+level\s+security)\b',sql,re.I): errors.append('destructive SQL keyword found')
if errors:
    print('\n'.join('FAIL: '+e for e in errors)); raise SystemExit(1)
print('PASS: HTML references, duplicate IDs, local imports, CSS brace balance, sitemap XML and additive migration static checks.')
