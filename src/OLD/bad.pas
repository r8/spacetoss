{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit Bad;

interface

Uses
  r8ftn,
  r8dtm,
  r8pkt,
  r8objs,
  nodes,
  global;

Procedure ExportBad;

implementation

Procedure ExportMessage;
Var
  TempAddress :tAddress;
  DateTime : TDateTime;
  i:integer;
  TempNode : PNode;
begin
  InboundDir^.CreateNewPkt;
  InboundDir^.Packet^.SetPktAreaType(btEchomail);
  InboundDir^.Packet^.WritePkt;

  InboundDir^.Packet^.CreateNewMsg(False);

  InboundDir^.Packet^.SetMsgArea(
         InboundDir^.Packet^.MessageBody^.KludgeBase^.GetKludge('AREA:'));

  InboundDir^.Packet^.SetMsgTo(BadMail^.GetTo);
  InboundDir^.Packet^.SetMsgFrom(BadMail^.GetFrom);
  InboundDir^.Packet^.SetMsgSubj(BadMail^.GetSubj);

  BadMail^.GetToAddress(TempAddress);
  InboundDir^.Packet^.SetMsgToAddress(TempAddress);

  BadMail^.GetFromAddress(TempAddress);
  InboundDir^.Packet^.SetMsgFromAddress(TempAddress);

  InboundDir^.Packet^.
             MessageBody^.AddToMsgBodyStream(BadMail^.MessageBody^.GetMsgBodyStream);

  ftnStrToAddress(InboundDir^.Packet^.MessageBody^.KludgeBase^.GetKludge('PKTFROM:'),
                                        TempAddress);

  InboundDir^.Packet^.SetFromAddress(TempAddress);

  InboundDir^.Packet^.SetPassword('');
  TempNode:=NodeBase^.FindNode(TempAddress);

  If TempNode<>nil then
    begin
      InboundDir^.Packet^.SetPassword(TempNode^.PktPassword^);
    end;

  AddressBase^.FindNearest(TempAddress,TempAddress);
  InboundDir^.Packet^.SetToAddress(TempAddress);

  InboundDir^.Packet^.MessageBody^.KludgeBase^.KillKludge('AREA:');
  InboundDir^.Packet^.MessageBody^.KludgeBase^.KillKludge('PKTFROM:');
  InboundDir^.Packet^.MessageBody^.KludgeBase^.KillKludge('REASON:');

  BadMail^.GetDateWritten(DateTime);
  InboundDir^.Packet^.SetMsgDateTime(DateTime);

  InboundDir^.Packet^.WritePkt;
  InboundDir^.Packet^.WriteMsg;
  InboundDir^.Packet^.CloseMsg;

  BadMail^.KillMessage;

  InboundDir^.ClosePkt;
end;

Procedure ExportBad;
Var
  i:integer;
begin
  LogFile^.SendStr('Retossing Badmail area...','#');

  InboundDir:=New(PPktDir,Init);
  InboundDir^.SetPktExtension('PKT');
  InboundDir^.OpenDir(TempInboundPath);

  BadMail^.Seek(0);
  For i:=0 to BadMail^.GetCount-1 do
    begin
      BadMail^.OpenMessage;
      ExportMessage;
      BadMail^.CloseMessage;
      BadMail^.SeekNext;
    end;

  InboundDir^.CloseDir;
  objDispose(InboundDir);
end;

end.
