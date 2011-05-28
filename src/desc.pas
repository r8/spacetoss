{
 Descer Stuff for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2002.
}
Unit Desc;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  color,
  lng,
  areas,
  elist,

  r8dtm,
  r8ftn,
  r8mail,
  r8str,
  r8alst,

  regexp,

  crt,
  r8objs,
  objects;

Type

 TDescer = object(TObject)
   Arealist   : TArealistRec;

   Constructor Init;
   Destructor  Done; virtual;

   Procedure Desc;
 end;
 PDescer = ^TDescer;

implementation

Uses
  global;

Constructor TDescer.Init;
begin
  inherited Init;

  AreaList.List:=nil;
end;

Destructor  TDescer.Done;
begin
  objDispose(AreaList.List);

  inherited Done;
end;

Procedure TDescer.Desc;
Var
  sTemp : string;

  Procedure ProcessArea(P:pointer);far;
  Var
    TempArea : PArea absolute P;
    sTemp : string;
  begin
    sTemp:=AreaList.List^.GetDesc(TempArea^.Name^);
    If sTemp<>'' then
      begin
        AssignStr(TempArea^.Desc,sTemp);
        AreaBase^.Modified:=True;
     end;
  end;
  Procedure ProcessParameter(P:pointer);far;
  Var
    S : PString absolute P;
    S2 : String;
    T  : text;

    Procedure CheckWildCard(P:pointer);far;
    Var
      Area : PArea absolute P;
    begin
      If GrepCheck(S^,Area^.Name^,False) then ProcessArea(Area);
    end;
  begin
    AreaBase^.Areas^.ForEach(@CheckWildCard);
  end;
begin
  If ParamString^.Parameters^.Count<2
     then ErrorOut(LngFile^.GetString(LongInt(lngIncorrectNumberofParams)));

  sTemp:=PString(ParamString^.Parameters^.At(0))^+#32+
     PString(ParamString^.Parameters^.At(1))^;
  ParserArealist(sTemp,Arealist);

  If (AreaList.ListType=ltNone) or (AreaList.ListType=ltUnknown) then
    begin
      LngFile^.AddVar('DESC');
      LngFile^.AddVar(AreaList.Path);
      sTemp:=LngFile^.GetString(LongInt(lngCantOpenArealist));
      LogFile^.SendStr(sTemp,'!');
      ErrorOut(sTemp);
    end;

  ReadEcholist(AreaList,'DESC');

  If (AreaList.ListType=ltNone) or (AreaList.ListType=ltUnknown)
    then ErrorOut(sTemp);

  TextColor(7);

  Writeln(LngFile^.GetString(LongInt(lngDescriptingBases)));
  WriteLn;
  LogFile^.SendStr(LngFile^.GetString(LongInt(lngDescriptingBases)),#32);

  ParamString^.Parameters^.AtFree(0);
  ParamString^.Parameters^.AtFree(0);

  If ParamString^.Parameters^.Count>0 then
    ParamString^.Parameters^.ForEach(@ProcessParameter)
   else
    AreaBase^.Areas^.ForEach(@ProcessArea);

  LogFile^.SendStr(LngFile^.GetString(LongInt(lngDone)),#32);
  TextColor(7);
  WriteLn;
end;

end.
