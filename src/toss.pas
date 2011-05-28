{
 Tosser Engine for SpaceToss
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.

 cant open badmail/dupemail на cantopenbase
}
Unit Toss;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}
{$B-}
interface

Uses
  r8ftn,
  color,
  lng,

  arc,
  afix,
  bats,
  nodes,
  areas,
  uplinks,
  count,
  dupe,
  bad,

  equeue,
  pqueue,

  acreate,

  r8dos,
  r8pkt,
  r8objs,
  r8ftspc,
  r8str,
  r8abs,
  r8mail,
  r8msgb,

  r8alst,
  r8bcl,

  crt,
  dos,
  objects;

const

  tsrOk = $00000000;

  tsrProtectedPkt = $00000001;
  tsrRenameToSec  = $00000002;
  tsrMovePackets  = $00000004;
  tsrUnSecure     = $00000008;
  tsrRunProcesses = $00000020;
  tsrScanning     = $00000040;
  tsrFlushPkt     = $00000100;
  tsrFlushBase    = $00000200;

type

  TTosser = object(TObject)
    Status : longint;
    Flags : longint;

    InboundDir : PPktDir;

    PktQueue  : PPktQueue;

    Counter : PCounter;
    Arcer : PArcer;
    BadRetosser : PBadRetosser;

    DupeEngine : PDupeEngine;

    Constructor Init(const AFlags:longint);
    Destructor  Done; virtual;
    Procedure Toss;

    Procedure TossDir(const APath, AExt:string);
    Procedure ProcessPacket;
    Procedure TossMessages;
    Procedure TossEchomail;

    Function CreateArea:PArea;
    Procedure PutToBadMail(const Reason:string);
    Procedure PutToDupeMail;
    Procedure PutToBase(const Area:PArea);
    Procedure PutToNetMail;

    Procedure SendToNode(const Node:PNode);

    Procedure MoveToTemp;
    Procedure ReceiveBCL;
  private
    PktFromAddress : TAddress;
    PktToAddress : TAddress;

    PktMessage : PAbsMessage;

    Paths   : PAddressCollection;
    SeenBys : PAddressSortedCollection;
  end;
  PTosser = ^TTosser;

implementation

Uses
  global;

Constructor TTosser.Init(const AFlags:longint);
begin
  inherited Init;

  Status:=tsrOk;
  Flags:=AFlags;
end;

Destructor  TTosser.Done;
begin
  inherited Done;
end;

Procedure TTosser.PutToBase(const Area:PArea);
Var
  EchoBase : PMessageBase;
begin
  ScriptsEngine^.TosserHook('hookTossToBase');

  EchoBase:=EchoQueue^.OpenBase(Area);
  If EchoBase=nil then
    begin
      PutToBadMail('Cannot open message base.');
      exit;
    end;

  Echobase^.CreateMessage(False);
  Echobase^.SetAbsMessage(PktMessage);
  EchoBase^.SetFlags(flgNone);

  If Area^.CheckFlag('S') then
    begin
      Echobase^.MessageBody^.SeenByLink:=nil;
      Echobase^.MessageBody^.PathLink:=nil;
      Echobase^.MessageBody^.ViaLink:=nil;
    end;

  Echobase^.WriteMessage;
  Echobase^.CloseMessage;
  If (Flags and tsrFlushBase)=tsrFlushBase then Echobase^.Flush;

  ImportLists^.AddArea(Area);
end;

Procedure TTosser.PutToNetmail;
Var
  NetBase : PMessageBase;
begin
  ScriptsEngine^.TosserHook('hookTossToNetmail');

  NetBase:=EchoQueue^.OpenBase(NetmailArea);
  If NetBase=nil then
    begin
      PutToBadMail('Cannot open message base.');
      exit;
    end;

  NetBase^.SetBaseType(btNetmail);

  NetBase^.CreateMessage(False);
  NetBase^.PutAbsMessage(PktMessage);

  NetBase^.SetFlag(flgTransit);
  NetBase^.ClearFlag(flgLocal or flgHold or flgKill);

  NetBase^.WriteMessage;
  NetBase^.CloseMessage;

  If (Flags and tsrFlushBase)=tsrFlushBase then NetBase^.Flush;
