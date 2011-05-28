{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit Toss;

interface
Uses
  arc,
  acreate,
  areafix,
  bats,
  global,
  queue,
  areas,
  nodes,
  r8dos,
  r8mbe,
  r8objs,
  r8dtm,
  r8ftn,
  r8pkt,
  r8ftspc,
  uplinks,
  groups,
  objects,
  dupe,
  r8str,
  sort,
  tsl,
  bad,
  tracker,
  color,
  dos,
  r8alst,
  Crt;

Var
  CheckSecurity : boolean;
  Scanning : boolean;
  ProcessTrack : boolean;

Procedure DoToss;
Procedure TossPackets(Path:string;Ext:string);

implementation

Var
  CurrentPacket : longint;

  PktFrom : TAddress;
  PktTo : TAddress;
  From : TAddress;
  Area : string;
  HdrStream : PStream;
  BodyStream : PStream;
  SeenByStream : PStream;
  PathStream : PStream;
  SeenbyAddr : PAddressBase;
  PathAddr  : PAddressBase;
  PathAddr2 : PAddressBase;
  DateTime : TDateTime;
  iTemp:longint;

Procedure PutToBadMail(Reason:string);
Var
  TempAddress:TAddress;
begin
  WriteLn('Tossed to BADMAIL');

  Badmail^.CreateMessage(False);

  Badmail^.SetTo(InboundDir^.Packet^.GetMsgTo);
  Badmail^.SetFrom(InboundDir^.Packet^.GetMsgFrom);
  Badmail^.SetSubj(InboundDir^.Packet^.GetMsgSubj);

  InboundDir^.Packet^.GetMsgDateTime(DateTime);
  Badmail^.SetDateWritten(DateTime);

  PathStream:=New(PMemoryStream,Init(0,cBuffSize));
  MakePaths(PathStream,PathAddr^.Akas);

  Badmail^.MessageBody^.AddToMsgBodyStream(BodyStream);
  Badmail^.MessageBody^.PutMsgSeenByStream(SeenByStream);
  Badmail^.MessageBody^.PutMsgPathStream(PathStream);

  Badmail^.MessageBody^.KludgeBase^.SetKludge('PKTFROM:',ftnAddressToStrEx(PktFrom));
  Badmail^.MessageBody^.KludgeBase^.SetKludge('AREA:',InboundDir^.Packet^.GetMsgArea);
  Badmail^.MessageBody^.KludgeBase^.SetKludge('REASON:',Reason);

  objDispose(PathStream);

  InboundDir^.Packet^.GetMsgFromAddress(TempAddress);
  Badmail^.SetFromAddress(TempAddress);
  InboundDir^.Packet^.GetMsgToAddress(TempAddress);
  Badmail^.SetToAddress(TempAddress);

  Badmail^.WriteMessage;
  Badmail^.CloseMessage;

  LogFile^.SendStr('³   Tossed to BadMail','!');
  LogFile^.SendStr('³   Reason: '+Reason,'!');
end;

Procedure PutToDupeBoard;
Var
  TempAddress:TAddress;
begin
  WriteLn('Tossed to DUPEMAIL');

  Dupemail^.CreateMessage(False);

  Dupemail^.SetTo(InboundDir^.Packet^.GetMsgTo);
  Dupemail^.SetFrom(InboundDir^.Packet^.GetMsgFrom);
  Dupemail^.SetSubj(InboundDir^.Packet^.GetMsgSubj);

  InboundDir^.Packet^.GetMsgDateTime(DateTime);
  Dupemail^.SetDateWritten(DateTime);

  PathStream:=New(PMemoryStream,Init(0,cBuffSize));
  MakePaths(PathStream,PathAddr^.Akas);

  Dupemail^.MessageBody^.AddToMsgBodyStream(BodyStream);
  Dupemail^.MessageBody^.PutMsgSeenByStream(SeenByStream);
  Dupemail^.MessageBody^.PutMsgPathStream(PathStream);

  Dupemail^.MessageBody^.KludgeBase^.SetKludge('AREA:',InboundDir^.Packet^.GetMsgArea);

  objDispose(PathStream);

  InboundDir^.Packet^.GetMsgFromAddress(TempAddress);
  Dupemail^.SetFromAddress(TempAddress);
  InboundDir^.Packet^.GetMsgToAddress(TempAddress);
  Dupemail^.SetToAddress(TempAddress);

  Dupemail^.WriteMessage;
  Dupemail^.CloseMessage;
  LogFile^.SendStr('³   Tossed to DupeMail','!');
end;

Function UnknownArea:boolean;
Var
  i:longint;
  TempUplink : PUplink;
  sTemp:string;
begin
  UnknownArea:=False;
  Write('Unknown area ',Area,' ÍÍ ');

  i:=UplinkBase^.FindUplink(PktFrom);

  If i=-1 then Exit;

  TempUplink:=UplinkBase^.Uplinks^.At(i);
  sTemp:=TempUplink^.AutocreateGroup;

  If not AutoCreateArea(Area,sTemp,TempUplink) then exit;
  WriteLn('Autocreated to group ',sTemp);
  LogFile^.SendStr('³   Autocreated to group '+sTemp,'&');

  iTemp:=AreaBase^.FindArea(Area);

  UnknownArea:=True;
end;

Function MakeNewPkt(Node:PNode):longint;
begin
  QueueDir^.PktType:=Node^.PktType;

  QueueDir^.CreateNewPkt;
  QueueDir^.Packet^.SetToAddress(Node^.Address);
  QueueDir^.Packet^.SetFromAddress(Node^.UseAka);
  QueueDir^.Packet^.SetPassword(Node^.PktPassword^);
  QueueDir^.Packet^.WritePkt;

  MakeNewPkt:=QueueDir^.CurrentPacket;
  PktQueue^.SetPktNumber(Node^.Address,QueueDir^.CurrentPacket);
  QueueDir^.ClosePkt;
end;

Procedure PackToNode(Node:PNode);
Var
  PktName : PString;
  TempAddress :TAddress;
  DateTime:TDateTime;
begin
  CurrentPacket:=PktQueue^.GetPktNumber(Node^.Address);

  If Currentpacket=-1 then CurrentPacket:=MakeNewPkt(Node);

  PktName:=QueueDir^.Packets^.At(CurrentPacket);
  If dosFileSize(PktName^)>Node^.MaxPktSize
           then CurrentPacket:=MakeNewPkt(Node);

  PathStream:=New(PMemoryStream,Init(0,cBuffSize));
  PathAddr2:=New(PAddressbase,Init);
  PathAddr2^.GetFrom(PathAddr^.Akas);

  TempAddress:=Node^.UseAka;

  If (PathAddr2^.FindAddress(TempAddress)=-1)
     and (Node^.UseAka.Point=0)
     then PathAddr2^.AddAddress(Node^.UseAka);

  If (PathAddr2^.FindAddress(Node^.Address)=-1)
     and (Node^.UseAka.Point<>0)
     then PathAddr2^.AddAddress(Node^.Address);

  MakePaths(PathStream,PathAddr2^.Akas);

  QueueDir^.Seek(CurrentPacket);
  QueueDir^.OpenPkt;
  QueueDir^.Packet^.SetPktAreaType(btEchomail);
  QueueDir^.Packet^.CreateNewMsg(False);
  QueueDir^.Packet^.PutMsgHdrStream(HdrStream);

  InboundDir^.Packet^.GetMsgDateTime(DateTime);
  QueueDir^.Packet^.SetMsgDateTime(DateTime);

  QueueDir^.Packet^.MessageBody^.AddToMsgBodyStream(BodyStream);

  InboundDir^.Packet^.GetMsgFromAddress(TempAddress);
  QueueDir^.Packet^.SetMsgFromAddress(TempAddress);
  InboundDir^.Packet^.GetMsgToAddress(TempAddress);
  QueueDir^.Packet^.SetMsgToAddress(TempAddress);

  QueueDir^.Packet^.MessageBody^.PutMsgSeenByStream(SeenByStream);
  QueueDir^.Packet^.MessageBody^.PutMsgPathStream(PathStream);
  QueueDir^.Packet^.WriteMsg;
  QueueDir^.Packet^.CloseMsg;
  QueueDir^.ClosePkt;

  objDispose(PathStream);
  objDispose(PathAddr2);
end;

Procedure PutToBase(Echo:TEchoType);
Var
  TempAddress:TAddress;
begin
  If not EchoQueue^.OpenBase(Echo.Path, EchoBase)
       then
         begin
           PutToBadMail('Cannot open message base.');
           exit;
         end;

  EchoBase^.CreateMessage(False);

  EchoBase^.SetTo(InboundDir^.Packet^.GetMsgTo);
  EchoBase^.SetFrom(InboundDir^.Packet^.GetMsgFrom);
  EchoBase^.SetSubj(InboundDir^.Packet^.GetMsgSubj);
  EchoBase^.SetFlags(flgNone);

  InboundDir^.Packet^.GetMsgDateTime(DateTime);
  EchoBase^.SetDateWritten(DateTime);

  PathStream:=New(PMemoryStream,Init(0,cBuffSize));
  MakePaths(PathStream,PathAddr^.Akas);

  EchoBase^.MessageBody^.AddtoMsgBodyStream(BodyStream);
  EchoBase^.MessageBody^.PutMsgSeenByStream(SeenByStream);
  EchoBase^.MessageBody^.PutMsgPathStream(PathStream);

  objDispose(PathStream);

  InboundDir^.Packet^.GetMsgFromAddress(TempAddress);
  EchoBase^.SetFromAddress(TempAddress);
  InboundDir^.Packet^.GetMsgToAddress(TempAddress);
  EchoBase^.SetToAddress(TempAddress);

  EchoBase^.WriteMessage;
  EchoBase^.CloseMessage;
  EchoBase^.Flush;
end;

Procedure TossEchomail;
Var
  TempArea : PArea;
  TempNode : PNode;
  TempExport : PNodelistItem;
  TempAddress:PAddress;
  TempAddress2:TAddress;
  TempAddress3:TAddress;
  DupeRec : PDupeRec;
  TrackRec : PTrackrec;
begin
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{®«ãç ¥¬ á¨­¡ ¨.}

  SeenByAddr:=New(PAddressbase,Init);
  InboundDir^.Packet^.GetMsgSeenBys(SeenbyAddr^.Akas);
  SeenbyStream:=InboundDir^.Packet^.MessageBody^.SeenByLink;

  PathAddr:=New(PAddressbase,Init);
  InboundDir^.Packet^.GetMsgPaths(PathAddr^.Akas);

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

{ å®¤¨¬  à¥î}
  iTemp:=AreaBase^.FindArea(Area);

{…á«¨ â ª®© ­¥âã, â® ¯ëâ ¥¬áï áªà¨¥©â¨âì,   ¥á«¨ ¨ íâ® ­¥ ¯®«ãç ¥âáï,}
{â® ª« ¤ñ¬ ¢ Badmail}
  If iTemp=-1 then
      If not UnknownArea then
        begin
          PutToBadMail('Link is not active for this area.');
          objDispose(SeenByAddr);
          objDispose(PathAddr);

          Exit;
        end;

  TempArea:=AreaBase^.Areas^.At(iTemp);

  If TempArea^.CheckFlag('P') then
    begin
{      AreaBase^.Modified:=True;
       TempArea^.ClearFlag('P');}

       PutToBadMail('Area is passive.');
       objDispose(SeenByAddr);
       objDispose(PathAddr);
       Exit;
    end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{‘¥ªìîà¨â¨}

  If CheckSecurity then
    begin

{€ ¬ë ¢®®¡é¥ ¯®¤¯¨á ­ë?}
      iTemp:=TempArea^.FindLink(PktFrom);
      If iTemp=-1 then
        begin
          PutToBadMail('Link is not active for this area.');
          objDispose(SeenByAddr);
          objDispose(PathAddr);
          Exit;
        end;

{…á«¨ ¤  - â® á¬®âà¨¬, ª ª.}
      TempExport:=TempArea^.Links^.At(iTemp);
      TempNode:=PNode(TempExport^.Node);

{¥ ¬®¦¥¬ ¯®áë« âì}
      If ((TempExport^.Mode) and modWrite)<>modWrite then
        begin
          PutToBadMail('Link can''t send messages to this area.');
          objDispose(SeenByAddr);
          objDispose(PathAddr);
          Exit;
        end;

      If TempNode^.Level<TempArea^.WriteLevel then
        begin
          PutToBadMail('Link can''t send messages to this area.');
          objDispose(SeenByAddr);
          objDispose(PathAddr);
          Exit;
        end;

{—¥ª ¥¬ ¤ã¯ë}
      DupeRec:=New(PDupeRec,Init);

      DupeRec^.MsgFrom:=NewStr(InboundDir^.Packet^.GetMsgFrom);
      DupeRec^.MsgArea:=NewStr(Area);
      DupeRec^.MsgTo:=NewStr(InboundDir^.Packet^.GetMsgTo);
      DupeRec^.MsgSubj:=NewStr(InboundDir^.Packet^.GetMsgSubj);
      DupeRec^.MsgId:=NewStr(InboundDir^.Packet^.MessageBody^.Kludgebase^.GetKludge('MSGID:'));
      InboundDir^.Packet^.GetMsgDateTime(DupeRec^.MsgDate);

      If DupeBase^.CheckDupe(DupeRec) then
        begin
          PutToDupeBoard;
          objDispose(SeenByAddr);
          objDispose(PathAddr);
          Exit;
        end;

    end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{’à¥ª ¥¬}

  If ProcessTrack then
    begin
      TrackRec:=New(PTrackRec,Init);

      TrackRec^.FromName:=NewStr(InboundDir^.Packet^.GetMsgFrom);

      InboundDir^.Packet^.GetMsgFromAddress(TempAddress2);
      TrackRec^.FromAddress:=NewStr(ftnAddressToStrEx(TempAddress2));

      TrackRec^.ToName:=NewStr(InboundDir^.Packet^.GetMsgTo);

      InboundDir^.Packet^.GetMsgToAddress(TempAddress2);
      TrackRec^.ToAddress:=NewStr(ftnAddressToStrEx(TempAddress2));

      TrackRec^.Subj:=NewStr(InboundDir^.Packet^.GetMsgSubj);
      TrackRec^.Area:=NewStr(Area);

      TrackRec^.Pkt:=InboundDir^.Packet;

      If TrackerEngine^.ProcessTracker(TrackRec) then
        begin
          objDispose(SeenByAddr);
          objDispose(PathAddr);
          exit;
        end;
   end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

{‘®§¤ ñ¬ á¯¨á®ª ­®¤, ­  ª®â®àë¥ íâ® ¤¥«® ¤®«¦­® ã©â¨.}
  For iTemp:=0 to TempArea^.Links^.Count-1
     do ExportNodes^.Insert(TempArea^.Links^.At(iTemp));

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{à®¢¥àï¥¬, ­  ¢á¥ «¨ ­®¤ë ­ ¤® ¯ ª®¢ âì}

  iTemp:=0;
  while iTemp<ExportNodes^.Count do
    begin
      TempExport:=ExportNodes^.At(iTemp);
      TempNode:=PNode(TempExport^.Node);

{¥ ¡ã¤¥¬ ¯®áë« âì ­ § ¤, ®âªã¤  ¯à¨è«® :)}
      If ftnAddressCompare(TempNode^.Address,PktFrom) then
        begin
          ExportNodes^.AtDelete(iTemp);
          continue;
        end;

