{
  Script MusNews for SpaceToss.
  Copyright(c)Sergey Storchay, 2002.
}
Program MusNews;

  Function hookTossToBase(msg:longint):boolean;
  var
    s : string;
    Area : string;
    newmsg : longint;
  begin
    Area:=UpperCase(spcMsgGetArea(msg));

    If (Area='RINET.CITYCAT.CULTURE.MUSIC.NEWS.EURONEWS')
     or (Area='RINET.CITYCAT.CULTURE.MUSIC.ROCK.METALLICA')
      or (Area='RINET.CITYCAT.MUSIC.METAL')
        begin
          newmsg:=spcMsgCopyToArea(msg,'LVIV.MUSIC');

          spcLogWriteLn('³   MUSNEWS: '+Area+
            '  LVIV.MUSIC';
          spcMsgSetTearLine(newmsg,'SpaceToss 1.0.11.2485');
        end;
  end;

begin
end.