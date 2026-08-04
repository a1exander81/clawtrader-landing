#!/bin/bash
set -euo pipefail

DRYRUN="${DRYRUN:-1}"
STAMP=$(date -u +%Y%m%d_%H%M%S)

echo "=== Wallet connect + parallax + magnetic button (DRYRUN=$DRYRUN) ==="

for f in index.html scripts.js; do
  if [ ! -f "$f" ]; then
    echo "ABORT: $f not found in current directory"
    exit 1
  fi
done

cp index.html "index.html.bak.pre-hero-enhancements-${STAMP}"
cp scripts.js "scripts.js.bak.pre-hero-enhancements-${STAMP}"

export DRYRUN
python3 << 'PYEOF'
import sys, os

DRYRUN = os.environ.get("DRYRUN", "1") == "1"

# ---------- index.html: nav wallet button + CSS ----------
with open("index.html", "r", encoding="utf-8") as f:
    html = f.read()

nav_old = '''  <div class="nav-right">
    <button class="theme-btn" id="themeBtn">🌙</button>
    <a href="https://t.me/RightclawTrade" target="_blank" class="nav-btn">📡 Join Channel →</a>
  </div>'''
nav_new = '''  <div class="nav-right">
    <button class="theme-btn" id="themeBtn">🌙</button>
    <button class="nav-btn wallet-btn" id="walletBtn">🔗 Connect Wallet</button>
    <a href="https://t.me/RightclawTrade" target="_blank" class="nav-btn">📡 Join Channel →</a>
  </div>'''

css_old = '.nav-btn:hover{background:var(--claw2);transform:translateY(-1px)}'
css_new = '''.nav-btn:hover{background:var(--claw2);transform:translateY(-1px)}
.wallet-btn{background:rgba(0,212,170,0.1);border:1px solid rgba(0,212,170,0.3);color:var(--teal)}
.wallet-btn:hover{background:rgba(0,212,170,0.18);transform:translateY(-1px)}
.wallet-btn.wallet-connected{background:rgba(0,212,170,0.15);border-color:var(--teal);font-family:var(--mono);font-size:0.78rem}'''

html_applied = 0

# nav button: full-block swap, old genuinely vanishes -- safe to test old directly
count = html.count(nav_old)
if count == 0:
    print("SKIP index.html (nav wallet button): already applied or anchor missing")
elif count != 1:
    print(f"ABORT index.html (nav wallet button): expected 1 match, got {count}")
    sys.exit(1)
else:
    html = html.replace(nav_old, nav_new)
    html_applied += 1

# wallet CSS: append-style (new = old + extra lines), so old stays a substring of
# new forever -- must test for a marker unique to NEW before counting old, or a
# re-run duplicates the block (same bug class as U-CHART-STAGE2).
css_marker = '.wallet-btn{background:rgba(0,212,170,0.1)'
if css_marker in html:
    print("SKIP index.html (wallet CSS): already applied")
else:
    count = html.count(css_old)
    if count == 0:
        print("ABORT index.html (wallet CSS): anchor missing and marker absent")
        sys.exit(1)
    elif count != 1:
        print(f"ABORT index.html (wallet CSS): expected 1 match, got {count}")
        sys.exit(1)
    else:
        html = html.replace(css_old, css_new)
        html_applied += 1

# ---------- scripts.js: append the three new modules ----------
with open("scripts.js", "r", encoding="utf-8") as f:
    js = f.read()