{…á«¨ ­®¤  ¢ ¯ á¨¢¥ - â® ­¥ ¡ã¤¥¬ ¯ ª®¢ âì}
      If TempNode^.CheckFlag('P') then
        begin
          ExportNodes^.AtDelete(iTemp);
          continue;
        end;

{…á«¨ ­®¤  ã¦¥ ¥áâì ¢ á¨­¡ ïå, â® â®¦¥ ­¥ ¡ã¤¥¬ ¯®áë« âì}
      If SeenbyAddr^.FindAddress(TempNode^.Address)<>-1 then
        begin
          ExportNodes^.AtDelete(iTemp);
          continue;
        end;

{…á«¨ ­¥â, â® ¤®¡ ¢¨¬}
      If TempNode^.Address.Point=0
              then SeenbyAddr^.AddAddress(TempNode^.Address);

{€ ¥á«¨ ®­  ¢ à¨¤®­«¨, ¨«¨ á¥ªìîà¨â¨ ¬ «¥­ìª®¥ - â® â®¦¥ ¯ ª®¢ âì ­¥ ¡ã¤¥¬.}
      If ((TempExport^.Mode) and modRead)<>modRead then
        begin
          ExportNodes^.AtDelete(iTemp);
          continue;
        end;

      If TempNode^.Level<TempArea^.ReadLevel then
        begin
          ExportNodes^.AtDelete(iTemp);
          continue;
        end;

