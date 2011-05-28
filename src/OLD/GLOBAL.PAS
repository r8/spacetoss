{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit Global;

interface

Uses
  r8lng,
  lng,

  r8const,
  r8dos,
  r8dtm,
  objects,
  pqueue,
  equeue,
  areas,
  rules,
  afix,
  groups,
  nodes,
  uplinks,
  r8pstr,
  r8str,
  r8log,
  r8arc,
  r8objs,
  r8pkt,
  r8ftn,
  r8crt,
  r8ctl,
  r8out,
  r8mail,
  r8mcr,
  macro,

  Crt,
  autexprt,
  netmail,
  dupe,
  announce,
  ilist,
  sort,

  scripts,
  toss,
  scan,
  purge,
  pack,

  r8mbe,

  r8alst,
  r8elst,
  r8felst,
  r8bcl,
  r8xofl,


  r8tbox,
  r8tlbox,
  r8ama,
  r8bso;

Type

  TTemplatesBase = object(TObject)
    Path : PString;

    NewEchoFromUplink : PString;

    List : PString;
    RulesList : PString;
    Help : PString;
    Query : PString;
    Unlinked : PString;
    Avail : PString;
    Rules : PString;
    Compress : PString;
    BadPass  : PString;
    BadNode  : PString;

    Constructor Init;
    Destructor  Done; virtual;
  end;

  PTemplatesBase = ^TTemplatesBase;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

{$i build.inc}

const
  constProgramName = 'SpaceToss';
  constVersion = '1.0.11';
  constSVersion = constVersion+'.'+sBuild;
{  constSVersion = constVersion+'.'+sBuild+'/XMassEdition';}
  constLongLine = 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ';
  constPID = constProgramName+'/'+cstrOsId+' v'+constSVersion;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Var
  LngFile : PLngFile;

  ParamString : PParamString;
  LogFile : PLogFile;
  AreafixLogFile : PLogFile;

  RouteFileName : PString;
  AreaFileName  : PString;
  DataPath : PString;

  MainCTL : PCTLFile;
  AreasCTL : PSectionCTL;
  GroupsCTL : PSectionCTL;
  NodesCTL : PSectionCTL;
  UplinksCTL : PSectionCTL;
  NetmailCTL : PSectionCTL;

  AddressBase : PAddressBase;
  AreaBase : PAreaBase;
  RulesBase : PRulesBase;
  GroupBase : PGroupBase;
  NodeBase : PNodeBase;
  UplinkBase : PUplinkBase;
  AutoExportBase : PAutoExportBase;

  SysopName : PStringsCollection;
  Origins    : PStringsCollection;

  InboundPath : string;
  LocalInboundPath : string;
  TempInboundPath : string;
  InboundDir : PPktDir;
  QueuePath : string;

  ArcEngine : PArcEngine;
  MessageBasesEngine : PMessageBasesEngine;
  EchoQueue : PEchoQueue;

  DefaultArchiver : string[10];

  MaxPktSize : longint;
  MaxArcSize : longint;
  MaxDupes : longint;

  BeforePack : string;
  BeforeUnPack : string;
  AfterPack : string;
  AfterUnPack : string;
  AfterScan : string;

  PresentOuts : word;

  AMA : PAMA;
  AMAPath : string;

  BSO : PBSO;
  BSOPath : string;

  TBOX : PTBOX;
  TBOXPath : string;

  TLBOX : PTLBOX;
  TLBOXPath : string;

  DefOut : POutbound;

  NetmailArea : PArea;

  EchoBase   : PMessageBase;

  Areafix :PAreafix;
  Tosser : PTosser;
  Scanner : PScanner;
  Purger : PPurger;
  Packer : PPacker;

  ScriptsEngine : PScriptsEngine;

  LongAutoCreate : boolean;

  DefaultPurgeDays : integer;
  DefaultPurgeMsgs : integer;

  Templates : PTemplatesBase;
  NetmailBase : PNetmailbase;

  DefaultGroups : string[50];

  MacroEngine : PMacroEngine;
  MacroModifier : PMacroModifier;

  AutoDesc : string;
  AutoDescType : word;
  DefEcholist : TArealistRec;

  ImportLists : PImportLists;

  ExportListsPath : string;

  Announces : PAnnounceCollection;
  AnnouncesStack : PAnnounceTaskCollection;

  PreserveRequests : integer;

  MsgSplitSize : longint;

  KeepReceipts  : boolean;
  CopyRequests  : string;
  KillAfterImport : boolean;
  KillAfterRoute  : boolean;

  TosserFlags : longint;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure SLoadWrite(S:string);
Procedure SLoadOK;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure ErrorOut(s:string);

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure InitObjects;
Procedure FreeObjects;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
Procedure NodeList(S:PStream;Nodes:PNodeList;
         FirstWord:string;ShowZone:boolean;RO,WO,LO,PS:string);

Procedure MakeSeenbys(S:PStream;Addresses:PAddressCollection);
Procedure MakePaths(S:PStream;Addresses:PAddressCollection);

Function ValidLink(Address:TAddress;Node:PObject):boolean;

Procedure ParserEchoType(S:string;Area:PArea);
Procedure ParserArealist(S:string;var Arealist:TArealistRec);

Procedure OpenOutbounds;
Procedure CloseOutbounds;

Procedure CheckAreasForPassive;

Procedure LoadDefEcholist;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure SortNodes(NodeBase:PNodeBase);
Procedure SortNodelist(Nodelist:PNodelist);
Procedure SortLinks;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

implementation
Uses
  flag;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure SLoadWrite(S:string);
begin
  Write('  ');
  TextColor(7);
  Write(S,':');
  GotoXY(66,WhereY);
  Write('[    ]');
end;

Procedure SLoadOK;
begin
  GotoXY(68,WhereY);
  TextColor(10);
  WriteLn('OK');
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure ErrorOut(s:string);
begin
  TextColor(4);
  TextBackGround(0);
  WriteLn;
  WriteLn;
  WriteLn('  ',S,'!');
  TextColor(7);
  WriteLn(' ');
  crtShowCursor;
  FreeObjects;
  Halt(255);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure InitObjects;
begin
  LngFile:=nil;

  LogFile:=nil;
  AreafixLogFile:=nil;
  ParamString:=nil;

  MainCTL:=nil;
  AreasCTL:=nil;
  NodesCTL:=nil;
  GroupsCTL:=nil;
  UplinksCTL:=nil;
  NetmailCTL:=nil;

  AddressBase:=nil;
  AreaBase:=nil;
  RulesBase:=nil;
  NodeBase:=nil;
  GroupBase:=nil;
  UplinkBase:=nil;
  NetmailBase:=nil;
  AutoExportBase:=nil;
  NetmailArea:=nil;

  EchoBase:=nil;

  Areafix:=nil;
  Tosser:=nil;

  InboundDir:=nil;
  ArcEngine:=nil;
  MessageBasesEngine:=nil;
  Announces:=nil;
  AnnouncesStack:=nil;

  SysopName:=nil;
  Origins:=nil;

  EchoQueue:=nil;

  Templates:=nil;

  AMA:=nil;
  BSO:=nil;
  TBOX:=nil;
  TLBOX:=nil;
  DefOut:=nil;

  ImportLists:=nil;

  MacroEngine:=nil;
  MacroModifier:=nil;

  ScriptsEngine:=nil;

  TosserFlags:=0;
end;

Procedure FreeObjects;
begin
  objDispose(ArcEngine);
  objDispose(Areafix);

  objDispose(ParamString);

  objDispose(MainCTL);
  objDispose(AreasCTL);
  objDispose(NodesCTL);
  objDispose(GroupsCTL);
  objDispose(UplinksCTL);
  objDispose(NetmailCTL);

  objDispose(UplinkBase);
  objDispose(EchoQueue);
  objDispose(AreaBase);
  objDispose(RulesBase);
  objDispose(NodeBase);
  objDispose(GroupBase);
  objDispose(NetmailBase);
  objDispose(AutoExportBase);
  objDispose(AddressBase);

  objDispose(SysopName);
  objDispose(Origins);

  objDispose(ImportLists);

  objDispose(Tosser);

  objDispose(Announces);
  objDispose(AnnouncesStack);

  objDispose(InboundDir);

  objDispose(AMA);
  objDispose(BSO);
  objDispose(TBOX);
  objDispose(TLBOX);

  objDispose(MacroEngine);
  objDispose(MacroModifier);

  objDispose(Templates);

  If DefEcholist.ListType<>ltNone then objDispose(DefEcholist.List);

  objDispose(LogFile);
  objDispose(AreafixLogFile);

  objDispose(LngFile);

  objDispose(MessageBasesEngine);
  objDispose(ScriptsEngine);

  DisposeStr(DataPath);
  DisposeStr(AreaFileName);
  DisposeStr(RouteFileName);
  CloseFlag;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Function ValidLink(Address:TAddress;Node:PObject):boolean;
begin
  ValidLink:=ftnAddressCompare(Address,PNode(Node)^.Address)=0;
end;

Procedure NodeList(S:PStream;Nodes:PNodeList;
         FirstWord:string;ShowZone:boolean;RO,WO,LO,PS:string);
Var
  sTemp : string;
  sTemp1 : string;
  i:integer;
  TempNodeList:PNodelistItem;
  TempNode:PNode;
  PrevAddress : TAddress;
begin

 If FirstWord<>'' then
  objStreamWrite(S,FirstWord);

  PrevAddress.Zone:=-1;
  PrevAddress.Net:=-1;
  PrevAddress.Node:=-1;
  PrevAddress.Point:=-1;

  sTemp1:='';

  For i:=0 to Nodes^.Count-1 do
    begin
      TempNodeList:=Nodes^.At(i);
      TempNode:=PNode(TempNodeList^.Node);
      sTemp:='';
      If ShowZone then
        If TempNode^.Address.Zone<>PrevAddress.Zone
          then sTemp:=sTemp+strIntToStr(TempNode^.Address.Zone)+':';
     If TempNode^.Address.Net<>PrevAddress.Net
       then sTemp:=sTemp+strIntToStr(TempNode^.Address.Net)+'/';
     If TempNode^.Address.Node<>PrevAddress.Node
       then sTemp:=sTemp+strIntToStr(TempNode^.Address.Node);
     If (TempNode^.Address.Point<>PrevAddress.point) and (TempNode^.Address.Point<>0)
       then sTemp:=sTemp+'.'+strIntToStr(TempNode^.Address.Point);

   If FirstWord<>'' then
     If Length(sTemp)+Length(sTemp1)+Length(FirstWord)>78 then
       begin
         objStreamWrite(S,sTemp1);
         sTemp1:='';
         objStreamWrite(S,#13+FirstWord);

         sTemp:=ftnAddressToStr(TempNode^.Address);
       end;


     sTemp:=sTemp+#32;

     If LO<>#0 then
       If (TempNodeList^.Mode and modLocked)=modLocked then sTemp:=LO+sTemp;

     If PS<>#0 then
       If (TempNodeList^.Mode and modPassive)=modPassive then sTemp:=PS+sTemp;

     If RO<>#0 then
       If ((TempNodeList^.Mode and modRead)=modRead) and
          ((TempNodeList^.Mode and modWrite)<>modWrite)
              then sTemp:=RO+sTemp;

     If WO<>#0 then
       If ((TempNodeList^.Mode and modRead)<>modRead) and
          ((TempNodeList^.Mode and modWrite)=modWrite)
              then sTemp:=WO+sTemp;

     sTemp1:=sTemp1+sTemp;
     PrevAddress:=TempNode^.Address;
    end;
  objStreamWrite(S,sTemp1);
  objStreamWrite(S,#13);
end;

Procedure MakeSeenbys(S:PStream;Addresses:PAddressCollection);
begin
  S^.Reset;
  S^.Seek(0);
  S^.Truncate;

  ftnAddressList(S,Addresses,'SEEN-BY: ',False,78);
end;

Procedure MakePaths(S:PStream;Addresses:PAddressCollection);
begin
  S^.Reset;
  S^.Seek(0);
  S^.Truncate;

  ftnAddressList(S,Addresses,#1'PATH: ',False,78);
end;

Procedure ParserEchoType(S:string;Area:PArea);
begin

  Area^.EchoType.Storage:=etPassThrough;

  If S='' then exit;

  Area^.EchoType.Path:=S;

  S:=strUpper(S);

  S:=Copy(S,1,3);

  If S='MSG' then Area^.EchoType.Storage:=etMSG
  else
  If S='SQH' then Area^.EchoType.Storage:=etSquish
  else
  If S='JAM' then Area^.EchoType.Storage:=etJAM
{  else
  If S='SMB' then Area^.EchoType.Storage:=etSMB
  else
  If S='HUD' then Area^.EchoType.Storage:=etHudson}
  else ErrorOut(Area^.Name^+': Invalid echotype');

end;

Procedure ParserArealist(S:string;var Arealist:TArealistRec);
begin
  Arealist.ListType:=ltNone;

  Arealist.Path:=dosMakeValidString(strParser(S,2,[#32]));

  S:=strUpper(strParser(S,1,[#32]));

  If S='ECHOLIST' then Arealist.ListType:=ltEcholist else
  If S='BCL' then Arealist.ListType:=ltBCL else
  If S='FASTECHO' then Arealist.ListType:=ltFastecho else
  If S='XOFCELIST' then Arealist.ListType:=ltxOfcEList else
  If S='SQUISH' then Arealist.ListType:=ltSquish else
      Arealist.ListType:=ltUnknown;
end;

Procedure LoadDefEcholist;
begin
  Case DefEcholist.ListType of
    ltEchoList : DefEcholist.List:=New(PEchoList,Init);
    ltBCL      : DefEcholist.List:=New(PBCL,Init);
    ltFastecho : DefEcholist.List:=New(PFeList,Init);
    ltXOfcEList: DefEcholist.List:=New(PxOfcEList,Init);
  end;

  DefEcholist.List^.SetFilename(DefEcholist.Path);
  DefEcholist.List^.Read;
end;

Procedure SortAreas(AreaBase:PAreaBase);
begin
  If AreaBase^.Areas^.Count<2 then exit;
  srtSort(0,AreaBase^.Areas^.Count-1,AreaBase^.Areas,srtCompareAreas);
end;

Procedure SortNodes(NodeBase:PNodeBase);
begin
  If NodeBase^.Nodes^.Count<2 then exit;
  srtSort(0,NodeBase^.Nodes^.Count-1,NodeBase^.Nodes,srtCompareNodes);
end;

Procedure SortNodelist(Nodelist:PNodelist);
begin
  If Nodelist^.Count<2 then exit;
  srtSort(0,Nodelist^.Count-1,Nodelist,srtCompareNodelists);
end;

Procedure SortLinks;
Var
  TempArea : PArea;
  i:integer;
begin
  For i:=0 to AreaBase^.Areas^.Count-1 do
    begin
      TempArea:=AreaBase^.Areas^.At(i);
      SortNodelist(TempArea^.Links);
    end;
end;

Procedure OpenOutbounds;
begin
{  If AMA<>nil then AMA^.OpenDir(AMAPath);}
  If BSO<>nil then BSO^.OpenDir(BSOPath);
  If TBOX<>nil then TBOX^.OpenDir(TBOXPath);
  If TLBOX<>nil then TLBOX^.OpenDir(TLBOXPath);
end;

Procedure CloseOutbounds;
begin
  objDispose(AMA);
  objDispose(BSO);
  objDispose(TBOX);
  objDispose(TLBOX);
end;

Procedure CheckAreasForPassive;

  Procedure CheckArea(Area:PArea);far;
  Var
    TempLink : PNodelistItem;
    TempNode : PNode;
    TempUplink : PUplink;
    i : longint;
    i2 : longint;
    UplinkCount : longint;
  begin
    If Area^.CheckFlag('P') then exit;
    If Area^.Echotype.Storage<>etPassthrough then exit;

    UplinkCount:=0;
    TempUpLink:=nil;

    For i:=0 to Area^.Links^.Count-1 do
      begin
        TempLink:=Area^.Links^.At(i);
        TempNode:=PNode(TempLink^.Node);

        TempUplink:=UplinkBase^.FindUplink(TempNode^.Address);

        If TempUplink<>nil then
          begin
            Inc(UplinkCount);
            continue;
          end;

        If not TempNode^.CheckFlag('P') then exit;
      end;

    If (UplinkCount>1) or (TempUplink=nil) then exit;

    TempUplink^.Requests^.Insert(NewStr('-'+Area^.Name^));
    Area^.SetFlag('P');

    Writeln('Area ',Area^.Name^,' set to passive...');
    Logfile^.SendStr('Area '+Area^.Name^+' set to passive.',' ');

    AreaBase^.Modified:=true;
  end;

begin
  AreaBase^.EchoMail^.ForEach(@CheckArea);
end;


Constructor TTemplatesBase.Init;
begin
  inherited Init;

  Path:=nil;
  NewEchoFromUplink:=nil;
  RulesList:=nil;
  List:=nil;
  Help:=nil;
  Query:=nil;
  Unlinked:=nil;
  Avail:=nil;
  Rules:=nil;
  Compress:=nil;
  BadPass:=nil;
  BadNode:=nil;
end;

Destructor  TTemplatesBase.Done;
begin
  DisposeStr(Path);
  DisposeStr(NewEchoFromUplink);
  DisposeStr(List);
  DisposeStr(RulesList);
  DisposeStr(Help);
  DisposeStr(Query);
  DisposeStr(Unlinked);
  DisposeStr(Avail);
  DisposeStr(Rules);
  DisposeStr(Compress);
  DisposeStr(BadPass);
  DisposeStr(BadNode);

  inherited Done;
end;

end.
