{
 SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2000-2002.
}
{.$DEFINE SPCTOOL}
{.$DEFINE NOFLAG}
{.$DEFINE WARNING}
{.$DEFINE FORCEHOMEDIR}

{$IFDEF VIRTUALPASCAL}
  {$M 65536,512000}
{$ELSE}
{$IFNDEF FPC}
  {$M 65521,0,655000}
{$ENDIF}
{$ENDIF}

{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}

Program SpaceToss; {$R res\spctoss.res}

Uses
  crt,
  dos,
  lng,
  r8lng,
  r8const,
  r8arc,
  r8objs,
  r8alst,
  r8elst,
  r8bcl,
  r8felst,
  r8xofl,
  r8log,
  r8pstr,
  r8ftn,
  r8dos,
  r8str,
  r8ctl,
  r8mail,
  r8mcr,
  r8pkt,
  r8mbe,

  flag,

  r8out,
  ilist,

  announce,
  acreate,

  global,
  areas,
  rules,
  nodes,
  groups,
  uplinks,
  dupe,
  macro,
  route,
  equeue,
  scripts,
  desc,
  netmail,

  outbnds,

  bad,

  toss,
  scan,
  autexprt,
  hand,
  purge,
  pack,

  objects,

{$IFDEF WIN32}
  windows,
{$ENDIF}

  afix,
  arc;

{$IFDEF SPCTOOL}

Procedure ParsConfig;

implementation
{$ENDIF}

var
  T:tAddress;
  l:longint;

Procedure Intro;
begin
  ClrScr;
  TextColor(14);
  Write(constProgramName+'/'+cstrOsId+' v'+constSVersion);
  TextColor(10);
  Write(' *FREEWARE* ');
  TextColor(14);
  WriteLn('ù FAST! Echomail Processor');
  TextColor(15);
  WriteLn('Copyright (C) 2000-2002 by Sergey Storchay (2:462/117) ù All rights reserved.');
  WriteLn;
end;

Procedure HelpToss;
begin
  TextColor(7);
  WriteLn('Usage:');
  WriteLn;
  WriteLn('   SPCTOSS Toss [-A] [-B] [-P] [-S]');
  WriteLn;
  WriteLn('Keys:');
  WriteLn;
  Writeln('   -A            Process areafix messages');
  Writeln('   -B            Retoss messages from Badmail area');
  Writeln('   -P            Disable all before/after-pack/unpack processes');
  Writeln('   -S            Disable all security checks');
  WriteLn;
  FreeObjects;
  Halt;
end;

Procedure HelpScan;
begin
  TextColor(7);
  WriteLn('Usage:');
  WriteLn;
  WriteLn('   SPCTOSS Scan [-H] [<AreaName>...|@<Filename>...]');
  WriteLn;
  WriteLn('Keys:');
  WriteLn;
  Writeln('   -H            Don''t use highwaters');
  WriteLn;
  WriteLn('You may also use wildcards in <AreaName>.' );
  FreeObjects;
  Halt;
end;

Procedure HelpImport;
begin
  TextColor(7);
  WriteLn('Usage:');
  WriteLn;
  WriteLn('   SPCTOSS Import [-A]');
  WriteLn;
  WriteLn('Keys:');
  WriteLn;
  Writeln('   -A            Process areafix mesages');
  WriteLn;
  FreeObjects;
  Halt;
end;

Procedure HelpHand;
begin
  TextColor(7);
  WriteLn('Usage:');
  WriteLn;
  WriteLn('   SPCTOSS Hand <LinkAddress> [<LinkAddress>...]  "<AreafixCommand>"');
  WriteLn;
  WriteLn;
  WriteLn('You may also use wildcards in <LinkAddress>' );
  FreeObjects;
  Halt;
end;

Procedure HelpPurge;
begin
  TextColor(7);
  WriteLn('Usage:');
  WriteLn;
  WriteLn('   SPCTOSS Purge [-D:<days>] [-M:<messages>] [<AreaName>...|@<Filename>...]');
  WriteLn;
  WriteLn('Keys:');
  WriteLn;
  Writeln('   -D:<days>      Redefine PurgeDays');
  Writeln('   -M:<messages>  Redefine PurgeMsgs');
  WriteLn;
  WriteLn('You may also use wildcards in <AreaName>.' );
  FreeObjects;
  Halt;
end;

Procedure HelpPack;
begin
  TextColor(7);
  WriteLn('Usage:');
  WriteLn;
  WriteLn('   SPCTOSS Pack [<AreaName>...|@<Filename>...]');
  WriteLn;
  WriteLn('You may also use wildcards in <AreaName>.' );
  FreeObjects;
  Halt;
end;

Procedure HelpDesc;
begin
  TextColor(7);
  WriteLn('Usage:');
  WriteLn;
  WriteLn('   SPCTOSS Desc <Echolist type> <Echolist path> [<AreaName>...|@<Filename>...]');
  WriteLn;
  WriteLn('You may also use wildcards in <AreaName>.' );
  FreeObjects;
  Halt;
end;

Procedure Help;
begin
  TextColor(7);
  WriteLn('Usage:');
  WriteLn;
  WriteLn('   SPCTOSS <command> [parameters]');
  WriteLn;
  WriteLn('Commands:');
  WriteLn;
  Writeln('   Toss            Toss and forward incoming mailbundles');
  Writeln('   Scan            Scan the message base for outgoing messages');
  Writeln('   Import          Import netmail to netmail areas');
  Writeln('   Export          Export netmail from netmail areas');
  Writeln('   Purge           Purge message bases');
  Writeln('   Pack            Pack message bases');
  Writeln('   Route           Route and pack netmail to outbound');
  Writeln('   Mgr             Process areamanager requests');
  Writeln('   Hand            Simulate link''s request to areafix');
  Writeln('   Desc            Add description to echoareas');
  Writeln('   Check           Check configuration files');
  WriteLn;
  WriteLn('Enter ''SPCTOSS <command> ?'' for more information about [parameters]');
  FreeObjects;
  Halt;
end;