{‚áâ ¢«ï¥¬ á¢®¨ á¨­¡ ¨}
      InboundDir^.Packet^.GetMsgFromAddress(TempAddress3);
      TempAddress2:=TempNode^.UseAka;
      TempAddress2.Zone:=TempAddress3.Zone;
      If (SeenByAddr^.FindAddress(TempAddress2)=-1)
          and (TempNode^.UseAka.Point=0)
            then SeenByAddr^.AddAddress(TempNode^.UseAka);

      Inc(iTemp);
    end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{’¥¯¥àì ®âá®àâ¨àã¥¬ á¨­¡ ¨}

  If SeenByAddr^.Akas^.Count>1 then
      srtSort(0,SeenByAddr^.Akas^.Count-1,SeenByAddr^.Akas,srtCompareAddr2D);

{ˆ á¤¥« ¥¬ ¨§ ­¨å áâà¨¬}
  SeenByStream:=New(PMemoryStream,Init(0,cBuffSize));
  MakeSeenbys(SeenByStream,SeenByAddr^.Akas);

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{…á«¨ ­¥ áª ­¨àã¥¬, â® ¯®«®¦¨¬ ¢ ¡ §ã}


  If not Scanning then
  If TempArea^.EchoType.Storage<>etPassThrough then
    begin
      PutToBase(TempArea^.EchoType);
      ImportLists^.AddArea(TempArea);
    end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{’¥¯¥àì ¤«ï ª ¦¤®© § ¯ ªã¥¬}

  For iTemp:=0 to ExportNodes^.Count-1 do
    begin
      TempExport:=ExportNodes^.At(iTemp);
      PackToNode(PNode(TempExport^.Node));
    end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{ˆ ãáñ}

  ExportNodes^.DeleteAll;
  objDispose(SeenByAddr);
  objDispose(PathAddr);
  objDispose(SeenByStream);
