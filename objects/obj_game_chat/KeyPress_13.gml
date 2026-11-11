// Enter: abre el chat o envia lo escrito (identico al lobby).
// En Android, el "Done" del teclado virtual dispara este mismo evento.
if(chatMode)
        chatClose(true);
else
        chatOpen();
