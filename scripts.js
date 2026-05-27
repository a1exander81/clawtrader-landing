const html=document.documentElement,themeBtn=document.getElementById("themeBtn")
const saved=localStorage.getItem("cm-theme")
const init=saved||(window.matchMedia("(prefers-color-scheme:dark)").matches?"dark":"light")
html.setAttribute("data-theme",init);themeBtn.textContent=init==="dark"?"☀️":"🌙"
themeBtn.addEventListener("click",()=>{
  const next=html.getAttribute("data-theme")==="dark"?"light":"dark"
  html.setAttribute("data-theme",next);themeBtn.textContent=next==="dark"?"☀️":"🌙"
  localStorage.setItem("cm-theme",next)
})
const canvas=document.getElementById("wormhole-canvas")
const ctx=canvas.getContext("2d")
function resizeCanvas(){canvas.width=innerWidth;canvas.height=document.getElementById("hero").offsetHeight||innerHeight}
resizeCanvas();window.addEventListener("resize",resizeCanvas)
class Beam{
  constructor(){this.reset(true)}
  reset(init){
    this.angle=Math.random()*Math.PI*2
    this.speed=0.0003+Math.random()*0.0005
    this.radius=60+Math.random()*200
    this.arcLen=0.25+Math.random()*0.55
    this.width=0.8+Math.random()*2.5
    this.opacity=0
    this.maxOpacity=0.03+Math.random()*0.07
    this.life=init?Math.floor(Math.random()*300):0
    this.maxLife=180+Math.random()*250
    const r=Math.random()
    this.hue=r<0.5?18+Math.random()*12:r<0.75?200+Math.random()*20:265+Math.random()*20
    this.sat=65+Math.random()*30
    this.spiralR=0.75+Math.random()*0.5
    this.cx=canvas.width*(0.45+Math.random()*0.2)
    this.cy=canvas.height*(0.35+Math.random()*0.3)
  }
  update(){
    this.angle+=this.speed;this.life++
    const fl=50
    if(this.life<fl)this.opacity=(this.life/fl)*this.maxOpacity
    else if(this.life>this.maxLife-fl)this.opacity=((this.maxLife-this.life)/fl)*this.maxOpacity
    else this.opacity=this.maxOpacity
    if(this.life>=this.maxLife)this.reset()
  }
  draw(c){
    const a2=this.angle+this.arcLen
    const x1=this.cx+Math.cos(this.angle)*this.radius*this.spiralR
    const y1=this.cy+Math.sin(this.angle)*this.radius
    const x2=this.cx+Math.cos(a2)*(this.radius+140)*this.spiralR
    const y2=this.cy+Math.sin(a2)*(this.radius+140)
    const g=c.createLinearGradient(x1,y1,x2,y2)
    g.addColorStop(0,`hsla(${this.hue},${this.sat}%,62%,0)`)
    g.addColorStop(0.25,`hsla(${this.hue},${this.sat}%,67%,${this.opacity})`)
    g.addColorStop(0.75,`hsla(${this.hue},${this.sat}%,72%,${this.opacity*0.7})`)
    g.addColorStop(1,`hsla(${this.hue},${this.sat}%,62%,0)`)
    c.beginPath();c.moveTo(x1,y1);c.lineTo(x2,y2)
    c.strokeStyle=g;c.lineWidth=this.width;c.lineCap="round";c.stroke()
    // Pulsating light orb travelling along the beam
    const t=Math.min(1,(this.life%120)/120)
    const px=x1+(x2-x1)*t
    const py=y1+(y2-y1)*t
    const pulse=0.5+0.5*Math.sin(this.life*0.12)
    const orbSize=1.5+pulse*2.5
    const orbOpacity=this.opacity*3*pulse
    const og=c.createRadialGradient(px,py,0,px,py,orbSize*4)
    og.addColorStop(0,`hsla(${this.hue},100%,90%,${orbOpacity})`)
    og.addColorStop(0.3,`hsla(${this.hue},${this.sat}%,70%,${orbOpacity*0.6})`)
    og.addColorStop(1,`hsla(${this.hue},${this.sat}%,60%,0)`)
    c.beginPath();c.arc(px,py,orbSize*4,0,Math.PI*2)
    c.fillStyle=og;c.fill()
    c.beginPath();c.arc(px,py,orbSize*0.5,0,Math.PI*2)
    c.fillStyle=`hsla(${this.hue},100%,95%,${orbOpacity*1.5})`
    c.fill()
  }
}
const beams=Array.from({length:65},()=>new Beam())
let mX=0.5,mY=0.5
document.addEventListener("mousemove",e=>{mX=e.clientX/innerWidth;mY=e.clientY/innerHeight})
function drawGlow(){
  const cx=canvas.width*(0.5+mX*0.06),cy=canvas.height*(0.48+mY*0.05)
  const g=ctx.createRadialGradient(cx,cy,0,cx,cy,canvas.width*0.28)
  g.addColorStop(0,"rgba(255,85,0,0.04)");g.addColorStop(0.5,"rgba(80,40,180,0.015)");g.addColorStop(1,"rgba(0,0,0,0)")
  ctx.fillStyle=g;ctx.fillRect(0,0,canvas.width,canvas.height)
}
function animate(){
  ctx.clearRect(0,0,canvas.width,canvas.height)
  drawGlow()
  beams.forEach(b=>{
    b.cx=canvas.width*(0.52+mX*0.06);b.cy=canvas.height*(0.48+mY*0.05)
    b.update();b.draw(ctx)
  })
  requestAnimationFrame(animate)
}
animate()
function addTilt(sel){
  document.querySelectorAll(sel).forEach(card=>{
    card.addEventListener("mousemove",e=>{
      const r=card.getBoundingClientRect()
      const x=(e.clientX-r.left)/r.width-0.5
      const y=(e.clientY-r.top)/r.height-0.5
      card.style.transform=`perspective(500px) rotateY(${x*18}deg) rotateX(${-y*18}deg) translateZ(14px) scale(1.03)`
    })
    card.addEventListener("mouseleave",()=>{
      card.style.transform="perspective(500px) rotateY(0deg) rotateX(0deg) translateZ(0) scale(1)"
    })
  })
}
addTilt(".sess-card");addTilt(".feat-item");addTilt(".how-item");addTilt(".social-card")
if(innerWidth<=900){
  const cards=document.querySelectorAll(".sess-card,.feat-item,.social-card")
  const mObs=new IntersectionObserver(entries=>{
    entries.forEach(e=>{
      e.target.style.transform=e.isIntersecting
        ?"perspective(500px) rotateY(0deg) rotateX(0deg)"
        :"perspective(500px) rotateY(-3deg) rotateX(2deg)"
    })
  },{threshold:0.35})
  cards.forEach(c=>mObs.observe(c))
}
const revEls=document.querySelectorAll(".reveal")
const obs=new IntersectionObserver(entries=>{
  entries.forEach((e,i)=>{if(e.isIntersecting)setTimeout(()=>e.target.classList.add("vis"),i*70)})
},{threshold:0.1})
revEls.forEach(r=>obs.observe(r))
window.addEventListener("scroll",()=>{
  document.getElementById("nav").style.boxShadow=scrollY>60?"0 4px 40px rgba(0,0,0,0.5)":"none"
})

document.addEventListener("DOMContentLoaded", function(){
  new Accordion(".ac-container", {
    duration: 400,
    showMultiple: false,
    openOnInit: []
  });
});