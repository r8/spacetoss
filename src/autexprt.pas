{
 Autoexport Stuff for SpaceToss
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
 MadMed hudson board
 TM-Ed hudson board
 T:text ง ฌฅญจโ์ ญ  F:Stream.
 writeInfo: ็ฅเฅง เฅแใเแ๋ จ ใช ง๋ข โ์ Done จซจ Failed
}
Unit autexprt;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  r8ftn,
  r8dos,
  r8str,
  r8objs,
  r8dtm,
  r8med,

  areas,
  groups,
  crt,
  dos,
  r8mbe,
  objects;

const
  aetGoldEd   = $01;
  aetAreasBBS = $02;
  aetTermail  = $03;
  aetTMEd     = $04;
  aetSquish   = $05;
  aetMadMED   = $06;

Type

  TAutoExportItem = object(TObject)
    FileType : byte;
    FileName : PString;
    ShortName : boolean;

    Constructor Init;
    Destructor  Done; virtual;
  end;
  PAutoExportItem = ^TAutoExportItem;

  TAutoExportBase = object(TCollection)
    Procedure FreeItem(Item:pointer);virtual;
  end;
  PAutoExportBase = ^TAutoExportBase;

  TAutoExport = object(TObject)
    FileName : PString;
    NameMode : boolean;

    T : text;

    Constructor Init;
    Destructor Done;virtual;

    Procedure Export;virtual;

    Procedure WriteHeader;virtual;
    Procedure WriteInfo;virtual;
    Procedure WriteArea(Area:PArea);virtual;
    Procedure WriteGroup(Group:PGroup);virtual;

    Function ShortBaseName(Area:PArea):string;
  end;
  PAutoExport = ^TAutoExport;

{อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ}

  TGoldedAutoExport = object(TAutoExport)
    Constructor Init;
    Destructor Done;virtual;

    Procedure WriteInfo;virtual;
    Procedure WriteArea(Area:PArea);virtual;
  end;
  PGoldedAutoExport = ^TGoldedAutoExport;

{อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ}
  TAreasBBSAutoExport = object(TAutoExport)
    Constructor Init;
    Destructor Done;virtual;

    Procedure WriteHeader;virtual;
    Procedure WriteInfo;virtual;
    Procedure WriteArea(Area:PArea);virtual;
  end;
  PAreasBBSAutoExport = ^TAreasBBSAutoExport;
{อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ}

  TTerMailAutoExport = object(TAutoExport)
    Constructor Init;
    Destructor Done;virtual;

    Procedure WriteInfo;virtual;
    Procedure WriteArea(Area:PArea);virtual;
    Procedure WriteGroup(Group:PGroup);virtual;
  end;
  PTerMailAutoExport = ^TTerMailAutoExport;

{อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ}

  TTMEDAutoExport = object(TAutoExport)
    Constructor Init;
    Destructor Done;virtual;

    Procedure WriteInfo;virtual;
    Procedure WriteArea(Area:PArea);virtual;
  end;
  PTMEDAutoExport = ^TTMEDAutoExport;

{อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ}

  TSquishAutoExport = object(TAutoExport)
    Constructor Init;
    Destructor Done;virtual;

    Procedure WriteInfo;virtual;
    Procedure WriteArea(Area:PArea);virtual;
  end;
  PSquishAutoExport = ^TSquishAutoExport;

{อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ}

  TMadMEDAutoExport = object(TAutoExport)
    S : PBufStream;

    Constructor Init;
    Destructor Done;virtual;

    Procedure Export;virtual;

    Procedure WriteInfo;virtual;
    Procedure WriteArea(Area:PArea);virtual;
    Procedure WriteGroup(Group:PGroup);virtual;
  end;
  PMadMEDAutoExport = ^TMadMEDAutoExport;
{อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ}

Procedure AutoExportAll;

implementation

Uses
   r8mail,
   global;

