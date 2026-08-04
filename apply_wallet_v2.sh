#!/bin/bash
set -euo pipefail

DRYRUN="${DRYRUN:-1}"
STAMP=$(date -u +%Y%m%d_%H%M%S)

echo "=== Wallet connect v2: multi-provider + hover-disconnect (DRYRUN=$DRYRUN) ==="

for f in index.html scripts.js; do
  if [ ! -f "$f" ]; then
    echo "ABORT: $f not found in current directory"
    exit 1
  fi
done

cp index.html "index.html.bak.pre-wallet-v2-${STAMP}"
cp scripts.js "scripts.js.bak.pre-wallet-v2-${STAMP}"

export DRYRUN
python3 << 'PYEOF'
import sys, os

DRYRUN = os.environ.get("DRYRUN", "1") == "1"

# ---------- index.html: nav structure + CSS ----------
with open("index.html", "r", encoding="utf-8") as f:
    html = f.read()

nav_old = '''  <div class="nav-right">
    <button class="theme-btn" id="themeBtn">🌙</button>
    <button class="nav-btn wallet-btn" id="walletBtn">🔗 Connect Wallet</button>
    <a href="https://t.me/RightclawTrade" target="_blank" class="nav-btn">📡 Join Channel →</a>
  </div>'''
nav_new = '''  <div class="nav-right">
    <button class="theme-btn" id="themeBtn">🌙</button>
    <div class="wallet-wrap">
      <button class="nav-btn wallet-btn" id="walletBtn">🔗 Connect Wallet</button>
      <div class="wallet-menu" id="walletMenu"></div>
    </div>
    <a href="https://t.me/RightclawTrade" target="_blank" class="nav-btn">📡 Join Channel →</a>
  </div>'''

css_old = '''.wallet-btn{background:rgba(0,212,170,0.1);border:1px solid rgba(0,212,170,0.3);color:var(--teal)}
.wallet-btn:hover{background:rgba(0,212,170,0.18);transform:translateY(-1px)}
.wallet-btn.wallet-connected{background:rgba(0,212,170,0.15);border-color:var(--teal);font-family:var(--mono);font-size:0.78rem}'''
css_new = css_old + '''
.wallet-wrap{position:relative}
.wallet-menu{position:absolute;top:calc(100% + 8px);right:0;min-width:200px;background:var(--surface2);border:1px solid var(--border);border-radius:10px;padding:0.4rem;display:none;flex-direction:column;gap:2px;box-shadow:0 16px 40px rgba(0,0,0,0.4);z-index:300}
.wallet-menu.open{display:flex}
.wallet-menu-item{display:flex;align-items:center;gap:10px;padding:0.6rem 0.75rem;border-radius:7px;background:none;border:none;color:var(--white);font-family:"DM Sans",sans-serif;font-size:0.85rem;cursor:pointer;text-align:left;width:100%;transition:background 0.15s;text-decoration:none}
.wallet-menu-item:hover{background:rgba(255,255,255,0.06)}
.wallet-menu-item img{width:20px;height:20px;border-radius:5px;flex-shrink:0}
.wallet-menu-empty{padding:0.75rem;font-size:0.78rem;color:var(--muted);text-align:center}
.wallet-btn.wallet-connected:hover{background:rgba(255,59,92,0.15)!important;border-color:#FF3B5C!important;color:#FF3B5C!important}'''

html_applied = 0

count = html.count(nav_old)
if count == 0:
    print("SKIP index.html (nav wallet wrap): already applied or anchor missing")
elif count != 1:
    print(f"ABORT index.html (nav wallet wrap): expected 1 match, got {count}")
    sys.exit(1)
else:
    html = html.replace(nav_old, nav_new)
    html_applied += 1

css_marker = '.wallet-menu{position:absolute'
if css_marker in html:
    print("SKIP index.html (wallet v2 CSS): already applied")
else:
    count = html.count(css_old)
    if count == 0:
        print("ABORT index.html (wallet v2 CSS): anchor missing and marker absent")
        sys.exit(1)
    elif count != 1:
        print(f"ABORT index.html (wallet v2 CSS): expected 1 match, got {count}")
        sys.exit(1)
    else:
        html = html.replace(css_old, css_new)
        html_applied += 1

