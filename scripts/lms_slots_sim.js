#!/usr/bin/env node
/* lms_slots_sim.js v2 — valida el fix «Variable mus_lms_N not set» (v1.2).

Extrae el modulo LMS REAL del Suite_TD2D.html, lo corre en una sandbox
de Node con los archivos REALES del proyecto (scr_lms.gml v5.4, .yyp
con mus_lms_25/26 registradas, Server.h, Game.c, net_state_game.gml):

  1. todos los <script> del HTML compilan (sintaxis)
  2. scanLms parsea el formato NUEVO (canciones entre comillas) y las
     listas reales: Rouge = mus_lms_27/26/28, Kris = mus_lms_25
  3. el .yyp YA reparado -> LMS.missing = [] y nextAsset = mus_lms_29
  4. buildCharBlock emite comillas (texto seguro) y NUNCA assets directos
  5. scanLms tambien parsea el formato VIEJO (sin comillas)
  6. slots propios: pickReplace/forkSong siguen sin pisar compartidas
  7. EL BUG REAL: .yyp sin mus_lms_25/26 (estado que rompia el juego)
     -> scanLms lo DETECTA (LMS.missing) y lo avisa
  8. yypInsertEntries: inserta, valida, es idempotente y devuelve null
     si no hay lista "resources"
  9. repairLmsYyp (boton 🩹): re-registra con backup + deshacer y al
     re-escanear ya no falta nada
 10. el writer re-registra tambien las perdidas y avisa de GameMaker
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
mod += '\nrenderLms = function () {};\n';
mod += '\n__x = { LMS_CHARS, LMS, assetOwners, sharedAssets, nextAsset, buildCharBlock, buildShowsTable, pendingInfo, listsChanged, forkSong, pickReplace, scanLms, songInfo, lmsYypText, lmsYypName, lmsYypOk, yypInsertEntries, repairLmsYyp, writeLms };\n';

/* ---------- archivos reales + fixture overrides ---------- */
const realFiles = {
  'scripts/scr_lms/scr_lms.gml': fs.readFileSync(path.join(ROOT, 'scripts/scr_lms/scr_lms.gml'), 'utf8'),
  'betterserver-oss/include/Server.h': fs.readFileSync(path.join(ROOT, 'betterserver-oss/include/Server.h'), 'utf8'),
  'betterserver-oss/disasterserver/states/Game.c': fs.readFileSync(path.join(ROOT, 'betterserver-oss/disasterserver/states/Game.c'), 'utf8'),
  'scripts/net_state_game/net_state_game.gml': fs.readFileSync(path.join(ROOT, 'scripts/net_state_game/net_state_game.gml'), 'utf8'),
  'proyecto.yyp': fs.readFileSync(path.join(ROOT, 'Sonicexe The Disaster 2D Remake.yyp'), 'utf8')
};
let overrides = {};   // fixture activo (scr_lms viejo / .yyp roto)
const fileState = () => Object.assign({}, realFiles, overrides);

// .yyp PRE-FIX: el estado que rompia el juego (sin 25 ni 26 registradas)
const yypFixed = realFiles['proyecto.yyp'];
const yypBroken = yypFixed
  .replace('    {"id":{"name":"mus_lms_25","path":"sounds/mus_lms_25/mus_lms_25.yy",},},\n', '')
  .replace('    {"id":{"name":"mus_lms_26","path":"sounds/mus_lms_26/mus_lms_26.yy",},},\n', '');

// scr_lms VIEJO (sin comillas, pre-slots): Blaze/Rouge/Kris compartian la 15
const B = '\x5b'; // corchete abierto (se construye asi a proposito)
const gmlOld = [
  'global.lmsCharSongs = ds_map_create();',
  'global.lmsCharSongs[? CHARACTER_BLAZE] = ' + B + 'mus_lms_15];',
  'global.lmsCharSongs[? CHARACTER_ROUGE] = ' + B + 'mus_lms_15];',
  'global.lmsCharSongs[? CHARACTER_KRIS] = ' + B + 'mus_lms_15];',
  'function scr_lms_play_song() {}'
].join('\n');

