Program SpaceRes;
Uses
  crt,
  r8dos,
  r8objs,
  r8lng,
  r8str,
  r8const;

{$i ..\build.inc}

Var
  LngFile : PLngFile;
  T:text;

Procedure Intro;
begin
  TextColor(14);
  WriteLn('SpaceRes v1.0'+'/'+cstrOsId+' for SpaceToss');
  TextColor(15);
  WriteLn('Copyright (C) 2000-01 by Sergey Storchay (2:462/117) ù All rights reserved.');
  TextColor(7);
  WriteLn;
end;

Procedure ErrorOut(s:string);
begin
  TextColor(4);
  TextBackGround(0);
  WriteLn;
  WriteLn(S,'!');
  TextColor(7);
  WriteLn(' ');
  Halt(255);
end;

Procedure Compile;
Var
  sTemp : string;
begin
  LngFile:=New(PLngFile,Init('spctoss.lng','SPACETOSS',strStrToInt(sBuild)));

  Assign(T,ParamStr(1));
  Reset(T);

  While not Eof(T) do
    begin
      ReadLn(T,sTemp);
      Write('.');
      LngFile^.AddLngItem(sTemp);
    end;

  Close(T);

  LngFile^.SaveFile;
  objDispose(LngFile);
  WriteLn('.');
end;

begin

{  HomeDir:='C:\BP\SOURCES\FTN\spctoss\lng';
  WorkDir:='C:\BP\SOURCES\FTN\spctoss\lng';}

  Intro;

  If ParamCount<>1 then
    begin
      WriteLn('Usage:');
      WriteLn;
      WriteLn('   SPACERES.EXE  <resource_file>');
      Halt(255);
    end;

  If not dosFileExists(ParamStr(1)) then ErrorOut('Can''t find '+ParamStr(1));

  Compile;
end.
