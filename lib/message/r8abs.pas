{
 AsoluteMessage stuff.
 (c) by Sergey Storchay (2:462/117@fidonet), 2000-2001.
}
Unit r8abs;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  r8ftn,
  r8dtm,
  r8str,
  r8msgb,
  r8objs,
  objects;

Type

  TAbsMessageCollection = object(TCollection)
    Procedure FreeItem(Item:pointer);virtual;
  end;
  PAbsMessageCollection = ^TAbsMessageCollection;

  TAbsMessage = object(TObject)
    FromAddress : TAddress;
    ToAddress   : TAddress;
    Area : PString;
    FromName : PString;
    ToName  : PString;
    Subject : PString;
    Flags : longint;

    DateTime : TDateTime;

    MessageBody : PMessageBody;

    Constructor Init(UseMsgID:Boolean;BaseType:word);
    Destructor Done;virtual;
  end;
  PAbsMessage = ^TAbsMessage;

Function absCopyAbsMessage(InAbsMessage:PAbsMessage):PAbsMessage;

implementation

Constructor TAbsMessage.Init(UseMsgID:Boolean;BaseType:word);
begin
  inherited Init;

  Area:=nil;
  FromName:=nil;
  ToName:=nil;
  Subject:=nil;
  Flags:=0;
  dtmGetDateTime(DateTime);

  MessageBody:=New(PMessageBody,Init);

  If UseMsgID then
    begin
      MessageBody^.KludgeBase^.SetKludge('MSGID:',
             ftnAddressToStrEx(NullAddress)+#32+strLower(ftnPktName));
      If BaseType=btNetmail then
        MessageBody^.KludgeBase^.SetKludge('INTL','0:0/0 0:0/0');
    end;
end;

Destructor TAbsMessage.Done;
begin
  DisposeStr(Area);
  DisposeStr(FromName);
  DisposeStr(ToName);
  DisposeStr(Subject);

  objDispose(MessageBody);

  inherited Done;
end;

Procedure TAbsMessageCollection.FreeItem(Item:pointer);
begin
  objDispose(PAbsMessage(Item));
end;

Function absCopyAbsMessage(InAbsMessage:PAbsMessage):PAbsMessage;
Var
  AbsMessage : PAbsMessage;
begin
  absCopyAbsMessage:=nil;
  If InAbsMessage=nil then exit;

  AbsMessage:=New(PAbsMessage,Init(False,btEchoMail));

  If InAbsMessage^.Area<>nil
    then AbsMessage^.Area:=NewStr(InAbsMessage^.Area^);

  AbsMessage^.FromAddress:=InAbsMessage^.FromAddress;
  AbsMessage^.ToAddress:=InAbsMessage^.ToAddress;

  If InAbsMessage^.FromName<>nil
    then AbsMessage^.FromName:=NewStr(InAbsMessage^.FromName^);
  If InAbsMessage^.ToName<>nil
    then AbsMessage^.ToName:=NewStr(InAbsMessage^.ToName^);
  If InAbsMessage^.Subject<>nil
    then AbsMessage^.Subject:=NewStr(InAbsMessage^.Subject^);

  AbsMessage^.Flags:=InAbsMessage^.Flags;
  AbsMessage^.DateTime:=InAbsMessage^.DateTime;

  AbsMessage^.MessageBody^.KludgeBase^.CopyFrom(InAbsMessage^.MessageBody^.KludgeBase);
  objDispose(AbsMessage^.MessageBody^.MsgBodyLink);
  AbsMessage^.MessageBody^.MsgBodyLink:=InAbsMessage^.MessageBody^.GetMsgRawBodyStream;
  AbsMessage^.MessageBody^.PathLink:=InAbsMessage^.MessageBody^.GetMsgPathStream;
  AbsMessage^.MessageBody^.SeenByLink:=InAbsMessage^.MessageBody^.GetMsgSeenByStream;
  AbsMessage^.MessageBody^.ViaLink:=InAbsMessage^.MessageBody^.GetMsgViaStream;

  If InAbsMessage^.MessageBody^.TearLine<>nil
       then AbsMessage^.MessageBody^.TearLine:=NewStr(InAbsMessage^.MessageBody^.TearLine^);
  If InAbsMessage^.MessageBody^.Origin<>nil
       then AbsMessage^.MessageBody^.Origin:=NewStr(InAbsMessage^.MessageBody^.Origin^);

  absCopyAbsMessage:=AbsMessage;
end;


end.