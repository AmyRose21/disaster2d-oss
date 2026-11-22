#!/usr/bin/env node3
// check_v70.js — verificación de regla 6 para v70 (Suite Cajas + macros).
// Ejecuta el MOTOR REAL del Suite (C.parseMacros/C.setMacro extraídos del
// Suite_TD2D.html) contra el GML REAL modificado: la prueba de verdad es
// que el motor de la Suite pueda leer y re-escribir las macros nuevas.
const fs = require('fs');
const path = '/home/z/my-project/repo/Suite_TD2D.html';
const html = fs.readFileSync(path, 'utf8');

// Extraer el bloque <script> de AnimCore (donde viven parseMacros/setMacro)
const lines = html.split('\n');
let core = null;
let inS = false, buf = [];
for (let i = 0; i < lines.length; i++) {
  if (!inS && /^<script>/.test(lines[i])) { inS = true; buf = []; continue; }
  if (inS && /^<\/script>/.test(lines[i])) {
    const js = buf.join('\n');
    if (/function parseMacros/.test(js) && /function setMacro/.test(js)) core = js;
    inS = false; continue;
  }
  if (inS) buf.push(lines[i]);
}
if (!core) { console.log('FAIL: no encontré AnimCore'); process.exit(1); }

let fails = 0;
const check = (name, cond, detail) => {
  console.log(`  [${cond ? 'OK' : 'FAIL'}] ${name}${detail ? ' — ' + detail : ''}`);
  if (!cond) fails++;
};

// AnimCore es UMD (module.exports en Node, window.AnimCore en browser):
// aislar el FACTORY (la función anónima `function () { ... }` que retorna
// el objeto con parseMacros/setMacro) y ejecutarlo aquí directamente.
const umdStart = core.indexOf('function (root, factory) {');
const factoryStart = core.indexOf('function () {', umdStart);
if (umdStart < 0 || factoryStart < 0) { console.log('FAIL: UMD no encontrado'); process.exit(1); }
// el factory termina en el último '});' del bloque — el cierre del UMD completo
const factoryEnd = core.lastIndexOf('});');
const factorySrc = core.slice(factoryStart, factoryEnd); // 'function () { ... }'
// el factory termina ANTES del '});' final (cierre del factory + del UMD):
// el slice correcto es factorySrc + '}' (cerrar la función, sin el ')' del UMD)
const factorySrc2 = factorySrc + '\n}';
let factory;
try { factory = (new Function('return (' + factorySrc2 + ')'))(); }
catch (e) { console.log('FAIL al construir factory:', e.message); process.exit(1); }
const C = factory();
if (!C || !C.parseMacros) { console.log('FAIL: factory sin parseMacros'); process.exit(1); }

console.log('== A. GML: macros ITEMBOX_*_TIME ==');
const gml = fs.readFileSync('/home/z/my-project/repo/scripts/net_state_game/net_state_game.gml', 'utf8');
const macs = C.parseMacros(gml);
const names = ['ITEMBOX_SHIELD_TIME', 'ITEMBOX_INVULN_TIME', 'ITEMBOX_ELECTRIC_TIME', 'ITEMBOX_BOOTS_TIME'];
const defs = { ITEMBOX_SHIELD_TIME: 5, ITEMBOX_INVULN_TIME: 3, ITEMBOX_ELECTRIC_TIME: 2.5, ITEMBOX_BOOTS_TIME: 8 };
for (const n of names) {
  const m = macs.find(x => x.name === n);
  check(`macro ${n} parseable (kind=sec)`, m && m.kind === 'sec', m ? m.raw : 'NO ENCONTRADA');
  if (m) check(`  segundos leidos = ${defs[n]}`, Math.abs(m.seconds) === defs[n], `leido: ${m.seconds}`);
}
check('literales viejos fuera (5 * 60 / 3 * 60 / 60 * 2.5 / 60 * 8 en rewards)',
  !/shieldTimer = 5 \* 60/.test(gml) && !/hurttime = 3 \* 60/.test(gml) &&
  !/electricShieldTimer = 60 \* 2\.5/.test(gml) && !/bootsTimer = 60 \* 8/.test(gml));
check('usos de las macros en el switch(_type)',
  /shieldTimer = ITEMBOX_SHIELD_TIME;/.test(gml) && /hurttime = ITEMBOX_INVULN_TIME;/.test(gml) &&
  /electricShieldTimer = ITEMBOX_ELECTRIC_TIME;/.test(gml) && /bootsTimer = ITEMBOX_BOOTS_TIME;/.test(gml));

