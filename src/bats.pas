{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit Bats;

interface

uses
  r8str,
  r8dos,
  color,
  crt;

Procedure DoBeforePack;
Procedure DoBeforeUnPack;
Procedure DoAfterPack;
Procedure DoAfterUnPack;
Procedure DoAfterScan;

implementation

Uses
  global;

Procedure DoBeforePack;
Var
  Name,
  Params : string;
  Errorlevel : word;
begin
  If BeforePack='' then exit;
  TextColor(colOperation);
  WriteLn('Executing BeforePack...');
  LogFile^.SendStr('Executing BeforePack...',#32);

  TextColor(colLongline);
  WriteLn(constLongLine);
  TextColor(7);

  strSplitWords(BeforePack,Name,Params);
  LogFile^.SendStr('Command line: '+Name+#32+Params,'@');
  Errorlevel:=dosExec(Name,Params);

  TextColor(colLongline);
  WriteLn(constLongLine);

  TextColor(colError);
  WriteLn('Exit code: ',ErrorLevel);
  TextColor(7);
  WriteLn(' ');
end;

Procedure DoAfterPack;
Var
  Name,
  Params : string;
  Errorlevel : word;
begin
  If AfterPack='' then exit;
  TextColor(colOperation);
  WriteLn('Executing AfterPack...');
  LogFile^.SendStr('Executing AfterPack...',#32);

  TextColor(colLongline);
  WriteLn(constLongLine);
  TextColor(7);

  strSplitWords(AfterPack,Name,Params);
  LogFile^.SendStr('Command line: '+Name+#32+Params,'@');
  Errorlevel:=dosExec(Name,Params);

  TextColor(colLongline);
  WriteLn(constLongLine);

  TextColor(colError);
  WriteLn('Exit code: ',ErrorLevel);
  LogFile^.SendStr('Exit code: '+strIntToStr(ErrorLevel),'#');
  TextColor(7);
  WriteLn(' ');
end;

Procedure DoBeforeUnPack;
Var
  Name,
  Params : string;
  Errorlevel : word;
begin
  If BeforeUnPack='' then exit;
  TextColor(colOperation);
  WriteLn('Executing BeforeUnPack...');
  LogFile^.SendStr('Executing BeforeUnPack...',#32);

  TextColor(colLongline);
  WriteLn(constLongLine);
  TextColor(7);

  strSplitWords(BeforeUnPack,Name,Params);
  LogFile^.SendStr('Command line: '+Name+#32+Params,'@');
  Errorlevel:=dosExec(Name,Params);

  TextColor(colLongline);
  WriteLn(constLongLine);

  TextColor(colError);
  WriteLn('Exit code: ',ErrorLevel);
  LogFile^.SendStr('Exit code: '+strIntToStr(ErrorLevel),'#');
  TextColor(7);
  WriteLn(' ');
end;

Procedure DoAfterUnPack;
Var
  Name,
  Params : string;
  Errorlevel : word;
begin
  If AfterUnPack='' then exit;
  TextColor(colOperation);
  WriteLn('Executing AfterUnPack...');
  LogFile^.SendStr('Executing AfterUnPack...',#32);

  TextColor(colLongline);
  WriteLn(constLongLine);
  TextColor(7);

  strSplitWords(AfterUnPack,Name,Params);
  LogFile^.SendStr('Command line: '+Name+#32+Params,'@');
  Errorlevel:=dosExec(Name,Params);

  TextColor(colLongline);
  WriteLn(constLongLine);

  TextColor(colError);
  WriteLn('Exit code: ',ErrorLevel);
  LogFile^.SendStr('Exit code: '+strIntToStr(ErrorLevel),'#');
  TextColor(7);
  WriteLn(' ');
end;

Procedure DoAfterScan;
Var
  Name,
  Params : string;
  Errorlevel : word;
begin
  If AfterScan='' then exit;
  TextColor(colOperation);
  WriteLn('Executing AfterScan...');
  LogFile^.SendStr('Executing AfterScan...',#32);

  TextColor(colLongline);
  WriteLn(constLongLine);
  TextColor(7);

  strSplitWords(AfterScan,Name,Params);
  LogFile^.SendStr('Command line: '+Name+#32+Params,'@');
  Errorlevel:=dosExec(Name,Params);

  TextColor(colLongline);
  WriteLn(constLongLine);

  TextColor(colError);
  WriteLn('Exit code: ',ErrorLevel);
  LogFile^.SendStr('Exit code: '+strIntToStr(ErrorLevel),'#');
  TextColor(7);
  WriteLn(' ');
end;

end.