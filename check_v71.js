#!/usr/bin/env node
// check_v71.js — verificación de regla 6 para v71 (FIX música de botas).
// 1) Los 3 hunks de música v69 presentes en net_state_game.gml (con macros v70 intactas).
// 2) Los otros 4 archivos v69 y el sonido .yyp REGISTRADO (los que sobrevivieron).
// 3) El motor REAL del Suite (AnimCore) sigue parseando/editando las macros sobre el combinado.
// 4) Integridad: llaves/paréntesis, regla 7 (cero red/server).
const fs = require('fs');
const cp = require('child_process');
const REPO = '/home/z/my-project/repo';

let fails = 0;
const check = (name, cond, detail) => {
  console.log(`  [${cond ? 'OK' : 'FAIL'}] ${name}${detail ? ' — ' + detail : ''}`);
  if (!cond) fails++;
};

const gml = fs.readFileSync(REPO + '/scripts/net_state_game/net_state_game.gml', 'utf8');

console.log('== A. Hunks de música v69 restaurados ==');
check('case 4: snd_speedboost en LOOP', /audio_play_sound\(snd_speedboost, 0, true\)/.test(gml));
check('case 4: scr_music_duck() al romper la caja', /scr_music_duck\(\);/.test(gml));
check('LMS: audio_stop_sound(snd_speedboost)', (gml.match(/audio_stop_sound\(snd_speedboost\)/g) || []).length >= 2, `${(gml.match(/audio_stop_sound\(snd_speedboost\)/g) || []).length} cortes`);
check('scr_music_unduck en cortes', (gml.match(/scr_music_unduck\(\)/g) || []).length >= 2);
check('snd_spring FUERA del case 4 de botas', !/bootsTimer = [^;]+;\s*\n\s*audio_play_sound\(snd_spring/.test(gml));
{
  const codeRefs = (gml.replace(/\/\/[^\n]*/g, '').match(/snd_speedboost/g) || []).length;
  check('refs CODIGO snd_speedboost = 3 (v69 exacto)', codeRefs === 3, `${codeRefs} refs en codigo (${(gml.match(/snd_speedboost/g) || []).length} con comentarios)`);
}

console.log('== B. Macros v70 intactas ==');
for (const n of ['ITEMBOX_SHIELD_TIME', 'ITEMBOX_INVULN_TIME', 'ITEMBOX_ELECTRIC_TIME', 'ITEMBOX_BOOTS_TIME']) {
  check('#macro ' + n + ' + uso', gml.includes('#macro ' + n) && gml.includes(n + ';'));
}

console.log('== C. Resto de v69 que sobrevivió (otros 4 archivos + sonido) ==');
for (const f of ['scripts/scr_music/scr_music.gml', 'scripts/scr_move_basic/scr_move_basic.gml',
                 'scripts/scr_menu_more/scr_menu_more.gml', 'scripts/scr_player_hurt/scr_player_hurt.gml']) {
  const t = fs.readFileSync(REPO + '/' + f, 'utf8');
  check(f.split('/').pop() + ' tiene v69', t.includes('snd_speedboost') || t.includes('scr_music_unduck'));
}
check('sounds/snd_speedboost/snd_speedboost.ogg existe', fs.existsSync(REPO + '/sounds/snd_speedboost/snd_speedboost.ogg'));
check('sounds/snd_speedboost/snd_speedboost.yy existe', fs.existsSync(REPO + '/sounds/snd_speedboost/snd_speedboost.yy'));
check('.yyp registra snd_speedboost', fs.readFileSync(REPO + '/Sonicexe The Disaster 2D Remake.yyp', 'utf8').includes('snd_speedboost'));

console.log('== D. Integridad de net_state_game.gml ==');
{
  // strip strings y comentarios antes de contar (como en v70)
  const strip = (s) => s.replace(/"(?:[^"\\]|\\.)*"/g, '""').replace(/\/\/[^\n]*/g, '').replace(/\/\*.*?\*\//g, '');
  const s2 = strip(gml);
  check('llaves balanceadas', s2.split('{').length === s2.split('}').length, `${s2.split('{').length}/${s2.split('}').length}`);
  check('paréntesis balanceados', s2.split('(').length === s2.split(')').length, `${s2.split('(').length}/${s2.split(')').length}`);
}

console.log('== E. Motor REAL del Suite sobre el combinado ==');
{
  // reutilizar la extracción del factory AnimCore de check_v70.js
  const html = fs.readFileSync(REPO + '/Suite_TD2D.html', 'utf8');
  const lines = html.split('\n');
  let core = null, inS = false, buf = [];
  for (let i = 0; i < lines.length; i++) {
    if (!inS && /^<script>/.test(lines[i])) { inS = true; buf = []; continue; }
    if (inS && /^<\/script>/.test(lines[i])) {
      const js = buf.join('\n');
      if (/function parseMacros/.test(js) && /function setMacro/.test(js)) core = js;
      inS = false; continue;
    }
    if (inS) buf.push(lines[i]);
  }
  const umdStart = core.indexOf('function (root, factory) {');
  const factoryStart = core.indexOf('function () {', umdStart);
  const factoryEnd = core.lastIndexOf('});');
  const factorySrc = core.slice(factoryStart, factoryEnd) + '\n}';
  const factory = (new Function('return (' + factorySrc + ')'))();
  const C = factory();   // new Function devuelve la factory; hay que LLAMARLA
  const macs = C.parseMacros(gml);
  const defs = { ITEMBOX_SHIELD_TIME: 5, ITEMBOX_INVULN_TIME: 6.25, ITEMBOX_ELECTRIC_TIME: 3, ITEMBOX_BOOTS_TIME: 15 };
  for (const n of Object.keys(defs)) {
    const m = macs.find(x => x.name === n);
    check(`Suite lee ${n} = ${defs[n]} s`, m && m.kind === 'sec' && Math.abs(m.seconds) === defs[n], m ? m.raw : 'NO ENCONTRADA');
  }
  const r = C.setMacro(gml, 'ITEMBOX_BOOTS_TIME', { seconds: 20 });
  check('Suite edita botas 15→20 s sobre el combinado', r.changed && /\(60 \* 20\)/.test(r.gml));
  const d = r.gml.split('\n'), o = gml.split('\n');
  let dl = 0;
  for (let i = 0; i < Math.max(d.length, o.length); i++) if (d[i] !== o[i]) dl++;
  check('solo 1 línea de diff', dl === 1, `${dl} líneas`);
  check('la música SOBREVIVE a la edición del Suite', /audio_play_sound\(snd_speedboost, 0, true\)/.test(r.gml) && /scr_music_duck\(\);/.test(r.gml));
}

console.log('== F. Regla 7: superficie de red intacta ==');
{
  const diff = cp.execSync(`git -C ${REPO} diff --stat -- scripts/net_packets/ betterserver-oss/ states/`, { encoding: 'utf8' });
  check('sin cambios en net_packets/ betterserver-oss/ states/', diff.trim() === '', diff.trim() || 'limpio');
  const diffAll = cp.execSync(`git -C ${REPO} status --porcelain`, { encoding: 'utf8' });
  const files = diffAll.split('\n').filter(Boolean).map(l => l.slice(3).trim());
  check('solo net_state_game.gml (+docs) tocados', files.every(f => f.startsWith('scripts/net_state_game/') || /\.(md|txt|js|py)$/.test(f)), files.join(', '));
}

console.log('');
if (fails) { console.log(`RESULT: ${fails} FALLOS`); process.exit(1); }
console.log('RESULT: TODOS LOS CHECKS v71 OK');
