{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit Purge;

interface

Uses
  crt,
  color,
  areas,
  r8mbe,
  r8objs,
  r8ftn,
  objects,
  r8dtm,
  r8mail,
  r8str,
  prareas,
  global;

Procedure PurgeBases;

implementation

Var
  CurrentDate : longint;

Procedure PurgeBase(Area:PArea);
Var
  i:longint;
  Path:string;
  Purged : longint;
  DateTime : TDateTime;
  UnixDate : longint;
  Count:longint;
  LR:longint;
begin
  Path:=Area^.Echotype.Path;

  If not OpenOrCreateMessageBase(Path,EchoBase) then exit;

  Purged:=0;

  ProcessStart(Area^.Name^,EchoBase^.GetCount);

  If (Area^.PurgeDays=0) and (Area^.PurgeMsgs=0) then
    begin
      EchoBase^.CloseBase;
      objDispose(EchoBase);
      exit;
    end;

  LR:=EchoBase^.GetLastRead;
  WriteLn(LR);

  EchoBase^.Seek(0);
  For i:=0 to EchoBase^.GetCount-1 do
    begin
      ProcessInc;
      EchoBase^.OpenMsg;

      If (Area^.PurgeMsgs<>0) and (EchoBase^.GetCount>Area^.PurgeMsgs)
            then
              begin
                EchoBase^.CloseMessage;
                EchoBase^.KillMessage;
                EchoBase^.SeekNext;
                Inc(Purged);
                continue;
              end;

      EchoBase^.GetDateArrived(DateTime);
      UnixDate:=dtmDateToUnix(DateTime);
      UnixDate:=CurrentDate-UnixDate;

      If (Area^.PurgeDays<>0) and ((UnixDate div 86400)>Area^.PurgeDays)
            then
              begin
                EchoBase^.CloseMessage;
                EchoBase^.KillMessage;
                EchoBase^.SeekNext;
                Inc(Purged);
                continue;
              end;

      EchoBase^.CloseMessage;
      EchoBase^.SeekNext;
    end;

  If Purged<>0 then EchoBase^.SetLastRead(LR-Purged);

  EchoBase^.CloseBase;
  objDispose(EchoBase);

  ProcessStop(strIntToStr(Purged)+' msgs purged...');
end;

Procedure PurgeBases;
var
  i:longint;
  TempArea : PArea;
  DateTime : TDateTime;
begin
  TextColor(colOperation);
  WriteLn('Purging echobases...');
  TextColor(colLongline);
  WriteLn(constLongLine);

  dtmGetDateTime(DateTime);
  CurrentDate:=dtmDateToUnix(DateTime);

  For i:=0 to AreaBase^.Areas^.Count-1 Do
    begin
      TempArea:=AreaBase^.Areas^.At(i);
      If (TempArea^.Echotype.Storage<>etPassthrough)
      then
        begin
           PurgeBase(TempArea);
        end;
    end;
end;

end.