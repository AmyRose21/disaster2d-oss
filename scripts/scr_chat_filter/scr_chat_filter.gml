global.chatFilter = [
        "nigger",
        "nigga",
        "niggas",
        "nigg",
        "faggot",
        "tranny",
        "экзюшка",
        "эгусик",
        "эггусик",
        "эмичка",
        "кримка",
        "салька",
        "наксик",
        "хохол",
        "москаль"
];

// Censura una PALABRA: si al quitarle separadores (. - _ * etc.) contiene
// algun termino prohibido, se enmascara entera (n.i.g.g.a -> ****). Sin
// esto el filtro directo se bypasseaba separando las letras.
function scr_chat_censor_word(word)
{
        var _clean = string_lower(word);
        
        var _seps = [".", "-", "_", "*", "/", "|", "@", "&", "`", "~", "#", "$", "%", ",", ";", ":", "(", ")", "'", "\"", "+", "=", "?", "!", "¿", "¡", "<", ">", "[", "]", "{", "}", "^"];
        
        for(var s = 0; s < array_length(_seps); s++)
                _clean = string_replace_all(_clean, _seps[s], "");
        
        for(var i = 0; i < array_length(global.chatFilter); i++)
        {
                if(string_pos(global.chatFilter[i], _clean) > 0)
                        return string_repeat("*", string_length(word));
        }
        
        return word;
}

function scr_chat_filter(str)
{
        // var (antes era una global implicita: podia colar estado entre
        // llamadas — fix v1 IN-GAME CHAT)
        var finalStr = str;
        
        // pase directo: terminos prohibidos tal cual (igual que siempre)
        for(var i = 0; i < array_length(global.chatFilter); i++)
                finalStr = string_replace_all(finalStr, global.chatFilter[i], string_repeat("*", string_length(global.chatFilter[i])));
        
        // anti-bypass: re-examinar palabra por palabra sin separadores
        var _res = "";
        var _word = "";
        var _len = string_length(finalStr);
        
        for(var w = 1; w <= _len; w++)
        {
                var _ch = string_char_at(finalStr, w);
                
                if(_ch == " ")
                {
                        _res += scr_chat_censor_word(_word) + " ";
                        _word = "";
                }
                else
                        _word += _ch;
        }
        
        _res += scr_chat_censor_word(_word);
        finalStr = _res;
        
        finalStr = string_replace_all(finalStr, "\r", "");
        finalStr = string_replace_all(finalStr, "\t", "");
        finalStr = string_replace_all(finalStr, "\n", "");
        
        return finalStr;
}