Procedure InitMainCTL;
begin
  MainCTL:=New(PCtlFile,Init);

  MainCTL^.SetErrorMessages(LngFile^.GetString(LongInt(lngctlCantFindFile)),
     LngFile^.GetString(LongInt(lngctlUnknownKeyword)),
     LngFile^.GetString(LongInt(lngctlLoopInclude)));

  MainCTL^.AddKeyword('Address');
  MainCTL^.AddKeyword('AKA');
  MainCTL^.AddKeyword('Sysop');

  MainCTL^.AddKeyword('Inbound');
  MainCTL^.AddKeyword('LocalInbound');
  MainCTL^.AddKeyword('TempInbound');
  MainCTL^.AddKeyword('QueueDir');
  MainCTL^.AddKeyword('LogFile');
  MainCTL^.AddKeyword('LogBuffer');
  MainCTL^.AddKeyword('AreafixLogFile');
  MainCTL^.AddKeyword('MovePackets');

  MainCTL^.AddKeyword('Netmail');
  MainCTL^.AddKeyword('HudsonPath');
  MainCTL^.AddKeyword('MaxDupes');
  MainCTL^.AddKeyword('AutoDesc');
  MainCTL^.AddKeyword('Announce');
  MainCTL^.AddKeyword('ImportList');
  MainCTL^.AddKeyword('ExportLists');
  MainCTL^.AddKeyword('LongAutocreate');
  MainCTL^.AddKeyword('MsgSplitSize');
  MainCTL^.AddKeyword('Origin');

  MainCTL^.AddKeyword('FlushBuffers');

  MainCTL^.AddKeyword('DataPath');
  MainCTL^.AddKeyword('RouteFile');
  MainCTL^.AddKeyword('AreaFile');
  MainCTL^.AddKeyword('ScriptsDir');

  MainCTL^.AddKeyword('KillAfterImport');
  MainCTL^.AddKeyword('KillAfterRoute');

  MainCTL^.AddKeyword('AutoExport');

  MainCTL^.AddKeyword('TemplatesDir');
  MainCTL^.AddKeyword('ListTPL');
  MainCTL^.AddKeyword('HelpTPL');
  MainCTL^.AddKeyword('QueryTPL');
  MainCTL^.AddKeyword('RulesListTPL');
  MainCTL^.AddKeyword('UnlinkedTPL');
  MainCTL^.AddKeyword('CompressTPL');
  MainCTL^.AddKeyword('AvailTPL');
  MainCTL^.AddKeyword('BadPassTPL');
  MainCTL^.AddKeyword('BadNodeTPL');

  MainCTL^.AddKeyword('PreserveRequests');
  MainCTL^.AddKeyword('Alias');
  MainCTL^.AddKeyword('AreafixIn');
  MainCTL^.AddKeyword('AreafixOut');
  MainCTL^.AddKeyword('AvailArcs');
  MainCTL^.AddKeyword('RulesDir');
  MainCTL^.AddKeyword('RulesId');
  MainCTL^.AddKeyword('KeepRequests');
  MainCTL^.AddKeyword('KeepReceipts');
  MainCTL^.AddKeyword('CopyRequests');

  MainCTL^.AddKeyword('BSODir');
  MainCTL^.AddKeyword('AMADir');
  MainCTL^.AddKeyword('TBoxDir');
  MainCTL^.AddKeyword('TLBoxDir');
  MainCTL^.AddKeyword('DefaultOutbound');
  MainCTL^.AddKeyword('BusyOutbound');
  MainCTL^.AddKeyword('DefaultGroups');

  MainCTL^.AddKeyword('DefaultArchiver');
  MainCTL^.AddKeyword('MaxPktSize');
  MainCTL^.AddKeyword('MaxArcSize');
  MainCTL^.AddKeyword('BeforePack');
  MainCTL^.AddKeyword('BeforeUnPack');
  MainCTL^.AddKeyword('AfterPack');
  MainCTL^.AddKeyword('AfterScan');
  MainCTL^.AddKeyword('AfterUnPack');

  MainCTL^.SetCTLName(dosMakeValidString('spctoss.ctl'));
  MainCTL^.LoadCTL;

  If MainCTL^.CTLError<>ctlErrNone
      then ErrorOut(MainCTL^.ExplainStatus(MainCTL^.CTLError));
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure InitNodesCTL;
begin
  NodesCTL:=New(PSectionCtl,Init('BEGINNODE','ENDNODE'));

  NodesCTL^.SetErrorMessages(LngFile^.GetString(LongInt(lngctlCantFindFile)),
     LngFile^.GetString(LongInt(lngctlUnknownKeyword)),
     LngFile^.GetString(LongInt(lngctlLoopInclude)));


  NodesCTL^.AddKeyword('Address');
  NodesCTL^.AddKeyword('SysopName');
  NodesCTL^.AddKeyword('PktPassword');
  NodesCTL^.AddKeyword('AreafixPassword');
  NodesCTL^.AddKeyword('UseAKA');
  NodesCTL^.AddKeyword('OutBound');
  NodesCTL^.AddKeyword('Archiver');
  NodesCTL^.AddKeyword('Flavour');
  NodesCTL^.AddKeyword('Groups');
  NodesCTL^.AddKeyword('MaxPktSize');
  NodesCTL^.AddKeyword('MaxArcSize');
  NodesCTL^.AddKeyword('Level');
  NodesCTL^.AddKeyword('PktType');
  NodesCTL^.AddKeyword('Flags');

  NodesCTL^.SetCTLName(dosMakeValidString('spctoss.nod'));
  NodesCTL^.LoadCTL;

  If NodesCTL^.CTLError<>ctlErrNone
      then ErrorOut(NodesCTL^.ExplainStatus(NodesCTL^.CTLError));
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure InitGroupsCTL;
begin
  GroupsCTL:=New(PSectionCtl,Init('BEGINGROUP','ENDGROUP'));

  GroupsCTL^.SetErrorMessages(LngFile^.GetString(LongInt(lngctlCantFindFile)),
     LngFile^.GetString(LongInt(lngctlUnknownKeyword)),
     LngFile^.GetString(LongInt(lngctlLoopInclude)));

  GroupsCTL^.AddKeyword('Name');
  GroupsCTL^.AddKeyword('Desc');
  GroupsCTL^.AddKeyword('EchoDesc');
  GroupsCTL^.AddKeyword('Path');
  GroupsCTL^.AddKeyword('UseAka');
  GroupsCTL^.AddKeyword('WriteLevel');
  GroupsCTL^.AddKeyword('ReadLevel');
  GroupsCTL^.AddKeyword('Links');
  GroupsCTL^.AddKeyword('Flags');
  GroupsCTL^.AddKeyword('PurgeDays');
  GroupsCTL^.AddKeyword('PurgeMsgs');

  GroupsCTL^.SetCTLName(dosMakeValidString('spctoss.grp'));
  GroupsCTL^.LoadCTL;

  If GroupsCTL^.CTLError<>ctlErrNone
      then ErrorOut(GroupsCTL^.ExplainStatus(GroupsCTL^.CTLError));
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure InitUplinksCTL;
begin
  UplinksCTL:=New(PSectionCtl,Init('BEGINUPLINK','ENDUPLINK'));

  UplinksCTL^.SetErrorMessages(LngFile^.GetString(LongInt(lngctlCantFindFile)),
     LngFile^.GetString(LongInt(lngctlUnknownKeyword)),
     LngFile^.GetString(LongInt(lngctlLoopInclude)));

  UplinksCTL^.AddKeyword('Address');
  UplinksCTL^.AddKeyword('AreafixName');
  UplinksCTL^.AddKeyword('AreafixPassword');
  UplinksCTL^.AddKeyword('AutocreateGroup');
  UplinksCTL^.AddKeyword('Unconditional');
  UplinksCTL^.AddKeyword('Arealist');
  UplinksCTL^.AddKeyword('AutoDesc');
  UplinksCTL^.AddKeyword('ForwardLevel');


  UplinksCTL^.SetCTLName(dosMakeValidString('spctoss.upl'));
  UplinksCTL^.LoadCTL;

  If UplinksCTL^.CTLError<>ctlErrNone
      then ErrorOut(UplinksCTL^.ExplainStatus(UplinksCTL^.CTLError));
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure ReadNodes;
Var
  i,i2:integer;
  SR:CTLSR;
  TempNode : PNode;

  sTemp : string;
  S : string;
  TempAddress : TAddress;