Procedure AutoExportAll;
Var
  i:longint;
  AutoExportItem : PAutoExportItem;
  Flag : boolean;
  TempAutoexport : PAutoExport;

  ConfigTime, ExportTime:longint;
  F : Text;

  DT : DateTime;
  Time: Longint;

  Procedure CheckBase(P:pointer);far;
  var
    Area : PArea absolute P;
    Echobase : PMessageBase;
  begin
    If (Area^.Echotype.Storage=etPassthrough)
      or (Area^.Echotype.Storage=etHudson)
        then exit;

    If MessageBasesEngine^.BaseExists(Area^.EchoType.Path) then exit;

    EchoBase:=MessageBasesEngine^.OpenOrCreateBase(Area^.EchoType.Path);
    MessageBasesEngine^.DisposeBase(EchoBase);
  end;

begin
  TextColor(7);

  If AreaFileName=nil then exit;

  AreaBase^.Areas^.ForEach(@CheckBase);

{$I-}
  Assign(F, AreaFileName^);
  Reset(F);
{$I+}
  If IOResult=0 then
    begin
      GetFTime(F,Time);
      UnpackTime(Time,DT );
      Close(F);
      ConfigTime:=dtmDOSToUnix(DT);
    end;

  For i:=0 to AutoExportBase^.Count-1 do
    begin
      AutoExportItem:=AutoExportBase^.At(i);

      ExportTime:=0;
{$I-}
      Assign(F, AutoExportItem^.FileName^);
      Reset(F);
{$I+}
      If IOResult=0 then
        begin
          GetFTime(F,Time);
          UnpackTime(Time,DT );
          Close(F);
          ExportTime:=dtmDOSToUnix(DT);
        end;

      If (not AreaBase^.Modified)
         and (dosFileExists(AutoExportItem^.FileName^))
         and (ExportTime>ConfigTime)
         then continue;

      Case AutoExportItem^.FileType of
        aetGolded : TempAutoexport:=New(PGoldedAutoExport,Init);
        aetAreasBBS : TempAutoexport:=New(PAreasBBSAutoExport,Init);
        aetTermail : TempAutoexport:=New(PTermailAutoExport,Init);
        aetTMED : TempAutoexport:=New(PTMEDAutoExport,Init);
        aetSquish : TempAutoexport:=New(PSquishAutoExport,Init);
        aetMadMED : TempAutoexport:=New(PMadMEDAutoExport,Init);
      end;

      TempAutoexport^.NameMode:=AutoExportItem^.ShortName;
      TempAutoexport^.FileName:=NewStr(AutoExportItem^.FileName^);

      TempAutoexport^.Export;
      objDispose(TempAutoexport);
    end;
end;

{------------------------------------------------------------------------------}

Procedure TAutoExportBase.FreeItem(Item:pointer);
begin
  If Item<>nil then objDispose(PAutoExportItem(Item));
end;

Constructor TAutoExportItem.Init;
begin
  inherited Init;

  FileName:=nil;
end;

Destructor  TAutoExportItem.Done;
begin
  DisposeStr(FileName);

  inherited Done;
end;

Constructor TAutoExport.Init;
begin
  inherited Init;
end;

Destructor  TAutoExport.Done;
begin
  DisposeStr(FileName);
  inherited Done;
end;

Function TAutoExport.ShortBaseName(Area:PArea):string;
Var
  sTemp:string;
begin
  sTemp:=Copy(Area^.EchoType.Path,4,
               Length(Area^.EchoType.Path)-3);

  If Area^.Echotype.Storage=etHudson then
    begin
      ShortBaseName:=sTemp;
      exit;
    end;

  If NameMode then
    begin

      Case Area^.Echotype.Storage of
        etJam     : sTemp:=sTemp+'.JHR';
        etSquish  : sTemp:=sTemp+'.SQD';
        etSMB     : sTemp:=sTemp+'.SHD';
       end;

      sTemp:=dosGetShortName(sTemp);

      If (Area^.Echotype.Storage=etJam)
         or (Area^.Echotype.Storage=etSquish)
         or (Area^.Echotype.Storage=etSMB)
        then Dec(sTemp[0],4);
    end;

  ShortBaseName:=sTemp;
