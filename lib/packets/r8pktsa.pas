{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
  {$PackRecords 1}
{$ENDIF}
Unit r8PktSA;

interface
Uses
  r8ftn,
  r8dtm,
  r8str,
  r8dos,
  r8objs,
  objects,
  r8pkt;


Type

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

  TSAPktHeader = record
    OrigNode : word;
    DestNode : word;

    Year     : word;
    Month    : word;
    Day      : word;
    Hour     : word;
    Minute   : word;
    Second   : word;

    Baud     : word;

    Sign     : word;

    OrigNet  : word;
    DestNet  : word;

    ProductCode : byte;
    Serial      : byte;

    Password : array[1..8] of char;

    OrigZone  : word;
    DestZone  : word;

    Fill : array[1..20] of byte;
  end;

  PSAPktHeader = ^TSAPktHeader;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

  TPktMsgHeader = Record
    Sign: Word;
    OrigNode: Word;
    DestNode: Word;
    OrigNet: Word;
    DestNet: Word;
    Flags: Word;
    Cost: Word;
    DateTime: Array [1..20] of Char;
  End;

  PPktMsgHeader = ^TPktMsgHeader;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

  TPacketSA = object(TPacket)
    MsgHeader : TPktMsgHeader;
    MsgTo     : string[35];
    MsgFrom   : string[35];
    MsgSubject : string[80];

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
    Procedure SetMsgFlags(var Flags:longint);virtual;
    Procedure GetMsgFromAddress(Var Address:TAddress);virtual;
    Procedure GetMsgToAddress(Var Address:TAddress);virtual;
    Procedure SetMsgFromAddress(Address:TAddress);virtual;
    Procedure SetMsgToAddress(Address:TAddress);virtual;
    Procedure SetMsgTo(const ToName:string);virtual;
    Procedure SetMsgFrom(const FromName:string);virtual;
    Procedure SetMsgSubj(const Subject:string);virtual;

    Function GetMsgHdrStream:PStream;virtual;
    Procedure PutMsgHdrStream(HdrStream:PStream);virtual;
  private
    PktSAHeader : TSAPktHeader;
    FakeNet : Integer;
  end;

  PPacketSA = ^TPacketSA;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

implementation

{袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴}

Constructor TPacketSA.Init;
begin
  inherited Init;

  PktType:=ptStoneAge;
  PktHeader:=@PktSAHeader;
  PktHeaderSize:=SizeOf(PktSAHeader);
  FakeNet:=0;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Destructor TPacketSA.Done;
begin
  inherited Done;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacketSA.OpenPkt(Pkt:string);
begin
  If Status<>pktOk then exit;

  If PktOpened then exit;

  If not dosFileExists(Pkt) then
    begin
      Status:=pktFileNotExist;
      exit;
    end;

  DisposeStr(PktName);
  PktName:=NewStr(Pkt);

  PktLink:=New(PBufStream,Init(PktName^,stOpen,cBuffSize));

  PktSize:=PktLink^.GetSize;

  PktLink^.Read(PktHeader^,PktHeaderSize);
  If PktLink^.Status<>stOK then
    begin
      Status:=pktBadPacket;
      exit;
    end;

  CurrentMessage:=0;
  PktOpened:=True;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacketSA.ClosePkt;
begin
  objDispose(PktLink);
  Messages^.FreeAll;
  PktOpened:=False;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacketSA.CreateNewPkt(Pkt:string):boolean;
begin
  CreateNewPkt:=False;

  If PktOpened then Exit;

  DisposeStr(PktName);
  PktName:=NewStr(Pkt);

  PktLink:=New(PBufStream,Init(PktName^,stCreate,cBuffSize));

  PktSize:=0;

  FillChar(PktHeader^,PktHeaderSize,#0);
  SetPktHeaderDefaults;

  CurrentMessage:=-1;

  CreateNewPkt:=True;
  PktOpened:=True;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacketSA.SetPktHeaderDefaults;
var
  DateTime : TDateTime;
begin
  dtmGetDateTime(DateTime);

  PktSAHeader.Year:=DateTime.Year;
  PktSAHeader.Month:=DateTime.Month-1;
  PktSAHeader.Day:=DateTime.Day;
  PktSAHeader.Hour:=DateTime.Hour;
  PktSAHeader.Minute:=DateTime.Minute;
  PktSAHeader.Second:=DateTime.Sec;

  PktSAHeader.Sign:=2;

  PktSAHeader.ProductCode:=Lo(ProductCode);
  PktSAHeader.Serial:=Lo(Version);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacketSA.WritePkt;
begin
  PktLink^.Seek(0);
  PktLink^.Write(PktHeader^,PktHeaderSize);
  If PktSize=0 then objStreamWrite(PktLink, #0#0);
  PktSize:=PktLink^.GetSize;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacketSA.SetFakeNet(Fake:Integer);
begin
  FakeNet:=Fake;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacketSA.GetToAddress(var Address:TAddress);
begin
  Address.Zone:=PktSAHeader.DestZone;
  Address.Net:=PktSAHeader.DestNet;
  Address.Node:=PktSAHeader.DestNode;
  Address.Point:=0;

  If (FakeNet<>0) and (PktSAHeader.DestNet=FakeNet) then
    begin
      Address.Point:=PktSAHeader.DestNode;
      Address.Net:=PktSAHeader.OrigNet;
      Address.Node:=PktSAHeader.OrigNode;
    end;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacketSA.GetFromAddress(var Address:TAddress);
begin
  Address.Zone:=PktSAHeader.OrigZone;
  Address.Net:=PktSAHeader.OrigNet;
  Address.Node:=PktSAHeader.OrigNode;
  Address.Point:=0;

  If (FakeNet<>0) and (PktSAHeader.OrigNet=FakeNet) then
    begin
      Address.Point:=PktSAHeader.OrigNode;
      Address.Net:=PktSAHeader.DestNet;
      Address.Node:=PktSAHeader.DestNode;
    end;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacketSA.SetToAddress(Address:TAddress);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacketSA.SetFromAddress(Address:TAddress);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacketSA.GetPassword:string;
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacketSA.SetPassword(Pass:string);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacketSA.GetProductCode:word;
begin
  GetProductCode:=PktSAHeader.ProductCode;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacketSA.GetProductVersionString:string;
begin
  GetProductVersionString:=strIntToStr(PktSAHeader.Serial)+'.0';
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacketSA.GetPktTypeString:string;
begin
  GetPktTypeString:='Stone Age';
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacketSA.OpenMsg;
Var
  lTemp : longint;
  lTemp2 : longint;
  sTemp : string;
  TempStream : PStream;
  c:char;
begin
  If not PktOpened then exit;
  Status:=pktNoMoreMessages;

  PktLink^.Read(MsgHeader,SizeOf(MsgHeader));
  If PktLink^.Status<>stOk then exit;

  Status:=pktBadPacket;
  If MsgHeader.Sign<>2 then exit;

  MsgTo:=objStreamReadLnZero(PktLink);
  MsgFrom:=objStreamReadLnZero(PktLink);
  MsgSubject:=objStreamReadLnZero(PktLink);

  lTemp2:=PktLink^.GetPos;
  MsgArea:=objStreamReadLn(PktLink);
  If MsgArea[1]=#1 then
    begin
      PktLink^.Seek(lTemp2);
      MsgArea:='';
    end
    else MsgArea:=strRightStr(MsgArea,Length(MsgArea)-5);

  lTemp:=objStreamSearchChar(PktLink,[#0]);
  If lTemp=-1 then exit;

  TempStream:=New(PMemoryStream,Init(0,cBuffSize));
  lTemp2:=(lTemp-1)-PktLink^.GetPos;
  If lTemp2<0 then exit;
  TempStream^.CopyFrom(PktLink^,lTemp2);

  PktLink^.Seek(PktLink^.GetPos+1);

  inherited OpenMsg;

  MessageBody^.AddToMsgBodyStream(TempStream);

  objDispose(TempStream);

  Status:=pktOK;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacketSA.CreateNewMsg(UseMsgID:Boolean):boolean;
Var
  lTemp : ^longint;
  sTemp : string;
begin
  CreateNewMsg:=False;

  If not PktOpened then exit;

  FillChar(MsgHeader,SizeOf(MsgHeader),#0);

  MsgHeader.Sign := $0002;

  inherited CreateNewMsg(UseMsgID);

  CreateNewMsg:=True;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacketSA.WriteMsg;
Var
  TempStream : PStream;
begin
  If not PktOpened then exit;

  PktLink^.Seek(PktSize-2);
  PktLink^.Truncate;

  PktLink^.Write(MsgHeader,SizeOf(MsgHeader));

  objStreamWrite(PktLink,MsgTo+#0);
  objStreamWrite(PktLink,MsgFrom+#0);
  objStreamWrite(PktLink,MsgSubject+#0);

  If MsgArea<>'' then objStreamWriteLn(PktLink,'AREA:'+MsgArea);

  TempStream:=MessageBody^.GetMsgBodyStreamEx;

  TempStream^.Seek(0);
  PktLink^.CopyFrom(TempStream^,TempStream^.GetSize);

  objDispose(TempStream);

  objStreamWrite(PktLink, #0#0#0);

  PktSize:=PktLink^.GetSize;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacketSA.CloseMsg;
begin
  inherited CloseMsg;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacketSA.GetMsgArea:string;
begin
  GetMsgArea:=MsgArea;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacketSA.GetMsgTo:string;
begin
  GetMsgTo:=MsgTo;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacketSA.GetMsgSubj:string;
begin
  GetMsgSubj:=MsgSubject;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacketSA.GetMsgFrom:string;
begin
  GetMsgFrom:=MsgFrom;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacketSA.GetMsgHdrStream:PStream;
var
  TempStream : PStream;
begin
  TempStream:=New(PMemoryStream,Init(0,cBuffSize));

  TempStream^.Write(MsgHeader, SizeOf(MsgHeader));

  objStreamWrite(TempStream,MsgTo+#0);
  objStreamWrite(TempStream,MsgFrom+#0);
  objStreamWrite(TempStream,MsgSubject+#0);

  If MsgArea<>'' then objStreamWriteLn(TempStream,'AREA:'+MsgArea);

  GetMsgHdrStream:=TempStream;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacketSA.PutMsgHdrStream(HdrStream:PStream);
begin
  HdrStream^.Seek(0);

  HdrStream^.Read(MsgHeader,SizeOf(MsgHeader));

  MsgTo:=objStreamReadStr(HdrStream);
  MsgFrom:=objStreamReadStr(HdrStream);
  MsgSubject:=objStreamReadStr(HdrStream);

  MsgArea:=objStreamReadStr(HdrStream);
  If MsgArea<>'' then MsgArea:=strParser(MsgArea,2,[':']);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacketSA.GetMsgDateTime(var DateTime:TDateTime);
Var
  sTemp:string;
  S : string[20];
  i:integer;
begin
  FillChar(DateTime,SizeOf(DateTime),#0);
  S[0]:=#19;
  Move(MsgHeader.DateTime,S[1],19);

  DateTime.Day:=strStrToInt(strParser(S,1,[#32]));

  sTemp:=strParser(S,2,[#32]);
  DateTime.Month:=dtmStrToMonth(sTemp);

  DateTime.Year:=strStrToInt(strParser(S,3,[#32]));
  If DateTime.Year<70 then DateTime.Year:=2000+DateTime.Year
                 else DateTime.Year:=1900+DateTime.Year;

  sTemp:=strParser(S,4,[#32]);

  DateTime.Hour:=strStrToInt(strParser(sTemp,1,[':']));
  DateTime.Minute:=strStrToInt(strParser(sTemp,2,[':']));
  DateTime.Sec:=strStrToInt(strParser(sTemp,3,[':']));
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacketSA.SetMsgDateTime(DateTime:TDateTime);
begin
  dtmDateToFTN(DateTime,MsgHeader.DateTime);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacketSA.GetMsgFlags:word;
begin
  GetMsgFlags:=MsgHeader.Flags;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacketSA.SetMsgFlags(var Flags:longint);
begin
  MsgHeader.Flags:=Long(Flags).LowWord;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacketSA.GetMsgFromAddress(Var Address:TAddress);
Var
  sTemp:string;
begin
  sTemp:=MessageBody^.KludgeBase^.GetKludge('MSGID:');
  sTemp:=strParser(sTemp,1,[#32]);
  If ftnCheckAddressString(sTemp) then
    begin
      ftnStrToAddress(sTemp,Address);
    end
    else
    begin
      sTemp:=MessageBody^.KludgeBase^.GetKludge('INTL');
      sTemp:=strParser(sTemp,2,[#32]);
      ftnStrToAddress(sTemp,Address);
      sTemp:=MessageBody^.KludgeBase^.GetKludge('FMPT');
      If sTemp='' then
         Address.Point:=0
             else Address.Point:=strStrToInt(sTemp);
    end;
end;

Procedure TPacketSA.GetMsgToAddress(Var Address:TAddress);
Var
  sTemp:string;
begin
  sTemp:=MessageBody^.KludgeBase^.GetKludge('REPLY:');
  sTemp:=strParser(sTemp,1,[#32]);
  If ftnCheckAddressString(sTemp) then
    begin
      ftnStrToAddress(sTemp,Address);
    end
    else
    begin
      sTemp:=MessageBody^.KludgeBase^.GetKludge('INTL');
      sTemp:=strParser(sTemp,1,[#32]);
      ftnStrToAddress(sTemp,Address);
      sTemp:=MessageBody^.KludgeBase^.GetKludge('TOPT');
      If sTemp='' then
         Address.Point:=0
             else Address.Point:=strStrToInt(sTemp);
    end;
end;


Procedure TPacketSA.SetMsgFromAddress(Address:TAddress);
Var
  TempAddress : TAddress;
begin
  inherited SetMsgFromAddress(Address);

  GetFromAddress(TempAddress);
  MsgHeader.OrigNet:=TempAddress.Net;
  MsgHeader.OrigNode:=TempAddress.Node;
end;

Procedure TPacketSA.SetMsgToAddress(Address:TAddress);
Var
  TempAddress : TAddress;
begin
  inherited SetMsgToAddress(Address);

  GetToAddress(TempAddress);
  MsgHeader.DestNet:=TempAddress.Net;
  MsgHeader.DestNode:=TempAddress.Node;
end;

Procedure TPacketSA.SetMsgTo(const ToName:string);
begin
  MsgTo:=ToName;
end;

Procedure TPacketSA.SetMsgFrom(const FromName:string);
begin
  MsgFrom:=FromName;
end;

Procedure TPacketSA.SetMsgSubj(const Subject:string);
begin
  MsgSubject:=Subject;
end;

end.
