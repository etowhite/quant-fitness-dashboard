const fs = require('node:fs');
const path = require('node:path');
const sharp = require('C:/Users/white/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');

// Concept assets only. This script does not access application resources.
const OUT = __dirname;
const BG = '#121212', INK = '#000000', VIOLET = '#B4A0E5';
const concepts = [
  {id:'01-fluid', title:'Плавная q', note:'Текучая дуга · мягкий выход в диагональ',
    d:'M 50 68 C 35 73 22 61 22 46 C 22 30 33 20 48 21 C 64 21 75 33 73 47 C 72 59 70 63 81 78',
    widths:[13,15,15,14,12]},
  {id:'02-motion', title:'Движение', note:'Наклон · упругий поворот · ускорение',
    d:'M 43 68 C 27 70 23 59 29 44 C 35 29 49 20 62 23 C 77 27 77 39 68 51 C 61 60 63 64 81 77',
    widths:[11,15,16,14,12]},
  {id:'03-geometric', title:'Геометричная q', note:'Круговая основа · ровная толщина · ясный хвост',
    d:'M 47 73 C 34 72 24 62 24 48 C 24 34.193 35.193 23 49 23 C 62.807 23 74 34.193 74 48 C 74 54 72 60 68 64 L 81 77',
    geometric:true},
];

// Convert the two variable-width ribbons to filled vector contours, retaining
// smooth optical weight changes and circular end caps. No bitmap tracing.
function outline(d, widths) {
  const tokens = d.match(/[MCL]|-?\d*\.?\d+/g);
  let i=0, current, seg=0;
  const points=[];
  while (i < tokens.length) {
    const op=tokens[i++];
    if(op==='M') { current=[+tokens[i++],+tokens[i++]]; continue; }
    if(op!=='C') throw new Error('Only cubic ribbon segments supported');
    const p0=current, p1=[+tokens[i++],+tokens[i++]], p2=[+tokens[i++],+tokens[i++]], p3=[+tokens[i++],+tokens[i++]];
    for(let j=seg?1:0;j<=40;j++) {
      const t=j/40, u=1-t;
      const x=u*u*u*p0[0]+3*u*u*t*p1[0]+3*u*t*t*p2[0]+t*t*t*p3[0];
      const y=u*u*u*p0[1]+3*u*u*t*p1[1]+3*u*t*t*p2[1]+t*t*t*p3[1];
      const dx=3*u*u*(p1[0]-p0[0])+6*u*t*(p2[0]-p1[0])+3*t*t*(p3[0]-p2[0]);
      const dy=3*u*u*(p1[1]-p0[1])+6*u*t*(p2[1]-p1[1])+3*t*t*(p3[1]-p2[1]);
      const length=Math.hypot(dx,dy), r=(widths[seg]*(1-t)+widths[seg+1]*t)/2;
      points.push({x,y,nx:-dy/length,ny:dx/length,r});
    }
    current=p3; seg++;
  }
  const a=points[0], b=points.at(-1);
  const contour=points.map(p=>[p.x+p.nx*p.r,p.y+p.ny*p.r]);
  function cap(p,startAngle) {
    for(let j=1;j<=20;j++) {
      const angle=startAngle-Math.PI*j/20;
      contour.push([p.x+Math.cos(angle)*p.r,p.y+Math.sin(angle)*p.r]);
    }
  }
  cap(b,Math.atan2(b.ny,b.nx));
  contour.push(...points.toReversed().map(p=>[p.x-p.nx*p.r,p.y-p.ny*p.r]));
  cap(a,Math.atan2(-a.ny,-a.nx));
  return contour.map((p,j)=>(j?'L':'M')+p.map(n=>n.toFixed(3)).join(' ')).join(' ')+' Z';
}
for(const c of concepts) if(!c.geometric) c.contour=outline(c.d,c.widths);

