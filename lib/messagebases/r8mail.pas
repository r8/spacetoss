{
 MessageBases stuff.
 (c) by Sergey Storchay (2:462/117@fidonet), 2000-2001.
}
Unit r8mail;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  r8abs,
  r8msgb,

  r8objs,
  r8dtm,
  r8ftn,
  r8str,

  objects;

const

{Error codes}
  mlOk                      = $00000000;
  mlPathNotFound            = $00000001;
  mlCantOpenOrCreateBase    = $00000002;
  mlCantOpenOrCreateMessage = $00000003;
  mlOutOfMessages           = $00000004;
  mlBaseLocked              = $00000005;


type

  TLastRead = record
    UserCRC : longint;
    UserID : longint;
    LastReadMsg : longint;
    HighReadMsg : longint;
  end;
  PLastRead = ^TLastRead;

  TLastreadCollection = object(TCollection)
    Procedure FreeItem(P:pointer);virtual;
  end;
  PLastreadCollection = ^TLastreadCollection;

  TMessageBase = object(TObject)
    Status : longint;
    CurrentMessage : longint;

    BasePath : PString;
    BaseType : byte;

    MessageBody : PMessageBody;
    Lastreads : PLastreadCollection;
    Indexes : PLongIntCollection;

    MessageOpened : boolean;

    Constructor Init;
    Destructor  Done; virtual;

    Procedure Open(const ABasePath:string);virtual;
    Procedure Create(const ABasePath:string);virtual;
    Procedure Close;virtual;

    Function GetCount:longint;virtual;

    Procedure CreateMessage(UseMsgID:Boolean);virtual;
    Procedure OpenMessage;virtual;
    Procedure OpenHeader;virtual;
    Procedure WriteMessage;virtual;
    Procedure WriteHeader;virtual;
    Procedure CloseMessage;virtual;
    Procedure KillMessage;virtual;
    Function GetAbsMessage:PAbsMessage;
    Function CutAbsMessage:PAbsMessage;
    Procedure PutAbsMessage(const AbsMessage:PAbsMessage);
    Procedure SetAbsMessage(const AbsMessage:PAbsMessage);

    Procedure SetTo(const ToName:string);virtual;
    Function GetTo:string;virtual;
    Procedure SetFrom(const FromName:string);virtual;
    Function GetFrom:string;virtual;
    Procedure SetSubj(const Subject:string);virtual;
    Function GetSubj:string;virtual;

    Procedure SetFromAddress(const Address:TAddress);virtual;
    Procedure SetToAddress(const Address:TAddress);virtual;
    Procedure GetFromAddress(var Address:TAddress);virtual;
    Procedure GetToAddress(var Address:TAddress);virtual;

    Procedure SetDateWritten(const ADateTime:TDateTime);virtual;
    Procedure SetDateArrived(const ADateTime:TDateTime);virtual;
    Procedure GetDateWritten(var ADateTime:TDateTime);virtual;
    Procedure GetDateArrived(var ADateTime:TDateTime);virtual;

    Procedure SetFlags(const Flags:longint);virtual;
    Procedure GetFlags(var Flags:longint);virtual;
    Function CheckFlag(const Flag:longint):boolean;
    Procedure SetFlag(const Flag:longint);virtual;
    Procedure ClearFlag(const Flag:longint);

    Function GetTimesRead:longint;virtual;
    Procedure SetTimesRead(const TR:longint);virtual;

    Procedure Flush;virtual;
    Procedure SetBaseType(const BT:byte);

    Procedure Seek(const i:longint);virtual;
    Procedure SeekNext;virtual;
    Procedure SeekPrev;virtual;

    Procedure ReadLastreads;virtual;
    Procedure WriteLastreads;virtual;
    Procedure IncLastreads(const I:longint);
    Procedure DecLastreads(const I:longint);

    Function SearchForIndex(const l:longint):longint;

    Function PackIsNeeded:boolean;virtual;

    Function GetSize:longint;virtual;

    Procedure Reset;virtual;
   end;
  PMessageBase =  ^TMessageBase;

implementation

Procedure TLastreadCollection.FreeItem(P:pointer);
begin
  If P<>nil then Dispose(PLastread(P));
end;


Constructor TMessageBase.Init;
begin
  inherited Init;

  Status:=mlOk;
  BaseType:=btNetmail;
  MessageOpened:=False;

  Lastreads:=New(PLastreadCollection,Init($10,$10));
  Indexes:=New(PLongIntCollection,Init($100,$100));