end;

Procedure TTosser.PutToBadMail(const Reason:string);
var
  sTemp : string;
  Badmail : PMessageBase;
  TempKludge : PKludge;
begin
  ScriptsEngine^.TosserHook('hookTossToBadmail');

  BadMail:=EchoQueue^.OpenBase(AreaBase^.Badmail^.At(0));
  If BadMail=nil then
    begin
      ErrorOut(LngFile^.GetString(LongInt(lngCantOpenBadmail)));
    end;

  Badmail^.CreateMessage(False);
  Badmail^.PutAbsMessage(PktMessage);
  Badmail^.SetFlag(flgNone);

  Badmail^.MessageBody^.KludgeBase^.SetKludge('PKTFROM:',ftnAddressToStrEx(PktFromAddress));
  Badmail^.MessageBody^.KludgeBase^.SetKludge('REASON:',Reason);

  TempKludge:=New(PKludge);
  TempKludge^.Name:=NewStr('AREA:'+PktMessage^.Area^);
  TempKludge^.Value:=nil;
  Badmail^.MessageBody^.KludgeBase^.Kludges^.AtInsert(0,TempKludge);

  Badmail^.WriteMessage;
  Badmail^.CloseMessage;
  If (Flags and tsrFlushBase)=tsrFlushBase then  Badmail^.Flush;

  sTemp:=LngFile^.GetString(LongInt(lngPktMessageTossedToBadmail));
  WriteLn(sTemp);
  LogFile^.SendStr('│   '+sTemp,'!');
  LogFile^.SendStr('│   Reason: '+Reason,'!');
end;

Procedure TTosser.PutToDupeMail;
var
  sTemp : string;
  DupeMail : PMessageBase;
  TempKludge : PKludge;
begin
  ScriptsEngine^.TosserHook('hookTossToDupemail');

  DupeMail:=EchoQueue^.OpenBase(AreaBase^.Dupemail^.At(0));
  If DupeMail=nil then
    begin
      ErrorOut(LngFile^.GetString(LongInt(lngCantOpenDupemail)));
    end;

  DupeMail^.CreateMessage(False);
  DupeMail^.PutAbsMessage(PktMessage);
  DupeMail^.SetFlag(flgNone);

  TempKludge:=New(PKludge);
  TempKludge^.Name:=NewStr('AREA:'+PktMessage^.Area^);
  TempKludge^.Value:=nil;
  DupeMail^.MessageBody^.KludgeBase^.Kludges^.AtInsert(0,TempKludge);

  DupeMail^.WriteMessage;
  DupeMail^.CloseMessage;
  If (Flags and tsrFlushBase)=tsrFlushBase then  DupeMail^.Flush;

  sTemp:=LngFile^.GetString(LongInt(lngPktMessageTossedToDupeMail));
  WriteLn(sTemp);
  LogFile^.SendStr('│   '+sTemp,'!');
end;

Function TTosser.CreateArea:PArea;
Var
  TempUplink : PUplink;
  TempArea : PArea;
  sTemp : string;
