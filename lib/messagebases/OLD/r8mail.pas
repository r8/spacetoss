{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit r8Mail;

interface

Uses
  r8dtm,
  r8abs,
  r8ftn,
  r8objs,
  strings,
  r8msgb,
  r8str,
  objects;

Type

  TMessageBase = object(TObject)
    BasePath : PString;
    BaseType : byte;

    MessageBody : PMessageBody;

    CurrentMessage : longint;

    MsgOpened : boolean;

    Constructor Init;
    Destructor Done;virtual;

    Function OpenBase(Path:string):boolean;virtual;
    Function CreateBase(Path:string):boolean;virtual;
    Procedure CloseBase;virtual;

    Procedure GetBaseTime(var BaseTime:TDateTime);virtual;

    Function GetSize:longint;virtual;

    Function GetCount:longint;virtual;
    Procedure Seek(i:longint);virtual;
    Procedure SeekNext;virtual;

    Function CreateNewMessage(UseMsgID:Boolean):boolean;virtual;
    Function OpenMsg:boolean;virtual;
    Function WriteMessage:boolean;virtual;
    Procedure CloseMessage;virtual;
    Procedure KillMessage;virtual;

    Procedure SetTo(const ToName:string);virtual;
    Function GetTo:string;virtual;
    Procedure SetFrom(const FromName:string);virtual;
    Function GetFrom:string;virtual;
    Procedure SetSubj(const Subject:string);virtual;
    Function GetSubj:string;virtual;
    Procedure SetDateWritten(MDateTime:TDateTime);virtual;
    Procedure SetDateArrived(MDateTime:TDateTime);virtual;
    Procedure GetDateWritten(var MDateTime:TDateTime);virtual;
    Procedure GetDateArrived(var MDateTime:TDateTime);virtual;
    Procedure SetFlags(Flags:longint);virtual;
    Procedure GetFlags(var Flags:longint);virtual;
    Procedure SetFromAddress(Address:TAddress);virtual;
    Procedure SetToAddress(Address:TAddress);virtual;
    Procedure GetFromAddress(var Address:TAddress);virtual;
    Procedure GetToAddress(var Address:TAddress);virtual;
    Procedure SetFromAndToAddress(FromAddress,ToAddress:tAddress);
    Function CheckFlag(Flag:longint):boolean;
    Procedure SetFlag(Flag:longint);virtual;
    Procedure ClearFlag(Flag:longint);
    Function GetLastRead:longint;virtual;
    Procedure SetLastRead(lr:longint);virtual;

    Function GetMsgBodyStream:PStream;virtual;

    Procedure GetMsgSeenbys(var Addresses:PAddressCollection);virtual;
    Procedure GetMsgPaths(var Addresses:PAddressCollection);virtual;

    Procedure SetBaseType(BT:byte);
    Procedure Flush;virtual;

    Function GetRawMessage:pointer;virtual;
    Procedure PutRawMessage(P:pointer);virtual;
    Function PackIsNeeded:boolean;virtual;

    Procedure PutAbsMessage(Message:PAbsMessage);
    Function  GetAbsMessage:PAbsMessage;
  end;

PMessageBase = ^TMessageBase;

implementation

Constructor TMessageBase.Init;
begin
  inherited Init;

  BasePath:=nil;
  BaseType:=btEchoMail;
  CurrentMessage:=0;
  MsgOpened:=False;
end;

Destructor TMessageBase.Done;
begin
  DisposeStr(BasePath);

  inherited Done;
end;

Function TMessageBase.OpenBase(Path:string):boolean;
begin
  CurrentMessage:=0;
end;

Function TMessageBase.CreateBase(Path:string):boolean;
begin
  Abstract;
end;

Function TMessageBase.CreateNewMessage(UseMsgID:Boolean):boolean;
Var
  TempDateTime : TDateTime;
begin
  MessageBody:=New(PMessageBody,Init);

  If UseMsgID then
      MessageBody^.KludgeBase^.SetKludge('MSGID:',
             ftnAddressToStrEx(NullAddress)+#32+strLower(ftnPktName));

  dtmGetDateTime(TempDateTime);
  SetDateWritten(TempDateTime);
end;

Procedure TMessageBase.CloseMessage;
begin
  MsgOpened:=False;
  objDispose(MessageBody);
end;

Procedure TMessageBase.KillMessage;
begin
  Abstract;
end;

Function TMessageBase.WriteMessage:boolean;
begin
  Abstract;
end;

Procedure TMessageBase.SetTo(const ToName:string);
begin
  Abstract;
end;

Procedure TMessageBase.SetFrom(const FromName:string);
begin
  Abstract;
end;

Procedure TMessageBase.SetSubj(const Subject:string);
begin
  Abstract;
end;

Procedure TMessageBase.SetDateWritten(MDateTime:TDateTime);
begin
  Abstract;
end;

Procedure TMessageBase.SetDateArrived(MDateTime:TDateTime);
begin
  Abstract;
end;

Procedure TMessageBase.GetDateWritten(var MDateTime:TDateTime);
begin
  Abstract;
end;

Procedure TMessageBase.GetDateArrived(var MDateTime:TDateTime);
begin
  Abstract;
end;

Procedure TMessageBase.SetFlags(Flags:longint);
begin
  Abstract;
end;

Procedure TMessageBase.ClearFlag(Flag:longint);
var
  Flags : longint;
begin
  GetFlags(Flags);
  SetFlags(Flags and not Flag);
end;

Procedure TMessageBase.GetFlags(var Flags:longint);
begin
  Abstract;
end;

Procedure TMessageBase.SetFromAddress(Address:TAddress);
Var
 ToAddress : TAddress;
begin
  GetToAddress(ToAddress);

  If BaseType=btNetmail then
   begin
    MessageBody^.KludgeBase^.SetKludge('INTL',
        ftnAddressToStrPointless(ToAddress)+#32+
        ftnAddressToStrPointless(Address));
    end;

  If BaseType=btNetmail then
   begin
    If Address.Point<>0 then MessageBody^.KludgeBase^.SetKludge('FMPT',
                          strIntToStr(Address.Point)) else
                           MessageBody^.KludgeBase^.KillKludge('FMPT');
   end;


  If ftnCheckAddrString(strParser(MessageBody^.KludgeBase^.
             GetKludge('MSGID:'),1,[#32])) then
    MessageBody^.KludgeBase^.SetKludge('MSGID:',ftnAddressToStrEx(Address)+#32+
        strParser(MessageBody^.KludgeBase^.GetKludge('MSGID:'),2,[#32]));
end;

Procedure TMessageBase.SetToAddress(Address:TAddress);
Var
 FromAddress : TAddress;
begin
  GetFromAddress(FromAddress);

  If BaseType=btNetmail then
    MessageBody^.KludgeBase^.SetKludge('INTL',
        ftnAddressToStrPointless(Address)+#32+
        ftnAddressToStrPointless(FromAddress));

  If BaseType=btNetmail then
  If Address.Point<>0 then MessageBody^.KludgeBase^.SetKludge('TOPT',
                         strIntToStr(Address.Point)) else
                         MessageBody^.KludgeBase^.KillKludge('TOPT');
end;

Procedure TMessageBase.GetFromAddress(Var Address:TAddress);
begin
  Abstract;
end;

Procedure TMessageBase.GetToAddress(var Address:TAddress);
begin
  Abstract;
end;

Procedure TMessageBase.SetBaseType(BT:byte);
begin
  BaseType:=BT;
end;

Procedure TMessageBase.CloseBase;
begin
  Abstract;
end;

Function TMessageBase.GetCount:longint;
begin
  Abstract;
end;

Procedure TMessageBase.Seek(i:longint);
begin
  If i>GetCount-1 then exit;
  If i<0 then exit;
  If GetCount=0 then exit;
  CurrentMessage:=i;
end;

Procedure TMessageBase.SeekNext;
begin
  Seek(CurrentMessage+1);
end;

Function TMessageBase.OpenMsg:boolean;
begin
  MessageBody:=New(PMessageBody,Init);
end;

Function TMessageBase.GetTo:string;
begin
  Abstract;
end;

Function TMessageBase.GetSubj:string;
begin
  Abstract;
end;

Function TMessageBase.GetFrom:string;
begin
  Abstract;
end;

Function TMessageBase.CheckFlag(Flag:longint):boolean;
Var
  TempFlags : longint;
begin
  CheckFlag:=False;

  GetFlags(TempFlags);
  If (TempFlags and Flag)=Flag then CheckFlag:=True;
end;

Procedure TMessageBase.SetFlag(Flag:longint);
Var
  TempFlags : longint;
begin
  GetFlags(TempFlags);

  SetFlags(TempFlags or Flag);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TMessageBase.SetFromAndToAddress(FromAddress,ToAddress:tAddress);
begin
  SetFromAddress(FromAddress);
  SetToAddress(ToAddress);
end;

Function TMessageBase.GetSize:longint;
begin
  Abstract;
end;

Function TMessageBase.GetMsgBodyStream:PStream;
begin
  GetMsgBodyStream:=MessageBody^.GetMsgBodyStream;
end;

Procedure TMessageBase.GetBaseTime(var BaseTime:TDateTime);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TMessageBase.GetMsgSeenbys(var Addresses:PAddressCollection);
var
  iTemp:longint;
  i:integer;
  sTemp:string;
  s:string;
  PrevAddress:TAddress;
  TempAddress:PAddress;
begin
  MessageBody^.SeenByLink^.Seek(0);

  GetFromAddress(PrevAddress);

  iTemp:=MessageBody^.SeenByLink^.GetSize;
  While MessageBody^.SeenByLink^.GetPos<iTemp-1 do
    begin
      sTemp:=strTrimR(objStreamReadStr(MessageBody^.SeenByLink),[#32]);
      For i:=2 to strNumbOfTokens(sTemp,[#32]) do
        begin
          s:=strParser(sTemp,i,[#32]);
          New(TempAddress);
          TempAddress^:=PrevAddress;
          ftnStrToAddress(s,TempAddress^);
          Addresses^.Insert(TempAddress);
          PrevAddress:=TempAddress^;
        end;
    end;
end;

Procedure TMessageBase.GetMsgPaths(var Addresses:PAddressCollection);
var
  iTemp:longint;
  i:integer;
  sTemp:string;
  s:string;
  PrevAddress:TAddress;
  TempAddress:PAddress;
begin
  MessageBody^.PathLink^.Seek(0);

  GetFromAddress(PrevAddress);

  iTemp:=MessageBody^.PathLink^.GetSize;
  While MessageBody^.PathLink^.GetPos<iTemp-1 do
    begin
      sTemp:=strTrimR(objStreamReadStr(MessageBody^.PathLink),[#32]);
      For i:=2 to strNumbOfTokens(sTemp,[#32]) do
        begin
          s:=strParser(sTemp,i,[#32]);
          New(TempAddress);
          TempAddress^:=PrevAddress;
          ftnStrToAddress(s,TempAddress^);
          Addresses^.Insert(TempAddress);
          PrevAddress:=TempAddress^;
        end;
    end;
end;

Procedure TMessageBase.Flush;
begin
  Abstract;
end;

Function TMessageBase.GetRawMessage:pointer;
begin
  Abstract;
end;

Procedure TMessageBase.PutRawMessage(P:pointer);
begin
  Abstract;
end;

Function TMessageBase.PackIsNeeded:boolean;
begin
  Abstract;
end;

Procedure TMessageBase.PutAbsMessage(Message:PAbsMessage);
begin
  CreateNewMessage(False);

  SetTo(Message^.ToName);
  SetFrom(Message^.FromName);
  SetSubj(Message^.Subj);
  SetFlags(flgNone);

  SetDateWritten(Message^.DateTime);

  MessageBody^.AddtoMsgBodyStream(Message^.BodyStream);
  MessageBody^.PutMsgSeenByStream(Message^.SeenByStream);
  MessageBody^.PutMsgPathStream(Message^.PathStream);

  SetFromAddress(Message^.FromAddress);
  SetToAddress(Message^.ToAddress);

  WriteMessage;
  CloseMessage;
end;

Function TMessageBase.GetAbsMessage:PAbsMessage;
Var
  Message : PAbsMessage;
begin
  Message:=New(PAbsMessage,Init);

  Message^.ToName:=GetTo;
  Message^.FromName:=GetFrom;
  Message^.Subj:=GetSubj;

  GetDateWritten(Message^.DateTime);

  MessageBody^.AddtoMsgBodyStream(Message^.BodyStream);
  MessageBody^.PutMsgSeenByStream(Message^.SeenByStream);
  MessageBody^.PutMsgPathStream(Message^.PathStream);

  GetFromAddress(Message^.FromAddress);
  GetToAddress(Message^.ToAddress);
end;

Function TMessageBase.GetLastRead:longint;
begin
  Abstract;
end;

Procedure TMessageBase.SetLastRead(lr:longint);
begin
  Abstract;
end;

end.
