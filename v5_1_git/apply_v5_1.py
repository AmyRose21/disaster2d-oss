#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
apply_v5_1.py — v5.1 «Copias propias (Sally Canon / Vanilla) + LMS multi-canción»

Aplica SOBRE el repo disaster2d-oss (clon fresco o working tree):

  A) SPRITES NUEVOS (14, copias editables):
     Sally Canon  <- copia de Sally : spr_lobby_icon_sallycanon, spr_char_info_sallycanon,
                     spr_playerhealth_sallycanon (7f), _hit_, _demon_, spr_playerescaped_,
                     spr_menu_sallycanon (retrato animado).
     Vanilla      <- copia de Cream : mismos 7 sprites con sufijo _vanilla.
     Registrados en .yyp y .resource_order.

  B) SCR_CHARACTERS.GML — bloque v5.1 de resolvedores (sustituye al v3.7):
     scr_lobby_icon_sprite/frame/animated/pair + scr_lobby_shiny_setup/resolve/escape
     + scr_hud_strip / scr_hud_strip_red / scr_hud_hit / scr_hud_demon /
       scr_hud_escaped / scr_hud_escaped_draw.
     Prioridad lobby: brillo (sh) > sprite propio > tira común.
     El Suite TD2D regenera este bloque al escribir (mismos marcadores).

  C) REDIRECCIONES (dejan de reusar arte ajeno; usan las copias):
     obj_lobby/Create_0.gml (retratos chars[8]/[9]), obj_lobby/Draw_0.gml (placas),
     obj_lobby_icon/Draw_0.gml (navegación + resolve), net_state_charselect.gml,
     obj_menu_waiting/Draw_64.gml, obj_level/Draw_64.gml (HUD propio + ajeno),
     obj_level/Create_0.gml (marcador TAB), net_state_results.gml (cases 1-4).

  D) LMS MULTI-CANCIÓN:
     Server.h (LMS_SONG_COUNT + LMS_SONG_SEC[] + game.lms_song), Game.c (elección
     al azar + PacketWrite8 + reenvío en join), Packet.h (comentario payload u8),
     scr_lms.gml (LMS_HP + global.lmsSongs + scr_lms_play_song),
     net_state_game.gml (lee índice u8 + usa LMS_HP).