end;

Destructor TMessageBase.Done;
begin
  Close;

  DisposeStr(BasePath);
  objDispose(MessageBody);
  objDispose(Lastreads);
  objDispose(Indexes);

  inherited Done;
end;

Procedure TMessageBase.Open(const ABasePath:string);
begin
  Abstract;
end;

Procedure TMessageBase.Create(const ABasePath:string);
begin
  Abstract;
end;

Procedure TMessageBase.Close;
begin
  Abstract;
end;

Function TMessageBase.GetCount:longint;
begin
  Abstract;
end;

Procedure TMessageBase.CreateMessage(UseMsgID:Boolean);
Var
  TempDateTime : TDateTime;
begin
  MessageBody:=New(PMessageBody,Init);

  If UseMsgID then
    begin
      MessageBody^.KludgeBase^.SetKludge('MSGID:',
             ftnAddressToStrEx(NullAddress)+#32+strLower(ftnPktName));
      If BaseType=btNetmail then
        MessageBody^.KludgeBase^.SetKludge('INTL','0:0/0 0:0/0');
    end;

  dtmGetDateTime(TempDateTime);
  SetDateWritten(TempDateTime);
end;

Procedure TMessageBase.OpenMessage;
begin
  MessageBody:=New(PMessageBody,Init);
end;

Procedure TMessageBase.OpenHeader;
begin
  Abstract;
end;

Procedure TMessageBase.WriteMessage;
begin
  Abstract;
end;

Procedure TMessageBase.WriteHeader;
begin
  Abstract;
end;

Procedure TMessageBase.CloseMessage;
begin
  objDispose(MessageBody);
  MessageOpened:=False;
end;

Procedure TMessageBase.KillMessage;
begin
  Abstract;
end;

Function TMessageBase.GetAbsMessage:PAbsMessage;
Var
  AbsMessage : PAbsMessage;
begin
  AbsMessage:=New(PAbsMessage,Init(False,BaseType));

  GetFromAddress(AbsMessage^.FromAddress);
  GetToAddress(AbsMessage^.ToAddress);
  AbsMessage^.FromName:=NewStr(GetFrom);
  AbsMessage^.ToName:=NewStr(GetTo);
  AbsMessage^.Subject:=NewStr(GetSubj);
  GetFlags(AbsMessage^.Flags);
  GetDateWritten(AbsMessage^.DateTime);

  AbsMessage^.MessageBody^.KludgeBase^.CopyFrom(MessageBody^.KludgeBase);
  objDispose(AbsMessage^.MessageBody^.MsgBodyLink);
  AbsMessage^.MessageBody^.MsgBodyLink:=MessageBody^.GetMsgRawBodyStream;
  AbsMessage^.MessageBody^.PathLink:=MessageBody^.GetMsgPathStream;
  AbsMessage^.MessageBody^.SeenByLink:=MessageBody^.GetMsgSeenByStream;
  AbsMessage^.MessageBody^.ViaLink:=MessageBody^.GetMsgViaStream;

  If MessageBody^.TearLine<>nil
       then AbsMessage^.MessageBody^.TearLine:=NewStr(MessageBody^.TearLine^);
  If MessageBody^.Origin<>nil
       then AbsMessage^.MessageBody^.Origin:=NewStr(MessageBody^.Origin^);

  GetAbsMessage:=AbsMessage;
end;

Function TMessageBase.CutAbsMessage:PAbsMessage;
Var
  AbsMessage : PAbsMessage;
begin
  AbsMessage:=New(PAbsMessage,Init(False,BaseType));

  GetFromAddress(AbsMessage^.FromAddress);
  GetToAddress(AbsMessage^.ToAddress);
  AbsMessage^.FromName:=NewStr(GetFrom);
  AbsMessage^.ToName:=NewStr(GetTo);
  AbsMessage^.Subject:=NewStr(GetSubj);
  GetFlags(AbsMessage^.Flags);
  GetDateWritten(AbsMessage^.DateTime);

  objDispose(AbsMessage^.MessageBody);
  AbsMessage^.MessageBody:=MessageBody;
  MessageBody:=nil;
end;

Procedure TMessageBase.PutAbsMessage(const AbsMessage:PAbsMessage);
begin
  If AbsMessage^.FromName<>nil then SetFrom(AbsMessage^.FromName^);
  If AbsMessage^.ToName<>nil then SetTo(AbsMessage^.ToName^);
  If AbsMessage^.Subject<>nil then SetSubj(AbsMessage^.Subject^);

  SetDateWritten(AbsMessage^.DateTime);
  SetFlags(AbsMessage^.Flags);

  MessageBody^.KludgeBase^.CopyFrom(AbsMessage^.MessageBody^.KludgeBase);
  objDispose(MessageBody^.MsgBodyLink);
  MessageBody^.MsgBodyLink:=AbsMessage^.MessageBody^.GetMsgRawBodyStream;
  MessageBody^.PathLink:=AbsMessage^.MessageBody^.GetMsgPathStream;
  MessageBody^.SeenByLink:=AbsMessage^.MessageBody^.GetMsgSeenByStream;
  MessageBody^.ViaLink:=AbsMessage^.MessageBody^.GetMsgViaStream;

  If AbsMessage^.MessageBody^.TearLine<>nil
       then MessageBody^.TearLine:=NewStr(AbsMessage^.MessageBody^.TearLine^);
  If AbsMessage^.MessageBody^.Origin<>nil
       then MessageBody^.Origin:=NewStr(AbsMessage^.MessageBody^.Origin^);

  SetFromAddress(AbsMessage^.FromAddress);
  SetToAddress(AbsMessage^.ToAddress);
end;

Procedure TMessageBase.SetAbsMessage(const AbsMessage:PAbsMessage);
begin
  If AbsMessage^.FromName<>nil then SetFrom(AbsMessage^.FromName^);
  If AbsMessage^.ToName<>nil then SetTo(AbsMessage^.ToName^);
  If AbsMessage^.Subject<>nil then SetSubj(AbsMessage^.Subject^);

  SetDateWritten(AbsMessage^.DateTime);
  SetFlags(AbsMessage^.Flags);

  objDispose(MessageBody^.KludgeBase);
  MessageBody^.KludgeBase:=AbsMessage^.MessageBody^.KludgeBase;
  AbsMessage^.MessageBody^.KludgeBase:=nil;

  objDispose(MessageBody^.MsgBodyLink);
  MessageBody^.MsgBodyLink:=AbsMessage^.MessageBody^.MsgBodyLink;
  AbsMessage^.MessageBody^.MsgBodyLink:=nil;

  MessageBody^.PathLink:=AbsMessage^.MessageBody^.PathLink;
  AbsMessage^.MessageBody^.PathLink:=nil;

  MessageBody^.SeenByLink:=AbsMessage^.MessageBody^.SeenByLink;
  AbsMessage^.MessageBody^.SeenByLink:=nil;

  MessageBody^.ViaLink:=AbsMessage^.MessageBody^.ViaLink;
  AbsMessage^.MessageBody^.ViaLink:=nil;

  MessageBody^.TearLine:=AbsMessage^.MessageBody^.TearLine;
  AbsMessage^.MessageBody^.TearLine:=nil;
  MessageBody^.Origin:=AbsMessage^.MessageBody^.Origin;
  AbsMessage^.MessageBody^.Origin:=nil;

  SetFromAddress(AbsMessage^.FromAddress);
  SetToAddress(AbsMessage^.ToAddress);
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

Procedure TMessageBase.SetFromAddress(const Address:TAddress);
Var
 ToAddress : TAddress;
 sTemp : string;
begin
  GetToAddress(ToAddress);

  If BaseType=btNetmail then
   begin
      If MessageBody^.KludgeBase^.FindKludge('INTL')<>nil then
        MessageBody^.KludgeBase^.SetKludge('INTL',
        ftnAddressToStrPointless(ToAddress)+#32+
        ftnAddressToStrPointless(Address));

     If Address.Point<>0 then MessageBody^.KludgeBase^.SetKludge('FMPT',
                          strIntToStr(Address.Point)) else
                          MessageBody^.KludgeBase^.KillKludge('FMPT');
   end;


  sTemp:=MessageBody^.KludgeBase^.GetKludge('MSGID:');

  If ftnCheckAddressString(strParser(sTemp,1,[#32])) then
    MessageBody^.KludgeBase^.SetKludge('MSGID:',
      ftnAddressToStrEx(Address)+#32+strParser(sTemp,2,[#32]));
end;

Procedure TMessageBase.SetToAddress(const Address:TAddress);
Var
 FromAddress : TAddress;
begin
  GetFromAddress(FromAddress);

  If BaseType=btNetmail then
    begin
      If MessageBody^.KludgeBase^.FindKludge('INTL')<>nil then
        MessageBody^.KludgeBase^.SetKludge('INTL',
        ftnAddressToStrPointless(Address)+#32+
        ftnAddressToStrPointless(FromAddress));

     If Address.Point<>0 then MessageBody^.KludgeBase^.SetKludge('TOPT',
                           strIntToStr(Address.Point)) else
                           MessageBody^.KludgeBase^.KillKludge('TOPT');
    end;
end;

Procedure TMessageBase.GetFromAddress(Var Address:TAddress);
begin
  Abstract;
end;

Procedure TMessageBase.GetToAddress(var Address:TAddress);
begin
  Abstract;
end;

Procedure TMessageBase.SetDateWritten(const ADateTime:TDateTime);
begin
  Abstract;
end;

Procedure TMessageBase.SetDateArrived(const ADateTime:TDateTime);
begin
  Abstract;
end;

Procedure TMessageBase.GetDateWritten(var ADateTime:TDateTime);
begin
  Abstract;
end;

Procedure TMessageBase.GetDateArrived(var ADateTime:TDateTime);
begin
  Abstract;
end;

Procedure TMessageBase.SetFlags(const Flags:longint);
begin
  Abstract;
end;

Procedure TMessageBase.GetFlags(var Flags:longint);
begin
  Abstract;
end;

Procedure TMessageBase.Flush;
begin
  Abstract;
end;

Procedure TMessageBase.Seek(const i:longint);
begin
  Abstract;
end;

Procedure TMessageBase.SeekNext;
begin
  Abstract;
end;

Procedure TMessageBase.SeekPrev;
begin
  Abstract;
end;

Procedure TMessageBase.Reset;
begin
  Status:=mlOk;
end;

Function TMessageBase.CheckFlag(const Flag:longint):boolean;
Var
  TempFlags : longint;
begin
  CheckFlag:=False;

  GetFlags(TempFlags);
  If (TempFlags and Flag)=Flag then CheckFlag:=True;
end;

Procedure TMessageBase.SetFlag(const Flag:longint);
Var
  TempFlags : longint;
begin
  GetFlags(TempFlags);

  SetFlags(TempFlags or Flag);
end;

Procedure TMessageBase.ClearFlag(const Flag:longint);
var
  Flags : longint;
begin
  GetFlags(Flags);
  SetFlags(Flags and not Flag);
end;

Procedure TMessageBase.SetBaseType(const BT:byte);
begin
  BaseType:=BT;
end;

Procedure TMessageBase.ReadLastreads;
begin
  Abstract;
end;

Procedure TMessageBase.WriteLastreads;
begin
  Abstract;
end;

Procedure TMessageBase.IncLastreads(const I:longint);
  Procedure ProcessLastread(P:pointer);far;
  Var
    Lastread : PLastread absolute P;
  begin
    Inc(Lastread^.LastReadMsg,I);
    Inc(Lastread^.HighReadMsg,I);
  end;
begin
  Lastreads^.ForEach(@ProcessLastread);
end;

Procedure TMessageBase.DecLastreads(const I:longint);
  Procedure ProcessLastread(P:pointer);far;
  Var
    Lastread : PLastread absolute P;
  begin
    Dec(Lastread^.LastReadMsg,I);
    Dec(Lastread^.HighReadMsg,I);

    If Lastread^.LastReadMsg<0 then Lastread^.LastReadMsg:=0;
    If Lastread^.HighReadMsg<0 then Lastread^.HighReadMsg:=0;
  end;
begin
  Lastreads^.ForEach(@ProcessLastread);
end;

Function TMessageBase.PackIsNeeded:boolean;
begin
  Abstract;
end;

Function TMessageBase.GetSize:longint;
begin
  Abstract;
end;

Function TMessageBase.GetTimesRead:longint;
begin
  Abstract;
end;

Procedure TMessageBase.SetTimesRead(const TR:longint);
begin
  Abstract;
end;

Function TMessageBase.SearchForIndex(const l:longint):longint;
var
  pTemp : Pointer;
  i : longint;

  Function ProcessIndex(p:pointer):boolean;far;
  var
    Index : PLongint absolute p;
  begin
    Inc(i);
    if Index^=l then ProcessIndex:=True else ProcessIndex:=false;
  end;
begin
  SearchForIndex:=-1;

  i:=-1;
  pTemp:=Indexes^.FirstThat(@ProcessIndex);
  if pTemp<>nil then SearchForIndex:=i+1;
end;

end.
