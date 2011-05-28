{
à®¢¥àªã ­  Kludge^.Name Kludge^.value=nil

}
{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
  {$PackRecords 1}
{$ENDIF}
Unit r8PktY2;

interface
Uses
  r8ftn,
  r8dtm,
  r8str,
  r8dos,
  r8objs,
  objects,
  r8pktsa,
  r8msgb,
  r8pkt;

const

  y2kKillSent     = 1;
  y2kFileAttached = 2;
  y2kFileRequest  = 3;
  y2kTruncFile    = 4;
  y2kKillFile     = 5;

  y2kCrash        = 1;
  y2kHold         = 2;
  y2kDirect       = 3;
  y2kExclusive    = 4;
  y2kImmediate    = 5;

  y2kLocal        = 1;
  y2kSent         = 2;
  y2kPrivate      = 3;
  y2kOrphan       = 4;

Type

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
  TPktY2Address = record
    Zone, Net, Node, Point : word;
  end;
  PPktY2Address = ^TPktY2Address;

  TPktY2Hdr = record
    MainHeaderLen   : word;
    SubHeaderLen    : word;
    OrigZone,
    OrigNet,
    OrigNode,
    OrigPoint : word;
    OrigDomain      : string[30];
    DestZone,
    DestNet,
    DestNode,
    DestPoint : word;
    DestDomain      : string[30];
    Password        : string[8];
    ProductName     : string[30];
    PktVersionMajor : word;
    PktVersionMinor : word;
  end;

  TMsgY2Hdr = record
    OrigAddress      : TPktY2Address;
    DestAddress      : TPktY2Address;
    WrittenAddress   : TPktY2Address;
    Year             : Word;
    Month            : Byte;
    Day              : Byte;
    Hour             : Byte;
    Min              : Byte;
    Sec              : Byte;
    Sec100           : Byte;
    FAttribute       : Byte;
    RAttribute       : Byte;
    GAttribute       : Byte;
    SeenBys          : Word;
    Paths            : Word;
    TextBytes        : Longint;
  end;

  TPacketY2 = object(TPacket)
    PktY2Header : TPktY2Hdr;
    MsgHeader : TMsgY2Hdr;
    MsgTo     : string[35];
    MsgFrom   : string[35];
    MsgSubject : string[80];

    ReplyTo : string;
    MsgId : string;

    SeenBys : PAddressCollection;
    Paths : PAddressCollection;

    Constructor Init;
    Destructor Done;virtual;

    Procedure OpenPkt(Pkt:string);virtual;
    Procedure ClosePkt;virtual;
    Function CreateNewPkt(Pkt:string):boolean;virtual;
    Procedure SetPktHeaderDefaults;virtual;
    Procedure WritePkt;virtual;

    Procedure SetFakeNet(Fake:Integer);virtual;
    Procedure GetToAddress(var Address:TAddress);virtual;
    Procedure GetFromAddress(var Address:TAddress);virtual;
    Procedure SetToAddress(Address:TAddress);virtual;
    Procedure SetFromAddress(Address:TAddress);virtual;
    Function GetPassword:string;virtual;
    Procedure SetPassword(Pass:string);virtual;
    Function GetMsgTo:string;virtual;
    Function GetMsgFrom:string;virtual;
    Function GetMsgSubj:string;virtual;
    Function GetProductCode:word;virtual;
    Function GetProductVersionString:string;virtual;
    Function GetPktTypeString:string;virtual;

    Procedure OpenMsg;virtual;
    Function CreateNewMsg(UseMsgID:Boolean):boolean;virtual;
    Procedure WriteMsg;virtual;
    Procedure CloseMsg;virtual;
    Function GetMsgArea:string;virtual;
    Procedure GetMsgDateTime(var DateTime:TDateTime);virtual;
    Procedure SetMsgDateTime(DateTime:TDateTime);virtual;
    Function GetMsgFlags:word;virtual;
    Procedure GetMsgFromAddress(Var Address:TAddress);virtual;
    Procedure GetMsgToAddress(Var Address:TAddress);virtual;
    Procedure SetMsgFromAddress(Address:TAddress);virtual;
    Procedure SetMsgToAddress(Address:TAddress);virtual;
    Procedure SetMsgTo(const ToName:string);virtual;
    Procedure SetMsgFrom(const FromName:string);virtual;
    Procedure SetMsgSubj(const Subject:string);virtual;

    Function GetMsgHdrStream:PStream;virtual;
    Procedure PutMsgHdrStream(HdrStream:PStream);virtual;

    Procedure AddressToPktY2Address(const Address:TAddress;var SAddress:TPktY2Address);
    Procedure PktY2AddressToAddress(const SAddress:TPktY2Address;var Address:tAddress);
  end;

  PPacketY2 = ^TPacketY2;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

implementation

Constructor TPacketY2.Init;
begin
  inherited Init;

  PktType:=ptPkt2000;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Destructor TPacketY2.Done;
begin
  inherited Done;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Function TPacketY2.GetPktTypeString:string;
begin
  GetPktTypeString:='Pkt 2000';
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.OpenPkt(Pkt:string);
begin
  If Status<>pktOk then exit;

  If PktOpened then exit;

  If not dosFileExists(Pkt) then exit;

  DisposeStr(PktName);
  PktName:=NewStr(Pkt);

  PktLink:=New(PBufStream,Init(PktName^,stOpen,cBuffSize));

  PktSize:=PktLink^.GetSize;

  PktLink^.Read(PktY2Header,SizeOf(PktY2Header));
  If PktLink^.Status<>stOK then exit;

  CurrentMessage:=0;

  PktOpened:=True;

  If not FastOpen then
    begin
      BaseType:=btNetmail;
      OpenMsg;
      If GetMsgArea<>'' then BaseType:=btEchomail;
      CloseMsg;
    end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.ClosePkt;
begin
  objDispose(PktLink);
  Messages^.FreeAll;
  PktOpened:=False;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Function TPacketY2.CreateNewPkt(Pkt:string):boolean;
begin
  CreateNewPkt:=False;

  If PktOpened then Exit;

  DisposeStr(PktName);
  PktName:=NewStr(Pkt);

  PktLink:=New(PBufStream,Init(PktName^,stCreate,cBuffSize));

  PktSize:=0;

  FillChar(PktY2Header,SizeOf(PktY2Header),#0);
  SetPktHeaderDefaults;

  CurrentMessage:=-1;

  CreateNewPkt:=True;
  PktOpened:=True;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.SetPktHeaderDefaults;
begin
  PktY2Header.MainHeaderLen:=SizeOf(PktY2Header);
  PktY2Header.PktVersionMajor:=2000;
  PktY2Header.PktVersionMinor:=5;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.WritePkt;
begin
  PktLink^.Seek(0);
  PktLink^.Write(PktY2Header,SizeOf(PktY2Header));
  PktSize:=PktLink^.GetSize;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.SetFakeNet(Fake:Integer);
begin
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.GetToAddress(var Address:TAddress);
begin
  Address.Zone:=PktY2Header.DestZone;
  Address.Net:=PktY2Header.DestNet;
  Address.Node:=PktY2Header.DestNode;
  Address.Net:=PktY2Header.DestNet;
  Address.Point:=PktY2Header.DestPoint;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.GetFromAddress(var Address:TAddress);
begin
  Address.Zone:=PktY2Header.OrigZone;
  Address.Net:=PktY2Header.OrigNet;
  Address.Node:=PktY2Header.OrigNode;
  Address.Net:=PktY2Header.OrigNet;
  Address.Point:=PktY2Header.OrigPoint;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.SetToAddress(Address:TAddress);
begin
  PktY2Header.DestZone:=Address.Zone;
  PktY2Header.DestNet:=Address.Net;
  PktY2Header.DestNode:=Address.Node;
  PktY2Header.DestNet:=Address.Net;
  PktY2Header.DestPoint:=Address.Point;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.SetFromAddress(Address:TAddress);
begin
  PktY2Header.OrigZone:=Address.Zone;
  PktY2Header.OrigNet:=Address.Net;
  PktY2Header.OrigNode:=Address.Node;
  PktY2Header.OrigNet:=Address.Net;
  PktY2Header.OrigPoint:=Address.Point;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Function TPacketY2.GetPassword:string;
begin
  GetPassword:=PktY2Header.Password;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.SetPassword(Pass:string);
begin
  PktY2Header.Password:=strUpper(Pass);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Function TPacketY2.GetMsgArea:string;
begin
  GetMsgArea:=MsgArea;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Function TPacketY2.GetMsgTo:string;
begin
  GetMsgTo:=MsgTo;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Function TPacketY2.GetMsgSubj:string;
begin
  GetMsgSubj:=MsgSubject;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Function TPacketY2.GetMsgFrom:string;
begin
  GetMsgFrom:=MsgFrom;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Function TPacketY2.GetProductCode:word;
begin
  GetProductCode:=0;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Function TPacketY2.GetProductVersionString:string;
begin
  GetProductVersionString:=PktY2Header.ProductName;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.GetMsgDateTime(var DateTime:TDateTime);
begin
  DateTime.Year:=MsgHeader.Year;
  DateTime.Month:=MsgHeader.Month;
  DateTime.Day:=MsgHeader.Day;
  DateTime.Hour:=MsgHeader.Hour;
  DateTime.Minute:=MsgHeader.Min;
  DateTime.Hour:=MsgHeader.Hour;
  DateTime.Sec:=MsgHeader.Sec;
  DateTime.Sec100:=MsgHeader.Sec100;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.SetMsgDateTime(DateTime:TDateTime);
begin
  MsgHeader.Year:=DateTime.Year;
  MsgHeader.Month:=DateTime.Month;
  MsgHeader.Day:=DateTime.Day;
  MsgHeader.Hour:=DateTime.Hour;
  MsgHeader.Min:=DateTime.Minute;
  MsgHeader.Hour:=DateTime.Hour;
  MsgHeader.Sec:=DateTime.Sec;
  MsgHeader.Sec100:=DateTime.Sec100;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.GetMsgFromAddress(Var Address:TAddress);
begin
  Address.Zone:=MsgHeader.OrigAddress.Zone;
  Address.Net:=MsgHeader.OrigAddress.Net;
  Address.Node:=MsgHeader.OrigAddress.Node;
  Address.Point:=MsgHeader.OrigAddress.Point;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.GetMsgToAddress(Var Address:TAddress);
begin
  Address.Zone:=MsgHeader.DestAddress.Zone;
  Address.Net:=MsgHeader.DestAddress.Net;
  Address.Node:=MsgHeader.DestAddress.Node;
  Address.Point:=MsgHeader.DestAddress.Point;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.SetMsgFromAddress(Address:TAddress);
Var
 ToAddress : TAddress;
begin
  inherited SetMsgFromAddress(Address);

  MsgHeader.OrigAddress.Zone:=Address.Zone;
  MsgHeader.OrigAddress.Net:=Address.Net;
  MsgHeader.OrigAddress.Node:=Address.Node;
  MsgHeader.OrigAddress.Point:=Address.Point;

  MsgHeader.WrittenAddress.Zone:=Address.Zone;
  MsgHeader.WrittenAddress.Net:=Address.Net;
  MsgHeader.WrittenAddress.Node:=Address.Node;
  MsgHeader.WrittenAddress.Point:=Address.Point;

end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.SetMsgToAddress(Address:TAddress);
Var
 FromAddress : TAddress;
begin
  inherited SetMsgToAddress(Address);

  MsgHeader.DestAddress.Zone:=Address.Zone;
  MsgHeader.DestAddress.Net:=Address.Net;
  MsgHeader.DestAddress.Node:=Address.Node;
  MsgHeader.DestAddress.Point:=Address.Point;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.SetMsgTo(const ToName:string);
begin
  MsgTo:=ToName;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.SetMsgFrom(const FromName:string);
begin
  MsgFrom:=FromName;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.SetMsgSubj(const Subject:string);
begin
  MsgSubject:=Subject;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Function TPacketY2.GetMsgFlags:word;
var
  Flags : word;
begin
  Flags:=0;

  If (MsgHeader.FAttribute and y2kKillSent)=y2kKillSent
      then Flags:=Flags or flgKill;

  If (MsgHeader.FAttribute and y2kFileAttached)=y2kFileAttached
      then Flags:=Flags or flgAttach;

  If (MsgHeader.FAttribute and y2kFileRequest)=y2kFileRequest
      then Flags:=Flags or flgFRq;


  If (MsgHeader.RAttribute and y2kCrash)=y2kCrash
      then Flags:=Flags or flgCrash;

  If (MsgHeader.RAttribute and y2kHold)=y2kHold
      then Flags:=Flags or flgHold;


  If (MsgHeader.GAttribute and y2kLocal)=y2kLocal
      then Flags:=Flags or flgLocal;

  If (MsgHeader.GAttribute and y2kSent)=y2kSent
      then Flags:=Flags or flgSent;

  If (MsgHeader.GAttribute and y2kPrivate)=y2kPrivate
      then Flags:=Flags or flgPrivate;

  If (MsgHeader.GAttribute and y2kOrphan)=y2kOrphan
      then Flags:=Flags or flgOrphan;

  GetMsgFlags:=Flags;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.CloseMsg;
begin
  inherited CloseMsg;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Function TPacketY2.CreateNewMsg(UseMsgID:Boolean):boolean;
begin
  CreateNewMsg:=False;

  If not PktOpened then exit;

  FillChar(MsgHeader,SizeOf(MsgHeader),#0);
  ReplyTo:='';

  inherited CreateNewMsg(UseMsgID);

  CreateNewMsg:=True;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.OpenMsg;
Var
  lTemp : ^longint;
  sTemp : string;
  iTemp:Longint;
  TempAddress : TPktY2Address;
  TempStream : PStream;
  FromAddress,ToAddress : TAddress;
  TPAddress : PAddress;
begin
  If not PktOpened then exit;
  Status:=pktNoMoreMessages;


  PktLink^.Read(MsgHeader,SizeOf(MsgHeader));
  If PktLink^.Status<>stOk then exit;

  inherited OpenMsg;

  sTemp:=objStreamReadStr(PktLink);
  if sTemp<>'' then MessageBody^.Kludgebase^.SetKludge('REPLYTO:',sTemp);
  sTemp:=objStreamReadStr(PktLink);
  if sTemp<>'' then MessageBody^.Kludgebase^.SetKludge('MSGID:',sTemp);

  GetMsgFromAddress(FromAddress);
  GetMsgToAddress(ToAddress);

  If BaseType=btNetmail then
    begin
      MessageBody^.KludgeBase^.SetKludge('INTL',
            ftnAddressToStrPointless(ToAddress)+#32+
            ftnAddressToStrPointless(FromAddress));

      If ToAddress.Point<>0 then
        MessageBody^.KludgeBase^.SetKludge('TOPT',strIntToStr(ToAddress.Point));

      If FromAddress.Point<>0 then
        MessageBody^.KludgeBase^.SetKludge('FMPT',strIntToStr(FromAddress.Point));
    end;

  MsgTo:=objStreamReadStr(PktLink);
  MsgFrom:=objStreamReadStr(PktLink);
  MsgSubject:=objStreamReadStr(PktLink);
  MsgArea:=objStreamReadStr(PktLink);

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  Paths:=New(PAddressCollection,Init($10,$10));

  TempStream:=New(PMemoryStream,Init(0,cBuffSize));
  TempStream^.CopyFrom(PktLink^,MsgHeader.Paths*SizeOf(TPktY2Address));
  TempStream^.Seek(0);
  iTemp:=TempStream^.GetSize;

  If iTemp<>0 then
    While TempStream^.GetPos<iTemp-1 do
      begin
        TempStream^.Read(TempAddress,SizeOf(TempAddress));
        New(TPAddress);
        PktY2AddressToAddress(TempAddress,TPAddress^);
        Paths^.Insert(TPAddress);
      end;

  ftnAddressList(MessageBody^.PathLink,Paths,#1'PATH: ',False,78);

  objDispose(TempStream);
  objDispose(Paths);

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  SeenBys:=New(PAddressCollection,Init($10,$10));

  TempStream:=New(PMemoryStream,Init(0,cBuffSize));
  TempStream^.CopyFrom(PktLink^,MsgHeader.SeenBys*SizeOf(TPktY2Address));
  TempStream^.Seek(0);
  iTemp:=TempStream^.GetSize;

  If iTemp<>0 then
    While TempStream^.GetPos<iTemp-1 do
      begin
        TempStream^.Read(TempAddress,SizeOf(TPktY2Address));
        New(TPAddress);
        PktY2AddressToAddress(TempAddress,TPAddress^);
        SeenBys^.Insert(TPAddress);
      end;

  ftnAddressList(MessageBody^.SeenByLink,SeenBys,'SEEN-BY: ',False,78);

  objDispose(TempStream);
  objDispose(SeenBys);

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  TempStream:=New(PMemoryStream,Init(0,cBuffSize));
  TempStream^.CopyFrom(PktLink^,MsgHeader.TextBytes);
  MessageBody^.AddToMsgBodyStream(TempStream);
  objDispose(TempStream);

  Status:=pktOK;
end;


{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.WriteMsg;
Var
  TempKludge : PKludge;
  i:integer;
  TempBody : PStream;
  TempPath : PStream;
  TempSeenBy : PStream;
  TempAddress : PAddress;
  TSAddress : TPktY2Address;
begin
  If not PktOpened then exit;

  TempBody:=New(PMemoryStream,Init(0,cBuffSize));
  TempBody^.Seek(0);

  for i:=0 to MessageBody^.KludgeBase^.Kludges^.Count-1 do
    begin
      TempKludge:=MessageBody^.KludgeBase^.Kludges^.At(i);

      If strUpper(TempKludge^.Name^)='MSGID:'
         then Msgid:=TempKludge^.Value^
         else
      If strUpper(TempKludge^.Name^)='REPLY:'
         then ReplyTo:=TempKludge^.Value^
         else
      If strUpper(TempKludge^.Name^)='TOPT'
         then continue
         else
      If strUpper(TempKludge^.Name^)='FMPT'
         then continue
         else
      If strUpper(TempKludge^.Name^)='INTL'
         then continue
         else
          objStreamWriteLn(TempBody,#1+TempKludge^.Name^+#32+TempKludge^.Value^);
    end;

  MessageBody^.MsgBodyLink^.Seek(0);
  TempBody^.CopyFrom(MessageBody^.MsgBodyLink^,
           MessageBody^.MsgBodyLink^.GetSize);

  If MessageBody^.TearLine<>nil then
         objStreamWriteLn(TempBody,MessageBody^.TearLine^);
  If MessageBody^.Origin<>nil then
         objStreamWriteLn(TempBody,MessageBody^.Origin^);

  SeenBys:=New(PAddressCollection,Init($10,$10));
  Paths:=New(PAddressCollection,Init($10,$10));

  GetMsgSeenBys(SeenBys);
  GetMsgPaths(Paths);

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  TempPath:=New(PMemoryStream,Init(0,cBuffSize));
  TempPath^.Seek(0);

  For i:=0 to Paths^.Count-1 do
    begin
      TempAddress:=Paths^.At(i);
      AddressToPktY2Address(TempAddress^,TSAddress);
      TempPath^.Write(TSAddress,SizeOf(TSAddress));
    end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  TempSeenBy:=New(PMemoryStream,Init(0,cBuffSize));
  TempSeenBy^.Seek(0);

  For i:=0 to SeenBys^.Count-1 do
    begin
      TempAddress:=SeenBys^.At(i);
      AddressToPktY2Address(TempAddress^,TSAddress);
      TempSeenBy^.Write(TSAddress,SizeOf(TSAddress));
    end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  MsgHeader.Paths:=Paths^.Count;
  MsgHeader.SeenBys:=SeenBys^.Count;
  MsgHeader.TextBytes:=TempBody^.GetSize;

  PktLink^.Seek(PktSize);

  PktLink^.Write(MsgHeader,SizeOf(MsgHeader));

  objStreamWrite(PktLink,ReplyTo);
  objStreamWrite(PktLink,Msgid);
  objStreamWrite(PktLink,MsgTo);
  objStreamWrite(PktLink,MsgFrom);
  objStreamWrite(PktLink,MsgSubject);
  objStreamWrite(PktLink,MsgArea);

  TempPath^.Seek(0);
  PktLink^.CopyFrom(TempPath^,TempPath^.GetSize);

  TempSeenBy^.Seek(0);
  PktLink^.CopyFrom(TempSeenBy^,TempSeenBy^.GetSize);

  TempBody^.Seek(0);
  PktLink^.CopyFrom(TempBody^,TempBody^.GetSize);

  objDispose(TempPath);
  objDispose(TempSeenBy);
  objDispose(Paths);
  objDispose(SeenBys);
  objDispose(TempBody);

  PktSize:=PktLink^.GetSize;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TPacketY2.PutMsgHdrStream(HdrStream:PStream);
var
  MHeader : TPktMsgHeader;
begin
  HdrStream^.Seek(0);

  HdrStream^.Read(MHeader,SizeOf(MHeader));

  MsgTo:=objStreamReadStr(HdrStream);
  MsgFrom:=objStreamReadStr(HdrStream);
  MsgSubject:=objStreamReadStr(HdrStream);

  MsgArea:=objStreamReadStr(HdrStream);
  If MsgArea<>'' then MsgArea:=strParser(MsgArea,2,[':']);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Function TPacketY2.GetMsgHdrStream:PStream;
var
  TempStream : PStream;
  lTemp:^longint;
  MHeader : TPktMsgHeader;
  DateTime : TDateTime;
begin
  TempStream:=New(PMemoryStream,Init(0,cBuffSize));

  MHeader.Sign:=2;
  MHeader.OrigNet:=MsgHeader.OrigAddress.Net;
  MHeader.OrigNode:=MsgHeader.OrigAddress.Node;
  MHeader.DestNet:=MsgHeader.DestAddress.Net;
  MHeader.DestNode:=MsgHeader.DestAddress.Node;

  MHeader.Flags:=GetMsgFlags;
  MHeader.Cost:=0;

  GetMsgDateTime(DateTime);
{!!!!!!
ftnSetFTNDateTime(DateTime,MHeader.DateTime);}

  TempStream^.Seek(0);
  TempStream^.Write(MHeader,SizeOf(MHeader));

  objStreamWrite(TempStream,MsgTo+#0);
  objStreamWrite(TempStream,MsgFrom+#0);
  objStreamWrite(TempStream,MsgSubject+#0);

  If MsgArea<>'' then objStreamWriteLn(TempStream,'AREA:'+MsgArea);

  GetMsgHdrStream:=TempStream;
end;

Procedure TPacketY2.AddressToPktY2Address(const Address:TAddress;var SAddress:TPktY2Address);
begin
  SAddress.Zone:=Address.Zone;
  SAddress.Net:=Address.Net;
  SAddress.Node:=Address.Node;
  SAddress.Point:=Address.Point;
end;

Procedure TPacketY2.PktY2AddressToAddress(const SAddress:TPktY2Address;var Address:tAddress);
begin
  Address.Zone:=SAddress.Zone;
  Address.Net:=SAddress.Net;
  Address.Node:=SAddress.Node;
  Address.Point:=SAddress.Point;
end;

end.