MARKER = "/* ── Wallet Connect (injected provider) ──"
addon = '''

/* ── Wallet Connect (injected provider) ──
   v1: native window.ethereum (MetaMask/Rabby/Coinbase Wallet ext). No deps, no build step.
   Upgrade path: swap for Reown AppKit once REOWN_PROJECT_ID exists, for WalletConnect/mobile support. */
(function(){
  const btn=document.getElementById("walletBtn")
  if(!btn)return
  const SHORT=a=>a.slice(0,6)+"…"+a.slice(-4)
  const STORE_KEY="cm-wallet-connected"

  function setDisconnected(){
    btn.textContent="🔗 Connect Wallet"
    btn.classList.remove("wallet-connected")
    btn.dataset.address=""
  }
  function setConnected(addr){
    btn.textContent=SHORT(addr)
    btn.classList.add("wallet-connected")
    btn.dataset.address=addr
  }
  async function silentReconnect(){
    if(!window.ethereum)return
    try{
      const accounts=await window.ethereum.request({method:"eth_accounts"})
      if(accounts&&accounts.length&&localStorage.getItem(STORE_KEY)==="1"){
        setConnected(accounts[0])
      }
    }catch(e){/* ignore silent-reconnect failures */}
  }
  async function connect(){
    if(!window.ethereum){
      window.open("https://metamask.io/download","_blank")
      return
    }
    if(btn.classList.contains("wallet-connected")){
      setDisconnected()
      localStorage.removeItem(STORE_KEY)
      return
    }
    try{
      const accounts=await window.ethereum.request({method:"eth_requestAccounts"})
      if(accounts&&accounts.length){
        setConnected(accounts[0])
        localStorage.setItem(STORE_KEY,"1")
      }
    }catch(e){
      console.warn("wallet connect rejected or failed",e)
    }
  }
  btn.addEventListener("click",connect)
  if(window.ethereum){
    window.ethereum.on&&window.ethereum.on("accountsChanged",accounts=>{
      if(accounts.length)setConnected(accounts[0])
      else{setDisconnected();localStorage.removeItem(STORE_KEY)}
    })
  }
  silentReconnect()
})()

/* ── Scroll-linked hero parallax (real scroll-tied depth, not just fade-in) ── */
(function(){
  const heroGrid=document.querySelector(".hero-grid")
  const terminal=document.querySelector(".terminal")
  const hero=document.getElementById("hero")
  if(!hero)return
  let ticking=false
  function applyParallax(){
    const rect=hero.getBoundingClientRect()
    const progress=Math.min(1,Math.max(0,-rect.top/(rect.height||1)))
    if(heroGrid)heroGrid.style.transform=`translateY(${progress*60}px)`
    if(terminal)terminal.style.transform=`translateY(${progress*-30}px)`
    ticking=false
  }
  window.addEventListener("scroll",()=>{
    if(!ticking){requestAnimationFrame(applyParallax);ticking=true}
  },{passive:true})
  applyParallax()
})()

/* ── Magnetic button hover (cursor attraction on primary CTAs) ──
   Bakes in the existing -2px hover lift since setting inline transform
   here overrides the CSS :hover translateY rule. */
(function(){
  document.querySelectorAll(".btn-fill").forEach(b=>{
    b.addEventListener("mousemove",e=>{
      const r=b.getBoundingClientRect()
      const x=(e.clientX-r.left-r.width/2)*0.25
      const y=(e.clientY-r.top-r.height/2)*0.35
      b.style.transform=`translate(${x}px,${y-2}px)`
    })
    b.addEventListener("mouseleave",()=>{
      b.style.transform="translate(0,0)"
    })
  })
})()
'''

js_applied = 0
if MARKER in js:
    print("SKIP scripts.js: already applied")
else:
    js = js + addon
    js_applied = 1

if DRYRUN:
    print(f"[DRYRUN] index.html: {html_applied} replacement(s) would apply")
    print(f"[DRYRUN] scripts.js: {'append would apply' if js_applied else 'skip'}")
else:
    with open("index.html", "w", encoding="utf-8") as f:
        f.write(html)
    with open("scripts.js", "w", encoding="utf-8") as f:
        f.write(js)
    print(f"index.html: {html_applied} replacement(s) applied")
    print(f"scripts.js: {'appended' if js_applied else 'skipped (already present)'}")
PYEOF

if [ "$DRYRUN" = "1" ]; then
  echo ""
  echo "=== DRYRUN complete. Re-run with DRYRUN=0 ./apply_hero_enhancements.sh to apply. ==="
  rm -f "index.html.bak.pre-hero-enhancements-${STAMP}" "scripts.js.bak.pre-hero-enhancements-${STAMP}"
else
  echo ""
  echo "=== Applied. Backups: *.bak.pre-hero-enhancements-${STAMP} ==="
fi