function mark(c,color) {
  return c.geometric
    ? `<path d="${c.d}" fill="none" stroke="${color}" stroke-width="13" stroke-linecap="round" stroke-linejoin="round"/>`
    : `<path d="${c.contour}" fill="${color}"/>`;
}
function svg(content,w=108,h=w) {return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${content}</svg>`;}
function tile(c,{size=108,color=VIOLET,bg=BG,mask='rounded',x=0,y=0}={}) {
  let shape=mask==='circle'?`<circle cx="54" cy="54" r="54" fill="${bg}"/>`:`<rect width="108" height="108" rx="${mask==='square'?0:26}" fill="${bg}"/>`;
  return `<g transform="translate(${x} ${y}) scale(${size/108})">${shape}${mark(c,color)}</g>`;
}
const esc=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;');
function label(x,y,t,size=16,color='#F0EDF6',weight=400) {return `<text x="${x}" y="${y}" font-family="Segoe UI, sans-serif" font-size="${size}" font-weight="${weight}" fill="${color}">${esc(t)}</text>`;}
async function saveSvgPng(file, source, width) {
  fs.writeFileSync(path.join(OUT,file+'.svg'),source);
  await sharp(Buffer.from(source)).resize({width}).png().toFile(path.join(OUT,file+'.png'));
}

async function main() {
  fs.mkdirSync(OUT,{recursive:true});
  for(const c of concepts) {
    const dir=path.join(OUT,c.id); fs.mkdirSync(dir,{recursive:true});
    fs.writeFileSync(path.join(dir,'mark.svg'),svg(mark(c,'currentColor')));
    for(const [name,color,bg] of [['black-on-white',INK,'#FFFFFF'],['white-on-black','#FFFFFF',INK],['lavender',VIOLET,BG]]) {
      const source=svg(tile(c,{color,bg}));
      fs.writeFileSync(path.join(dir,name+'.svg'),source);
      await sharp(Buffer.from(source)).resize(512,512).png().toFile(path.join(dir,name+'.png'));
      for(const size of [16,24,32,48,64]) await sharp(Buffer.from(source)).resize(size,size).png().toFile(path.join(dir,`${name}-${size}.png`));
    }
  }
  let board=`<rect width="1500" height="1210" fill="#19191D"/>`;
  board+=label(66,66,'quant',34,'#FFFFFF',650)+label(1434,62,'КОНЦЕПЦИИ ИКОНКИ / 01',13,'#9F9BAA',500).replace('x="1434"','x="1434" text-anchor="end"');
  board+=label(66,103,'Открытая q. Один цвет. Три характера.',19,'#B9B4C4');
  for(let i=0;i<3;i++) {
    const c=concepts[i], x=66+470*i;
    board+=`<path d="M${x} 135 H${x+428}" stroke="#3A3741"/>`;
    board+=label(x,178,'0'+(i+1),15,VIOLET,600)+label(x+38,179,c.title,25,'#FFFFFF',600);
    board+=label(x,211,c.note,14,'#B9B4C4');
    board+=tile(c,{x:x+69,y:245,size:290});
    board+=label(x,584,'МОНОХРОМ И ИНВЕРСИЯ',12,'#A9A4B2',500);
    board+=tile(c,{x:x+25,y:608,size:172,color:INK,bg:'#FFFFFF'});
    board+=tile(c,{x:x+231,y:608,size:172,color:'#FFFFFF',bg:INK});
    board+=label(x,829,'В МАЛОМ РАЗМЕРЕ / PX',12,'#A9A4B2',500);
    let sx=x+25;
    for(const size of [64,48,32,24,16]) {
      board+=tile(c,{x:sx,y:862+(64-size)/2,size});
      board+=label(sx+size/2,951,String(size),12,'#B9B4C4').replace(`x="${sx+size/2}"`,`x="${sx+size/2}" text-anchor="middle"`);
      sx+=size+29;
    }
    board+=label(x,1005,'МАСКИ / 72 PX',12,'#A9A4B2',500);
    for(const [j,mask] of ['circle','square','rounded'].entries()) board+=tile(c,{x:x+40+j*132,y:1030,size:72,mask});
  }
  board+=label(66,1171,'ЗНАК  #B4A0E5     ФОН  #121212',13,'#A9A4B2');
  board+=label(1434,1171,'Эскизы для выбора · ресурсы приложения не заменены',13,'#A9A4B2').replace('x="1434"','x="1434" text-anchor="end"');
  await saveSvgPng('comparison',svg(board,1500,1210),1500);

  // Compact mobile-friendly boards, one per concept.
  for(const [index,c] of concepts.entries()) {
    let s=`<rect width="1000" height="650" fill="#19191D"/>`;
    s+=label(40,54,`0${index+1} / ${c.title}`,28,'#FFFFFF',600);
    s+=label(40,86,c.note,17,'#B9B4C4');
    s+=tile(c,{x:40,y:126,size:288,color:INK,bg:'#FFFFFF'});
    s+=tile(c,{x:356,y:126,size:288,color:'#FFFFFF',bg:INK});
    s+=tile(c,{x:672,y:126,size:288});
    s+=label(40,460,'РАЗМЕРЫ / PX',12,'#A9A4B2',500);
    let x=40;
    for(const size of [64,48,32,24,16]) {
      s+=tile(c,{x,y:480+(64-size)/2,size});
      s+=label(x+size/2,570,String(size),12,'#A9A4B2').replace(`x="${x+size/2}"`,`x="${x+size/2}" text-anchor="middle"`);
      x+=size+30;
    }
    s+=label(590,460,'МАСКИ / 72 PX',12,'#A9A4B2',500);
    for(const [j,mask] of ['circle','square','rounded'].entries()) s+=tile(c,{x:590+j*132,y:480,size:72,mask});
    s+=label(40,620,'quant · #B4A0E5 / #121212 · концепция',14,'#A9A4B2');
    await saveSvgPng(c.id+'/preview',svg(s,1000,650),1000);
  }
  fs.writeFileSync(path.join(OUT,'README.md'),`# quant — варианты иконки\n\nЭтап выбора дизайна. Ресурсы Flutter и Android не заменены.\n\n- 01-fluid: Плавная q — текучая дуга с мягким переходом в хвост.\n- 02-motion: Движение — наклонная форма с переменной толщиной и упругим поворотом.\n- 03-geometric: Геометричная q — круговая основа и постоянная толщина 13/108.\n\nЗнак: #B4A0E5 (AccentPalette.lavender из проекта). Фон: #121212 (AppColors.background).\n\nВ каждой папке: mark.svg без фона, SVG и PNG 512 px в трех сочетаниях, PNG 16/24/32/48/64 px, preview.svg и preview.png.\n\ncomparison.png и comparison.svg — общее сравнение. Все изображения получены из одних и тех же векторных контуров; силуэт при инверсии одинаков.\n\nКруглая, квадратная и скругленная маски показаны для визуальной проверки полей. Это концепты: финальные адаптивные Android-слои и проверка launcher будут подготовлены после выбора.\n\nСборка превью: node generate.cjs (использует sharp из bundled Node runtime).\n`);
  console.log('Wrote three vector concepts and preview boards to '+OUT);
}
main().catch(error=>{console.error(error);process.exitCode=1;});