end;

Procedure TossNetmail;
Var
  TempAddress:TAddress;
begin
  NetMailDir^.CreateMessage(False);

  NetmailDir^.SetTo(InboundDir^.Packet^.GetMsgTo);
  NetmailDir^.SetFrom(InboundDir^.Packet^.GetMsgFrom);
  NetmailDir^.SetSubj(InboundDir^.Packet^.GetMsgSubj);
  NetmailDir^.SetFlags(InboundDir^.Packet^.GetMsgFlags);
  NetmailDir^.SetFlag(flgTransit);

  NetmailDir^.ClearFlag(flgLocal);
  NetmailDir^.ClearFlag(flgHold);
  NetmailDir^.ClearFlag(flgKill);

  InboundDir^.Packet^.GetMsgDateTime(DateTime);
  NetmailDir^.SetDateWritten(DateTime);

  NetMailDir^.MessageBody^.AddToMsgBodyStream(BodyStream);

  InboundDir^.Packet^.GetMsgFromAddress(TempAddress);
  NetMailDir^.SetFromAddress(TempAddress);
  InboundDir^.Packet^.GetMsgToAddress(TempAddress);
  NetMailDir^.SetToAddress(TempAddress);

  NetMailDir^.WriteMessage;
  NetMailDir^.CloseMessage;
