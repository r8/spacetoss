{
 LogFile stuff.
 (c) by Sergey Storchay (2:462/117@fidonet), 2000-2001.
}
Unit r8Log;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

Interface
Uses
  dos,
  objects,

  r8objs,
  r8dtm, r8dos;

const
  logOk               = $00000000;
  logCantOpenOrCreate = $00000001;


Type

TLogFile = object(TObject)
  Status : longint;

  ProgramName : PString;

  LogFileName : PString;
  LogMode : PString;
  Opened : boolean;

  BuffSize : word;

  Constructor Init(const AProgramName : string);
  Destructor Done;virtual;

  Procedure SetLogFilename(const AFileName : string);
  Procedure SetLogMode(const ALogMode : string);

  Procedure Open;
  Procedure SendStr(const S:string;const C:char);

  Function ExplainStatus(const AStatus:longint):string;
private
  F : PBufStream;

  LogDateTime : TDateTime;
  Function OpenOrCreate(const S:string):boolean;
  Procedure PutHeader;
end;
PlogFile = ^TLogFile;

Implementation
Uses
  r8Const;

Constructor TLogFile.Init(const AProgramName : string);
begin
  inherited Init;

  ProgramName:=NewStr(AProgramName);
  LogMode:=nil;
  LogFileName:=nil;
  F:=nil;

  Status:=logOk;
  BuffSize:=0;

  Opened:=False;
end;

Destructor TLogFile.Done;
Begin
  If F<>nil then
    begin
      If F^.Status=stOk then objStreamWrite(F, #13#10);
      objDispose(F);
    end;

  DisposeStr(LogFileName);
  DisposeStr(ProgramName);
  DisposeStr(LogMode);

  inherited Done;
End;

Function TLogFile.OpenOrCreate(const S:string):boolean;
Begin
  OpenOrCreate:=True;
  If BuffSize=0 then BuffSize:=2;

  If not dosFileExists(S) then
    begin

      F:=New(PBufStream,Init(S,stCreate,BuffSize));

      If F^.Status<>stOk then
        begin
          OpenOrCreate:=False;
          Exit;
        end;

      objStreamWrite(F,#13#10);

      objDispose(F);
    End;

    F:=New(PBufStream,Init(S,fmOpen or fmWrite or fmDenyWrite,BuffSize));

    If F^.Status<>0 Then
      Begin
        OpenOrCreate:=False;
        Exit;
      End;

    F^.Seek(F^.GetSize);
End;

Procedure TLogFile.PutHeader;
Begin
  objStreamWrite(F,'----------  ');
  dtmGetDateTime(LogDateTime);
  objStreamWrite(F,dtmDayOfWeek[LogDateTime.DayOfWeek]+#32);
  objStreamWrite(F,dtmDate2String(LogDateTime,#32,True,True));
  objStreamWrite(F,', '+ProgramName^+' ['+cstrOsId+']');
  If LogMode<>nil Then objStreamWrite(F,'; '+LogMode^);
  objStreamWrite(F,#13#10);
End;

Procedure TLogFile.SetLogFilename(const AFileName : string);
begin
  DisposeStr(LogFileName);
  LogFileName:=NewStr(AFileName);
end;

Procedure TLogFile.SetLogMode(const ALogMode : string);
begin
  LogMode:=NewStr(ALogMode);
end;

Procedure TLogFile.Open;
Begin
  Status:=logCantOpenOrCreate;

  If (LogFileName=nil) or (ProgramName=nil) then exit;
  If not OpenOrCreate(LogFileName^) then exit;

  PutHeader;
  Opened:=True;
  Status:=logOk;
End;

Procedure TLogFile.SendStr(const S:string;const C:char);
Var
  C1:char;
Begin
  If F=nil then exit;

  c1:=c;
  if c1='' then c1:=#32;
  dtmGetDateTime(LogDateTime);
  objStreamWrite(F,c1+#32);
  objStreamWrite(F,dtmTime2String(LogDateTime,':',True,False));
  objStreamWrite(F,#32+#32+S+#13#10);
End;

Function TLogFile.ExplainStatus(const AStatus:longint):string;
begin
  Case AStatus of
    logCantOpenOrCreate : ExplainStatus:='Cannot create log file';
  end;
end;

End.