end;

Procedure TAutoExport.WriteInfo;
begin
  Abstract;
end;

Procedure TAutoExport.WriteHeader;
var
  DateTime : TDateTime;
begin
  dtmGetDateTime(DateTime);

  WriteLn(T,';  Created by '+constPID+' at '+
    dtmDate2String(DateTime,'/',False,False)+#32+
      dtmTime2String(DateTime,':',False,False));
  WriteLn(T,';');
end;

Procedure TAutoExport.WriteArea(Area:PArea);
begin
  Abstract;
end;

Procedure TAutoExport.WriteGroup(Group:PGroup);
begin
end;

Procedure TAutoExport.Export;
Var
  i,i2:integer;
  TempArea : pArea;
  TempGroup : pGroup;
begin
  WriteInfo;

{$I-}
  Assign(T,FileName^);
  Rewrite(T);
{$I+}
  If IOResult<>0 then exit;

  WriteHeader;

  For i:=0 to GroupBase^.Areas^.Count-1 do
    begin
      TempGroup:=GroupBase^.Areas^.At(i);
      WriteGroup(TempGroup);

      For i2:=0 to TempGroup^.ItemBase^.Areas^.Count-1 do
        begin
          TempArea:=TempGroup^.ItemBase^.Areas^.At(i2);
          If not TempArea^.CheckFlag('E') then  WriteArea(TempArea);
        end;
    end;

  Close(T);
end;

{------------------------------------------------------------------------------}

Constructor TGoldedAutoExport.Init;
begin
  inherited Init;
end;

Destructor  TGoldedAutoExport.Done;
begin
  inherited Done;
end;

Procedure TGoldedAutoExport.WriteInfo;
begin
  WriteLn('Saving GoldEd configuration to ',FileName^,'...');
  WriteLn;
end;

Procedure TGoldedAutoExport.WriteArea(Area:PArea);
Var
  sTemp : string;
begin
  If Area^.Echotype.Storage=etPassthrough then exit;

  Write(T, 'AREADEF ');
  If Area^.Name<>nil then Write(T,Area^.Name^);
  Write(T,' "');
  If Area^.Desc<>nil then Write(T,Area^.Desc^);
  Write(T,'" ',Area^.Group);

  Case Area^.BaseType of
    btNetmail  : Write(T,' Net ');
    btEchomail : Write(T,' Echo ');
    btLocal    : Write(T,' Local ');
    btBadmail  : Write(T,' Local ');
    btDupemail : Write(T,' Local ');
  end;

  Case Area^.Echotype.Storage of
    etMsg     : Write(T,'Opus ');
    etJam     : Write(T,'Jam ');
    etSquish  : Write(T,'Squish ');
    etHudson  : Write(T,'Hudson ');
    etSMB     : Write(T,'SMB ');
  end;

  sTemp:=ShortBaseName(Area);

  Write(T,sTemp);

  If not ftnIsAddressInvalidated(Area^.UseAka) then
     Write(T,' ',ftnAddressToStrEx(Area^.UseAka));

  WriteLn(T,' ');
end;

{------------------------------------------------------------------------------}

Constructor TAreasBBSAutoExport.Init;
begin
  inherited Init;
end;

Destructor  TAreasBBSAutoExport.Done;
begin
  inherited Done;
end;

Procedure TAreasBBSAutoExport.WriteHeader;
begin
  inherited WriteHeader;

  If Origins^.Count=0 then
    Write(T,'Yet Another SpaceToss Site')
  else  Write(T,PString(Origins^.At(0))^);

  WriteLn(T,' ! ',PString(SysopName^.At(0))^);
end;

Procedure TAreasBBSAutoExport.WriteInfo;
begin
  WriteLn('Saving AreasBBS configuration to ',FileName^,'...');
  WriteLn;
end;

Procedure TAreasBBSAutoExport.WriteArea(Area:PArea);
Var
  sTemp:string;
  St:PStream;