Convención: anclas exactas con match == 1 (o bloque por líneas), idempotente
(re-ejecutar no rompe nada), indentación de espacios preservada, LF.
"""

import argparse
import os
import re
import sys
import uuid

APPLIED = []
FAILED = []


def ok(msg):
    APPLIED.append(msg)
    print("  +", msg)


# ---------------------------------------------------------------------
# helpers de archivo
# ---------------------------------------------------------------------

def rd(repo, rel):
    with open(os.path.join(repo, rel), "rb") as f:
        return f.read().decode("utf-8")


def wr(repo, rel, data):
    path = os.path.join(repo, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data.encode("utf-8") if isinstance(data, str) else data)
    ok("ESCRITO: " + rel)


def patch(repo, rel, old, new, count=1):
    """Reemplazo exacto idempotente."""
    src = rd(repo, rel)
    if new in src:
        ok("SKIP(idempotente): " + rel + " :: " + new.strip().splitlines()[0][:60])
        return
    n = src.count(old)
    if n != count:
        FAILED.append("ancla (%d matches, esperaba %d) en %s: %r" % (n, count, rel, old[:100]))
        return
    wr(repo, rel, src.replace(old, new))
    ok("PATCH: " + rel)


def block_replace(repo, rel, first_anchor, last_anchor, new_text, occurrence=1, end_raw=None, end_offset=0):
    """Sustituye el bloque de líneas [first_anchor..last_anchor] (comparando
    stripped; con end_raw compara la línea EXACTA; end_offset añade N líneas
    tras el ancla final) por new_text. Idempotente."""
    src = rd(repo, rel)
    if new_text in src:
        ok("SKIP(idempotente): " + rel + " :: bloque " + first_anchor[:40])
        return
    lines = src.split("\n")
    starts = [i for i, ln in enumerate(lines) if ln.strip() == first_anchor.strip()]
    if len(starts) < occurrence:
        FAILED.append("ancla inicial no hallada (%d) en %s: %r" % (len(starts), rel, first_anchor[:80]))
        return
    i0 = starts[occurrence - 1]
    if end_raw is not None:
        ends = [i for i in range(i0, len(lines)) if lines[i] == end_raw]
    else:
        ends = [i for i in range(i0, len(lines)) if lines[i].strip() == last_anchor.strip()]
    if not ends:
        FAILED.append("ancla final no hallada en %s: %r" % (rel, last_anchor[:80]))
        return
    i1 = ends[0] + end_offset
    out = lines[:i0] + new_text.split("\n") + lines[i1 + 1:]
    wr(repo, rel, "\n".join(out))
    ok("BLOQUE: " + rel + " (líneas %d-%d -> %d nuevas)" % (i0 + 1, i1 + 1, len(new_text.split("\n"))))


# ---------------------------------------------------------------------
# A) sprites copia
# ---------------------------------------------------------------------

def sprite_meta(repo, name):
    t = rd(repo, "sprites/%s/%s.yy" % (name, name))
    frames = re.findall(r'\{"\$GMSpriteFrame":"v1","%Name":"([0-9a-f-]+)"', t)
    layers = re.findall(r'\{"\$GMImageLayer":"","%Name":"([0-9a-f-]+)"', t)
    par = re.search(r'"parent":\s*\{\s*"name":"([^"]+)"[^}]*"path":"([^"]+)"', t)
    return t, frames, layers, par.groups()


def build_sprite_yy(name, w, h, xo, yo, origin_enum, speed, nframes, parent_name, parent_path, tex):
    fid = lambda: str(uuid.uuid4())
    frames = [fid() for _ in range(nframes)]
    layer = fid()
    frame_entries = ",\n".join(
        '    {"$GMSpriteFrame":"v1","%%Name":"%s","name":"%s","resourceType":"GMSpriteFrame","resourceVersion":"2.0",}' % (g, g)
        for g in frames)
    key_entries = ",\n".join(
        ('            {"$Keyframe<SpriteFrameKeyframe>":"","Channels":{\n'
         '                "0":{"$SpriteFrameKeyframe":"","Id":{"name":"%s","path":"sprites/%s/%s.yy",},"resourceType":"SpriteFrameKeyframe","resourceVersion":"2.0",},\n'
         '              },"Disabled":false,"id":"%s","IsCreationKey":false,"Key":%d.0,"Length":1.0,"resourceType":"Keyframe<SpriteFrameKeyframe>","resourceVersion":"2.0","Stretch":false,}')
        % (g, name, name, fid(), i) for i, g in enumerate(frames))
    return ("{\n"
            '  "$GMSprite":"v2",\n'
            '  "%%Name":"%s",\n'
            '  "bboxMode":0,\n'
            '  "bbox_bottom":%d,\n'
            '  "bbox_left":0,\n'
            '  "bbox_right":%d,\n'
            '  "bbox_top":0,\n'
            '  "collisionKind":1,\n'
            '  "collisionTolerance":0,\n'
            '  "DynamicTexturePage":false,\n'
            '  "edgeFiltering":false,\n'
            '  "For3D":false,\n'
            '  "frames":[\n%s\n  ],\n'
            '  "gridX":0,\n'
            '  "gridY":0,\n'
            '  "height":%d,\n'
            '  "HTile":false,\n'
            '  "layers":[\n'
            '    {"$GMImageLayer":"","%%Name":"%s","blendMode":0,"displayName":"default","isLocked":false,"name":"%s","opacity":100.0,"resourceType":"GMImageLayer","resourceVersion":"2.0","visible":true,},\n'
            '  ],\n'
            '  "name":"%s",\n'
            '  "nineSlice":null,\n'
            '  "origin":%d,\n'
            '  "parent":{\n'
            '    "name":"%s",\n'
            '    "path":"%s",\n'
            '  },\n'
            '  "preMultiplyAlpha":false,\n'
            '  "resourceType":"GMSprite",\n'
            '  "resourceVersion":"2.0",\n'
            '  "sequence":{\n'
            '    "$GMSequence":"v1",\n'
            '    "%%Name":"%s",\n'
            '    "autoRecord":true,\n'
            '    "backdropHeight":768,\n'
            '    "backdropImageOpacity":0.5,\n'
            '    "backdropImagePath":"",\n'
            '    "backdropWidth":1366,\n'
            '    "backdropXOffset":0.0,\n'
            '    "backdropYOffset":0.0,\n'
            '    "events":{\n'
            '      "$KeyframeStore<MessageEventKeyframe>":"",\n'
            '      "Keyframes":[],\n'
            '      "resourceType":"KeyframeStore<MessageEventKeyframe>",\n'
            '      "resourceVersion":"2.0",\n'
            '    },\n'
            '    "eventStubScript":null,\n'
            '    "eventToFunction":{},\n'
            '    "length":%d.0,\n'
            '    "lockOrigin":false,\n'
            '    "moments":{\n'
            '      "$KeyframeStore<MomentsEventKeyframe>":"",\n'
            '      "Keyframes":[],\n'
            '      "resourceType":"KeyframeStore<MomentsEventKeyframe>",\n'
            '      "resourceVersion":"2.0",\n'
            '    },\n'
            '    "name":"%s",\n'
            '    "playback":1,\n'
            '    "playbackSpeed":%s,\n'
            '    "playbackSpeedType":0,\n'
            '    "resourceType":"GMSequence",\n'
            '    "resourceVersion":"2.0",\n'
            '    "showBackdrop":true,\n'
            '    "showBackdropImage":false,\n'
            '    "timeUnits":1,\n'
            '    "tracks":[\n'
            '      {"$GMSpriteFramesTrack":"","builtinName":0,"events":[],"inheritsTrackColour":true,"interpolation":1,"isCreationTrack":false,"keyframes":{"$KeyframeStore<SpriteFrameKeyframe>":"","Keyframes":[\n'
            '%s\n'
            '          ],"resourceType":"KeyframeStore<SpriteFrameKeyframe>","resourceVersion":"2.0",},"modifiers":[],"name":"frames","resourceType":"GMSpriteFramesTrack","resourceVersion":"2.0","spriteId":null,"trackColour":0,"tracks":[],"traits":0,},\n'
            '    ],\n'
            '    "visibleRange":null,\n'
            '    "volume":1.0,\n'
            '    "xorigin":%d,\n'
            '    "yorigin":%d,\n'
            '  },\n'
            '  "swatchColours":null,\n'
            '  "swfPrecision":2.525,\n'
            '  "textureGroupId":{\n'
            '    "name":"%s",\n'
            '    "path":"texturegroups/%s",\n'
            '  },\n'
            '  "type":0,\n'
            '  "VTile":false,\n'
            '  "width":%d,\n'
            '}\n') % (name, h - 1, w - 1, frame_entries, h, layer, layer, name, origin_enum,
                      parent_name, parent_path, name, nframes, name, ("%.1f" % speed),
                      key_entries, xo, yo, tex, tex, w)
    # %Name necesita quedarse literal: reintroducir con el escape correcto
    out = out.replace('"%%Name"', '"%Name"')
    return out


# (name, src, src_frames, w, h, xo, yo, origin_enum, speed, parent, parent_path, tex)
def all_frames(repo, src):
    return list(range(len(sprite_meta(repo, src)[1])))


def make_copy(repo, c):
    name = c["name"]
    rel_yy = "sprites/%s/%s.yy" % (name, name)
    if os.path.exists(os.path.join(repo, rel_yy)):
        ok("SKIP(sprite ya existe): " + name)
        return
    _, src_frames, src_layers, _ = sprite_meta(repo, c["src"])
    src_layer = src_layers[0]
    frames = c["frames"] if c["frames"] is not None else list(range(len(src_frames)))
    yy = build_sprite_yy(name, c["w"], c["h"], c["xo"], c["yo"], c["oe"], c["speed"],
                         len(frames), c["parent"][0], c["parent"][1], c["tex"])
    wr(repo, rel_yy, yy)
    # GUIDs nuevos de frames/layer ya están en el .yy: extraerlos en orden
    new_frames = re.findall(r'\{"\$GMSpriteFrame":"v1","%Name":"([0-9a-f-]+)"', yy)
    new_layer = re.findall(r'\{"\$GMImageLayer":"","%Name":"([0-9a-f-]+)"', yy)[0]
    for i, sf in enumerate(frames):
        srcfg = src_frames[sf]
        nf = new_frames[i]
        for src_rel, dst_rel in (
            ("sprites/%s/%s.png" % (c["src"], srcfg), "sprites/%s/%s.png" % (name, nf)),
            ("sprites/%s/layers/%s/%s.png" % (c["src"], srcfg, src_layer),
             "sprites/%s/layers/%s/%s.png" % (name, nf, new_layer)),
        ):
            with open(os.path.join(repo, src_rel), "rb") as f:
                data = f.read()
            wr(repo, dst_rel, data)


LOBBY_PARENT = ("Lobby", "folders/Sprites/Lobby.yy")
GUI_PARENT = ("Player", "folders/Sprites/GUI/Player.yy")
GIFS_PARENT = ("Gifs", "folders/Sprites/Main Menu/Gifs.yy")

COPIES = [
    # --- Sally Canon (copias del arte de Sally) ---
    dict(name="spr_lobby_icon_sallycanon", src="spr_lobby_icon", frames=[7], w=24, h=24, xo=12, yo=12, oe=4, speed=0, parent=LOBBY_PARENT, tex="Menus"),
    dict(name="spr_char_info_sallycanon", src="spr_char_info", frames=[5], w=478, h=40, xo=0, yo=0, oe=0, speed=10, parent=LOBBY_PARENT, tex="Menus"),
    dict(name="spr_playerhealth_sallycanon", src="spr_playerhealth", frames=list(range(35, 42)), w=26, h=26, xo=0, yo=26, oe=6, speed=30, parent=GUI_PARENT, tex="Game"),
    dict(name="spr_playerhealth_hit_sallycanon", src="spr_playerhealth_hit", frames=[5], w=26, h=26, xo=0, yo=26, oe=6, speed=10, parent=GUI_PARENT, tex="Game"),
    dict(name="spr_playerhealth_demon_sallycanon", src="spr_playerhealth_demon", frames=[5], w=26, h=26, xo=0, yo=26, oe=6, speed=30, parent=GUI_PARENT, tex="Game"),
    dict(name="spr_playerescaped_sallycanon", src="spr_playerescaped", frames=[5], w=26, h=26, xo=0, yo=26, oe=6, speed=30, parent=GUI_PARENT, tex="Game"),
    dict(name="spr_menu_sallycanon", src="spr_menu_sally", frames=None, w=137, h=174, xo=73, yo=173, oe=9, speed=10, parent=GIFS_PARENT, tex="Menus"),
    # --- Vanilla (copias del arte de Cream) ---
    dict(name="spr_lobby_icon_vanilla", src="spr_lobby_icon", frames=[6], w=24, h=24, xo=12, yo=12, oe=4, speed=0, parent=LOBBY_PARENT, tex="Menus"),
    dict(name="spr_char_info_vanilla", src="spr_char_info", frames=[4], w=478, h=40, xo=0, yo=0, oe=0, speed=10, parent=LOBBY_PARENT, tex="Menus"),
    dict(name="spr_playerhealth_vanilla", src="spr_playerhealth", frames=list(range(28, 35)), w=26, h=26, xo=0, yo=26, oe=6, speed=30, parent=GUI_PARENT, tex="Game"),
    dict(name="spr_playerhealth_hit_vanilla", src="spr_playerhealth_hit", frames=[4], w=26, h=26, xo=0, yo=26, oe=6, speed=10, parent=GUI_PARENT, tex="Game"),
    dict(name="spr_playerhealth_demon_vanilla", src="spr_playerhealth_demon", frames=[4], w=26, h=26, xo=0, yo=26, oe=6, speed=30, parent=GUI_PARENT, tex="Game"),
    dict(name="spr_playerescaped_vanilla", src="spr_playerescaped", frames=[4], w=26, h=26, xo=0, yo=26, oe=6, speed=30, parent=GUI_PARENT, tex="Game"),
    dict(name="spr_menu_vanilla", src="spr_menu_cream", frames=None, w=186, h=174, xo=111, yo=174, oe=9, speed=10, parent=GIFS_PARENT, tex="Menus"),
]


# ---------------------------------------------------------------------
# registro .yyp + .resource_order
# ---------------------------------------------------------------------

def patch_registry(repo):
    yyp = "Sonicexe The Disaster 2D Remake.yyp"
    rorder = "Sonicexe The Disaster 2D Remake.resource_order"

    def yyp_entry(name, path):
        return '    {"id":{"name":"%s","path":"%s",},},\n' % (name, path)

    src = rd(repo, yyp)
    missing = [c["name"] for c in COPIES if ('"name":"%s"' % c["name"]) not in src]
    if not missing:
        ok("SKIP(.yyp ya registrado)")
        return
    anchors = [
        '    {"id":{"name":"spr_lms_banner","path":"sprites/spr_lms_banner/spr_lms_banner.yy",},},\n',
        '    {"id":{"name":"spr_lobby_icon_fw","path":"sprites/spr_lobby_icon_fw/spr_lobby_icon_fw.yy",},},\n',
        '    {"id":{"name":"mus_undefeatable","path":"sounds/mus_undefeatable/mus_undefeatable.yy",},},\n',
    ]
    anchor = next((a for a in anchors if a in src), None)
    if anchor is None:
        FAILED.append("sin ancla para registrar en .yyp")
        return
    add = "".join(yyp_entry(c["name"], "sprites/%s/%s.yy" % (c["name"], c["name"])) for c in COPIES if c["name"] in missing)
    wr(repo, yyp, src.replace(anchor, anchor + add, 1))
    ok(".yyp: %d sprite(s) registrado(s)" % len(missing))

    src = rd(repo, rorder)
    missing_ro = [c["name"] for c in COPIES if ('"name":"%s"' % c["name"]) not in src]
    if missing_ro:
        ro_anchors = [
            '    {"name":"spr_lms_banner","order":1,"path":"sprites/spr_lms_banner/spr_lms_banner.yy",},\n',
            '    {"name":"spr_lobby_icon_fw","order":1,"path":"sprites/spr_lobby_icon_fw/spr_lobby_icon_fw.yy",},\n',
        ]
        ra = next((a for a in ro_anchors if a in src), None)
        if ra is None:
            ok("AVISO: sin ancla en .resource_order (GM lo regenera solo)")
        else:
            add = "".join('    {"name":"%s","order":1,"path":"sprites/%s/%s.yy",},\n' % (n, n, n) for n in missing_ro)
            wr(repo, rorder, src.replace(ra, ra + add, 1))
            ok(".resource_order: %d sprite(s)" % len(missing_ro))


# ---------------------------------------------------------------------
# B) scr_characters.gml — bloque v5.1
# ---------------------------------------------------------------------

V51_BEG = "// ===== [Suite TD2D v5.1] iconos de selección y HUD por personaje (auto: no editar) ====="
V51_END = "// ===== fin [Suite TD2D v5.1] ====="
V37_BEG = "// ===== [Suite TD2D v3.7] retratos con brillo (auto: no editar) ====="
V37_END = "// ===== fin [Suite TD2D v3.7] retratos con brillo ====="

V51_BLOCK = V51_BEG + r"""
// Resolvedores de arte por personaje. LOBBY (icono de selección + lista
// de sala): prioridad brillo animado (spr_lobby_icon_sh_<key>, v3.7) >
// sprite propio (spr_lobby_icon_<key>; Sally Canon y Vanilla usan COPIAS
// propias desde v5.1 — antes reusaban las de Sally/Cream — y Fleetway su
// tira dedicada) > tira común spr_lobby_icon. HUD (barra de vida /
// golpeado / demonizado / escapó): tiras propias (spr_playerhealth_<key>)
// o las comunes con el bloque del personaje. El Suite TD2D regenera este
// bloque al escribir: no lo edites a mano.
function scr_lobby_icon_sprite(char)
{
    var _spr = -1;
    switch(char)
    {
        case CHARACTER_AMY_CANON: _spr = spr_lobby_icon_sh_amycanon; break;
    }
    if(_spr < 0)
    {
        switch(char)
        {
            case CHARACTER_SALLY_CANON: _spr = spr_lobby_icon_sallycanon; break;
            case CHARACTER_VANILLA: _spr = spr_lobby_icon_vanilla; break;
            case CHARACTER_FLEETWAY_AMY: _spr = spr_lobby_icon_fw; break;
        }
    }
    if(_spr >= 0)
        return _spr;
    return spr_lobby_icon;
}