begin
  CreateArea:=nil;

  LngFile^.AddVar(PktMessage^.Area^);
  Write(LngFile^.GetString(LongInt(lngUnknownArea)),#32);

  TempUplink:=UplinkBase^.FindUplink(PktFromAddress);

  If TempUplink=nil then exit;

  sTemp:=TempUplink^.AutocreateGroup;

  TempArea:=AutoCreateArea(PktMessage^.Area^,sTemp[1],TempUplink);
  If TempArea=nil then exit;

  LngFile^.AddVar(sTemp);
  sTemp:=LngFile^.GetString(LongInt(lngAutocreatedToGroup));

  WriteLn(sTemp);
  LogFile^.SendStr('│   '+sTemp,'&');

  CreateArea:=TempArea;
end;

Procedure TTosser.SendToNode(const Node:PNode);
Var
  Packet : PPacket;
begin
  Packet:=PktQueue^.OpenPkt(Node);
  If Packet=nil then
    begin
      WriteLn('PktQueue error!!!!');
      Halt;
    end;

  If Node^.UseAka.Point=0
     then Paths^.Insert(ftnNewAddress(Node^.UseAka));

  Packet^.CreateNewMsg(False);

  If Paths^.Count>0 then
    begin
      objDispose(PktMessage^.MessageBody^.PathLink);
      PktMessage^.MessageBody^.PathLink:=New(PMemoryStream,Init(0,cBuffSize));

      ftnAddressList(PktMessage^.MessageBody^.PathLink,Paths,
        #1'PATH: ',False,78);
    end;

  Packet^.SetAbsMessage(PktMessage,False);
  Packet^.WriteMsg;
  Packet^.MessageBody:=nil;

  If (Flags and tsrFlushPkt)=tsrFlushPkt then  Packet^.Flush;

  If Node^.UseAka.Point=0
     then Paths^.AtFree(Paths^.Count-1);
end;

Procedure TTosser.TossEchoMail;
Var
  l : longint;
{$IFDEF VER70}
  i:integer;
{$ELSE}
  i:longint;
{$ENDIF}

  TempArea : PArea;
  TempNode : PNode;
  TempLink : PNodelistItem;

  ExportNodes : PNodelist;
begin
{Находим арею}
  TempArea:=AreaBase^.FindArea(PktMessage^.Area^);

{Если такой нету, то пытаемся скриейтить, а если и это не получается,}
{то кладём в Badmail}
  If TempArea=nil then
    begin
      TempArea:=CreateArea;
      If TempArea=nil then
        begin
          PutToBadMail('Link is not active for this area.');
          exit;
        end;
    end else

{Если арея в пассиве, то кладём в BadMail}
  If TempArea^.CheckFlag('P') then
    begin
       PutToBadMail('Area is passive.');
       exit;
    end;

  If (Flags and tsrUnSecure)<>tsrUnSecure then
    begin

{А мы вообще подписаны?}
      TempLink:=TempArea^.FindLink(PktFromAddress);
      If TempLink=nil then
        begin
          PutToBadMail('Link is not active for this area.');
          Exit;
        end;

{Если да - то смотрим, как.}
      TempNode:=PNode(TempLink^.Node);

{Не можем посылать}
      If (((TempLink^.Mode) and modWrite)<>modWrite)
         or (TempNode^.Level<TempArea^.WriteLevel) then
        begin
          PutToBadMail('Link can''t send messages to this area.');
          exit;
        end;

{Проверяем дупы}
      If DupeEngine^.CheckDupe(PktMessage) then
        begin
          PutToDupeMail;
          exit;
        end;

    end;

{Парсим техническую информацию}
  SeenBys:=New(PAddressSortedCollection,Init($30,$30));
  SeenBys^.Duplicates:=True;
  ftnParsTechInfo(PktMessage^.MessageBody^.SeenByLink,SeenBys,PktFromAddress);

  Paths:=New(PAddressCollection,Init($30,$30));
  ftnParsTechInfo(PktMessage^.MessageBody^.PathLink,Paths,PktFromAddress);

{Создаём список нод, на которые это дело должно уйти.}
  ExportNodes:=New(PNodelist,Init($10,$10));
  For l:=0 to TempArea^.Links^.Count-1
     do ExportNodes^.Insert(TempArea^.Links^.At(l));

{Проверяем, куда это должно идти}
  l:=0;
  While l<ExportNodes^.Count do
    begin
      TempLink:=ExportNodes^.At(l);
      TempNode:=PNode(TempLink^.Node);

  {Не будем посылать назад, откуда пришло :)}
      If ftnAddressCompare(TempNode^.Address,PktFromAddress)=0 then
        begin
          ExportNodes^.AtDelete(l);
          continue;
        end else

  {Если нода в пасиве - то не будем паковать}
      If TempLink^.Mode=modPassive then
        begin
          If (TempNode^.SysopName<>nil) and (PktMessage^.ToName<>nil) then
             If TempNode^.SysopName^=PktMessage^.ToName^ then continue;
          ExportNodes^.AtDelete(l);
          continue;
        end else

  {Если нода уже есть в синбаях, то тоже не будем посылать}
      If SeenBys^.Search(@TempNode^.Address,i) then
        begin
          ExportNodes^.AtDelete(l);
          continue;
        end else

  {А если она в ридонли, или секьюрити маленькое - то тоже паковать не будем.}
      If (((TempLink^.Mode) and modRead)<>modRead)
        or (TempNode^.Level<TempArea^.ReadLevel) then
          begin
            ExportNodes^.AtDelete(l);
            continue;
          end else

      Inc(l);
    end;

{Добавляем синбаи}
  SeenBys^.Duplicates:=False;
  TempArea^.AddSeenBys(SeenBys);

  If SeenBys^.Count>0 then
    begin
      objDispose(PktMessage^.MessageBody^.SeenByLink);
      PktMessage^.MessageBody^.SeenByLink:=New(PMemoryStream,Init(0,cBuffSize));

      ftnAddressList(PktMessage^.MessageBody^.SeenByLink,SeenBys,
        'SEEN-BY: ',False,78);
    end;

  objDispose(SeenBys);

{Распихаем по пакетам на ноды}
  For l:=0 to ExportNodes^.Count-1 do
    begin
      TempLink:=ExportNodes^.At(l);
      SendToNode(PNode(TempLink^.Node));
    end;

  objDispose(Paths);

{Покладём в базу}
  If (Flags and tsrScanning)<>tsrScanning then
    If TempArea^.EchoType.Storage<>etPassThrough then
      begin
        PutToBase(TempArea);
      end;

{Бинго! Всем спасибо, все свободны =) }
  ExportNodes^.DeleteAll;
  objDispose(ExportNodes);
