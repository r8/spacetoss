{
 Bad Retosser.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.

 Area:<echotag>
}
Unit Bad;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  areas,
  nodes,
  color,
  lng,
  scan,
  pqueue,

  r8abs,
  r8msgb,
  r8ftn,
  r8objs,
  r8pkt,
  r8mail,
  r8str,

  crt,
  objects;

type

  TBadPktQueue = object(TPktQueue)
    Constructor Init;
    Destructor  Done; virtual;
    Procedure SetPktData(const Node:PNode);virtual;
  end;
  PBadPktQueue = ^TBadPktQueue;

  TBadRetosser = object(TScanner)
    BadPktQueue : PBadPktQueue;

    Constructor Init;
    Destructor  Done; virtual;

    Procedure Scan;virtual;
    Procedure ScanRAW(const Area:PArea);virtual;
    Procedure ExportMessage(const Area:PArea);virtual;
  end;
  PBadRetosser = ^TBadRetosser;

implementation

Uses
  global;

Constructor TBadPktQueue.Init;
begin
  inherited Init;

  objDispose(QueueDir);

  QueueDir:=New(PPktDir,Init);
  QueueDir^.SetPktExtension('PKT');
  QueueDir^.OpenDir(TempInboundPath);
end;

Destructor TBadPktQueue.Done;
begin
  inherited Done;
end;

Procedure TBadPktQueue.SetPktData(const Node:PNode);
begin
  QueueDir^.Packet^.SetToAddress(Node^.UseAka);
  QueueDir^.Packet^.SetFromAddress(Node^.Address);
  If Node^.PktPassword<>nil
    then QueueDir^.Packet^.SetPassword(Node^.PktPassword^);
  QueueDir^.Packet^.SetPktAreaType(btEchomail);
  QueueDir^.Packet^.WritePkt;
end;

Constructor TBadRetosser.Init;
begin
  inherited Init(scnDontUseHighWaters,AreaBase^.Badmail);

  BadPktQueue:=New(PBadPktQueue,Init);
end;

Destructor  TBadRetosser.Done;
begin
  objDispose(BadPktQueue);

  inherited Done;
end;

Procedure TBadRetosser.ExportMessage(const Area:PArea);
Var
  AbsMessage : PAbsMessage;
  TempNode : PNode;
  TempAddress : TAddress;
  sTemp : string;
  Packet : PPacket;
  TempKludge : PKludge;
begin
  Area^.MessageBase^.OpenMessage;
  AbsMessage:=Area^.MessageBase^.GetAbsMessage;

  TempKludge:=AbsMessage^.MessageBody^.KludgeBase^.Kludges^.At(0);

  If (AbsMessage^.MessageBody^.KludgeBase^.FindKludge('PKTFROM:')=nil) or
     (TempKludge^.Name=nil) or
     (strParser(TempKludge^.Name^,1,[':'])<>'AREA')
   then
    begin
      objDispose(AbsMessage);
      Area^.MessageBase^.CloseMessage;
      exit;
    end;

  ftnStrToAddress(AbsMessage^.MessageBody^.KludgeBase^.GetKludge('PKTFROM:'),
                                        TempAddress);

  TempNode:=NodeBase^.FindNode(TempAddress);
  Packet:=BadPktQueue^.OpenPkt(TempNode);

  AbsMessage^.Area:=NewStr(strParser(TempKludge^.Name^,2,[':']));
  AbsMessage^.MessageBody^.KludgeBase^.KillKludge(TempKludge^.Name^);
  AbsMessage^.MessageBody^.KludgeBase^.KillKludge('REASON:');
  AbsMessage^.MessageBody^.KludgeBase^.KillKludge('PKTFROM:');

  Packet^.CreateNewMsg(False);

  Packet^.SetAbsMessage(AbsMessage,False);
  Packet^.WriteMsg;
  Packet^.MessageBody:=nil;
  objDispose(AbsMessage);

  Area^.MessageBase^.KillMessage;
  Area^.MessageBase^.CloseMessage;
end;

Procedure TBadRetosser.ScanRAW(const Area:PArea);
begin
  OpenBase(Area);
  If Area^.MessageBase=nil then exit;

  Area^.MessageBase^.SeekNext;
  While Area^.MessageBase^.Status=mlOk do
    begin
      ExportMessage(Area);
      Area^.MessageBase^.SeekNext;
    end;

  CloseBase(Area);
end;

Procedure TBadRetosser.Scan;
begin
  TextColor(colOperation);
  Writeln(LngFile^.GetString(LongInt(lngExportingBads)));
  TextColor(colLongline);
  Writeln(constLongLine);
  TextColor(7);
  LogFile^.SendStr(LngFile^.GetString(LongInt(lngExportingBads)),#32);

  QueueDir:=New(PPktDir,Init);
  QueueDir^.SetPktExtension('PKT');
  QueueDir^.OpenDir(TempInboundPath);

  ScanRaw(Areas^.At(0));

  QueueDir^.CloseDir;
  objDispose(QueueDir);


  LogFile^.SendStr(LngFile^.GetString(LongInt(lngDone)),#32);
  TextColor(colLongline);
  Writeln(constLongLine);
  TextColor(7);
end;

end.

