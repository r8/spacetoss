{
 Purger Stuff for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2002.
}
Unit Purge;

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
  prbar,
  areas,


  r8dtm,
  r8ftn,
  r8mail,
  r8str,

  regexp,

  crt,
  objects;

Type

 TPurger = object(TObject)
   CurrentDate : longint;

   Constructor Init;
   Destructor  Done; virtual;

   Procedure Purge;

   Procedure FailedToOpenBase(const BaseName:string);
 end;
 PPurger = ^TPurger;

implementation

Uses
  global;

Constructor TPurger.Init;
begin
  inherited Init;
end;

Destructor  TPurger.Done;
begin
  inherited Done;
end;

Procedure TPurger.Purge;
Var
  UnixDate : longint;
  DateTime : TDateTime;

  PurgeMsgs : longint;
  PurgeDays     : longint;

  Procedure ProcessArea(P:pointer);far;
  Var
    TempArea : PArea absolute P;
    TempBase : PMessageBase;

    Purged : longint;
    sTemp : string;
    NumbOfMessages : longint;
    Current : longint;

      Procedure PrepareLastread(Lastread : PLastRead);far;
      begin
        If LastRead^.LastReadMsg>=NumbOfMessages then
          begin
            LastRead^.LastReadMsg:=NumbOfMessages;
            LastRead^.HighReadMsg:=LastRead^.LastReadMsg;
          end;
      end;
      Procedure ProcessLastread(Lastread : PLastRead);far;
      begin
        If LastRead^.LastReadMsg>=Current then
          begin
            Dec(LastRead^.LastReadMsg);
            If LastRead^.LastReadMsg<0 then LastRead^.LastReadMsg:=0;

            LastRead^.HighReadMsg:=LastRead^.LastReadMsg;
          end;
      end;
  begin
    If TempArea^.Echotype.Storage=etPassthrough then exit;

    TempBase:=EchoQueue^.OpenBase(TempArea);
    If TempBase=nil then
      begin
        FailedToOpenBase(TempArea^.Name^);
        MessageBasesEngine^.Reset;
        exit;
      end;

    NumbOfMessages:=TempBase^.GetCount;
    TempBase^.ReadLastReads;
    TempBase^.LastReads^.ForEach(@PrepareLastRead);
    TempBase^.WriteLastReads;

    Purged:=0;

    ProcessStart(TempArea^.Name^,NumbOfMessages);

    PurgeDays:=TempArea^.PurgeDays;
    PurgeMsgs:=TempArea^.PurgeMsgs;

    If ParamString^.CheckKey('D')
        then PurgeDays:=strStrToInt(ParamString^.GetKey('D'));
    If ParamString^.CheckKey('M')
        then PurgeMsgs:=strStrToInt(ParamString^.GetKey('M'));

    If (PurgeDays=0) and (PurgeMsgs=0) then exit;
    If TempBase^.GetCount=0 then exit;

    TempBase^.Seek(0);
    TempBase^.SeekNext;
    Current:=0;

    While TempBase^.Status=mlOk do
      begin
        ProcessInc;
        Inc(Current);
        TempBase^.OpenHeader;

        If (PurgeMsgs<>0) and (TempBase^.GetCount>PurgeMsgs) then
          begin
            TempBase^.CloseMessage;
            TempBase^.KillMessage;
            TempBase^.SeekNext;
            Inc(Purged);
            TempBase^.LastReads^.ForEach(@ProcessLastRead);
            continue;
          end;

        TempBase^.GetDateArrived(DateTime);
        UnixDate:=dtmDateToUnix(DateTime);
        UnixDate:=CurrentDate-UnixDate;

        If (PurgeDays<>0) and ((UnixDate div 86400)>PurgeDays) then
          begin
            TempBase^.CloseMessage;
            TempBase^.KillMessage;
            TempBase^.SeekNext;
            Inc(Purged);
            TempBase^.LastReads^.ForEach(@ProcessLastRead);
            continue;
          end;

      TempBase^.CloseMessage;
      TempBase^.SeekNext;
    end;

    LngFile^.AddVar(strIntToStr(Purged));
    sTemp:=LngFile^.GetString(LongInt(lngNumbOfPurged));

    If Purged<>0 then
      begin
        TempBase^.WriteLastReads;
        LogFile^.SendStr(TempArea^.Name^+': '+sTemp,'@');
      end;

    ProcessStop(sTemp);
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
  TextColor(7);

  Writeln(LngFile^.GetString(LongInt(lngPurgingBases)));
  WriteLn;
  LogFile^.SendStr(LngFile^.GetString(LongInt(lngPurgingBases)),#32);

  CurrentDate:=dtmGetDateTimeUnix;

  If ParamString^.Parameters^.Count>0 then
    ParamString^.Parameters^.ForEach(@ProcessParameter)
   else
    AreaBase^.Areas^.ForEach(@ProcessArea);

  LogFile^.SendStr(LngFile^.GetString(LongInt(lngDone)),#32);
  TextColor(7);
  WriteLn;
end;

Procedure TPurger.FailedToOpenBase(const BaseName:string);
var
  sTemp : string;
begin
  LngFile^.AddVar(BaseName);
  sTemp:=LngFile^.GetString(LongInt(lngFailedToOpenBase));
  GotoXY(1,WhereY);
  TextColor(7);
  WriteLn(strPadR(sTemp,#32,79));
  LogFile^.SendStr(sTemp,'!');
end;

end.