begin
  InitNodesCTL;

  NodeBase:=New(PNodeBase,Init);

  For i:=0 to NodesCTL^.GetSectionCount-1 do
    begin
      NodesCTL^.FindFirstAddressValue(i,'Address',TempAddress,SR);
      If NodesCTL^.CTLError<>0 then continue;

      If NodeBase^.FindNode(TempAddress)<>nil
        then ErrorOut(ftnAddressToStrEx(TempAddress)+': Duplicate entry');

      TempNode:=New(PNode,Init(TempAddress));

      sTemp:=NodesCTL^.FindFirstValue(i,'SysopName',SR);
      TempNode^.ChangeSysopName(sTemp);

      sTemp:=NodesCTL^.FindFirstValue(i,'PktPassword',SR);
      TempNode^.ChangePktPassword(strUpper(sTemp));

      sTemp:=NodesCTL^.FindFirstValue(i,'AreafixPassword',SR);
      TempNode^.ChangeAreafixPassword(strUpper(sTemp));

      ftnClearAddress(TempAddress);
      NodesCTL^.FindFirstAddressValue(i,'UseAKA',TempAddress,SR);
      If ftnIsAddressCleared(TempAddress)
          then AddressBase^.FindNearest(TempNode^.Address,TempAddress);
      If  AddressBase^.FindAddress(TempAddress)=nil
         then ErrorOut('Invalid AKA for '+ftnAddressToStrEx(TempNode^.Address));
      TempNode^.UseAka:=TempAddress;

      sTemp:=strUpper(NodesCTL^.FindFirstValue(i,'Outbound',SR));
      If NodesCTL^.CTLError<>0 then TempNode^.Outbound:=TosserOutbounds^.Default
        else
          begin
            S:=strParser(sTemp,1,[#32]);

            If S='DISKPOLL' then
              begin
                sTemp:=strParser(sTemp,2,[#32]);
                sTemp:=dosMakeValidString(sTemp);

                If not dosDirExists(sTemp)
                   then ErrorOut('Invalid DISKPOLL path for '
                      +ftnAddressToStrEx(TempNode^.Address));

                S:=ftnAddressToStrEx(TempNode^.Address)+'POLL';
                TosserOutbounds^.AddOutbound(S,outDiskPoll,sTemp);
              end;

            TempNode^.Outbound:=TosserOutbounds^.FindOutbound(S);
            If TempNode^.Outbound=nil
              then ErrorOut(ftnAddressToStrEx(TempNode^.Address)
                          +': Unknown or misconfigurated outbound type');
          end;

      sTemp:=strUpper(NodesCTL^.FindFirstValue(i,'MaxPktSize',SR));
      If sTemp=''
          then TempNode^.MaxPktSize:=MaxPktSize
            else TempNode^.MaxPktSize:=strStrToInt(sTemp);

      sTemp:=strUpper(NodesCTL^.FindFirstValue(i,'MaxArcSize',SR));
      If sTemp=''
          then TempNode^.MaxArcSize:=MaxArcSize
            else TempNode^.MaxArcSize:=strStrToInt(sTemp);

      sTemp:=strUpper(NodesCTL^.FindFirstValue(i,'Archiver',SR));
      If NodesCTL^.CTLError<>0 then TempNode^.ChangeArchiver(DefaultArchiver)
        else
          begin
            If sTemp<>'NONE' then
              If ArcEngine^.FindArcName(sTemp)=-1
                     then ErrorOut('Invalid archiver type for '
                          +ftnAddressToStrEx(TempNode^.Address));
            TempNode^.ChangeArchiver(sTemp);
          end;

      sTemp:=strUpper(NodesCTL^.FindFirstValue(i,'Flavour',SR));
      If sTemp='' then TempNode^.Flavour:=flvNormal else
      If sTemp='NORMAL' then TempNode^.Flavour:=flvNormal else
      If sTemp='CRASH' then TempNode^.Flavour:=flvCrash else
      If sTemp='HOLD' then TempNode^.Flavour:=flvHold else
      If sTemp='DIRECT' then TempNode^.Flavour:=flvDirect else
      If sTemp='IMMEDIATE' then TempNode^.Flavour:=flvImmediate else
       ErrorOut('Invalid flavour for '+ftnAddressToStrEx(TempNode^.Address));

      sTemp:=strUpper(NodesCTL^.FindFirstValue(i,'PktType',SR));
      If sTemp='' then TempNode^.PktType:=ptType2p else
      If sTemp='PKT2+' then TempNode^.PktType:=ptType2p else
      If sTemp='PKT2000' then TempNode^.PktType:=ptPkt2000 else
       ErrorOut('Invalid packet type for '+ftnAddressToStrEx(TempNode^.Address));

      TempNode^.Groups:=strUpper(NodesCTL^.FindFirstValue(i,'Groups',SR));
      If NodesCTL^.CTLError<>0 then TempNode^.Groups:=DefaultGroups;

      sTemp:=NodesCTL^.FindFirstValue(i,'Flags',SR);
      TempNode^.Flags:=strUpper(sTemp);

      i2:=1;
      While i2<=Length(TempNode^.Flags) do
        begin
          If TempNode^.Flags[i2]=#32 then
            begin
              Delete(TempNode^.Flags,i2,1);
              continue;
            end;

          If not (TempNode^.Flags[i2] in NodeFlags)
              then ErrorOut(ftnAddressToStrEx(TempNode^.Address)
                +': Invalid flag "'+TempNode^.Flags[i2]+'"');
          Inc(i2);
        end;

      sTemp:=NodesCTL^.FindFirstValue(i,'Level',SR);
      TempNode^.Level:=strStrToInt(sTemp);
      If NodesCTL^.CTLError<>0 then TempNode^.Level:=$FF;

      NodeBase^.AddNode(TempNode);
    end;

  objDispose(NodesCTL);
end;

Procedure ParserLinks(S:string;Area:PArea;GroupMode:boolean);
Var
  i:integer;
  i2:integer;
  sTemp:string;
  PrevAddress : TAddress;
  TempAddress : TAddress;
  TempNode : PNode;
  Mode : byte;
begin
  AddressBase^.GetAddress(0,PrevAddress);

  S:=strTrimB(S,[#32,#9]);

  If S='' then exit;

  For i:=1 to strNumbOfTokens(S,[#32,#9]) do
    begin
      sTemp:=strParser(S,i,[#32,#9]);

      Mode:=modNone;

      If sTemp[1]='!' then
        begin
          Mode:=modRead;
          sTemp:=Copy(sTemp,2,Length(sTemp)-1);
        end;

      If sTemp[1]='~' then
        begin
          Mode:=modWrite;
          sTemp:=Copy(sTemp,2,Length(sTemp)-1);
        end;

      If sTemp[1]='&' then
        begin
          Mode:=modLocked;
          sTemp:=Copy(sTemp,2,Length(sTemp)-1);
        end;

      if Mode=modNone then Mode:=modRead or modWrite;

      TempAddress:=PrevAddress;
      ftnStrToAddress(sTemp,TempAddress);

      TempNode:=NodeBase^.FindNode(TempAddress);

      if TempNode=nil then
          ErrorOut(Area^.Name^+': Node '
            +ftnAddressToStrEx(TempAddress)+' is unknown to SpaceToss');

      If not GroupMode then TempNode^.AddArea(Area^.Name^,Mode);
      Area^.AddLink(TempAddress,Mode);

      PrevAddress:=TempAddress;
    end;
end;

Procedure ReadAreas;
begin
  AreaBase:=New(PAreaBase,Init);

  If AreaFileName<>nil then
    If not AreaBase^.LoadConfigFile(AreaFileName^)
         then ErrorOut(AreaBase^.Error);
end;

Procedure ReadUplinks;
Var
  i : longint;
  i2:longint;
  TempNode : PNode;
  TempAddress : TAddress;
  SR : CTLSR;
  TempUplink : PUplink;
  sTemp:string;
begin
  InitUplinksCTL;
  UplinkBase:=New(PUplinkBase,Init);

  For i:=0 to UplinksCTL^.GetSectionCount-1 do
    begin
      UplinksCTL^.FindFirstAddressValue(i,'Address',TempAddress,SR);
      If UplinksCTL^.CTLError<>0 then continue;

      TempUplink:=New(PUplink,Init);
      UplinkBase^.AddUplink(TempUplink);

      TempNode:=NodeBase^.FindNode(TempAddress);

      If TempNode=nil then
         ErrorOut(ftnAddressToStrEx(TempAddress)+': Invalid uplink');

      TempUplink^.Address:=TempAddress;
      TempUplink^.UseAKA:=TempNode^.UseAKA;

      sTemp:=strUpper(strTrimB(UplinksCTL^.FindFirstValue(i,'AutocreateGroup',SR),[#32]));
      If GroupBase^.FindArea(sTemp)=nil
         then ErrorOut('Invalid autocreate group for '+ftnAddressToStrEx(TempUplink^.Address));
      TempUplink^.AutocreateGroup:=sTemp;

      TempUplink^.AreafixName:=
           NewStr(UplinksCTL^.FindFirstValue(i,'AreafixName',SR));
      If TempUplink^.AreafixName=nil
           then TempUplink^.AreafixName:=NewStr('Areafix');

      sTemp:=UplinksCTL^.FindFirstValue(i,'AreafixPassword',SR);
      TempUplink^.AreafixPassword:=NewStr(strUpper(sTemp));

      sTemp:=UplinksCTL^.FindFirstValue(i,'ForwardLevel',SR);
      TempUplink^.ForwardLevel:=strStrToInt(sTemp);
      If UplinksCTL^.CTLError<>0 then TempUplink^.ForwardLevel:=0;

      sTemp:=strUpper(UplinksCTL^.FindFirstValue(i,'Unconditional',SR));
      TempUplink^.Unconditional:=False;
      If sTemp='YES'then TempUplink^.Unconditional:=True;

      sTemp:=UplinksCTL^.FindFirstValue(i,'Arealist',SR);
      If UplinksCTL^.CTLError=0 then
        begin
          ParserArealist(sTemp,TempUplink^.Arealist);

(*          If not dosFileExists(TempUplink^.Arealist.Path)
              then ErrorOut('Invalid echolist path for '
            +ftnAddressToStrEx(TempUplink^.Address)); *)

          If TempUplink^.Arealist.ListType=ltUnknown
              then ErrorOut('Invalid echolist type for '
            +ftnAddressToStrEx(TempUplink^.Address));
        end;

      sTemp:=UplinksCTL^.FindFirstValue(i,'AutoDesc',SR);
      If UplinksCTL^.CTLError=0 then
        begin
          ParserArealist(sTemp,TempUplink^.AutoDesc);

          If not dosFileExists(TempUplink^.AutoDesc.Path)
              then ErrorOut('Invalid auto description file for '
            +ftnAddressToStrEx(TempUplink^.Address));
        end;
    end;
end;

Procedure ReadGroups;
Var
  i:integer;
  SR:CTLSR;
  TempGroup : PGroup;

  sTemp : string;
  TempAddress : TAddress;
begin
  InitGroupsCTL;
  GroupBase:=New(PGroupBase,Init);

  For i:=0 to GroupsCTL^.GetSectionCount-1 do
    begin
      sTemp:=strUpper(GroupsCTL^.FindFirstValue(i,'Name',SR));
      If GroupsCTL^.CTLError<>0 then continue;

      TempGroup:=New(PGroup,Init(sTemp));
      GroupBase^.AddArea(TempGroup);

      AssignStr(TempGroup^.Desc,GroupsCTL^.FindFirstValue(i,'Desc',SR));
      TempGroup^.EchoDesc:=GroupsCTL^.FindFirstValue(i,'EchoDesc',SR);

      sTemp:=GroupsCTL^.FindFirstValue(i,'ReadLevel',SR);
      TempGroup^.ReadLevel:=strStrToInt(sTemp);
      If GroupsCTL^.CTLError<>0 then TempGroup^.ReadLevel:=0;

      sTemp:=GroupsCTL^.FindFirstValue(i,'WriteLevel',SR);
      TempGroup^.WriteLevel:=strStrToInt(sTemp);
      If GroupsCTL^.CTLError<>0 then TempGroup^.WriteLevel:=0;

      sTemp:=GroupsCTL^.FindFirstValue(i,'PurgeDays',SR);
      TempGroup^.PurgeDays:=strStrToInt(sTemp);
      If GroupsCTL^.CTLError<>0 then TempGroup^.PurgeDays:=0;

      sTemp:=GroupsCTL^.FindFirstValue(i,'PurgeMsgs',SR);
      TempGroup^.PurgeMsgs:=strStrToInt(sTemp);
      If GroupsCTL^.CTLError<>0 then TempGroup^.PurgeMsgs:=0;

      sTemp:=GroupsCTL^.FindFirstValue(i,'Flags',SR);
      AssignStr(TempGroup^.Flags,strUpper(sTemp));

      sTemp:=GroupsCTL^.FindFirstValue(i,'Path',SR);
      ParserEchoType(sTemp,TempGroup);

      sTemp:=GroupsCTL^.FindFirstValue(i,'Links',SR);

      TempGroup^.UseAKA:=InvAddress;
      GroupsCTL^.FindFirstAddressValue(i,'UseAKA',TempAddress,SR);
      If GroupsCTL^.CTLError=0 then TempGroup^.UseAKA:=TempAddress;

      While GroupsCTL^.CTLError<>ctlErrCantFindParameter do
        begin
          ParserLinks(sTemp,TempGroup,True);
          sTemp:=GroupsCTL^.FindNextValue(SR);
        end;
    end;

  objDispose(GroupsCTL);
end;

Procedure ReadAnnounce;
Var
  i:integer;
  SR:CTLSR;
  sTemp:string;
  TempAnnounce : PAnnounce;

    Procedure AnnounceError(const Error:LngItems; const ErrorMessage:string);
    begin
       LngFile^.AddVar(ErrorMessage);
       objDispose(TempAnnounce);
       ErrorOut(LngFile^.GetString(LongInt(Error)));
    end;

begin
  Announces:=New(PAnnounceCollection,Init($10,$10));

  dosChangeWorkDir(Templates^.Path^);

  sTemp:=MainCTL^.FindFirstValue('Announce',SR);
  While MainCTL^.CTLError<>ctlErrCantFindParameter do
    begin
    TempAnnounce:=New(PAnnounce,Init);

    TempAnnounce^.Area:=NewStr(strUpper(strParserEx(sTemp,1,[#32],strBrackets)));

    TempAnnounce^.FromName:=NewStr(strParserEx(sTemp,2,[#32],strBrackets));
    TempAnnounce^.ToName:=NewStr(strParserEx(sTemp,4,[#32],strBrackets));

    TempAnnounce^.Subj:=NewStr(strParserEx(sTemp,6,[#32],strBrackets));

    TempAnnounce^.Template:=NewStr(dosMakeValidString(strParserEx(sTemp,7,[#32],strBrackets)));


    If Areabase^.FindArea(TempAnnounce^.Area^)=nil
      then AnnounceError(lngInvalidAnnounceArea,TempAnnounce^.Area^)
    else If (TempAnnounce^.FromName=nil) or (TempAnnounce^.FromName^='')
      then AnnounceError(lngInvalidAnnounceFromName,TempAnnounce^.Area^)
    else If (TempAnnounce^.ToName=nil) or (TempAnnounce^.ToName^='')
      then AnnounceError(lngInvalidAnnounceToName,TempAnnounce^.Area^)
    else If not ftnStrtoAddress(strParserEx(sTemp,3,[#32],strBrackets),TempAnnounce^.FromAddress)
      then AnnounceError(lngInvalidAnnounceFromAddress,TempAnnounce^.Area^)
    else If not ftnStrtoAddress(strParserEx(sTemp,5,[#32],strBrackets),TempAnnounce^.ToAddress)
      then AnnounceError(lngInvalidAnnounceToAddress,TempAnnounce^.Area^);

    Announces^.Insert(TempAnnounce);
    sTemp:=MainCTL^.FindNextValue(SR);
  end;

  dosChangeWorkDir(HomeDir);
end;

Procedure ReadArcs;
begin
  ArcEngine:=New(PArcEngine,Init(TempInboundPath));
  If not ArcEngine^.LoadConfig(HomeDir+'\compress.ctl')
         then ErrorOut(ArcEngine^.Error);
end;

Procedure ParsConfig;
Var
  SR:CTLSR;
  TempAddress : TAddress;
  AutoExportItem : PAutoExportItem;
  sTemp  : string;
  sTemp2 : string;
  i:integer;

  TempArc : PArcItem;
begin
  AddressBase:=New(PAddressBase,Init);
  MessageBasesEngine:=New(PMessageBasesEngine,Init);

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
  InitMainCTL;

  ftnClearAddress(TempAddress);

  MainCTL^.FindFirstAddressValue('Address',TempAddress,SR);
  If MainCTL^.CTLError<>0 then ErrorOut('Invalid main address');
  AddressBase^.AddAddress(TempAddress);

  MainCTL^.FindFirstAddressValue('AKA',TempAddress,SR);
  While MainCTL^.CTLError<>ctlErrCantFindParameter do
    begin
      If MainCTL^.CTLError=ctlErrInvalidParameter
          then ErrorOut('Invalid AKA');
      AddressBase^.AddAddress(TempAddress);
      MainCTL^.FindNextAddressValue(TempAddress,SR);
    end;

  SysopName:=New(PStringsCollection,Init($10,$10));

  sTemp:=MainCTL^.FindFirstValue('Sysop',SR);
  While MainCTL^.CTLError<>ctlErrCantFindParameter do
    begin
      SysopName^.Insert(NewStr(sTemp));
      sTemp:=MainCTL^.FindNextValue(SR);
    end;
  If SysopName^.Count=0 then SysopName^.Insert(NewStr('Sysop'));

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
  sTemp:=MainCTL^.FindFirstValue('HudsonPath',SR);
  If MainCTL^.CTLError=0 then
    begin
{      HudsonPath:=dosMakeValidString(sTemp);
      If not dosDirExists(HudsonPath)
         then ErrorOut('Invalid hudson path');}
    end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  ImportLists:=New(PImportLists,Init);
  sTemp:=MainCTL^.FindFirstValue('ImportList',SR);
  While MainCTL^.CTLError=0 do
    begin
      ImportLists^.AddList(strParser(sTemp,1,[#32]),strParser(sTemp,2,[#32]));
      sTemp:=MainCTL^.FindNextValue(SR);
    end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  sTemp:=MainCTL^.FindFirstValue('ExportLists',SR);
  ExportListsPath:='';
  If MainCTL^.CTLError=0 then
    begin
      ExportListsPath:=dosMakeValidString(sTemp);
      If not dosDirExists(ExportListsPath)
         then ErrorOut('Invalid export lists path');
    end;

  sTemp:=strUpper(MainCTL^.FindFirstValue('LongAutocreate',SR));
  LongAutocreate:=False;
  If sTemp='YES'then LongAutocreate:=True;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  AutoExportBase:=New(PAutoExportBase,Init($10,$10));

  sTemp:=MainCTL^.FindFirstValue('AutoExport',SR);
  While MainCTL^.CTLError=0 do
    begin
      AutoExportItem:=New(PAutoExportItem,Init);

      AutoExportItem^.FileType:=0;
      AutoExportItem^.FileName:=NewStr(strParser(sTemp,2,[#32]));
      AutoExportItem^.ShortName:=False;
      sTemp2:=strUpper(strParser(sTemp,3,[#32]));
      If sTemp2='SHORT' then AutoExportItem^.ShortName:=True;
      sTemp:=strUpper(strParser(sTemp,1,[#32]));

      If sTemp='GOLDED' then AutoExportItem^.FileType:=aetGoldEd;
      If sTemp='AREASBBS' then AutoExportItem^.FileType:=aetAreasBBS;
      If sTemp='TERMAIL' then AutoExportItem^.FileType:=aetTermail;
      If sTemp='TM-ED' then AutoExportItem^.FileType:=aetTMED;
      If sTemp='SQUISH' then AutoExportItem^.FileType:=aetSquish;
      If sTemp='MADMED' then AutoExportItem^.FileType:=aetMadMED;

      If AutoExportItem^.FileType=0 then
        begin
          objDispose(AutoExportItem);
          ErrorOut(sTemp+' is invalid autoexport type');
        end;

      AutoExportBase^.Insert(AutoExportItem);
      sTemp:=MainCTL^.FindNextValue(SR);
    end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  sTemp:=MainCTL^.FindFirstValue('LogFile',SR);
  If MainCTL^.CTLError=0
     then LogFile^.SetLogFilename(dosMakeValidString(sTemp));

  sTemp:=MainCTL^.FindFirstValue('AreafixLogFile',SR);
  If MainCTL^.CTLError=0 then
    begin
      AreafixLogFile:=New(PLogFile,Init(constProgramName+#32+constSVersion));
      AreafixLogFile^.SetLogFilename(dosMakeValidString(sTemp));
    end;

  sTemp:=MainCTL^.FindFirstValue('LogBuffer',SR);
  If MainCTL^.CTLError=0 then
    begin
      LogFile^.BuffSize:=strStrToInt(sTemp);
      If AreafixLogFile<>nil then AreafixLogFile^.BuffSize:=strStrToInt(sTemp);
    end;

  sTemp:=MainCTL^.FindFirstValue('Inbound',SR);
  If MainCTL^.CTLError<>0 then ErrorOut('Invalid inbound path');
  Inboundpath:=dosMakeValidString(sTemp);
  If not dosDirExists(InboundPath) then ErrorOut('Invalid inbound path');

  sTemp:=MainCTL^.FindFirstValue('LocalInbound',SR);
  If MainCTL^.CTLError<>0 then ErrorOut('Invalid local inbound path');
  LocalInboundPath:=dosMakeValidString(sTemp);
  If not dosDirExists(LocalInboundPath) then ErrorOut('Invalid local inbound path');
  If LocalInboundPath=InboundPath then ErrorOut('You cant use main inbound as local');

  sTemp:=MainCTL^.FindFirstValue('TempInbound',SR);
  If MainCTL^.CTLError<>0 then sTemp:=InboundPath;
  TempInboundPath:=dosMakeValidString(sTemp);
  If not dosDirExists(TempInboundPath) then ErrorOut('Invalid temp inbound path');
  If LocalInboundPath=TempInboundPath then ErrorOut('You cant use local inbound as temp');

  sTemp:=strUpper(MainCTL^.FindFirstValue('MovePackets',SR));
  If sTemp<>'NO' then TosserFlags:=TosserFlags or tsrMovePackets;

  ReadArcs;

  sTemp:=MainCTL^.FindFirstValue('QueueDir',SR);
  If MainCTL^.CTLError<>0 then ErrorOut('Invalid queue path');
  QueuePath:=dosMakeValidString(sTemp);
  If not dosDirExists(QueuePath) then ErrorOut('Invalid queue path');

  TosserOutbounds:=New(PTosserOutboundsBase,Init);

  sTemp:=MainCTL^.FindFirstValue('AMADir',SR);
  If MainCTL^.CTLError=0 then
    begin
      sTemp:=dosMakeValidString(sTemp);
      If not dosDirExists(sTemp) then ErrorOut('Invalid AMA path');
      TosserOutbounds^.AddOutbound('AMA',outAMA,sTemp);
    end;

  sTemp:=MainCTL^.FindFirstValue('BSODir',SR);
  If MainCTL^.CTLError=0 then
    begin
      sTemp:=dosMakeValidString(sTemp);
      If not dosDirExists(sTemp) then ErrorOut('Invalid BSO path');
      TosserOutbounds^.AddOutbound('BSO',outBSO,sTemp);
    end;

  sTemp:=MainCTL^.FindFirstValue('TBOXDir',SR);
  If MainCTL^.CTLError=0 then
    begin
      sTemp:=dosMakeValidString(sTemp);
      If not dosDirExists(sTemp) then ErrorOut('Invalid TBOX path');
      TosserOutbounds^.AddOutbound('TBOX',outTBOX,sTemp);
    end;

  sTemp:=MainCTL^.FindFirstValue('TLBOXDir',SR);
  If MainCTL^.CTLError=0 then
    begin
      sTemp:=dosMakeValidString(sTemp);
      If not dosDirExists(sTemp) then ErrorOut('Invalid TLBOX path');
      TosserOutbounds^.AddOutbound('TLBOX',outTLBOX,sTemp);
    end;

  sTemp:=strUpper(MainCTL^.FindFirstValue('DefaultOutbound',SR));
  If MainCTL^.CTLError<>0 then ErrorOut('Invalid or misconfigurated default outbound type');
  TosserOutbounds^.Default:=TosserOutbounds^.FindOutbound(sTemp);

  If TosserOutbounds^.Default=nil
    then ErrorOut('Invalid or misconfigurated default outbound type');

  sTemp:=strUpper(MainCTL^.FindFirstValue('BusyOutbound',SR));
  If MainCTL^.CTLError=0 then
    begin
      TosserOutbounds^.Busy:=TosserOutbounds^.FindOutbound(sTemp);
      If TosserOutbounds^.Busy=nil
         then ErrorOut('Invalid or misconfigurated busy outbound type');
    end;

  If TosserOutbounds^.Outbounds^.Count=0
     then ErrorOut('At least one outbound must be defined');

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
  sTemp:=MainCTL^.FindFirstValue('AreaFile',SR);
  AreaFileName:=nil;
  If MainCTL^.CTLError=0
    then AssignStr(AreaFileName,dosMakeValidString(sTemp));

  sTemp:=MainCTL^.FindFirstValue('DataPath',SR);
  If MainCTL^.CTLError=0
    then AssignStr(DataPath,dosMakeValidString(sTemp))
  else AssignStr(DataPath,HomeDir);
  If not dosDirExists(DataPath^) then ErrorOut('Invalid data dir');

  sTemp:=MainCTL^.FindFirstValue('RouteFile',SR);
  RouteFileName:=nil;
  If MainCTL^.CTLError=0 then
    begin
      AssignStr(RouteFileName,dosMakeValidString(sTemp));
      If not dosFileExists(RouteFileName^) then ErrorOut('Invalid route file');

      Router:=New(PRouter,Init(RouteFileName^));
    end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  RulesBase:=New(PRulesBase,Init);

  sTemp:=MainCTL^.FindFirstValue('RulesDir',SR);
  While MainCTL^.CTLError<>ctlErrCantFindParameter do
    begin
      RulesBase^.RulesDirs^.Insert(NewStr(sTemp));
      sTemp:=MainCTL^.FindNextValue(SR);
    end;

  sTemp:=MainCTL^.FindFirstValue('RulesId',SR);
  While MainCTL^.CTLError<>ctlErrCantFindParameter do
    begin
      RulesBase^.RulesId^.Insert(NewStr(sTemp));
      sTemp:=MainCTL^.FindNextValue(SR);
    end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  sTemp:=strUpper(MainCTL^.FindFirstValue('KillAfterImport',SR));
  KillAfterImport:=True;
  If sTemp='NO'then KillAfterImport:=False;

  sTemp:=strUpper(MainCTL^.FindFirstValue('KillAfterRoute',SR));
  KillAfterRoute:=True;
  If sTemp='NO'then KillAfterRoute:=False;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  sTemp:=MainCTL^.FindFirstValue('MsgSplitSize',SR);
  If sTemp='' then sTemp:='0';
  MsgSplitSize:=strStrToInt(sTemp);

  Origins:=New(PStringsCollection,Init($10,$10));

  sTemp:=MainCTL^.FindFirstValue('Origin',SR);
  While MainCTL^.CTLError<>ctlErrCantFindParameter do
    begin
      Origins^.Insert(NewStr(sTemp));
      sTemp:=MainCTL^.FindNextValue(SR);
    end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  sTemp:=MainCTL^.FindFirstValue('DefaultArchiver',SR);
  If MainCTL^.CTLError<>0 then ErrorOut('Invalid default archiver type');
  DefaultArchiver:=strUpper(sTemp);
  If DefaultArchiver<>'NONE' then
    If ArcEngine^.FindArcName(DefaultArchiver)=-1
       then ErrorOut('Invalid default archiver type');

  sTemp:=MainCTL^.FindFirstValue('MaxPktSize',SR);
  If sTemp='' then sTemp:='30000';
  MaxPktSize:=strStrToInt(sTemp);

  sTemp:=MainCTL^.FindFirstValue('MaxArcSize',SR);
  If sTemp='' then sTemp:='200000';
  MaxArcSize:=strStrToInt(sTemp);

  sTemp:=MainCTL^.FindFirstValue('BeforePack',SR);
  BeforePack:='';
  If MainCTL^.CTLError=0 then BeforePack:=dosMakeValidString(sTemp);

  sTemp:=MainCTL^.FindFirstValue('AfterPack',SR);
  AfterPack:='';
  If MainCTL^.CTLError=0 then AfterPack:=dosMakeValidString(sTemp);

  sTemp:=MainCTL^.FindFirstValue('BeforeUnPack',SR);
  BeforeUnPack:='';
  If MainCTL^.CTLError=0 then BeforeUnPack:=dosMakeValidString(sTemp);

  sTemp:=MainCTL^.FindFirstValue('AfterUnPack',SR);
  AfterUnPack:='';
  If MainCTL^.CTLError=0 then AfterUnPack:=dosMakeValidString(sTemp);

  sTemp:=MainCTL^.FindFirstValue('AfterScan',SR);
  AfterScan:='';
  If MainCTL^.CTLError=0 then AfterScan:=dosMakeValidString(sTemp);

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  DefaultGroups:=strUpper(MainCTL^.FindFirstValue('DefaultGroups',SR));
  If MainCTL^.CTLError=0
        then DefaultGroups:='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  Templates:=New(PTemplatesBase, Init);

  sTemp:=MainCTL^.FindFirstValue('TemplatesDir',SR);
  If MainCTL^.CTLError<>0 then ErrorOut('Invalid templates path');
  Templates^.Path:=NewStr(dosMakeValidString(sTemp));
  If not dosDirExists(Templates^.Path^) then ErrorOut('Invalid templates path');

  dosChangeWorkDir(Templates^.Path^);

  sTemp:=MainCTL^.FindFirstValue('ListTPL',SR);
  If MainCTL^.CTLError<>0 then ErrorOut('Invalid echolist template');
  Templates^.List:=NewStr(dosMakeValidString(sTemp));
  If not dosFileExists(Templates^.List^) then ErrorOut('Invalid echolist template');

  sTemp:=MainCTL^.FindFirstValue('RulesListTPL',SR);
  If MainCTL^.CTLError<>0 then ErrorOut('Invalid rules list template');
  Templates^.RulesList:=NewStr(dosMakeValidString(sTemp));
  If not dosFileExists(Templates^.RulesList^) then ErrorOut('Invalid rules list template');

  sTemp:=MainCTL^.FindFirstValue('HelpTPL',SR);
  If MainCTL^.CTLError<>0 then ErrorOut('Invalid areafix help template');
  Templates^.Help:=NewStr(dosMakeValidString(sTemp));
  If not dosFileExists(Templates^.Help^) then ErrorOut('Invalid areafix help template');

  sTemp:=MainCTL^.FindFirstValue('QueryTPL',SR);
  If MainCTL^.CTLError<>0 then ErrorOut('Invalid query template');
  Templates^.Query:=NewStr(dosMakeValidString(sTemp));
  If not dosFileExists(Templates^.Query^) then ErrorOut('Invalid query template');

  sTemp:=MainCTL^.FindFirstValue('UnlinkedTPL',SR);
  If MainCTL^.CTLError<>0 then ErrorOut('Invalid unlinked template');
  Templates^.Unlinked:=NewStr(dosMakeValidString(sTemp));
  If not dosFileExists(Templates^.Unlinked^) then ErrorOut('Invalid unlinked template');

  sTemp:=MainCTL^.FindFirstValue('AvailTPL',SR);
  If MainCTL^.CTLError<>0 then ErrorOut('Invalid avail list template');
  Templates^.Avail:=NewStr(dosMakeValidString(sTemp));
  If not dosFileExists(Templates^.Avail^) then ErrorOut('Invalid avail list template');

  sTemp:=MainCTL^.FindFirstValue('CompressTPL',SR);
  If MainCTL^.CTLError<>0 then ErrorOut('Invalid compress list template');
  Templates^.Compress:=NewStr(dosMakeValidString(sTemp));
  If not dosFileExists(Templates^.Compress^) then ErrorOut('Invalid compress list template');

  sTemp:=MainCTL^.FindFirstValue('BadPassTPL',SR);
  If MainCTL^.CTLError<>0 then ErrorOut('Invalid bad password template');
  Templates^.BadPass:=NewStr(dosMakeValidString(sTemp));
  If not dosFileExists(Templates^.BadPass^) then ErrorOut('Invalid bad password template');

  sTemp:=MainCTL^.FindFirstValue('BadNodeTPL',SR);
  If MainCTL^.CTLError<>0 then ErrorOut('Invalid bad node template');
  Templates^.BadNode:=NewStr(dosMakeValidString(sTemp));
  If not dosFileExists(Templates^.BadNode^) then ErrorOut('Invalid bad node template');

  dosChangeWorkDir(HomeDir);

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  sTemp:=MainCTL^.FindFirstValue('AutoDesc',SR);
  If MainCTL^.CTLError=0 then
    begin
      ParserArealist(sTemp,DefEcholist);

      If not dosFileExists(DefEcholist.Path)
          then ErrorOut('Invalid auto description file');

      If DefEcholist.ListType=ltUnknown
          then ErrorOut('Invalid auto description file');
    end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  sTemp:=MainCTL^.FindFirstValue('MaxDupes',SR);
  If sTemp='' then sTemp:='32000';
  MaxDupes:=strStrToInt(sTemp);

  sTemp:=strUpper(MainCTL^.FindFirstValue('FlushBuffers',SR));
  If sTemp='' then TosserFlags:=TosserFlags or tsrFlushPkt or tsrFlushBase else
    begin
      If sTemp='IN'  then TosserFlags:=TosserFlags or tsrFlushBase else
      If sTemp='OUT' then TosserFlags:=TosserFlags or tsrFlushPkt  else
      If sTemp='ALLWAYS' then TosserFlags:=TosserFlags or tsrFlushPkt or tsrFlushBase else
      If sTemp='NEVER' then TosserFlags:=TosserFlags else
      ErrorOut('Invalid FlushBuffers value');
    end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  ReadNodes;
  ReadGroups;
  ReadUplinks;
  ReadAreas;

  EchoQueue:=New(PEchoQueue,Init);

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  sTemp:=MainCTL^.FindFirstValue('Netmail',SR);
  If MainCTL^.CTLError<>0 then ErrorOut('Invalid netmail base');

  NetmailArea:=AreaBase^.FindArea(sTemp);
  If NetmailArea=nil then ErrorOut('Invalid netmail base');

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  Areafix:=New(PAreafix,Init);

  sTemp:=MainCTL^.FindFirstValue('AreafixIn',SR);
  If MainCTL^.CTLError<>0 then Areafix^.AreafixIn:=NetmailArea else
    begin
      Areafix^.AreafixIn:=AreaBase^.FindArea(sTemp);
      If Areafix^.AreafixIn=nil then ErrorOut('Invalid areafix in base');
    end;

  sTemp:=MainCTL^.FindFirstValue('AreafixOut',SR);
  If MainCTL^.CTLError<>0 then Areafix^.AreafixOut:=Areafix^.AreafixIn else
    begin
      Areafix^.AreafixOut:=AreaBase^.FindArea(sTemp);
      If Areafix^.AreafixOut=nil then ErrorOut('Invalid areafix out base');
    end;

  sTemp:=strUpper(MainCTL^.FindFirstValue('AvailArcs',SR));
  If MainCTL^.CTLError=0 then
    begin
      For i:=1 to strNumbOfTokens(sTemp,[#32]) do
        begin
          sTemp2:=strParser(sTemp,i,[#32]);
          If ArcEngine^.FindArcName(sTemp2)=-1 then
            begin
              LngFile^.AddVar(sTemp2);
              ErrorOut(LngFile^.GetString(LongInt(lngInvalidAreafixArc)));
            end;
          Areafix^.AvailArcs^.Insert(NewStr(sTemp2));
        end;
    end
    else
    begin
      For i:=0 to ArcEngine^.Arcbase^.Count-1 do
        begin
          TempArc:=ArcEngine^.Arcbase^.At(i);
          Areafix^.AvailArcs^.Insert(NewStr(TempArc^.Name^));
        end;
    end;

  sTemp:=MainCTL^.FindFirstValue('PreserveRequests',SR);
  Areafix^.ForwardFile^.ExpireDays:=strStrToInt(sTemp);

  sTemp:=strUpper(MainCTL^.FindFirstValue('KeepRequests',SR));
  If sTemp='YES'then Areafix^.Flags:=Areafix^.Flags or afxKeepRequests;

  sTemp:=strUpper(MainCTL^.FindFirstValue('KeepReceipts',SR));
  KeepReceipts:=False;
  If sTemp='YES'then KeepReceipts:=True;

  Areafix^.CopyArea:=nil;
  sTemp:=MainCTL^.FindFirstValue('CopyRequests',SR);
  If MainCTL^.CTLError=0 then
    begin
      Areafix^.CopyArea:=AreaBase^.FindArea(sTemp);
      If Areafix^.CopyArea=nil then ErrorOut('Invalid areafix copy base');
    end;

  sTemp:=MainCTL^.FindFirstValue('Alias',SR);
  While MainCTL^.CTLError=0 do
    begin
      Areafix^.Aliases^.Insert(NewStr(strUpper(sTemp)));
      sTemp:=MainCTL^.FindNextValue(SR);
    end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  ScriptsEngine:=New(PScriptsEngine,Init);

  sTemp:=MainCTL^.FindFirstValue('ScriptsDir',SR);
  If MainCTL^.CTLError=0 then
    begin
      AssignStr(ScriptsEngine^.ScriptsDir,dosMakeValidString(sTemp));
      If not dosDirExists(ScriptsEngine^.ScriptsDir^)
        then ErrorOut('Invalid scripts dir');
    end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

{  ReadNetmails;}
  ReadAnnounce;

  objDispose(MainCTL);

  SortNodes(NodeBase);
end;

Procedure InitMacroEngine;
begin
  MacroEngine:=New(PMacroEngine,Init);
  MacroModifier:=New(PMacroModifier,Init);

  MacroEngine^.AddMacro('PID',constPid,True);

  MacroEngine^.AddMacro('OADDRESS','',True);
  MacroEngine^.AddMacro('DADDRESS','',True);
  MacroEngine^.AddMacro('ADDRESS','',True);

  MacroEngine^.AddMacro('GROUPNAME','',True);
  MacroEngine^.AddMacro('GROUPDESC','',True);

  MacroEngine^.AddMacro('AREANAME','',True);
  MacroEngine^.AddMacro('AREADESC','',True);

  MacroEngine^.AddMacro('ARCNAME','',True);
  MacroEngine^.AddMacro('CURRENTARC','',True);

  MacroEngine^.AddMacro('DATE','',True);
  MacroEngine^.AddMacro('TIME','',True);

  MacroEngine^.AddMacro('MODE','',True);
end;

begin
{$IFDEF FORCEHOMEDIR}
  HomeDir:='x:\fido\spctoss';
  WorkDir:='x:\fido\spctoss';
{  HomeDir:='C:\FIDO\SPCT';
  WorkDir:='C:\FIDO\SPCT';}
{$ENDIF}

  Intro;

{$IFDEF WARNING}
  WriteLn('                            WARNING!');
  WriteLn('This version was compiled only for testing!');
  WriteLn('It can damage your data!');
  WriteLn('Press Ctrl-C for abort.');
  Writeln;
  WriteLn('                          ‚ˆŒ€ˆ…!');
  WriteLn('â  ¢¥àá¨ï ¡ë«  áª®¬¯¨«¨à®¢ ­  â®«ìª® ¤«ï â¥áâ¨à®¢ ­¨ï!');
  WriteLn('­  ¬®¦¥â ¯®¢à¥¤¨âì ¢ è ¤ ­­ë¥.');
  WriteLn(' ¦¬¨â¥ Ctrl-C, çâ®¡ ¯à¥à¢ âì ¢ë¯®«­¥­¨¥.');
  readln;
{$ENDIF}

  InitObjects;

  LngFile:=New(PLngFile,Init(HomeDir+'\SPCTOSS.LNG','SPACETOSS',strStrToInt(sBuild)));
  LngFile^.LoadFile;
  If LngFile^.Status<>lngNone
            then ErrorOut('Invalid version of resource file');

  If ParamCount=0 then Help;

{$IFNDEF NOFLAG}
  OpenFlag;
{$ENDIF}

  ParamString:=New(PParamString,Init);
  ParamString^.KeyChar:=['-'];
  ParamString^.Read;

  If ParamString^.Command=nil then help;

  If (strUpper(ParamString^.Command^)<>'TOSS')
   and (strUpper(ParamString^.Command^)<>'SCAN')
   and (strUpper(ParamString^.Command^)<>'ROUTE')
   and (strUpper(ParamString^.Command^)<>'PACK')
   and (strUpper(ParamString^.Command^)<>'PURGE')
   and (strUpper(ParamString^.Command^)<>'MGR')
   and (strUpper(ParamString^.Command^)<>'HAND')
   and (strUpper(ParamString^.Command^)<>'CHECK')
   and (strUpper(ParamString^.Command^)<>'DESC')
   then help;

  If ParamString^.CheckParameter('?') then
    begin
      If strUpper(ParamString^.Command^)='TOSS'
             then HelpToss;
      If strUpper(ParamString^.Command^)='SCAN'
             then HelpScan;
      If strUpper(ParamString^.Command^)='IMPORT'
             then HelpImport;
      If strUpper(ParamString^.Command^)='PURGE'
             then HelpPurge;
      If strUpper(ParamString^.Command^)='PACK'
             then HelpPack;
      If strUpper(ParamString^.Command^)='HAND'
             then HelpHand;
      If strUpper(ParamString^.Command^)='DESC'
             then HelpDesc;
      Help;
    end;

  LogFile:=New(PLogFile,Init(constProgramName+#32+constSVersion));
  LogFile^.SetLogFilename(HomeDir+'\spctoss.log');

  SLoadWrite(LngFile^.GetString(LongInt(lngReadConf)));
  ParsConfig;
  SLoadOk;

  ScriptsEngine^.LoadScripts;

  TextColor(7);

  InitMacroEngine;

  Writeln;

  LogFile^.SetLogMode(strUpper(ParamString^.Command^));

  LogFile^.Open;
  If LogFile^.Status<>logOk
     Then ErrorOut(LogFile^.ExplainStatus(LogFile^.Status));

  AnnouncesStack:=New(PAnnounceTaskCollection,Init($10,$10));

  LogFile^.SendStr(LngFile^.GetString(LongInt(lngConfLoaded)),#32);

  If strUpper(ParamString^.Command^)='TOSS' then
    begin
      If ParamString^.CheckKey('S')
           then TosserFlags:=TosserFlags or tsrUnSecure;
      If not ParamString^.CheckKey('P')
           then TosserFlags:=TosserFlags or tsrRunProcesses;

      Tosser:=New(PTosser,Init(TosserFlags));
      Tosser^.Toss;
      objDispose(Tosser);
    end;

  If strUpper(ParamString^.Command^)='SCAN' then
    begin
      Scanner:=New(PScanner,Init(0,AreaBase^.Echomail));

      If ParamString^.CheckKey('H')
           then Scanner^.Flags:=Scanner^.Flags or scnDontUseHighwaters;

      Scanner^.Scan;
      objDispose(Scanner);
    end;

  If strUpper(ParamString^.Command^)='ROUTE' then
    begin
      If Router<>nil then Router^.Route;
      objDispose(Router);
    end;

  If strUpper(ParamString^.Command^)='PURGE' then
    begin
      Purger:=New(PPurger,Init);
      Purger^.Purge;
      objDispose(Purger);
    end;

  If strUpper(ParamString^.Command^)='PACK' then
    begin
      Packer:=New(PPacker,Init);
      Packer^.Pack;
      objDispose(Packer);
    end;

  If strUpper(ParamString^.Command^)='IMPORT' then
    begin
      NetmailManager:=New(PNetmailManager,Init);
      NetmailManager^.DoImport;
      objDispose(NetmailManager);
    end;

  If strUpper(ParamString^.Command^)='EXPORT' then
    begin
      NetmailManager:=New(PNetmailManager,Init);
      NetmailManager^.DoExport;
      objDispose(NetmailManager);
    end;

  If strUpper(ParamString^.Command^)='MGR'
           then Areafix^.ScanNetmail;

  If strUpper(ParamString^.Command^)='HAND'
           then DoHand;

  If strUpper(ParamString^.Command^)='DESC' then
    begin
      Descer:=New(PDescer,Init);
      Descer^.Desc;
      objDispose(Descer);
    end;

  If NodeBase^.Modified then WriteNodeFile;

  objDispose(Areafix);

  AutoExportAll;

  FreeObjects;
end.