console.log('== B. MOTOR: setMacro sobre el GML real ==');
// 1) cambiar botas de 8 a 12 s
let r = C.setMacro(gml, 'ITEMBOX_BOOTS_TIME', { seconds: 12 });
check('setMacro botas 8→12s cambia', r.changed === true);
if (r.changed) {
  const m2 = C.parseMacros(r.gml).find(x => x.name === 'ITEMBOX_BOOTS_TIME');
  check('  releído = 12 s', m2 && Math.abs(m2.seconds) === 12, m2.raw);
  check('  formato (60 * 12) conservado', /\(60 \* 12\)/.test(r.gml));
  // 2) idempotencia: mismo valor otra vez = no-op
  const r2 = C.setMacro(r.gml, 'ITEMBOX_BOOTS_TIME', { seconds: 12 });
  check('re-escribir mismo valor = sin cambios', r2.gml === r.gml);
  // 3) decimales: 2.5
  const r3 = C.setMacro(gml, 'ITEMBOX_ELECTRIC_TIME', { seconds: 4.75 });
  const m3 = C.parseMacros(r3.gml).find(x => x.name === 'ITEMBOX_ELECTRIC_TIME');
  check('setMacro electric 2.5→4.75s', m3 && Math.abs(m3.seconds) === 4.75, m3.raw);
  // 4) el resto del archivo NO cambia salvo la línea de la macro
  const d = r.gml.split('\n');
  const o = gml.split('\n');
  let diffLines = 0;
  for (let i = 0; i < Math.max(d.length, o.length); i++) if (d[i] !== o[i]) diffLines++;
  check('solo 1 línea de diff (la macro)', diffLines === 1, `${diffLines} líneas`);
}

console.log('== C. SUITE: módulo cajas presente ==');
check('nav: botón data-mod=boxes', /data-mod="boxes"/.test(html));
check('panel: #mod-boxes', /id="mod-boxes"/.test(html));
check('switchModule: toggle mod-boxes', /\$\('#mod-boxes'\)\.classList\.toggle\('hidden', mod !== 'boxes'\)/.test(html));
check('dispatch: enterBoxes', /mod === 'boxes' && window\.enterBoxes/.test(html));
check('JS: BOX_REL correcto', /scripts\/net_state_game\/net_state_game\.gml/.test(html));
check('JS: 4 BOX_ITEMS', /ITEMBOX_SHIELD_TIME/.test(html) && /ITEMBOX_INVULN_TIME/.test(html) &&
  /ITEMBOX_ELECTRIC_TIME/.test(html) && /ITEMBOX_BOOTS_TIME/.test(html));
check('JS: escribe vía T.writeEdits', /\$\('#boxes-write'\)\.addEventListener\('click', \(\) => T\.writeEdits\(\)\)/.test(html));
check('JS: onAfterWrite re-entra módulo', /S\.module === 'boxes'/.test(html));
check('JS: descarte relee del disco', /Bx\.ready = false;.*al descartar/s.test(html));

console.log('== D. HTML/JS integridad ==');
// balance de script tags REALES (por línea)
let o2 = 0, c2 = 0;
for (const L of lines) {
  if (/^<script>/.test(L)) o2++;
  if (/^<\/script>/.test(L)) c2++;
}
check(`script tags reales ${o2}/${c2}`, o2 === c2);
// sintaxis de todos los bloques reales
{
  let inS2 = false, buf2 = [], bad = 0, n = 0;
  for (let i = 0; i < lines.length; i++) {
    if (!inS2 && /^<script>/.test(lines[i])) { inS2 = true; buf2 = []; continue; }
    if (inS2 && /^<\/script>/.test(lines[i])) {
      n++;
      try { new Function(buf2.join('\n')); } catch (e) { bad++; console.log('  FAIL bloque@' + i + ': ' + e.message); }
      inS2 = false; continue;
    }
    if (inS2) buf2.push(lines[i]);
  }
  check(`los ${n} bloques JS compilan`, bad === 0);
}

console.log('== E. Regla 7: superficie de red intacta ==');
const diff = require('child_process').execSync(
  'git -C /home/z/my-project/repo diff --stat scripts/net_packets/ betterserver-oss/', { encoding: 'utf8' });
check('sin cambios en net_packets/ ni betterserver-oss/', diff.trim() === '', diff.trim() || 'limpio');

console.log('');
if (fails) { console.log(`RESULT: ${fails} FALLOS`); process.exit(1); }
console.log('RESULT: TODOS LOS CHECKS v70 OK');