end;

Procedure TTosser.TossMessages;
Var
  sTemp  : string;
  i : word;
begin
  i:=0;

  While true do
    begin
      InboundDir^.Packet^.OpenMsg;
      Inc(i);

      If InboundDir^.Packet^.Status<>pktOk then break;

      If (Flags and tsrScanning)<>tsrScanning
        then Counter^.AddMsg;

      PktMessage:=InboundDir^.Packet^.CutAbsMessage;
      ScriptsEngine^.ScriptMessage:=PktMessage;
      If PktMessage^.Area=nil then PktMessage^.Area:=NewStr('NETMAIL');

      If PktMessage^.Area^<>'NETMAIL' then
        begin
          If ((Flags and tsrProtectedPkt)<>tsrProtectedPkt) and
             ((Flags and tsrUnSecure)<>tsrUnSecure)
           then Flags:=Flags or tsrRenameToSec;
        end;

      If (Flags and tsrScanning)<>tsrScanning then
        begin
          LngFile^.AddVar(strIntToStr(i));
          LngFile^.AddVar(PktMessage^.Area^);
          sTemp:=LngFile^.GetString(LongInt(lngPktMessage));

          If (Flags and tsrRenameToSec)=tsrRenameToSec
             then sTemp:=sTemp+#32+
               LngFile^.GetString(LongInt(lngPktMessageSkipped));

          WriteLn(sTemp);
          LogFile^.SendStr('│ '+sTemp,'@');
        end;

      If PktMessage^.Area^='NETMAIL' then PutToNetmail else
        If (Flags and tsrRenameToSec)<>tsrRenameToSec then TossEchoMail;

      InboundDir^.Packet^.CloseMsg;
      objDispose(PktMessage);
    end;

  If InboundDir^.Packet^.Status=pktBadPacket then
    begin
      If (Flags and tsrScanning)<>tsrScanning then
        begin
          sTemp:=LngFile^.GetString(LongInt(lngBadPacket));
          LogFile^.SendStr('╘ '+sTemp,'!');
          WriteLn('-- '+sTemp);
        end;

      InboundDir^.ChangeExtension('BAD');
    end;
