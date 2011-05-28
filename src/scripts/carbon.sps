{
  Carbon Copy for SpaceToss.
  Copyright(c)Sergey Storchay, 2002.
}

Program Carbon;

  Function hookTossToBase(msg:longint):boolean;
  var
    s : string;
    Area : string;
    carbon : longint;
  begin
    Area:=UpperCase(spcMsgGetArea(msg));

    If (Area<>'RSB.CARBON') and
      (UpperCase(spcMsgGetToName(msg))='SERGEY STORCHAY') then
        begin
          carbon:=spcMsgCopyToArea(msg,'RSB.CARBON');
          spcMsgInsertLine(carbon,' * Carbon copied from area '+Area+#13);
          spcMsgSetKludge(carbon,'AREA:',Area);

          spcLogWriteLn('³   CARBON: '+spcMsgGetFromName(msg)+
            '  '+spcMsgGetToName(msg));
        end;
  end;

begin
end.