function scr_lobby_icon_frame(char)
{
    if(scr_lobby_icon_sprite(char) != spr_lobby_icon)
        return 0;
    switch(char)
    {
        case CHARACTER_SALLY_CANON: return CHARACTER_SALLY + 1;
        case CHARACTER_VANILLA: return CHARACTER_CREAM + 1;
        case CHARACTER_METAL: return 10;
        case CHARACTER_AMELIA: return 11;
        case CHARACTER_BLAZE: return 12;
    }
    return char + 1;
}

function scr_lobby_icon_animated(char)
{
    var _spr = scr_lobby_icon_sprite(char);
    if(_spr == spr_lobby_icon)
        return false;
    return sprite_get_number(_spr) > 1;
}

function scr_lobby_icon_pair(char)
{
    return [scr_lobby_icon_sprite(char), scr_lobby_icon_frame(char)];
}

function scr_lobby_shiny_setup(char)
{
    // v5.1: un solo camino para todos (brillo > propio > tira común)
    sprite_index = scr_lobby_icon_sprite(char);
    if(scr_lobby_icon_animated(char))
    {
        image_speed = 1;
        if(image_index < 0 || image_index >= sprite_get_number(sprite_index))
            image_index = 0;
    }
    else
    {
        image_speed = 0;
        image_index = scr_lobby_icon_frame(char);
    }
}