# ---------- scripts.js: replace the whole v1 wallet IIFE with v2 ----------
with open("scripts.js", "r", encoding="utf-8") as f:
    js = f.read()

js_old = '''/* ── Wallet Connect (injected provider) ──
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
})()'''

js_new = '''/* ── Wallet Connect (multi-provider EVM, EIP-6963 discovery) ──
   Detects every installed EVM wallet (MetaMask, OKX Wallet, Coinbase Wallet, Rabby,
   Trust Wallet, etc.) via EIP-6963 announce/request, falls back to legacy
   window.ethereum / window.ethereum.providers for wallets that haven't adopted 6963.
   Remembers the chosen wallet by rdns for silent reconnect on reload.
   Upgrade path: swap for Reown AppKit once REOWN_PROJECT_ID exists, for WalletConnect/mobile. */
(function(){
  const btn=document.getElementById("walletBtn")
  const menu=document.getElementById("walletMenu")
  const wrap=document.querySelector(".wallet-wrap")
  if(!btn||!menu||!wrap)return

  const SHORT=a=>a.slice(0,4)+"…"+a.slice(-3)
  const CONNECTED_KEY="cm-wallet-connected"
  const RDNS_KEY="cm-wallet-rdns"

  const discovered=new Map()
  let activeProvider=null
  let activeAddress=null
  let hovering=false

  window.addEventListener("eip6963:announceProvider",e=>{
    const {info,provider}=e.detail
    discovered.set(info.rdns,{info,provider})
  })
  window.dispatchEvent(new Event("eip6963:requestProvider"))

  function legacyList(){
    const list=[]
    const eth=window.ethereum
    if(!eth)return list
    const tag=p=>p.isMetaMask?{name:"MetaMask",rdns:"io.metamask"}
      :(p.isOkxWallet||p.isOKExWallet)?{name:"OKX Wallet",rdns:"com.okex.wallet"}
      :p.isCoinbaseWallet?{name:"Coinbase Wallet",rdns:"com.coinbase.wallet"}
      :p.isRabby?{name:"Rabby",rdns:"io.rabby"}
      :p.isTrust?{name:"Trust Wallet",rdns:"com.trustwallet.app"}
      :{name:"Injected Wallet",rdns:"legacy.unknown"}
    if(Array.isArray(eth.providers)&&eth.providers.length){
      eth.providers.forEach(p=>{const t=tag(p);list.push({info:{name:t.name,rdns:t.rdns,icon:null},provider:p})})
    }else{
      const t=tag(eth)
      list.push({info:{name:t.name,rdns:t.rdns,icon:null},provider:eth})
    }
    return list
  }

  function allWallets(){
    if(discovered.size)return Array.from(discovered.values())
    return legacyList()
  }

  function renderIdle(){
    btn.classList.remove("wallet-connected")
    btn.textContent="🔗 Connect Wallet"
  }
  function renderConnected(){
    btn.classList.add("wallet-connected")
    btn.textContent=hovering?"Disconnect":SHORT(activeAddress)
  }
  function render(){activeAddress?renderConnected():renderIdle()}

  function disconnect(){
    activeProvider=null;activeAddress=null;hovering=false
    localStorage.removeItem(CONNECTED_KEY);localStorage.removeItem(RDNS_KEY)
    render()
  }

  async function connectTo(entry){
    try{
      const accounts=await entry.provider.request({method:"eth_requestAccounts"})
      if(accounts&&accounts.length){
        activeProvider=entry.provider;activeAddress=accounts[0]
        localStorage.setItem(CONNECTED_KEY,"1");localStorage.setItem(RDNS_KEY,entry.info.rdns)
        entry.provider.on&&entry.provider.on("accountsChanged",accs=>{
          if(accs.length){activeAddress=accs[0];render()}
          else disconnect()
        })
        render()
      }
    }catch(e){console.warn("wallet connect rejected or failed",e)}
    closeMenu()
  }

  function openMenu(){
    const wallets=allWallets()
    menu.innerHTML=""
    if(!wallets.length){
      const empty=document.createElement("div")
      empty.className="wallet-menu-empty"
      empty.textContent="No EVM wallet detected"
      menu.appendChild(empty)
      const link=document.createElement("a")
      link.href="https://metamask.io/download";link.target="_blank"
      link.className="wallet-menu-item"
      link.textContent="Install MetaMask →"
      menu.appendChild(link)
    }else{
      wallets.forEach(entry=>{
        const item=document.createElement("button")
        item.className="wallet-menu-item";item.type="button"
        if(entry.info.icon){
          const img=document.createElement("img")
          img.src=entry.info.icon;img.alt=""
          item.appendChild(img)
        }
        const label=document.createElement("span")
        label.textContent=entry.info.name
        item.appendChild(label)
        item.addEventListener("click",()=>connectTo(entry))
        menu.appendChild(item)
      })
    }
    menu.classList.add("open")
  }
  function closeMenu(){menu.classList.remove("open")}

  btn.addEventListener("click",()=>{
    if(activeAddress){disconnect();return}
    const wallets=allWallets()
    if(wallets.length===1)connectTo(wallets[0])
    else menu.classList.contains("open")?closeMenu():openMenu()
  })
  btn.addEventListener("mouseenter",()=>{if(activeAddress){hovering=true;render()}})
  btn.addEventListener("mouseleave",()=>{if(activeAddress){hovering=false;render()}})
  document.addEventListener("click",e=>{if(!wrap.contains(e.target))closeMenu()})

  async function silentReconnect(){
    const wasConnected=localStorage.getItem(CONNECTED_KEY)==="1"
    const savedRdns=localStorage.getItem(RDNS_KEY)
    if(!wasConnected||!savedRdns)return
    await new Promise(r=>setTimeout(r,150))
    const wallets=allWallets()
    const match=wallets.find(w=>w.info.rdns===savedRdns)||wallets[0]
    if(!match)return
    try{
      const accounts=await match.provider.request({method:"eth_accounts"})
      if(accounts&&accounts.length){
        activeProvider=match.provider;activeAddress=accounts[0]
        match.provider.on&&match.provider.on("accountsChanged",accs=>{
          if(accs.length){activeAddress=accs[0];render()}
          else disconnect()
        })
        render()
      }
    }catch(e){/* ignore silent-reconnect failures */}
  }
  render()
  silentReconnect()
})()'''