end;

Procedure BadPktDestination;
Var
  sTemp:string;
  FName : string;
begin
  sTemp:=InboundDir^.GetPktName;
  FName:=sTemp;
  Dec(sTemp[0],3);

  InboundDir^.ClosePkt;

  dosRename(FName,sTemp+'dst');

  WriteLn('           ÀÄ Packet is addressed to another system ÍÍ Renamed to *.DST');
  WriteLn;
  LogFile^.SendStr('³   Packet is addressed to another system ÍÍ Renamed to *.DST','!');
end;

Procedure BadPkt;
Var
  sTemp:string;
  FName : string;
begin
  sTemp:=InboundDir^.GetPktName;
  FName:=sTemp;

  WriteLn(dosGetFileName(sTemp)+' : Bad packet  ÍÍ Renamed to *.BAD');
  WriteLn;

  LogFile^.SendStr('³   Bad packet  ÍÍ Renamed to *.BAD','!');

  Dec(sTemp[0],3);

  InboundDir^.ClosePkt;

  dosRename(FName,sTemp+'bad');
end;

Procedure BadPktPassword;
Var
  sTemp:string;
  FName:string;
begin
  sTemp:=InboundDir^.GetPktName;
  FName:=sTemp;
  Dec(sTemp[0],3);

  InboundDir^.ClosePkt;

  dosRename(FName,sTemp+'sec');

  WriteLn('           ÀÄ Bad packet password ÍÍ Renamed to *.SEC');
  WriteLn;

  LogFile^.SendStr('³   Bad packet password ÍÍ Renamed to *.SEC','!');