/* ---------- FS falso: sonidos en disco + captura de escrituras ---------- */
const diskSounds = new Set(); for (let n = 2; n <= 28; n++) diskSounds.add(n);
const durOf = { 25: 232, 26: 212, 27: 187, 28: 198 };
const fsWrites = [];   // rel de todo lo escrito
const fsOverlay = {};  // rel -> texto (lo ultimo)
function fakeDir(p) {
  return {
    name: p ? p.split('/').pop() : '',
    getDirectoryHandle: async (n) => fakeDir(p ? p + '/' + n : n),
    getFileHandle: async (n) => ({
      createWritable: async () => ({
        write: async (d) => { const rel = (p ? p + '/' : '') + n; fsWrites.push(rel); fsOverlay[rel] = String(d); },
        close: async () => {}
      })
    }),
    entries: async function* () { yield ['proyecto.yyp', { kind: 'file' }]; }
  };
}
const resolveText = (rel) => {
  if (Object.prototype.hasOwnProperty.call(fsOverlay, rel)) return fsOverlay[rel];
  const st = fileState();
  if (Object.prototype.hasOwnProperty.call(st, rel)) return st[rel];
  const m = /^sounds\/(mus_lms_(\d+))\/\1\.yy$/.exec(rel);
  if (m && diskSounds.has(+m[2])) {
    const n = +m[2];
    return '{"duration":' + (durOf[n] || 180) + ',"soundFile":"' + m[1] + '.mp3"}';
  }
  return null;
};

const toasts = [];
let confirmText = null;
const S = { mode: 'fs', rootHandle: null };
let lastInp = null, changeCb = null;
const sandbox = {
  console, S, JSON, Math, Date, Set, RegExp,
  readText: async (rel) => resolveText(rel),
  fsWalkDir: async () => fakeDir(''),
  fsWalkFile: async (rel) => {
    if (rel === 'sounds/mus_lms_15/mus_lms_15.mp3')
      return { getFile: async () => ({ arrayBuffer: async () => new ArrayBuffer(16) }) };
    if (resolveText(rel) != null)
      return { getFile: async () => ({ text: async () => resolveText(rel) }) };
    throw new Error('no existe: ' + rel);
  },
  toast: (msg, kind) => toasts.push({ msg, kind }),
  confirm: (t) => { confirmText = t; return true; },
  normPath: (p) => String(p).replace(/\\/g, '/').replace(/^\.\//, ''),
  ensureDir: async (rel) => { fsWrites.push(rel + '/'); return fakeDir(rel); },
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
  ok(true, 'modulo LMS v1.2 carga en la sandbox');
} catch (e) { ok(false, 'modulo LMS NO carga: ' + e.message); process.exit(1); }
const X = sandbox.__x;
const { LMS, LMS_CHARS, assetOwners, sharedAssets, nextAsset, buildCharBlock, buildShowsTable, pendingInfo, forkSong, pickReplace, scanLms, yypInsertEntries, repairLmsYyp } = X;

const jsonOk = (t) => { try { JSON.parse(String(t).replace(/^\uFEFF/, '').replace(/,(\s*[}\]])/g, '$1')); return true; } catch (e) { return false; } };