function scr_lobby_shiny_resolve(inst)
{
    with(inst)
    {
        if(obj_netclient.exeId == master_id)
            return;
        if(obj_lobby.state == 2 && obj_netclient.nid == master_id && !isSelected)
            return;
        var _ch = -1;
        if(master_id == obj_netclient.nid)
            _ch = global.character;
        else if(ds_map_exists(obj_netclient.players, master_id) && !obj_netclient.players[? master_id].pending)
            _ch = obj_netclient.players[? master_id].character;
        // v5.1: tope ampliado a Fleetway (antes _ch > CHARACTER_BLAZE la
        // dejaba fuera del resolve)
        if(_ch < CHARACTER_TAILS || _ch == CHARACTER_EXE || _ch > CHARACTER_FLEETWAY_AMY)
            return;
        scr_lobby_shiny_setup(_ch);
    }
}

function scr_lobby_shiny_escape(char, xx, yy)
{
    var _spr = -1;
    switch(char)
    {
        case CHARACTER_AMY_CANON: _spr = spr_lobby_esc_sh_amycanon; break;
    }
    if(_spr < 0)
        return false;
    // [Suite TD2D v3.9.1] El brillo puede medir lo que sea (58x62, 24x24...):
    // su lienzo se CENTRA sobre el hueco del icono 26x26 de la barra
    // (origen abajo-izquierda => centro del hueco en xx+13, yy-13), igual
    // que los exeicon van centrados en su slot del lobby. Antes se dibujaba
    // en (xx, yy) a secas y cualquier brillo mas grande que 26x26 quedaba
    // desplazado (el de Amy Canon 58x62, unos 17px arriba a la derecha).
    var _w = sprite_get_width(_spr);
    var _h = sprite_get_height(_spr);
    var _ox = sprite_get_xoffset(_spr);
    var _oy = sprite_get_yoffset(_spr);
    draw_sprite(_spr, current_time / 150 % sprite_get_number(_spr),
        xx + 13 - _w / 2 + _ox,
        yy - 13 - _h / 2 + _oy);
    return true;
}

function scr_hud_strip(char)
{
    switch(char)
    {
        case CHARACTER_SALLY_CANON: return [spr_playerhealth_sallycanon, 0];
        case CHARACTER_VANILLA: return [spr_playerhealth_vanilla, 0];
    }
    return [spr_playerhealth, (char - CHARACTER_TAILS) * 7];
}

function scr_hud_strip_red(char)
{
    // variante anillo rojo: sin copia propia se usa la común (Sally Canon
    // y Vanilla caen en el bloque de Sally/Cream, como siempre)
    switch(char)
    {
        case CHARACTER_SALLY_CANON: return [spr_playerhealth_redring, (CHARACTER_SALLY - CHARACTER_TAILS) * 7];
        case CHARACTER_VANILLA: return [spr_playerhealth_redring, (CHARACTER_CREAM - CHARACTER_TAILS) * 7];
    }
    return [spr_playerhealth_redring, (char - CHARACTER_TAILS) * 7];
}

function scr_hud_hit(char)
{
    switch(char)
    {
        case CHARACTER_SALLY_CANON: return [spr_playerhealth_hit_sallycanon, 0];
        case CHARACTER_VANILLA: return [spr_playerhealth_hit_vanilla, 0];
    }
    return [spr_playerhealth_hit, char - CHARACTER_TAILS];
}

function scr_hud_demon(char)
{
    switch(char)
    {
        case CHARACTER_SALLY_CANON: return [spr_playerhealth_demon_sallycanon, 0];
        case CHARACTER_VANILLA: return [spr_playerhealth_demon_vanilla, 0];
    }
    return [spr_playerhealth_demon, char - CHARACTER_TAILS];
}

function scr_hud_escaped(char)
{
    switch(char)
    {
        case CHARACTER_SALLY_CANON: return [spr_playerescaped_sallycanon, 0];
        case CHARACTER_VANILLA: return [spr_playerescaped_vanilla, 0];
    }
    return [spr_playerescaped, char - CHARACTER_TAILS];
}