end;

Procedure TossPkt;
var
  i2 : longint;
begin
  i2:=0;

  While InboundDir^.Packet^.FastOpenMsg do
    begin
      Inc(i2);

      If not Scanning then
        Counter^.AddMsg;

      Area:=InboundDir^.Packet^.GetMsgArea;
      HdrStream:=InboundDir^.Packet^.GetMsgHdrStream;
      BodyStream:=InboundDir^.Packet^.GetMsgBodyStream;

      If Area='' then Area:='NETMAIL';
      If not Scanning then
        WriteLn('Pkt message ',i2,' ÍÍ ',Area);
      If not Scanning then
        LogFile^.SendStr('Ã Pkt message '+strIntToStr(i2)+' ÍÍ '+Area,'@');
      If Area='NETMAIL' then TossNetmail else TossEchomail;

      objDispose(HdrStream);
      objDispose(BodyStream);
      InboundDir^.Packet^.CloseMsg;
    end;

  If InboundDir^.Packet^.Status=pktBadPacket
        then BadPkt else  InboundDir^.ClosePkt;
end;

Procedure ProcessPacket;
Var
  sTemp:string;
  TempNode : PNode;
  i:integer;
begin
  If not InboundDir^.OpenPkt then
    begin
      BadPkt;
      exit;
    end;