const main = async () => {
  /* ---------- 2. estado REAL reparado: scan del formato nuevo ---------- */
  await scanLms();
  ok(LMS.base === 'ok', 'scanLms: base ok (lista por personaje)');
  ok(LMS_CHARS.length === 16, '16 personajes en el modulo: ' + LMS_CHARS.length);
  const rouge = LMS.chars.rouge.songs, kris = LMS.chars.kris.songs;
  ok(rouge.length === 3 && rouge.map(s => s.asset).join(',') === 'mus_lms_27,mus_lms_26,mus_lms_28',
    'Rouge escaneada con SUS 3 canciones en orden: ' + rouge.map(s => s.asset).join(','));
  ok(rouge.map(s => s.dur).join(',') === '187,212,198', 'durations de Rouge desde el .yy: ' + rouge.map(s => s.dur).join(','));
  ok(kris.length === 1 && kris[0].asset === 'mus_lms_25' && kris[0].dur === 232, 'Kris en su slot mus_lms_25 (dur 232)');
  ok(LMS.missing.length === 0, 'con el .yyp reparado no falta NINGUN registro: missing = []');

  /* ---------- 3. sin compartidas + nextAsset ---------- */
  ok(sharedAssets().length === 0, 'ninguna cancion compartida (los slots propios funcionan)');
  const nx = await nextAsset();
  ok(nx === 'mus_lms_29', 'nextAsset() = ' + nx + ' (2..28 usados/registrados/en disco, 29 libre)');

  /* ---------- 4. buildCharBlock: texto seguro, nunca asset directo ---------- */
  const cb = buildCharBlock();
  ok(cb.includes('CHARACTER_ROUGE] = ' + '["mus_lms_27", "mus_lms_26", "mus_lms_28"]'), 'buildCharBlock: Rouge con comillas (texto)');
  ok(cb.includes('CHARACTER_KRIS] = ' + '["mus_lms_25"]'), 'buildCharBlock: Kris con comillas');
  ok(!/\[\s*mus_/.test(cb), 'buildCharBlock NUNCA emite assets directos (sin comillas)');
  const st = buildShowsTable();
  ok(/\{ CH_ROUGE, 3, \{ 187, 212, 198 \} \}/.test(st), 'buildShowsTable: CH_ROUGE 3 canciones con sus duraciones');
  ok(/\{ CH_KRIS, 1, \{ 232 \} \}/.test(st), 'buildShowsTable: CH_KRIS dur 232');

  /* ---------- 5. formato VIEJO (sin comillas) sigue parseando ---------- */
  overrides = { 'scripts/scr_lms/scr_lms.gml': gmlOld };
  await scanLms();
  ok(LMS.chars.rouge.songs.length === 1 && LMS.chars.rouge.songs[0].asset === 'mus_lms_15'
    && LMS.chars.kris.songs[0].asset === 'mus_lms_15' && LMS.chars.blaze.songs[0].asset === 'mus_lms_15',
    'scanLms parsea el formato viejo sin comillas (Blaze/Rouge/Kris en mus_lms_15)');

  /* ---------- 6. slots propios: la proteccion v1.1 sigue intacta ---------- */
  const own15 = assetOwners('mus_lms_15', 'rouge').map(c => c.label);
  ok(own15.join(',') === 'Blaze,Kris', "assetOwners('mus_lms_15','rouge') = [" + own15.join(',') + ']');
  LMS.sel = 'kris';
  const p0 = pickReplace(0);
  lastInp.files = [{ name: 'kris_theme.mp3', arrayBuffer: async () => new ArrayBuffer(8) }];
  await changeCb(); await p0;
  const ks = LMS.chars.kris.songs[0];
  ok(ks.asset === 'mus_lms_29', 'pickReplace compartida → Kris a su slot propio ' + ks.asset + ' (no pisa la 15)');
  LMS.sel = 'rouge';
  await forkSong(0);
  const rs = LMS.chars.rouge.songs[0];
  ok(rs.asset === 'mus_lms_30', 'forkSong: Rouge → slot propio ' + rs.asset + ' (29 era de Kris)');
  ok(LMS.chars.blaze.songs[0].asset === 'mus_lms_15' && LMS.chars.kris.songs[0].asset !== 'mus_lms_15',
    'Blaze sigue en la 15 y Kris ya tiene la suya');
  const cb2 = buildCharBlock();
  ok(cb2.includes('["mus_lms_29"]') && cb2.includes('["mus_lms_30"]'), 'buildCharBlock: los slots nuevos tambien con comillas');
  const p = pendingInfo();
  ok(p.forks.length === 2, 'pendingInfo: 2 slots propios (kris y rouge)');

  /* ---------- 7. EL BUG REAL: .yyp sin mus_lms_25/26 ---------- */
  overrides = { 'proyecto.yyp': yypBroken };           // scr_lms real (v5.4) otra vez
  await scanLms();
  ok(LMS.missing.join(',') === 'mus_lms_25,mus_lms_26',
    'DETECCION: .yyp sin 25/26 → LMS.missing = [' + LMS.missing.join(',') + '] (el estado que revientaba el juego)');
  ok(LMS.chars.rouge.songs.length === 3 && LMS.chars.kris.songs[0].asset === 'mus_lms_25',
    'las listas reales siguen escaneadas (Rouge 3, Kris 25)');

  /* ---------- 8. yypInsertEntries: puro, idempotente, robusto ---------- */
  const res = yypInsertEntries(yypBroken, ['mus_lms_25', 'mus_lms_26', 'mus_lms_27']);
  ok(res && res.added.join(',') === 'mus_lms_25,mus_lms_26', 'inserta solo lo que falta (27 ya estaba): added = [' + (res && res.added.join(',')) + ']');
  ok(jsonOk(res.text), 'el .yyp resultante es JSON valido (comas colgantes ok)');
  ok(res.text.includes('"path":"sounds/mus_lms_25/mus_lms_25.yy"') && res.text.includes('"path":"sounds/mus_lms_26/mus_lms_26.yy"'), 'entradas 25 y 26 con el formato exacto del proyecto');
  const res2 = yypInsertEntries(res.text, ['mus_lms_25', 'mus_lms_26']);
  ok(res2.added.length === 0, 'idempotente: segunda pasada no anade nada');
  ok(yypInsertEntries('{"resources": [', ['mus_lms_99']) === null, 'devuelve null si no encuentra la lista resources');
  ok(jsonOk(yypFixed) && yypFixed.includes('mus_lms_25/mus_lms_25.yy'), 'el .yyp REAL del repo ya trae las 2 entradas (fix aplicado)');

  /* ---------- 9. 🩹 repairLmsYyp: el camino de recuperacion ---------- */
  toasts.length = 0; fsWrites.length = 0; confirmText = null;
  S.rootHandle = fakeDir('');
  await repairLmsYyp();
  ok(confirmText && /GameMaker debe estar CERRADO/.test(confirmText), 'el confirm avisa que GameMaker debe estar cerrado');
  ok(fsOverlay['proyecto.yyp'] && fsOverlay['proyecto.yyp'].includes('"name":"mus_lms_25"')
    && fsOverlay['proyecto.yyp'].includes('"name":"mus_lms_26"'), 'escribe el .yyp con las 2 entradas perdidas');
  ok(fsWrites.some(w => w.startsWith('_backups_animeditor/') && w.endsWith('proyecto.yyp')), 'backup del .yyp antes de reparar (deshacer posible)');
  ok(LMS.undoStack.length === 1, 'la reparacion entra en la pila de deshacer');
  ok(jsonOk(fsOverlay['proyecto.yyp']), 'el .yyp reparado es JSON valido');
  ok(LMS.missing.length === 0, 'al re-escanear tras la reparacion ya no falta nada');
  ok(toasts.some(t => /reparado/.test(t.msg)), 'toast de reparado: "' + (toasts[0] && toasts[0].msg.split('\n')[0]) + '"');
  // caso "se perdio hasta el audio": no puede reparar y lo dice
  toasts.length = 0;
  LMS.missing = ['mus_lms_99'];
  await repairLmsYyp();
  ok(toasts.some(t => /No puedo reparar/.test(t.msg)), 'sin audio en sounds/ avisa que no puede reparar (no escribe nada)');
  ok(LMS.missing.join(',') === 'mus_lms_99', 'el aviso temprano no re-escanea (missing intacto hasta el proximo scan)');

  /* ---------- 10. aserciones de fuente del writer v1.2 ---------- */
  ok(mod.includes('.concat(LMS.missing || [])'), 'writeLms re-registra tambien las canciones perdidas');
  ok(mod.includes('function yypInsertEntries'), 'helper yypInsertEntries presente');
  ok((mod.match(/yypInsertEntries\(/g) || []).length >= 3, 'yypInsertEntries usado por writer + reparacion');
  ok(/GameMaker debe estar CERRADO/.test(mod), 'writeLms avisa en el confirm de GameMaker abierto');
  ok(/ciérralo SIN guardar/.test(mod), 'toast final: cerrar GM sin guardar y reabrir');
  ok(/Re-registrar en el \.yyp/.test(mod), 'boton 🩹 de reparacion en el panel');
  ok(/replace\(\/\^\[\"\']\+\|\[\"\']\+\$\/g, \'\'\)/.test(mod), 'scanLms quita comillas (lee los 2 formatos)');
  ok(/GameMaker CERRADO al escribir/.test(html), 'nota del panel derecho sobre GM cerrado + 🩹');

  /* ---------- 11. scr_lms.gml v5.4: estatico ---------- */
  const gml = realFiles['scripts/scr_lms/scr_lms.gml'];
  ok((gml.match(/global\.lmsCharSongs\[\? CHARACTER_/g) || []).length === 16, 'scr_lms: 16 personajes en la lista');
  ok(gml.includes('CHARACTER_ROUGE] = ' + '["mus_lms_27", "mus_lms_26", "mus_lms_28"]'), 'scr_lms: Rouge exacta (orden preservado)');
  ok(gml.includes('CHARACTER_KRIS] = ' + '["mus_lms_25"]'), 'scr_lms: Kris en su slot');
  ok(!/\[\s*mus_lms/.test(gml), 'scr_lms: NINGUNA lista con assets directos (todo texto)');
  ok((gml.match(/asset_get_index/g) || []).length >= 3, 'scr_lms: resolucion por asset_get_index (2 en codigo + doc)');
  ok(/for\(var i = 0; i < array_length\(_list\); i\+\+\)/.test(gml), 'scr_lms: fallback a la primera cancion existente');
  ok(/scr_play_music\(_snd\);/.test(gml), 'scr_lms: toca el indice resuelto');
  const bal = (ch, cl) => (gml.split(ch).length - 1) === (gml.split(cl).length - 1);
  ok(bal('{', '}') && bal('(', ')') && bal('[', ']'), 'scr_lms: llaves/parens/corchetes balanceados');

  console.log('\n' + (fails ? fails + ' PRUEBA(S) FALLARON' : 'TODO OK — fix «mus_lms_N not set» validado (v1.2)'));
  process.exit(fails ? 1 : 0);
};
main().catch(e => { console.error('EXCEPCION:', e); process.exit(1); });
