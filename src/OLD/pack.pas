{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit Pack;

interface

Uses
  crt,
  color,
  areas,
  r8mbe,
  r8objs,
  objects,
  r8dtm,
  r8dos,
  r8mail,
  r8ftn,
  r8str,
  prareas,
  global;

Procedure PackBases;

implementation

Procedure PackBase(Area:PArea);
Var
  i:integer;
  NewEchoBase : PMessageBase;
  NewEchoName : string;
  Path:string;

  Before, After : longint;
begin
  Path:=Area^.Echotype.Path;

  If not OpenOrCreateMessageBase(Path,EchoBase) then exit;

  Before:=EchoBase^.GetSize;

  ProcessStart(Area^.Name^,EchoBase^.GetCount);

  If not EchoBase^.PackIsNeeded then
    begin
      EchoBase^.CloseBase;
      objDispose(EchoBase);
      exit;
    end;

  NewEchoName:=dosGetPath(Path)+'\tmp!!tmp';

  If not OpenOrCreateMessageBase(NewEchoName,NewEchoBase) then exit;

  For i:=0 to EchoBase^.GetCount-1 do
    begin
      EchoBase^.Seek(i);
      NewEchoBase^.PutRawMessage(EchoBase^.GetRawMessage);
      ProcessInc;
    end;

  After:=NewEchoBase^.GetSize;

  EchoBase^.CloseBase;
  NewEchoBase^.CloseBase;
  objDispose(EchoBase);
  objDispose(NewEchoBase);

  KillMessageBase(Path);

  RenameMessageBase(NewEchoName,dosGetFileName(Path));
  If Before>After
         then ProcessStop(strIntToStr(Before)+' ออ '+strIntToStr(After));
end;

Procedure PackBases;
var
  i:longint;
  TempArea : PArea;
begin
  TextColor(colOperation);
  WriteLn('Packing echobases...');
  TextColor(colLongline);
  WriteLn(constLongLine);

  For i:=0 to AreaBase^.Areas^.Count-1 Do
    begin
      TempArea:=AreaBase^.Areas^.At(i);
      If (TempArea^.Echotype.Storage<>etPassthrough)
        and (TempArea^.Echotype.Storage<>etHudson)
      then
        begin
           PackBase(TempArea);
        end;
    end;

{  PackBase(DupeMailPath,Before,After);}
{  PackBase(BadMailPath,Before,After);}
end;

end.