begin
  If (Area^.Echotype.Storage<>etMsg) and
     (Area^.Echotype.Storage<>etJam) and
     (Area^.Echotype.Storage<>etSquish) and
     (Area^.Echotype.Storage<>etHudson) and
     (Area^.Echotype.Storage<>etPassthrough)
     then exit;

  Case Area^.Echotype.Storage of
    etJam     : Write(T,'!');
    etSquish  : Write(T,'$');
    etPassThrough  : Write(T,'P   ');
    etHudson  : Write(T,'H');
  end;

  If (Area^.Echotype.Storage<>etPassThrough)
   then
    begin
      sTemp:=ShortBaseName(Area);

      Write(T,sTemp,' ');
    end;

  If Area^.Name<>nil then Write(T,Area^.Name^,' ');

  St:=New(PMemoryStream,Init(0,cBuffSize));
  NodeList(St,Area^.Links,'',True,#0,#0,#0,#0);

  St^.Seek(0);

  If St^.GetSize<>0 then
    begin
      sTemp:=objStreamReadLn(St);
      Write(T,sTemp);
    end;

  objDispose(St);

  Writeln(T,' ');
end;

{------------------------------------------------------------------------------}

Constructor TTerMailAutoExport.Init;
begin
  inherited Init;
end;

Destructor  TTerMailAutoExport.Done;
begin
  inherited Done;
end;

Procedure TTerMailAutoExport.WriteInfo;
begin
  WriteLn('Saving TerMail configuration to ',FileName^,'...');
  WriteLn;
end;

Procedure TTerMailAutoExport.WriteGroup(Group:PGroup);
begin
  Write(T,'@LINE ');
  If Group^.Desc<>nil then WriteLn(T,Group^.Desc^);
end;

Procedure TTerMailAutoExport.WriteArea(Area:PArea);
Var
  sTemp : string;
begin
  If (Area^.Echotype.Storage<>etMsg) and
     (Area^.Echotype.Storage<>etJam) then exit;

  sTemp:=ShortBaseName(Area);

  Write(T,sTemp);
  If Area^.Name<>nil then Write(T,'     '+Area^.Name^);

  Case Area^.Echotype.Storage of
    etMsg     : WriteLn(T,' MSG FIDO');
    etJam     : WriteLn(T,' JAM FIDO');
  end;
end;

{------------------------------------------------------------------------------}

Constructor TSquishAutoExport.Init;
begin
  inherited Init;
end;

Destructor  TSquishAutoExport.Done;
begin
  inherited Done;
end;

Procedure TSquishAutoExport.WriteInfo;
begin
  WriteLn('Saving Squish configuration to ',FileName^,'...');
  WriteLn;
end;

Procedure TSquishAutoExport.WriteArea(Area:PArea);
Var
  sTemp : string;
  St:PStream;
begin
  If (Area^.Echotype.Storage<>etMsg) and
     (Area^.Echotype.Storage<>etJam) and
     (Area^.Echotype.Storage<>etSquish) and
     (Area^.Echotype.Storage<>etPassthrough)
     then exit;

  Case Area^.BaseType of
    btNetmail  : Write(T,'NetArea ');
    btEchomail : Write(T,'EchoArea ');
    btLocal    : Write(T,'LocalArea ');
    btBadmail  : Write(T,'BadArea ');
    btDupemail : Write(T,'DupeArea ');
  end;

  Write(T,Area^.Name^,' ');

  If Area^.Echotype.Storage<>etPassThrough then
    begin
      sTemp:=ShortBaseName(Area);

      Write(T,sTemp,' ');
    end;

  Case Area^.Echotype.Storage of
    etJam     : Write(T,'-J ');
    etSquish  : Write(T,'-$ ');
    etPassThrough  :Write(T,'-0 ');
  end;

  If not ftnIsAddressInvalidated(Area^.UseAka) then
     Write(T,'-p',ftnAddressToStrEx(Area^.UseAka),' ');

  Write(T,'-$g',Area^.Group,' ');

  Write(T,'-n"');
  If Area^.Desc<>nil then Write(T,Area^.Desc^);
  Write(T,'" ');

  If Area^.PurgeDays<>0 then Write(T,'-$d',Area^.PurgeDays,' ');
  If Area^.PurgeMsgs<>0 then Write(T,'-$m',Area^.PurgeMsgs,' ');


  St:=New(PMemoryStream,Init(0,cBuffSize));
  NodeList(St,Area^.Links,'',True,'-x','-y','-z',#0);

  St^.Seek(0);

  If St^.GetSize<>0 then
    begin
      sTemp:=objStreamReadLn(St);
      Write(T,sTemp);
    end;

  objDispose(St);

  Writeln(T,' ');
end;

{------------------------------------------------------------------------------}

Constructor TTMEDAutoExport.Init;
begin
  inherited Init;
end;

Destructor  TTMEDAutoExport.Done;
begin
  inherited Done;
end;

Procedure TTMEDAutoExport.WriteInfo;
begin
  WriteLn('Saving TM-ED configuration to ',FileName^,'...');
  WriteLn;
end;

Procedure TTMEDAutoExport.WriteArea(Area:PArea);
Var
  sTemp : string;
begin
  If (Area^.Echotype.Storage<>etMsg) and
     (Area^.Echotype.Storage<>etHudson) and
     (Area^.Echotype.Storage<>etPassthrough)
     then exit;

  Write(T, 'Area ',Area^.Name^);
  Write(T,' "');
  If Area^.Desc<>nil then Write(T,Area^.Desc^);
  Write(T,'" ');

  Case Area^.Echotype.Storage of
    etMsg     :
      begin
        Write(T,'F');
        sTemp:=ShortBaseName(Area);
      end;
    etHudson  :
      begin
        Write(T,'Q');
        sTemp:='';
      end;
    etPassthrough  :
      begin
        Write(T,'P');
        sTemp:='0';
      end;
  end;

  Case Area^.BaseType of
    btNetmail  : Write(T,'N ');
    btEchomail : Write(T,'E ');
    btLocal    : Write(T,'E ');
    btBadmail  : Write(T,'E ');
    btDupemail  : Write(T,'E ');
  end;


  Write(T,sTemp);

  If not ftnIsAddressInvalidated(Area^.UseAka) then
     Write(T,' ',ftnAddressToStrEx(Area^.UseAka));

 WriteLn(T,' ');
end;

{------------------------------------------------------------------------------}

Constructor TMadMEDAutoExport.Init;
begin
  inherited Init;
end;

Destructor  TMadMEDAutoExport.Done;
begin
  inherited Done;
end;

Procedure TMadMEDAutoExport.WriteInfo;
begin
  WriteLn('Saving MadMED configuration to ',FileName^,'...');
  WriteLn;
end;

Procedure TMadMEDAutoExport.WriteGroup(Group:PGroup);
Var
  sTemp : string;
  FolderHeader : TFolderHeader;
begin
  FillChar(FolderHeader,SizeOf(FolderHeader),#0);

  FolderHeader.Flags:=FolderHeader.Flags or medLocalmail;
  FolderHeader.Flags:=FolderHeader.Flags or medCollapsed;

  FolderHeader.LevelIndex:=0;

  If Group^.Desc=nil then FolderHeader.NameLen:=Length(Group^.Name^)
    else  FolderHeader.NameLen:=Length(Group^.Desc^);
  FolderHeader.AreaLen:=Length(Group^.Name^);

  FolderHeader.Size:=SizeOf(FolderHeader)+
                       FolderHeader.NameLen+
                       FolderHeader.AreaLen;

  S^.Write(FolderHeader,SizeOf(FolderHeader));

  If Group^.Desc=nil then objStreamWrite(S,Group^.Name^)
    else  objStreamWrite(S,Group^.Desc^);

  objStreamWrite(S,Group^.Name^);
end;

Procedure TMadMEDAutoExport.WriteArea(Area:PArea);
Var
  sTemp : string;
  FolderHeader : TFolderHeader;
begin
  If (Area^.Echotype.Storage<>etMsg) and
     (Area^.Echotype.Storage<>etJam) and
     (Area^.Echotype.Storage<>etSquish) and
     (Area^.Echotype.Storage<>etHudson)
     then exit;

  FillChar(FolderHeader,SizeOf(FolderHeader),#0);

  Case Area^.Echotype.Storage of
    etMsg     : FolderHeader.Flags:=FolderHeader.Flags or medMsgOpus;
    etJam     : FolderHeader.Flags:=FolderHeader.Flags or medMsgJam;
    etSquish  : FolderHeader.Flags:=FolderHeader.Flags or medMsgSquish;
    etHudson  : FolderHeader.Flags:=FolderHeader.Flags or medMsgOpus;
  end;

  FolderHeader.DefaultAttrs:=FolderHeader.DefaultAttrs or flgLocal;
  FolderHeader.Flags:=FolderHeader.Flags+(medAddOrigin+medRandOrigin);
  Case Area^.BaseType of
    btNetmail  :
      begin
        FolderHeader.Flags:=FolderHeader.Flags or medNetmail;
        FolderHeader.DefaultAttrs:=FolderHeader.DefaultAttrs or flgPrivate;
        FolderHeader.Flags:=FolderHeader.Flags-(medAddOrigin+medRandOrigin);
      end;
    btEchomail : FolderHeader.Flags:=FolderHeader.Flags or medEchomail;
    btLocal    : FolderHeader.Flags:=FolderHeader.Flags or medLocalmail;
    btBadmail  : FolderHeader.Flags:=FolderHeader.Flags or medLocalmail;
    btDupemail : FolderHeader.Flags:=FolderHeader.Flags or medLocalmail;
  end;

  sTemp:=ShortBaseName(Area);

  FolderHeader.LevelIndex:=1;

  If not ftnIsAddressInvalidated(Area^.UseAka) then
    begin
      FolderHeader.DefaultAddress.Zone:=Area^.UseAka.Zone;
      FolderHeader.DefaultAddress.Net:=Area^.UseAka.Net;
      FolderHeader.DefaultAddress.Node:=Area^.UseAka.Node;
      FolderHeader.DefaultAddress.Point:=Area^.UseAka.Point;
    end;

  If Area^.Desc=nil then FolderHeader.NameLen:=Length(Area^.Name^)
    else  FolderHeader.NameLen:=Length(Area^.Desc^);
  FolderHeader.AreaLen:=Length(Area^.Name^);
  FolderHeader.PathLen:=Length(sTemp);

  FolderHeader.Size:=SizeOf(FolderHeader)+
                       FolderHeader.NameLen+
                       FolderHeader.AreaLen+
                       FolderHeader.PathLen;

  S^.Write(FolderHeader,SizeOf(FolderHeader));

  If Area^.Desc=nil then objStreamWrite(S,Area^.Name^)
    else  objStreamWrite(S,Area^.Desc^);

  objStreamWrite(S,Area^.Name^);
  objStreamWrite(S,sTemp);
end;

Procedure TMadMEDAutoExport.Export;
Var
  i,i2:integer;
  TempArea : pArea;
  TempGroup : pGroup;
begin
  WriteInfo;

  S:=New(PBufStream,Init(FileName^,
    fmCreate or fmWrite or fmDenyAll,cBuffSize));

  If IOResult<>0 then exit;
  If S^.Status<>stOk then exit;

  For i:=0 to GroupBase^.Areas^.Count-1 do
    begin
      TempGroup:=GroupBase^.Areas^.At(i);
      WriteGroup(TempGroup);

      For i2:=0 to TempGroup^.ItemBase^.Areas^.Count-1 do
        begin
          TempArea:=TempGroup^.ItemBase^.Areas^.At(i2);
          If not TempArea^.CheckFlag('E') then  WriteArea(TempArea);
        end;
    end;

  objDispose(S);
end;

{------------------------------------------------------------------------------}

end.