function scr_hud_escaped_draw(char, xx, yy)
{
    // icono de «escapó»: copia propia CENTRADA en el hueco 26x26 (cualquier
    // tamaño, origen abajo-izquierda) o la tira común en su hueco
    var _pair = scr_hud_escaped(char);
    if(_pair[0] != spr_playerescaped)
    {
        var _w = sprite_get_width(_pair[0]);
        var _h = sprite_get_height(_pair[0]);
        var _ox = sprite_get_xoffset(_pair[0]);
        var _oy = sprite_get_yoffset(_pair[0]);
        draw_sprite(_pair[0], _pair[1], xx + 13 - _w / 2 + _ox, yy - 13 - _h / 2 + _oy);
        return true;
    }
    draw_sprite(_pair[0], _pair[1], xx, yy);
    return true;
}
""" + V51_END + "\n"


def patch_scr_characters(repo):
    rel = "scripts/scr_characters/scr_characters.gml"
    src = rd(repo, rel)
    if V51_BEG in src:
        ok("SKIP(scr_characters ya v5.1)")
        return
    if V37_BEG in src:
        i0 = src.index(V37_BEG)
        i1 = src.index(V37_END) + len(V37_END)
        src = src[:i0] + V51_BLOCK + src[i1:].lstrip("\n")
        wr(repo, rel, src)
        ok("scr_characters.gml: bloque v3.7 -> v5.1 (resolvedores)")
    else:
        src = re.sub(r"\s*$", "\n\n", src) + V51_BLOCK
        wr(repo, rel, src)
        ok("scr_characters.gml: bloque v5.1 añadido")


# ---------------------------------------------------------------------
# C) redirecciones GML
# ---------------------------------------------------------------------

def patch_lobby_create(repo):
    patch(repo, "objects/obj_lobby/Create_0.gml",
          "        spr_menu_sally, // 8: Sally Canon reusa el retrato de Sally\n"
          "        spr_menu_cream, // 9: Vanilla reusa el retrato de Cream",
          "        spr_menu_sallycanon, // 8: Sally Canon — retrato PROPIO (v5.1, copia de Sally)\n"
          "        spr_menu_vanilla, // 9: Vanilla — retrato PROPIO (v5.1, copia de Cream)")


def patch_lobby_draw(repo):
    # placas: sally canon / vanilla dejan de reusar frames
    patch(repo, "objects/obj_lobby/Draw_0.gml",
          "        else if(sprInd == 8)\n"
          "                _infoFrame = 5; // sally canon: usa la placa de Sally\n"
          "        else if(sprInd == 9)\n"
          "                _infoFrame = 4; // vanilla: usa la placa de Cream\n"
          "        else if(sprInd == 7)",
          "        // [Suite TD2D v5.1] Sally Canon (8) y Vanilla (9) ya NO se remapean:\n"
          "        // dibujan sus placas PROPIAS (spr_char_info_sallycanon/vanilla)\n"
          "        else if(sprInd == 7)")
    patch(repo, "objects/obj_lobby/Draw_0.gml",
          "        if(!_amyHidden)\n"
          "        {\n"
          "                if(sprInd == 13)\n"
          "                        draw_sprite(spr_char_info_fw, 0, 1, 232-5);\n"
          "                else\n"
          "                        draw_sprite(spr_char_info, _infoFrame, 1, 232-5);\n"
          "        }",
          "        if(!_amyHidden)\n"
          "        {\n"
          "                // [Suite TD2D v5.1] placas PROPIAS: Sally Canon y Vanilla ya no\n"
          "                // reusan las de Sally/Cream — cada una con su copia editable.\n"
          "                // Fleetway sigue con su tira dedicada (v2.14).\n"
          "                if(sprInd == 8)\n"
          "                        draw_sprite(spr_char_info_sallycanon, 0, 1, 232-5);\n"
          "                else if(sprInd == 9)\n"
          "                        draw_sprite(spr_char_info_vanilla, 0, 1, 232-5);\n"
          "                else if(sprInd == 13)\n"
          "                        draw_sprite(spr_char_info_fw, 0, 1, 232-5);\n"
          "                else\n"
          "                        draw_sprite(spr_char_info, _infoFrame, 1, 232-5);\n"
          "        }")


def patch_lobby_icon(repo):
    rel = "objects/obj_lobby_icon/Draw_0.gml"
    # end_raw con indent EXACTO (16 espacios): el "image_blend = c_gray;" del
    # if interno de Fleetway (40 espacios) no debe cortar el bloque antes de tiempo
    block_replace(repo, rel,
                  "// v2.14: Fleetway Amy usa su PROPIA tira independiente",
                  "image_blend = c_gray;",
                  """                // [Suite TD2D v5.1] icono de navegación por resolvedor:
                // brillo > sprite propio (Sally Canon/Vanilla = COPIAS,
                // Fleetway su tira) > tira común. (antes: remapeos a mano)
                scr_lobby_shiny_setup(selected);
                image_blend = c_gray;""",
                  end_raw="                image_blend = c_gray;")
    patch(repo, rel,
          "y = aY - offset;\ndraw_self();",
          "// [Suite TD2D v5.1] resolver el icono del personaje de este jugador\n"
          "// cada fotograma (brillo animado / propio / tira común)\n"
          "if(obj_lobby.state > 0 && !hidden)\n"
          "        scr_lobby_shiny_resolve(self);\n"
          "\n"
          "y = aY - offset;\ndraw_self();")


def patch_charselect(repo):
    block_replace(repo, "scripts/net_state_charselect/net_state_charselect.gml",
                  "if(char == CHARACTER_FLEETWAY_AMY)",
                  "image_xscale = 0;",
                  """                                        // [Suite TD2D v5.1] icono por resolvedor
                                        // (brillo > propio > tira común)
                                        scr_lobby_shiny_setup(char);
                                        image_xscale = 0;""")
    # SERVER_LOBBY_CHARACTER_CHANGE (lo que ven los DEMÁS al elegir un pj):
    # mismo resolvedor — sin esto el icono ajeno usaba la tira vieja
    block_replace(repo, "scripts/net_state_charselect/net_state_charselect.gml",
                  "// v2.14.1: Fleetway Amy con su tira propia (mismo criterio",
                  "image_xscale = 0;",
                  """                                        // [Suite TD2D v5.1] icono por resolvedor (brillo >
                                        // propio > tira común), igual que en el RESPONSE
                                        scr_lobby_shiny_setup(char);
                                        image_xscale = 0;""")


def patch_menu_waiting(repo):
    # end_raw: el cierre del else a 24 espacios exactos (los cierres internos
    # del if/else de Fleetway van a 32 y no deben cortar el bloque)
    block_replace(repo, "objects/obj_menu_waiting/Draw_64.gml",
                  "// v2.14.1: Fleetway Amy (13 crudo) usa su tira propia",
                  "}",
                  """                                // v2.14.1: Fleetway Amy (13 crudo) usa su tira propia
                                // (spr_lobby_icon_fw): en la comun el frame 13 no existe
                                // (13 frames, 0..12) y al envolver salia el de otro pj.
                                // [Suite TD2D v5.1] icono por resolvedor
                                // (brillo > propio > tira común)
                                var _ch = plr.char + 1;
                                sprite = scr_lobby_icon_sprite(_ch);
                                index = scr_lobby_icon_frame(_ch);
                        }""",
                  end_raw="                        }")


def patch_level_draw(repo):
    rel = "objects/obj_level/Draw_64.gml"
    # --- bloque propio (self) ---
    block_replace(repo, rel,
                  "// Sally Canon reusa los iconos de Sally y Vanilla los de Cream",
                  "pos += 28;",
                  """                // [Suite TD2D v5.1] iconos del HUD por resolvedor: tiras propias
                // (Sally Canon / Vanilla = COPIAS independientes de las de
                // Sally/Cream) o la común con el bloque del personaje.
                var _hudChar = global.character;
                
                if(player_exists)
                {
                        if(global.player.revivalTimes < 2)
                        {
                                var sprIndex = round((1.0 - (global.player.hp / 100.0)) * 5);
                                
                                if(global.player.hp <= 0)
                                {
                                        if(global.player.revivalTimes == 0)
                                                sprIndex = 5;
                                        else
                                                sprIndex = 6;
                                }
                                
                                var _hudPair = global.player.redRingTimer > 0 ? scr_hud_strip_red(_hudChar) : scr_hud_strip(_hudChar);
                                draw_sprite(_hudPair[0], _hudPair[1] + sprIndex, pos, 268);
                                if(global.player.revivalTimes >= 1 && global.player.hp > 0)
                                {
                                        var _hudHit = scr_hud_hit(_hudChar);
                                        draw_sprite(_hudHit[0], _hudHit[1], pos, 268);
                                }
                                
                                if(global.player.isDead)
                                {
                                        if(global.player.revivalTimes == 0 && global.player.deadTimer < 31)
                                                scr_number_spr(pos + 12, 264, string(global.player.deadTimer), global.player.deadColor);
                                }
                                else if(global.player.shards > 0)
                                        scr_number_spr(pos + 12, 264, string(global.player.shards), #27ff23);           
                        }
                        else
                        {
                                var _hudDem = scr_hud_demon(_hudChar);
                                draw_sprite(_hudDem[0], _hudDem[1], pos, 268);
                        }
                }
                else
                        // [Suite v5.1] escape: brillo si existe; si no, propio o común
                        if(!scr_lobby_shiny_escape(_hudChar, pos, 268))
                                scr_hud_escaped_draw(_hudChar, pos, 268);
                
                pos += 28;""")
    # --- bloque del resto (others): parte salud/hit/demon ---
    # end_offset=1: incluye la llave que cierra el else demonizado
    block_replace(repo, rel,
                  "// Sally Canon reusa los iconos de Sally en la barra de vida",
                  "draw_sprite(spr_playerhealth_demon, _pch-CHARACTER_TAILS, pos + i * 28, 268);",
                  """                        // [Suite TD2D v5.1] tiras por resolvedor (propias o común)
                        var _pch = inst.character;
                        if(!inst.isDemonized || inst.character == CHARACTER_EXE)
                        {
                                var sprIndex = round((1.0 - (inst.hp / 100.0)) * 5);
                                
                                if(inst.hp <= 0)
                                {
                                        if(inst.revivalTimes == 0)
                                                sprIndex = 5;
                                        else
                                                sprIndex = 6;
                                }
                                
                                var _hudPair2 = redRing ? scr_hud_strip_red(_pch) : scr_hud_strip(_pch);
                                draw_sprite(_hudPair2[0], _hudPair2[1] + sprIndex, pos + i * 28, 268);
                                if(inst.revivalTimes >= 1 && inst.hp > 0)
                                {
                                        var _hudHit2 = scr_hud_hit(_pch);
                                        draw_sprite(_hudHit2[0], _hudHit2[1], pos + i * 28, 268);
                                }
                                
                                if(inst.revivalTimes == 0 && inst.deadTimer < 31)
                                        scr_number_spr(pos + i * 28 + 12, 264, string(inst.deadTimer), inst.deadColor);
                                else if(player_exists && global.character != CHARACTER_EXE && global.player.revivalTimes < 2 && !global.player.isDead && inst.shards > 0)
                                        scr_number_spr(pos + i * 28 + 12, 264, string(inst.shards), #27ff23);
                        }
                        else
                        {
                                var _hudDem2 = scr_hud_demon(_pch);
                                draw_sprite(_hudDem2[0], _hudDem2[1], pos + i * 28, 268);
                        }""",
                  end_offset=1)
    # --- bloque del resto (others): parte escapó ---
    block_replace(repo, rel,
                  "var _ech = player.character == CHARACTER_SALLY_CANON ? CHARACTER_SALLY : player.character;",
                  "draw_sprite(spr_playerescaped, (_ech-CHARACTER_TAILS), pos + i * 28, 268);",
                  """                                var _ech = player.character;
                                // [Suite v5.1] escape: brillo si existe; si no, propio o común
                                if(!scr_lobby_shiny_escape(_ech, pos + i * 28, 268))
                                        scr_hud_escaped_draw(_ech, pos + i * 28, 268);""")


def patch_level_tab(repo):
    rel = "objects/obj_level/Create_0.gml"
    patch(repo, rel,
          "        var hchar = char - 1;\n"
          "        // v2.5 (fix HUD TAB): mismo remapeo que obj_level/Draw_64.gml para el\n"
          "        // icono hit/demon. Sin esto Sally Canon/Vanilla caian en los frames\n"
          "        // 8/9 de spr_playerhealth_hit/demon (placeholders transparentes) y su\n"
          "        // icono de golpe/demonizacion quedaba invisible en el marcador TAB.\n"
          "        if(char == CHARACTER_SALLY_CANON)\n"
          "                hchar = CHARACTER_SALLY - 1;\n"
          "        else if(char == CHARACTER_VANILLA)\n"
          "                hchar = CHARACTER_CREAM - 1;\n"
          "        \n",
          "        var hchar = char - 1;\n"
          "        // [Suite v5.1] hit/demon por resolvedor (tiras propias de Sally\n"
          "        // Canon/Vanilla o la común): sin remapeos a mano.\n")
    patch(repo, rel,
          "        if(hchar > -1)\n"
          "        {\n"
          "                if(revival >= 2)\n"
          "                        draw_sprite(spr_playerhealth_demon, hchar, 480/2-113 + 1, 43 + index * 30 + 28);\n"
          "                else if(revival >= 1)\n"
          "                        draw_sprite(spr_playerhealth_hit, hchar, 480/2-113 + 1, 43 + index * 30 + 28);\n"
          "        }",
          "        if(hchar > -1)\n"
          "        {\n"
          "                // [Suite v5.1] tiras por resolvedor (propias o común)\n"
          "                var _tabPair = revival >= 2 ? scr_hud_demon(char) : scr_hud_hit(char);\n"
          "                draw_sprite(_tabPair[0], _tabPair[1], 480/2-113 + 1, 43 + index * 30 + 28);\n"
          "        }")


def patch_results(repo):
    rel = "scripts/net_state_results/net_state_results.gml"
    block_replace(repo, rel,
                  "// 6 = Amy Canon, 8 = Sally Canon (valores crudos del server):",
                  "// solo el icono de lobby (case 3) usa su tira dedicada via _isFw",
                  """                // 6 = Amy Canon (valor crudo del server): reusa los iconos de
                // Amy (3) en las tiras. v5.1: Sally Canon (8) y Vanilla (9) ya
                // NO se remapean — los resolvedores usan sus tiras PROPIAS
                // (copias independientes de las de Sally/Cream).
                if(_char == 6)
                        _char = 3;""")
    block_replace(repo, rel,
                  "_inst.icon = spr_playerhealth_demon;",
                  "break;",
                  """                                        var _rsDem = scr_hud_demon(_char + 1);
                                        _inst.icon = _rsDem[0];
                                        _inst.frame = _rsDem[1];
                                        break;""")
    block_replace(repo, rel,
                  "_inst.icon = spr_playerhealth;",
                  "break;",
                  """                                        var _rsStr = scr_hud_strip(_char + 1);
                                        _inst.icon = _rsStr[0];
                                        _inst.frame = _rsStr[1] + 6;
                                        break;""")
    block_replace(repo, rel,
                  "// v2.14.2: Fleetway Amy con su tira propia (spr_lobby_icon_fw)",
                  "_inst.frame = _char >= 10 ? _char : 2 + _char;",
                  """                                        // [Suite v5.1] icono por resolvedor (brillo > propio > tira)
                                        var _rsIco = scr_lobby_icon_pair(_char + 1);
                                        _inst.icon = _rsIco[0];
                                        _inst.frame = _rsIco[1];""")
    block_replace(repo, rel,
                  "_inst.icon = spr_playerescaped;",
                  "break;",
                  """                                        var _rsEsc = scr_hud_escaped(_char + 1);
                                        _inst.icon = _rsEsc[0];
                                        _inst.frame = _rsEsc[1];
                                        break;""")


# ---------------------------------------------------------------------
# D) LMS multi-canción
# ---------------------------------------------------------------------

def patch_lms(repo):
    # --- Server.h ---
    patch(repo, "betterserver-oss/include/Server.h",
          "/* v5.0 — LMS «El Show Fuerte»: segundos de show cuando Sonic queda como\n"
          "   ultimo superviviente = duracion de la cancion (Undefeatable V2,\n"
          "   281,8 s redondeado a 282). El reloj SOLO sube: si quedaban mas de\n"
          "   282 s se conservan los que hubiera. */\n"
          "#define LMS_TIME_SEC 282\n",
          "/* v5.1 — LMS «El Show Fuerte» MULTI-CANCION: el server elige UNA cancion\n"
          "   al azar de la lista al disparar el show, sube el reloj a la duracion\n"
          "   de LA ELEGIDA y avisa el indice en SERVER_GAME_LMS (payload u8).\n"
          "   La #1 es la original (mus_undefeatable = Undefeatable, 282 s); el\n"
          "   Suite TD2D anade mus_lms_2..N (.mp3/.ogg) y rellena esta lista con\n"
          "   las duraciones de cada una (redondeadas al segundo). El reloj SOLO\n"
          "   sube: si quedaba mas tiempo, se conserva. */\n"
          "#define LMS_SONG_COUNT 1\n"
          "static const uint16_t LMS_SONG_SEC[LMS_SONG_COUNT] = { 282 };\n")
    patch(repo, "betterserver-oss/include/Server.h",
          "        bool lms; /* v5.0: LMS «El Show Fuerte» activo (Sonic ultimo superviviente) */\n",
          "        bool lms; /* v5.0: LMS «El Show Fuerte» activo (Sonic ultimo superviviente) */\n"
          "        uint8_t lms_song; /* v5.1: indice de la cancion elegida (se reenvia al reconectar) */\n")
    patch(repo, "betterserver-oss/disasterserver/states/Game.c",
          "        /* v5.0 — LMS «EL SHOW FUERTE»: Sonic como ULTIMO SUPERVIVIENTE.\n"
          "           Cuando el unico jugador vivo del bando survivor es Sonic, el show\n"
          "           arranca: el reloj sube a la duracion de la cancion (LMS_TIME_SEC,\n"
          "           solo si queda menos) y se avisa a todos con SERVER_GAME_LMS\n"
          "           (musica Undefeatable + banner + cura a 100 + pasivas).",
          "        /* v5.0 — LMS «EL SHOW FUERTE»: Sonic como ULTIMO SUPERVIVIENTE.\n"
          "           Cuando el unico jugador vivo del bando survivor es Sonic, el show\n"
          "           arranca: el server elige UNA cancion al azar (LMS_SONG_SEC), sube\n"
          "           el reloj a SU duracion (solo si queda menos) y se avisa a todos\n"
          "           con SERVER_GAME_LMS (indice u8 + musica + banner + cura a 100 +\n"
          "           pasivas).")
    patch(repo, "betterserver-oss/disasterserver/states/Game.c",
          "                .lms = false,\n",
          "                .lms = false,\n"
          "                .lms_song = 0,\n")
    patch(repo, "betterserver-oss/disasterserver/states/Game.c",
          "                if (alive == 1 && last && last->surv_char == CH_SONIC)\n"
          "                {\n"
          "                        server->game.lms = true;\n"
          "\n"
          "                        if (server->game.time_sec < LMS_TIME_SEC)\n"
          "                                server->game.time_sec = LMS_TIME_SEC;\n"
          "\n"
          "                        Packet packet;\n"
          "                        PacketCreate(&packet, SERVER_GAME_LMS);\n"
          "                        RAssert(server_broadcast(server, &packet, true));\n"
          "\n"
          "                        Info(LOG_YLW \"LMS: Sonic is the last survivor - El Show Fuerte! (time %ds)\" LOG_RST, (int)server->game.time_sec);\n"
          "                }",
          "                if (alive == 1 && last && last->surv_char == CH_SONIC)\n"
          "                {\n"
          "                        server->game.lms = true;\n"
          "\n"
          "                        /* v5.1: cancion al azar de la lista; el reloj sube a la\n"
          "                           duracion de LA ELEGIDA y el indice viaja en el paquete\n"
          "                           (u8) para que todos los clientes oigan la misma. */\n"
          "                        server->game.lms_song = (uint8_t)(rand() % LMS_SONG_COUNT);\n"
          "\n"
          "                        if (server->game.time_sec < LMS_SONG_SEC[server->game.lms_song])\n"
          "                                server->game.time_sec = LMS_SONG_SEC[server->game.lms_song];\n"
          "\n"
          "                        Packet packet;\n"
          "                        PacketCreate(&packet, SERVER_GAME_LMS);\n"
          "                        PacketWrite(&packet, packet_write8, server->game.lms_song);\n"
          "                        RAssert(server_broadcast(server, &packet, true));\n"
          "\n"
          "                        Info(LOG_YLW \"LMS: Sonic is the last survivor - El Show Fuerte! (song %u/%d, time %ds)\" LOG_RST, (unsigned)server->game.lms_song + 1u, LMS_SONG_COUNT, (int)server->game.time_sec);\n"
          "                }")
    patch(repo, "betterserver-oss/disasterserver/states/Game.c",
          "        if (v->server->game.lms)\n"
          "        {\n"
          "                Packet packet;\n"
          "                PacketCreate(&packet, SERVER_GAME_LMS);\n"
          "                RAssert(packet_send(v->peer, &packet, true));\n"
          "        }",
          "        if (v->server->game.lms)\n"
          "        {\n"
          "                Packet packet;\n"
          "                PacketCreate(&packet, SERVER_GAME_LMS);\n"
          "                /* v5.1: la misma cancion que sono al disparar el show */\n"
          "                PacketWrite(&packet, packet_write8, v->server->game.lms_song);\n"
          "                RAssert(packet_send(v->peer, &packet, true));\n"
          "        }")
    patch(repo, "betterserver-oss/include/Packet.h",
          "        /* v5.0 — LMS «El Show Fuerte» (Sonic ultimo superviviente):\n"
          "           SERVER_GAME_LMS (sin payload): el server lo emite UNA VEZ al\n"
          "           detectar que el unico superviviente vivo es Sonic; sube el\n"
          "           reloj de la partida a LMS_TIME_SEC (282 s = duracion de\n"
          "           Undefeatable) y los clientes entran en el show (musica,\n"
          "           banner, cura a 100 y pasivas de Sonic). Se re-envia en\n"
          "           game_state_join para reconexiones. Mismo orden que el enum\n"
          "           del cliente (net_packets.gml); anadido AL FINAL en los DOS\n"
          "           lados. */",
          "        /* v5.1 — LMS «El Show Fuerte» (Sonic ultimo superviviente):\n"
          "           SERVER_GAME_LMS (payload u8 song = indice de la cancion que\n"
          "           el server eligio al azar): el server lo emite UNA VEZ al\n"
          "           detectar que el unico superviviente vivo es Sonic; sube el\n"
          "           reloj a la duracion de LA CANCION ELEGIDA (LMS_SONG_SEC) y\n"
          "           los clientes entran en el show (musica, banner, cura a 100\n"
          "           y pasivas de Sonic). Se re-envia en game_state_join para\n"
          "           reconexiones. Mismo orden que el enum del cliente\n"
          "           (net_packets.gml); anadido AL FINAL en los DOS lados. */")

    # --- scr_lms.gml ---
    patch(repo, "scripts/scr_lms/scr_lms.gml",
          "#macro LMS_SPIN_STUN true      // la bola (spindash/dropdash rodando) aturde al bando EXE por contacto\n",
          "#macro LMS_SPIN_STUN true      // la bola (spindash/dropdash rodando) aturde al bando EXE por contacto\n"
          "#macro LMS_HP 100              // v5.1: vida a la que Sonic sube al arrancar el show\n"
          "\n"
          "// v5.1 — MULTI-CANCION: lista de canciones del show. La #1 es la\n"
          "// original (mus_undefeatable); el Suite TD2D anade aqui mus_lms_2..N\n"
          "// y sus duraciones en el server (LMS_SONG_SEC). El server elige UNA al\n"
          "// azar y manda su indice en SERVER_GAME_LMS (u8); buffer_read_s devuel\n"
          "// ve -1 con un server viejo sin payload y cae en la #1.\n"
          "global.lmsSongs = [mus_undefeatable];\n"
          "\n"
          "function scr_lms_play_song(idx)\n"
          "{\n"
          "        var _songs = global.lmsSongs;\n"
          "        if(idx >= 0 && idx < array_length(_songs))\n"
          "                scr_play_music(_songs[idx]);\n"
          "        else\n"
          "                scr_play_music(mus_undefeatable);\n"
          "}\n")

    # --- net_state_game.gml ---
    patch(repo, "scripts/net_state_game/net_state_game.gml",
          "                        global.lmsActive = true;\n"
          "                        \n"
          "                        scr_play_music(mus_undefeatable);\n"
          "                        instance_create_depth(0, 0, 0, obj_lms_banner);",
          "                        global.lmsActive = true;\n"
          "                        \n"
          "                        // v5.1: el server eligio la cancion y manda su indice\n"
          "                        // (server viejo sin payload => -1 => cae en la #1)\n"
          "                        var _lmsSong = buffer_read_s(rbuff, buffer_u8);\n"
          "                        \n"
          "                        scr_lms_play_song(_lmsSong);\n"
          "                        instance_create_depth(0, 0, 0, obj_lms_banner);")
    patch(repo, "scripts/net_state_game/net_state_game.gml",
          "                        if(global.character == CHARACTER_SONIC && instance_exists(global.player) && !global.player.isDead)\n"
          "                        {\n"
          "                                global.player.hp = 100;",
          "                        if(global.character == CHARACTER_SONIC && instance_exists(global.player) && !global.player.isDead)\n"
          "                        {\n"
          "                                global.player.hp = LMS_HP;")


# ---------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default="/home/z/my-project/repo")
    args = ap.parse_args()
    repo = args.repo
    print("=== apply_v5_1.py sobre %s ===\n" % repo)

    print("[A] sprites copia (14): Sally Canon <- Sally · Vanilla <- Cream")
    for c in COPIES:
        make_copy(repo, c)
    patch_registry(repo)

    print("\n[B] scr_characters.gml — resolvedores v5.1")
    patch_scr_characters(repo)

    print("\n[C] redirecciones GML")
    patch_lobby_create(repo)
    patch_lobby_draw(repo)
    patch_lobby_icon(repo)
    patch_charselect(repo)
    patch_menu_waiting(repo)
    patch_level_draw(repo)
    patch_level_tab(repo)
    patch_results(repo)

    print("\n[D] LMS multi-canción")
    patch_lms(repo)

    print("\n=== RESUMEN: %d OK · %d FAIL ===" % (len(APPLIED), len(FAILED)))
    if FAILED:
        print("FALLOS (revisa anclas):")
        for f in FAILED:
            print("  !", f)
        sys.exit(1)


if __name__ == "__main__":
    main()