end;

Procedure TTosser.ProcessPacket;
Var
  sTemp  : string;
  sTemp2 : string;
  i : longint;

  PktName : string;
  TempNode : PNode;
begin
  InboundDir^.OpenPkt;

  InboundDir^.Packet^.GetToAddress(PktToAddress);
  InboundDir^.Packet^.GetFromAddress(PktFromAddress);

  PktName:=InboundDir^.GetPktName;
  If (Flags and tsrScanning)<>tsrScanning then
    begin
      sTemp2:=dosGetFileName(PktName);
      LngFile^.AddVar(sTemp2);
      LngFile^.AddVar(ftnAddressToStrEx(PktFromAddress));
      LngFile^.AddVar(ftnAddressToStrEx(PktToAddress));

      Counter^.AddBytes(InboundDir^.Packet^.PktSize);

      sTemp:=LngFile^.GetString(LongInt(lngProcessingPacket));
      i:=Pos(sTemp2,sTemp);

      WriteLn(sTemp);
      LogFile^.SendStr('╒ '+sTemp,#32);
    end;

  If InboundDir^.Packet^.Status<>0 then
    begin
      If (Flags and tsrScanning)<>tsrScanning then
        begin
          sTemp:=LngFile^.GetString(LongInt(lngBadPacket));
          LogFile^.SendStr('╘ '+sTemp,'!');
          sTemp:=strPadL('└─ ',#32,i+2)+sTemp;
          WriteLn(sTemp);
        end;

      InboundDir^.ChangeExtension('BAD');
      exit;
    end;

  If (Flags and tsrUnSecure)<>tsrUnSecure then
    If AddressBase^.FindAddress(PktToAddress)=nil then
      begin
      If (Flags and tsrScanning)<>tsrScanning then
        begin
          sTemp:=LngFile^.GetString(LongInt(lngBadPacketDestination));
          LogFile^.SendStr('╘ '+sTemp,'!');
          sTemp:=strPadL('└─ ',#32,i+2)+sTemp;
          WriteLn(sTemp);
        end;

        InboundDir^.ChangeExtension('DST');
        exit;
      end;

  Flags:=Flags or tsrProtectedPkt;
  Flags:=Flags and not tsrRenameToSec;

  TempNode:=NodeBase^.FindNode(PktFromAddress);

  If (Flags and tsrUnSecure)<>tsrUnSecure then
    If (TempNode=nil) or
       ((TempNode^.PktPassword<>nil) and (TempNode^.PktPassword^<>InboundDir^.Packet^.GetPassword)) or
       ((TempNode^.PktPassword=nil) and (InboundDir^.Packet^.GetPassword<>''))
         then Flags:=Flags and not tsrProtectedPkt;

  If (Flags and tsrScanning)<>tsrScanning then
    begin
      sTemp:=ftspcGetProgramName(InboundDir^.Packet^.GetProductCode)
      +#32+InboundDir^.Packet^.GetProductVersionString+', '
      +InboundDir^.Packet^.GetPktTypeString;
      sTemp:=strPadL('└─ ',#32,i+2)+sTemp;
      If (Flags and tsrProtectedPkt)=tsrProtectedPkt then sTemp:=sTemp+', Pwd';
      WriteLn(sTemp);
    end;

  TossMessages;
  If InboundDir^.Packet=nil then exit;

  If (Flags and tsrRenameToSec)=tsrRenameToSec then
    begin
      If (Flags and tsrScanning)<>tsrScanning then
        begin
          sTemp:=LngFile^.GetString(LongInt(lngBadPacketPassword));
          LogFile^.SendStr('╘ '+sTemp,'!');
          WriteLn('-- '+sTemp);
        end;

      InboundDir^.ChangeExtension('SEC');
      exit;
    end;

  If (Flags and tsrScanning)<>tsrScanning then
    begin
      LogFile^.SendStr('╘ '+LngFile^.GetString(LongInt(lngDone)),#32);
    end;
  InboundDir^.ClosePkt;
  dosErase(PktName);
end;

Procedure TTosser.TossDir(const APath, AExt:string);
Var
  i:longint;
begin
  InboundDir:=New(PPktDir,Init);

  PktQueue:=New(PPktQueue,Init);

  InboundDir^.SetPktExtension(AExt);
  InboundDir^.AddPktExtension('P2K');

  InboundDir^.OpenDir(APath);

  If (Flags and tsrScanning)<>tsrScanning then
    begin
      LngFile^.AddVar(strIntToStr(InboundDir^.GetCount));
      LogFile^.SendStr(LngFile^.GetString(LongInt(lngProcessingPackets)),'#');
    end;

  For i:=0 to InboundDir^.GetCount-1 do
    begin
      InboundDir^.Seek(i);
      ProcessPacket;
      WriteLn;
    end;

  InboundDir^.CloseDir;

  EchoQueue^.CloseBases;
  objDispose(PktQueue);
  objDispose(InboundDir);
end;

Procedure TTosser.ReceiveBCL;
Var
  SR : SearchRec;
  EchoList : PBCL;
  TempAddress : TAddress;
  i : longint;
  TempUplink : PUplink;
  sTemp : string;
begin
  FindFirst(TempInboundPath+'\*.BCL',AnyFile-Directory,SR);

  While DosError=0 do
    begin
      EchoList:=New(PBCL,Init);
      EchoList^.SetFilename(TempInboundPath+'\'+SR.Name);
      EchoList^.Read;

      EchoList^.GetAddress(TempAddress);
      objDispose(EchoList);

      TempUplink:=UplinkBase^.FindUplink(TempAddress);

      If TempUplink<>nil then
        If TempUplink^.AreaList.ListType=ltBCL then
          begin
            LngFile^.AddVar(ftnAddressToStrEx(TempAddress));
            sTemp:=LngFile^.GetString(LongInt(lngBCLReceived));

            WriteLn(sTemp);
            LogFile^.SendStr(sTemp,'&');
            writeln;

            dosMove(TempInboundPath+'\'+SR.Name,TempUplink^.AreaList.Path);
          end;

      FindNext(SR);
    end;
{$IFNDEF VER70}
  FindClose(SR);
{$ENDIF}
end;

Procedure TTosser.MoveToTemp;
  Procedure MoveExt(const S:string);
  Var
    SR : SearchRec;
  begin
    FindFirst(InboundPath+'\*.'+S,AnyFile-Directory,SR);
    While DOSError=0 do
      begin
        dosMove(InboundPath+'\'+SR.Name,TempInboundPath+'\'+SR.Name);
        FindNext(SR);
      end;
{$IFNDEF VER70}
  FindClose(SR);
{$ENDIF}
  end;
begin
  If (Flags and tsrMovePackets)=tsrMovePackets then
    begin
      MoveExt('PKT');
      MoveExt('P2K');
    end;
  MoveExt('BCL');
end;

Procedure TTosser.Toss;
begin
  If ParamString^.CheckKey('A') then Areafix^.ScanNetmail;

  If TempInboundPath<>InboundPath then MoveToTemp;

  If (Flags and tsrRunProcesses)=tsrRunProcesses then DoBeforeUnpack;

  Arcer:=New(PArcer,Init);
  ImportLists^.Read;

  TextColor(colOperation);
  Writeln(LngFile^.GetString(LongInt(lngUnpackingArchives)));
  TextColor(colLongline);
  Writeln(constLongLine);
  TextColor(7);
  LogFile^.SendStr(LngFile^.GetString(LongInt(lngUnpackingArchives)),#32);

  Arcer^.UnArcDir(InboundPath);

  LogFile^.SendStr(LngFile^.GetString(LongInt(lngDone)),#32);
  TextColor(colLongline);
  Writeln(constLongLine);
  TextColor(7);

  If (Flags and tsrRunProcesses)=tsrRunProcesses then DoAfterUnpack;

  ScriptsEngine^.RunHook('hookBeforeTossing');

  If ParamString^.CheckKey('B') then
    begin
      BadRetosser:=New(PBadRetosser,Init);
      BadRetosser^.Scan;
      objDispose(BadRetosser);
    end;

  DupeEngine:=New(PDupeEngine,Init(MaxDupes));
  DupeEngine^.OpenDupeFile(DataPath^+'\spctoss.dup');

  TextColor(colOperation);
  Writeln(LngFile^.GetString(LongInt(lngTossingMessages)));
  TextColor(colLongline);
  Writeln(constLongLine);
  TextColor(7);

  LogFile^.SendStr(LngFile^.GetString(LongInt(lngTossingMessages)),#32);

  If (Flags and tsrUnSecure)=tsrUnSecure then
      LogFile^.SendStr(LngFile^.GetString(LongInt(lngDisablingSecurity)),'&');

  Counter:=New(PCounter,Init);

  Counter^.StartCount;
  TossDir(TempInboundPath,'PKT');
  Counter^.EndCount;

  DupeEngine^.SaveDupeFile;
  objDispose(DupeEngine);

  LogFile^.SendStr(LngFile^.GetString(LongInt(lngDone)),#32);
  LogFile^.SendStr(Counter^.GetSeconds+' sec, '
      +Counter^.GetMsgs+' msgs, '
      +Counter^.GetKbytes+' kb, '
      +Counter^.GetMsgSec+' msg/sec, '
      +Counter^.GetKBytesSec+' kb/sec'
      ,'#');
  TextColor(colLongline);
  Writeln(constLongLine);
  TextColor(7);

  AnnounceAreas;

  TextColor(colOperation);
  Writeln(LngFile^.GetString(LongInt(lngTossingLocal)));
  TextColor(colLongline);
  Writeln(constLongLine);
  TextColor(7);
  LogFile^.SendStr(LngFile^.GetString(LongInt(lngTossingLocal)),#32);

  Flags:=Flags or tsrUnSecure;
  TossDir(LocalInboundPath,'PKT');

  LogFile^.SendStr(LngFile^.GetString(LongInt(lngDone)),#32);
  TextColor(colLongline);
  Writeln(constLongLine);
  TextColor(7);

  objDispose(ImportLists);
  objDispose(Counter);

  WriteLn;
  ReceiveBCL;

  If (Flags and tsrRunProcesses)=tsrRunProcesses then DoBeforePack;
  ScriptsEngine^.RunHook('hookAfterTossing');

  TextColor(colOperation);
  Writeln(LngFile^.GetString(LongInt(lngPackingOutboundMail)));
  TextColor(colLongline);
  Writeln(constLongLine);
  TextColor(7);
  LogFile^.SendStr(LngFile^.GetString(LongInt(lngPackingOutboundMail)),#32);

  Arcer^.PackQueue;
  objDispose(Arcer);

  LogFile^.SendStr(LngFile^.GetString(LongInt(lngDone)),#32);
  TextColor(colLongline);
  Writeln(constLongLine);
  TextColor(7);

  If (Flags and tsrRunProcesses)=tsrRunProcesses then DoAfterPack;
end;

end.
