{
 BasePacker Stuff For SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2002.
}
Unit Pack;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  prbar,

  objects;

type

  TPacker = object(TObject)
    Constructor Init;
    Destructor Done;virtual;

    Procedure Pack;
    Procedure FailedToOpenBase(const BaseName:string);
  end;
  PPacker = ^TPacker;

implementation

Uses
  crt,

  r8str,
  r8mail,
  r8ftn,
  r8dos,
  r8abs,
  r8objs,
  r8dtm,
  r8sqh,
  r8msg,

  regexp,

  areas,
  lng,
  global;

Constructor TPacker.Init;
begin
  inherited Init;

end;

Destructor TPacker.Done;
begin

  inherited Done;
end;

Procedure TPacker.Pack;
  Procedure ProcessArea(P:pointer);far;
  Var
    TempArea : PArea absolute P;
    TempBase : PMessageBase;

    NewEchoBase : PMessageBase;
    NewEchoName : string;
    AbsMessage : PAbsMessage;

    Before, After : longint;

    DateArrived : TDateTime;
    TimesRead : longint;

    TempLastReads : pointer;
    HighWater : longint;
  begin
    If TempArea^.Echotype.Storage=etPassthrough then exit;

    TempBase:=EchoQueue^.OpenBase(TempArea);
    If TempBase=nil then
      begin
        FailedToOpenBase(TempArea^.Name^);
        MessageBasesEngine^.Reset;
        exit;
      end;

    ProcessStart(TempArea^.Name^,TempBase^.GetCount);

    If not TempBase^.PackIsNeeded then exit;

    TempBase^.ReadLastReads;
    TempLastReads:=TempBase^.LastReads;

    If TempArea^.Echotype.Storage=etMsg then
      begin
        PMsgBase(TempBase)^.Renumber;
        TempBase^.WriteLastReads;
        TempBase^.Close;
        exit;
      end;

    Before:=TempBase^.GetSize;

    NewEchoName:=dosGetPath(TempArea^.EchoType.Path)+'\tmp!!tmp';

    NewEchoBase:=MessageBasesEngine^.OpenOrCreateBase(NewEchoName);
    If NewEchoBase=nil then exit;

    If TempArea^.Echotype.Storage=etSquish
      then HighWater:=TempBase^.SearchForIndex(PSqhBase(TempBase)^.SqhHeader.Highwater);

    TempBase^.Seek(0);
    TempBase^.SeekNext;
    While TempBase^.Status=mlOk do
      begin
        ProcessInc;

        TempBase^.OpenMessage;
        TempBase^.GetDateArrived(DateArrived);
        TimesRead:=TempBase^.GetTimesRead;
        AbsMessage:=TempBase^.GetAbsMessage;

        NewEchobase^.CreateMessage(False);
        NewEchoBase^.SetAbsMessage(AbsMessage);
        NewEchoBase^.SetDateArrived(DateArrived);
        NewEchoBase^.SetTimesRead(TimesRead);
        NewEchoBase^.WriteMessage;

        objDispose(AbsMessage);

        NewEchoBase^.CloseMessage;
        TempBase^.CloseMessage;

        TempBase^.SeekNext;
      end;

    After:=NewEchoBase^.GetSize;

    TempBase^.LastReads:=nil;
    TempBase^.Close;

    If TempArea^.Echotype.Storage=etSquish then
      begin
        if HighWater=-1 then HighWater:=0;
        PSqhBase(NewEchoBase)^.SetHighwater(HighWater);
      end;

    NewEchoBase^.LastReads:=TempLastReads;
    NewEchoBase^.WriteLastReads;
    NewEchoBase^.Close;
    MessageBasesEngine^.DisposeBase(TempBase);
    MessageBasesEngine^.DisposeBase(NewEchoBase);
    TempArea^.MessageBase:=nil;

    MessageBasesEngine^.KillMessageBase(TempArea^.EchoType.Path);
    MessageBasesEngine^.RenameMessageBase(NewEchoName,dosGetFileName(TempArea^.EchoType.Path));

    If Before>After then
      begin
        ProcessStop(strIntToStr(Before)+' ออ '+strIntToStr(After));
        LogFile^.SendStr(TempArea^.Name^+': '+strIntToStr(Before)+' ออ '+strIntToStr(After),'@');
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
  TextColor(7);

  Writeln(LngFile^.GetString(LongInt(lngPackingBases)));
  WriteLn;
  LogFile^.SendStr(LngFile^.GetString(LongInt(lngPackingBases)),#32);

  If ParamString^.Parameters^.Count>0 then
    ParamString^.Parameters^.ForEach(@ProcessParameter)
   else
    AreaBase^.Areas^.ForEach(@ProcessArea);

  LogFile^.SendStr(LngFile^.GetString(LongInt(lngDone)),#32);
  TextColor(7);
  WriteLn;
end;

Procedure TPacker.FailedToOpenBase(const BaseName:string);
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

begin
end.
