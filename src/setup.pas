Program Setup;

Uses
  spctoss,
  global,
  flag,
  lng,

  r8const,
  r8birth,
  r8lng,
  r8dos,
  r8str,
  r8pstr,

  crt,
  app;

Procedure Intro;
begin
  ClrScr;
  TextColor(14);
  WriteLn('SpaceTool'+'/'+cstrOsId+' for SpaceToss v'+constSVersion);
  TextColor(15);
  WriteLn('Copyright (C) 2000-01 by Sergey Storchay (2:462/117) ù All rights reserved.');
  DoBirth;
  WriteLn;
end;

begin
{  HomeDir:='C:\BP\SOURCES\FTN\spctoss';
  WorkDir:='C:\BP\SOURCES\FTN\spctoss';}

  Intro;

  OpenFlag;

  InitObjects;

  LngFile:=New(PLngFile,Init(HomeDir+'\SPCTOSS.LNG','SPACETOSS',strStrToInt(sBuild)));
  LngFile^.LoadFile;
  If LngFile^.Status<>lngNone
            then ErrorOut('Invalid version of resource file');

  ParamString:=New(PParamString,Init);
  ParamString^.Read;

  SLoadWrite(LngFile^.GetString(LongInt(lngReadConf)));
  ParsConfig;
  SLoadOk;
end.