{  InboundDir^.Packet^.SetFakeNet(777);}

  InboundDir^.Packet^.GetToAddress(PktTo);
  InboundDir^.Packet^.GetFromAddress(PktFrom);
  sTemp:=InboundDir^.GetPktName;

  If not Scanning then
     Counter^.AddBytes(InboundDir^.Packet^.PktSize);

  If not Scanning then
  WriteLn('Processing '+dosGetFileName(sTemp)+' from '
       +ftnAddressToStrEx(PktFrom)+' to '
       +ftnAddressToStrEx(PktTo)+'...');

  If not Scanning then
  LogFile^.SendStr('Õ Processing '+dosGetFileName(sTemp)+' from '
       +ftnAddressToStrEx(PktFrom)+' to '
       +ftnAddressToStrEx(PktTo)+'...',#32);

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  If CheckSecurity then
    begin

      If AddressBase^.FindAddress(PktTo)=-1 then
        begin
          BadPktDestination;
          exit;
        end;

      i:=NodeBase^.FindNode(PktFrom);

      If InboundDir^.Packet^.GetPktAreaType<>btNetmail then
        begin

          If i=-1 then
            begin
              BadPktPassword;
              Exit;
            end;

          TempNode:=NodeBase^.Nodes^.At(i);

          If TempNode^.PktPassword^<>InboundDir^.Packet^.GetPassword then
            begin
              BadPktPassword;
              Exit;
            end;

    end;
   end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  If not Scanning then
    WriteLn('           ÀÄ ',ftspcGetProgramName(InboundDir^.Packet^.GetProductCode)
    +#32+InboundDir^.Packet^.GetProductVersionString,', ',
    +InboundDir^.Packet^.GetPktTypeString);

  TossPkt;

  If not Scanning then
    LogFile^.SendStr('Ô Done!',#32);

  If not Scanning then
  WriteLn;
  dosErase(sTemp);
end;

Procedure TossPackets(Path:string;Ext:string);
Var
  i:integer;
begin
  InboundDir:=New(PPktDir,Init);
  PktQueue:=New(PPktQueue,Init);
  EchoQueue:=New(PEchoQueue,Init);

  InboundDir^.FastOpen:=True;

  InboundDir^.SetPktExtension(Ext);
  InboundDir^.AddPktExtension('P2K');

  InboundDir^.OpenDir(Path);

  If not Scanning then
     LogFile^.SendStr('Processing '+strIntToStr(InboundDir^.GetCount)
            +' incoming packets...','#');

  For i:=0 to InboundDir^.GetCount-1 do
    begin
      InboundDir^.Seek(i);
      ProcessPacket;
    end;

  InboundDir^.CloseDir;

  objDispose(PktQueue);
  objDispose(EchoQueue);
  objDispose(InboundDir);
end;

Procedure MoveToTemp;
  Procedure MoveExt(S:string);
  Var
    SR:SearchRec;
  begin
    FindFirst(InboundPath+'\*.'+S,AnyFile-Directory,SR);
    While DOSError=0 do
      begin
        dosMove(InboundPath+'\'+SR.Name,TempInboundPath+'\'+SR.Name);
        FindNext(SR);
      end;
  end;
begin
  If MovePackets then
    begin
      MoveExt('PKT');
      MoveExt('P2K');
    end;
  MoveExt('BCL');
end;

Procedure DoToss;
begin
  If DefEcholist.ListType<>ltNone then LoadDefEcholist;

  If ParamString^.CheckKey('A') then SpcAreafix^.ScanNetmail;

  If not ParamString^.CheckKey('P') then DoBeforeUnpack;

  If TempInboundPath<>InboundPath then MoveToTemp;

  TextColor(colOperation);
  Writeln('Unpacking archives...');
  TextColor(colLongline);
  Writeln(constLongLine);
  TextColor(7);
  WriteLn;
  LogFile^.SendStr('Unpacking archives...',#32);
  UnArcDir(InboundPath);
  LogFile^.SendStr('Done!',#32);

  If not ParamString^.CheckKey('P') then DoAfterUnpack;

  If ParamString^.CheckKey('B') then ExportBad;

  TextColor(colOperation);
  Writeln('Tossing messages...');
  TextColor(colLongline);
  Writeln(constLongLine);
  TextColor(7);

  LogFile^.SendStr('Tossing messages...',#32);

  Counter:=New(PCounter,Init);

  QueueDir:=New(PPktDir,Init);
  QueueDir^.SetPktExtension('QQQ');
  ExportNodes:=New(PNodelist,Init($10,$10));
  QueueDir^.OpenDir(QueuePath);
  QueueDir^.FastOpen:=True;

  ImportLists:=New(PImportLists,Init);
  ImportLists^.Path:=NewStr(ImportListsPath);
  ImportLists^.Read;

  DupeBase^.OpenDupeFile(HomeDir+'\spctoss.dup');

  CheckSecurity:=True;
  Scanning:=False;
  ProcessTrack:=True;

  If ParamString^.CheckKey('S') then
    begin
      CheckSecurity:=False;
      LogFile^.SendStr('Disabling all security checks...','&');
    end;

  Counter^.StartCount;
  TossPackets(TempInboundPath,'PKT');
  Counter^.EndCount;

  DupeBase^.SaveDupeFile;
  objDispose(DupeBase);

  LogFile^.SendStr('Done!',#32);
  LogFile^.SendStr(Counter^.GetSeconds+' sec, '
      +Counter^.GetMsgs+' msgs, '
      +Counter^.GetKbytes+' kb, '
      +Counter^.GetMsgSec+' msg/sec, '
      +Counter^.GetKBytesSec+' kb/sec'
      ,'#');

  AnnounceAreas;

  TextColor(colOperation);
  Writeln('Tossing local generated packets...');
  TextColor(colLongline);
  Writeln(constLongLine);
  TextColor(7);
  WriteLn;
  LogFile^.SendStr('Tossing local generated packets...',#32);

  CheckSecurity:=False;
  ProcessTrack:=False;
  TossPackets(LocalInboundPath,'PKT');

  LogFile^.SendStr('Done!',#32);

  objDispose(Badmail);
  objDispose(Dupemail);

  objDispose(ImportLists);
  If DefEcholist.ListType<>ltNone then objDispose(DefEcholist.List);

  ReceiveBCL;

  If not ParamString^.CheckKey('P') then DoBeforePack;

  TextColor(colOperation);
  Writeln('Packing outbound mail...');
  TextColor(colLongline);
  Writeln(constLongLine);
  TextColor(7);
  WriteLn;
  LogFile^.SendStr('Packing outbound mail...',#32);

  PackQueue;

  LogFile^.SendStr('Done!',#32);

  If not ParamString^.CheckKey('P') then DoAfterPack;
end;

end.