js_applied = 0
js_marker = "EIP-6963 discovery"
if js_marker in js:
    print("SKIP scripts.js: already applied")
else:
    count = js.count(js_old)
    if count == 0:
        print("ABORT scripts.js: v1 wallet block anchor not found (has it been modified since v1 shipped?)")
        sys.exit(1)
    elif count != 1:
        print(f"ABORT scripts.js: expected 1 match, got {count}")
        sys.exit(1)
    else:
        js = js.replace(js_old, js_new)
        js_applied = 1

if DRYRUN:
    print(f"[DRYRUN] index.html: {html_applied} replacement(s) would apply")
    print(f"[DRYRUN] scripts.js: {'v1->v2 wallet block swap would apply' if js_applied else 'skip'}")
else:
    with open("index.html", "w", encoding="utf-8") as f:
        f.write(html)
    with open("scripts.js", "w", encoding="utf-8") as f:
        f.write(js)
    print(f"index.html: {html_applied} replacement(s) applied")
    print(f"scripts.js: {'v1->v2 wallet block swapped' if js_applied else 'skipped (already present)'}")
PYEOF

if [ "$DRYRUN" = "1" ]; then
  echo ""
  echo "=== DRYRUN complete. Re-run with DRYRUN=0 ./apply_wallet_v2.sh to apply. ==="
  rm -f "index.html.bak.pre-wallet-v2-${STAMP}" "scripts.js.bak.pre-wallet-v2-${STAMP}"
else
  echo ""
  echo "=== Applied. Backups: *.bak.pre-wallet-v2-${STAMP} ==="
fi
