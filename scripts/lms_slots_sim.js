#!/usr/bin/env node
/* lms_slots_sim.js — valida el fix de slots LMS independientes (v1.1).

Extrae el modulo LMS REAL del Suite_TD2D.html, lo corre en una sandbox
de Node con los archivos REALES del proyecto (scr_lms.gml, Server.h,
Game.c, net_state_game.gml, .yyp) y pruebas de que:

  1. todos los <script> del HTML compilan (sintaxis)
  2. scanLms ve a Blaze/Rouge/Kris compartiendo mus_lms_15
  3. assetOwners/sharedAssets detectan lo compartido
  4. nextAsset devuelve mus_lms_25 (no pisa 2..24: usados + .yyp + disco)
  5. pickReplace sobre una COMPARTIDA (el bug de la duena) NO toca
     mus_lms_15: le crea a Kris su slot propio mus_lms_25
  6. forkSong (🔧 separar) hace lo mismo sin cambiar la cancion
  7. buildCharBlock/buildShowsTable dejan a Blaze/Rouge en mus_lms_15
     y a Kris en su slot nuevo
  8. pendingInfo lista "slot(s) propio(s)"
  9. el writer registra los slots en el .yyp y los escribe
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.resolve(__dirname, '..');
const HTML = path.join(ROOT, 'Suite_TD2D.html');
let fails = 0;
const ok = (cond, msg) => { console.log((cond ? 'OK  ' : 'FAIL') + ' ' + msg); if (!cond) fails++; };

const html = fs.readFileSync(HTML, 'utf8');

/* ---------- 1. sintaxis de TODOS los <script> del HTML ---------- */
const blocks = [...html.matchAll(/<script(?![^>]*\bsrc\b)[^>]*>([\s\S]*?)<\/script>/gi)].map(m => m[1]);
ok(blocks.length >= 5, 'bloques <script> encontrados: ' + blocks.length);
blocks.forEach((code, i) => {
  try { new vm.Script(code, { filename: 'script_' + i + '.js' }); }
  catch (e) { ok(false, 'sintaxis del bloque ' + i + ': ' + e.message); }
});
ok(true, 'sintaxis de los ' + blocks.length + ' bloques <script> verificada');

/* ---------- extraccion del modulo LMS REAL ---------- */
const a0 = html.indexOf('const REL_LMS');
const a1 = html.indexOf('function bindLms');
ok(a0 >= 0 && a1 > a0, 'modulo LMS localizado en el HTML (' + a0 + '..' + a1 + ')');
let mod = html.slice(a0, a1);
// renderLms puro DOM: se stubbea para poder probar pickReplace/forkSong
mod += '\nrenderLms = function () {};\n';
mod += '\n__x = { LMS_CHARS, LMS, assetOwners, sharedAssets, nextAsset, buildCharBlock, buildShowsTable, pendingInfo, listsChanged, forkSong, pickReplace, scanLms, songInfo, lmsYypText };\n';

