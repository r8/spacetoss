{
 Counter Stuff for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
}
Unit Count;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  r8dtm,
  r8str,

  objects;

type

  TCounter = object(TObject)
    Msgs : longint;
    ProcessTime : real;
    Bytes : longint;

    Constructor Init;
    Destructor Done;virtual;

    Procedure StartCount;
    Procedure EndCount;
    Procedure AddMsg;
    Procedure AddBytes(const L:Longint);
    Function GetSeconds:string;
    Function GetMsgs:string;
    Function GetKBytes:string;
    Function GetMsgSec:string;
    Function GetKBytesSec:string;
  end;

  PCounter = ^TCounter;

implementation

Constructor TCounter.Init;
begin
  inherited Init;
  Msgs:=0;
  ProcessTime:=0;
  Bytes:=0;
end;

Destructor TCounter.Done;
begin
  inherited Done;
end;

Procedure TCounter.StartCount;
begin
  ProcessTime:=dtmStartTimer;
end;

Procedure TCounter.EndCount;
begin
  ProcessTime:=dtmStopTimer(ProcessTime);
end;

Function TCounter.GetSeconds:string;
begin
  GetSeconds:=strRealToStr(ProcessTime);
end;

Procedure TCounter.AddMsg;
begin
  Inc(Msgs);
end;

Function TCounter.GetMsgs:string;
begin
  GetMsgs:=strIntToStr(Msgs);
end;

Procedure TCounter.AddBytes(const L:Longint);
begin
  Inc(Bytes,L);
end;

Function TCounter.GetKBytes:string;
Var
  R:Real;
begin
  R:=Bytes / 1024;
  GetKBytes:=strRealToStr(R);
end;

Function TCounter.GetMsgSec:string;
Var
  R:Real;
begin
  R:=0;
  If ProcessTime<>0 then R:=Msgs / ProcessTime;
  GetMsgSec:=strRealToStr(R);
end;

Function TCounter.GetKBytesSec:string;
Var
  R:Real;
begin
  R:=0;
  If ProcessTime<>0 then R:=Bytes / ProcessTime / 1024;
  GetKBytesSec:=strRealToStr(R);
end;

end.