/* ---------- mocks de la parte navegador ---------- */
const realFiles = {
  'scripts/scr_lms/scr_lms.gml': fs.readFileSync(path.join(ROOT, 'scripts/scr_lms/scr_lms.gml'), 'utf8'),
  'betterserver-oss/include/Server.h': fs.readFileSync(path.join(ROOT, 'betterserver-oss/include/Server.h'), 'utf8'),
  'betterserver-oss/disasterserver/states/Game.c': fs.readFileSync(path.join(ROOT, 'betterserver-oss/disasterserver/states/Game.c'), 'utf8'),
  'scripts/net_state_game/net_state_game.gml': fs.readFileSync(path.join(ROOT, 'scripts/net_state_game/net_state_game.gml'), 'utf8'),
  'proyecto.yyp': fs.readFileSync(path.join(ROOT, 'Sonicexe The Disaster 2D Remake.yyp'), 'utf8')
};
const toasts = [];
const S = { mode: 'fs' };
let lastInp = null, changeCb = null;
const sandbox = {
  console, S,
  readText: async (rel) => {
    if (Object.prototype.hasOwnProperty.call(realFiles, rel)) return realFiles[rel];
    // sonidos en el "disco" de la duena: mus_lms_2..24 existen (como en el proyecto real)
    const m = /^sounds\/(mus_lms_(\d+))\/\1\.yy$/.exec(rel);
    if (m) { const n = +m[2]; if (n >= 2 && n <= 24) return '{"duration":180,"soundFile":"cancion.ogg"}'; return null; }
    return null;
  },
  fsWalkDir: async () => ({ entries: async function* () { yield ['proyecto.yyp', { kind: 'file' }]; } }),
  fsWalkFile: async (rel) => {
    if (rel === 'sounds/mus_lms_15/mus_lms_15.ogg')
      return { getFile: async () => ({ arrayBuffer: async () => new ArrayBuffer(16) }) };
    throw new Error('no existe: ' + rel);
  },
  toast: (msg, kind) => toasts.push({ msg, kind }),
  confirm: () => true,
  normPath: (p) => String(p).replace(/\\/g, '/').replace(/^\.\//, ''),
  ensureDir: async () => { throw new Error('no debia llamarse'); },
  C: { parseMacros: () => [] },
  window: { AudioContext: class { decodeAudioData() { return Promise.resolve({ duration: 210 }); } } },
  document: {
    createElement: () => {
      const o = { type: '', accept: '', files: [], addEventListener: (ev, fn) => { if (ev === 'change') changeCb = fn; }, click: () => {} };
      lastInp = o; return o;
    }
  }
};
vm.createContext(sandbox);
vm.runInContext('var __x;', sandbox);
try {
  vm.runInContext(mod, sandbox, { filename: 'lms_module.js' });
  ok(true, 'modulo LMS carga en la sandbox');
} catch (e) { ok(false, 'modulo LMS NO carga: ' + e.message); process.exit(1); }
const X = sandbox.__x;
const { LMS, LMS_CHARS, assetOwners, sharedAssets, nextAsset, buildCharBlock, buildShowsTable, pendingInfo, listsChanged, forkSong, pickReplace, scanLms } = X;

const main = async () => {
  /* ---------- 2. scanLms contra los archivos reales ---------- */
  await scanLms();
  ok(LMS.base === 'ok', 'scanLms: base ok (lista por personaje)');
  ok(LMS_CHARS.length === 16, '16 personajes en el modulo: ' + LMS_CHARS.length);
  const kris = LMS.chars.kris.songs, rouge = LMS.chars.rouge.songs, blaze = LMS.chars.blaze.songs;
  ok(kris.length === 1 && kris[0].asset === 'mus_lms_15', 'Kris escaneado en mus_lms_15 (estado actual del proyecto)');
  ok(rouge.length === 1 && rouge[0].asset === 'mus_lms_15', 'Rouge escaneado en mus_lms_15');
  ok(blaze.length === 1 && blaze[0].asset === 'mus_lms_15', 'Blaze escaneado en mus_lms_15 — EL ORIGEN DEL BUG');
  ok(kris[0].dur === 180 && kris[0].ext === 'ogg', 'songInfo leyo dur 180 / ogg del .yy simulado');

  /* ---------- 3. deteccion de compartidas ---------- */
  const own15 = assetOwners('mus_lms_15', 'kris').map(c => c.label);
  ok(own15.join(',') === 'Blaze,Rouge', "assetOwners('mus_lms_15','kris') = [" + own15.join(',') + ']');
  ok(assetOwners('mus_lms_16', 'sonic').length === 0, "assetOwners('mus_lms_16','sonic') = [] (no compartida)");
  const sh = sharedAssets();
  ok(sh.length === 1 && sh[0].asset === 'mus_lms_15' && sh[0].chars.length === 3,
    'sharedAssets: mus_lms_15 compartida por ' + sh[0].chars.map(c => c.label).join('/'));

  /* ---------- 4. nextAsset no pisa nada existente ---------- */
  const nx = await nextAsset();
  ok(nx === 'mus_lms_25', 'nextAsset() = ' + nx + ' (2..24 usados/registrados, 25 libre)');

  /* ---------- 5. EL BUG: pickReplace sobre compartida ---------- */
  LMS.sel = 'kris';
  const p0 = pickReplace(0); // crea el input
  lastInp.files = [{ name: 'kris_theme.mp3', arrayBuffer: async () => new ArrayBuffer(8) }];
  await changeCb(); await p0;
  const ks = LMS.chars.kris.songs[0];
  ok(ks.asset === 'mus_lms_25', 'pickReplace compartida → Kris pasa a su slot propio ' + ks.asset);
  ok(ks.forkedFrom === 'mus_lms_15', 'forkedFrom = ' + ks.forkedFrom);
  ok(ks.isNew === true && ks.repl === false, 'marca isNew sin repl (archivo nuevo, no sobrescribe)');
  ok(ks.dur === 210 && ks.ext === 'mp3' && ks.bytes != null, 'audio nuevo guardado (dur 210, mp3, bytes)');
  ok(blaze[0].asset === 'mus_lms_15' && rouge[0].asset === 'mus_lms_15',
    'Blaze y Rouge SIGUEN en mus_lms_15: su musica NO se toco');
  ok(toasts.some(t => /NO la toqu/.test(t.msg)), 'toast avisa que no se toco la compartida');

  /* ---------- 6. pendingInfo + builders ---------- */
  const p = pendingInfo();
  ok(p.forks.length === 1 && p.forks[0].char.key === 'kris', 'pendingInfo: 1 slot propio para kris');
  ok(/slot\(s\) propio\(s\)/.test(p.text), 'texto pendiente: "' + p.text + '"');
  ok(listsChanged() === true, 'listsChanged detecta el cambio de lista');
  const cb = buildCharBlock();
  ok(/global\.lmsCharSongs\[\? CHARACTER_KRIS\] = \[mus_lms_25\];/.test(cb), 'buildCharBlock: KRIS → [mus_lms_25]');
  ok(/global\.lmsCharSongs\[\? CHARACTER_BLAZE\] = \[mus_lms_15\];/.test(cb), 'buildCharBlock: BLAZE → [mus_lms_15] (intacta)');
  ok(/global\.lmsCharSongs\[\? CHARACTER_ROUGE\] = \[mus_lms_15\];/.test(cb), 'buildCharBlock: ROUGE → [mus_lms_15]');
  const st = buildShowsTable();
  ok(/\{ CH_KRIS, 1, \{ 210 \} \}/.test(st), 'buildShowsTable: CH_KRIS con la duracion nueva (210)');
  ok(/\{ CH_BLAZE, 1, \{ 180 \} \}/.test(st), 'buildShowsTable: CH_BLAZE intacta (180)');
  ok(/LMS_SHOW_COUNT 16/.test(st), 'buildShowsTable: 16 shows');

  /* ---------- 7. 🔧 forkSong (separar SIN cambiar cancion) ---------- */
  LMS.sel = 'rouge';
  await forkSong(0);
  const rs = LMS.chars.rouge.songs[0];
  ok(rs.asset === 'mus_lms_26', 'forkSong: Rouge → slot propio ' + rs.asset + ' (25 ya es de Kris)');
  ok(rs.forkedFrom === 'mus_lms_15' && rs.repl === false && rs.bytes != null,
    'forkSong: copia del audio actual (bytes leidos de sounds/), misma cancion');
  ok(rs.dur === 180, 'forkSong conserva la duracion 180');
  ok(blaze[0].asset === 'mus_lms_15', 'Blaze sigue intacta tras separar a Rouge');

  /* ---------- 8. pickReplace sobre NO compartida: reemplazo normal ---------- */
  LMS.sel = 'sonic';
  const p1 = pickReplace(0); // mus_lms_16, solo de Sonic
  lastInp.files = [{ name: 'sonic_new.ogg', arrayBuffer: async () => new ArrayBuffer(8) }];
  await changeCb(); await p1;
  const ss = LMS.chars.sonic.songs[0];
  ok(ss.asset === 'mus_lms_16' && ss.repl === true && ss.forkedFrom === undefined,
    'pickReplace NO compartida: reemplazo directo de mus_lms_16 (comportamiento original)');
  const p2 = pendingInfo();
  ok(p2.repl.length === 1 && p2.forks.length === 2, 'pendingInfo: 1 reemplazo + 2 slots propios (kris y rouge)');

  /* ---------- 9. aserciones de fuente del writer ---------- */
  ok(mod.includes('for (const x of p.add.concat(p.forks, p.repl)) {'),
    'writeLms escribe audios de: nuevas + slots propios + reemplazos');
  ok(mod.includes('const newAssets = p.add.concat(p.forks).filter'),
    'writeLms registra slots propios en el .yyp');
  ok((mod.match(/LMS\.yypText = null;/g) || []).length >= 3,
    'cache del .yyp se invalida (scan/write/undo)');

  /* ---------- 10. la nota del panel derecho existe ---------- */
  ok(/Canciones compartidas:/.test(html), 'nota "Canciones compartidas" en el panel del Suite');
  ok(/compartida con /.test(html) && /mkBtn\('🔧'/.test(mod), 'badge ⚠ y boton 🔧 Separar en las filas');

  console.log('\n' + (fails ? fails + ' PRUEBA(S) FALLARON' : 'TODO OK — ' + 'fix de slots LMS independientes validado'));
  process.exit(fails ? 1 : 0);
};
main().catch(e => { console.error('EXCEPCION:', e); process.exit(1); });
