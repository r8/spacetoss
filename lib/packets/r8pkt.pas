{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit r8Pkt;

interface

Uses
  r8dos,
  r8objs,
  r8ftn,
  r8dtm,
  strings,
  r8msgb,
  r8abs,
  r8str,
  dos,
  objects;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
{Packet type}
Const
  ptNone     = $00000000;
  ptStoneAge = $00000001;
  ptType2    = $00000002;
  ptType22   = $00000003;
  ptType2p   = $00000004;
  ptPkt2000  = $00000005;
  ptBCL      = $00001000;

  pktOK             = $00000000;
  pktNoMoreMessages = $00000001;
  pktFileNotExist   = $00000002;
  pktBadPacket      = $00000003;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Type

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

  TPacket = object(TObject)
    Status  : longint;
    FastOpen:boolean;

    MsgArea : string[50];

    PktName : PString;
    PktType : word;
    BaseType : byte;
    ProductCode : word;
    Version : word;
    PktOpened : boolean;
    PktLink  : PStream;
    PktSize : longint;
    PktHeader : Pointer;
    PktHeaderSize : Integer;

    MessageBody : PMessageBody;

    Messages : PCollection;
    CurrentMessage : longint;

    Constructor Init;
    Destructor Done;virtual;

    Function GetCount:longint;

    Procedure OpenPkt(Pkt:string);virtual;
    Procedure ClosePkt;virtual;
    Function CreateNewPkt(Pkt:string):boolean;virtual;
    Procedure WritePkt;virtual;

    Function GetPktAreaType:byte;
    Procedure SetPktAreaType(at:byte);

    Procedure SetPktHeaderDefaults;virtual;

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
    Procedure GetMsgDateTime(var DateTime:TDateTime);virtual;
    Procedure SetMsgDateTime(DateTime:TDateTime);virtual;

    Function GetProductCode:word;virtual;
    Function GetProductVersionString:string;virtual;
    Function GetPktTypeString:string;virtual;

    Procedure OpenMsg;virtual;
    Procedure CloseMsg;virtual;
    Function CreateNewMsg(UseMsgID:Boolean):boolean;virtual;
    Procedure WriteMsg;virtual;

    Function GetAbsMessage:PAbsMessage;
    Function CutAbsMessage:PAbsMessage;
    Procedure SetAbsMessage(const AbsMessage:PAbsMessage;
      const Invalidate:boolean);

    Function GetMsgArea:string;virtual;
    Function GetMsgFlags:word;virtual;
    Procedure SetMsgFlags(var Flags:longint);virtual;
    Procedure GetMsgFromAddress(Var Address:TAddress);virtual;
    Procedure GetMsgToAddress(Var Address:TAddress);virtual;
    Procedure SetMsgFromAddress(Address:TAddress);virtual;
    Procedure SetMsgToAddress(Address:TAddress);virtual;
    Procedure SetMsgTo(const ToName:string);virtual;
    Procedure SetMsgFrom(const FromName:string);virtual;
    Procedure SetMsgSubj(const Subject:string);virtual;
    Procedure SetMsgArea(const Area:string);virtual;

    Procedure GetMsgSeenbys(var Addresses:PAddressCollection);virtual;
    Procedure GetMsgPaths(var Addresses:PAddressCollection);virtual;

    Function GetMsgBodyStream:PStream;virtual;

    Function GetMsgHdrStream:PStream;virtual;
    Procedure PutMsgHdrStream(HdrStream:PStream);virtual;

    Procedure Flush;virtual;
  end;
  PPacket =^TPacket;
{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

  TPacketItem = object(TObject)
    FileName : PString;
    CreateTime : longint;

    Constructor Init(const AFileName : string);
    Destructor  Done; virtual;
   end;
  PPacketItem = ^TPacketItem;

  TPacketCollection = object (TSortedCollection)
    Procedure FreeItem(Item:pointer);virtual;
{$IFDEF VER70}
    Function Compare(Key1, Key2: Pointer):Integer;virtual;
{$ELSE}
    Function Compare(Key1, Key2: Pointer):LongInt;virtual;
{$ENDIF}
  end;
  PPacketCollection = ^TPacketCollection;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

  TPktDir = object(TObject)
    FastOpen:boolean;

    DirOpened : boolean;
    PktPath : string;
    PktExtensions : PStringsCollection;
    CurrentPacket : longint;
    PktType:longint;

    Packets : PPacketCollection;
    Packet : PPacket;

    Constructor Init;
    Destructor Done;virtual;

    Function OpenDir(Dir:string):boolean;
    Procedure CloseDir;
    Procedure SetPktExtension(const Ext:string);
    Function GetPktExtension:string;
    Function GetExt(const Pkt:word):string;
    Procedure AddPktExtension(const Ext:string);

    Procedure Seek(i:longint);
    Function FindPkt(const Name:string):longint;
    Function GetCount:longint;
    Function GetPktName:string;

    Function OpenPkt:boolean;
    Function CreateNewPkt:boolean;
    Procedure ClosePkt;

    Procedure ChangeExtension(const NewExtension:string);
  end;

  PPktDir = ^TPktDir;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function GetPktType(pkt:string):longint;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

implementation
Uses
  r8pkt20,
  r8pkt2p,
  r8pktY2,
  r8pktbcl,
  r8pktsa;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Constructor TPacketItem.Init(const AFileName:string);
begin
  inherited Init;

  FileName:=NewStr(AFileName);
  CreateTime:=dtmFileTimeUnix(AFileName);
end;

Destructor TPacketItem.Done;
begin
  DisposeStr(FileName);

  inherited Done;
end;

Procedure TPacketCollection.FreeItem(Item:pointer);
begin
  objDispose(PPacketItem(Item));
end;

{$IFDEF VER70}
Function TPacketCollection.Compare(Key1, Key2: Pointer):Integer;
{$ELSE}
Function TPacketCollection.Compare(Key1, Key2: Pointer):LongInt;
{$ENDIF}
var
  P1 : PPacketItem absolute Key1;
  P2 : PPacketItem absolute Key2;
begin
  If P1^.CreateTime>P2^.CreateTime then Compare:=1 else
  If P1^.CreateTime<P2^.CreateTime then Compare:=-1 else
  Compare:=0;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Constructor TPktDir.Init;
begin
  inherited Init;

  Packets:=New(PPacketCollection,Init($100,$100));
  Packets^.Duplicates:=True;

  PktPath:='';
  PktExtensions:=New(PStringsCollection,Init($10,$10));
  PktExtensions^.Insert(NewStr('PKT'));
  PktType:=ptType2p;
  CurrentPacket:=-1;

  DirOpened:=false;
  FastOpen:=false;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Destructor TPktDir.Done;
begin
  objDispose(Packets);
  objDispose(PKTExtensions);

  inherited Done;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPktDir.OpenDir(Dir:string):boolean;
Var
  SR:SearchRec;
  i:integer;
  pTemp : PString;
begin
  OpenDir:=False;

  If DirOpened then exit;

  If Dir[Length(Dir)]='\' then Dec(Dir[0]);
  If not dosDirExists(Dir) then Exit;

  PktPath:=Dir;

  For i:=0 to PktExtensions^.Count-1 do
    begin
      pTemp:=PktExtensions^.At(i);

      FindFirst(PktPath+'\*.'+pTemp^,AnyFile-Directory,SR);
      While DosError=0 do
        begin
          Packets^.Insert(New(PPacketItem,Init(strUpper(PktPath+'\'+SR.Name))));
          FindNext(SR);
        end;
    end;
{$IFNDEF VER70}
  FindClose(SR);
{$ENDIF}

  DirOpened:=true;
  OpenDir:=true;
  Seek(0);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPktDir.CloseDir;
begin
  If not DirOpened then Exit;

  Packets^.FreeAll;
  PktPath:='';

  DirOpened:=False;
  Seek(-1);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPktDir.SetPktExtension(const Ext:string);
Var
  pTemp:PString;
begin
  pTemp:=PktExtensions^.At(0);
  pTemp^:=Ext;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPktDir.GetPktExtension:string;
Var
  pTemp:PString;
begin
  pTemp:=PktExtensions^.At(0);
  GetPktExtension:=pTemp^;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPktDir.AddPktExtension(const Ext:string);
begin
  PktExtensions^.Insert(NewStr(Ext));
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPktDir.Seek(i:longint);
begin
  If (i>Packets^.Count-1) or (i<0) then i:=-1;
  CurrentPacket:=i;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPktDir.GetPktName:string;
Var
  pTemp:PString;
begin
  GetPktName:='';

  If CurrentPacket=-1 then exit;

  Packets^.At(CurrentPacket);

  GetPktName:=PPacketItem(Packets^.At(CurrentPacket))^.FileName^;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPktDir.OpenPkt:boolean;
Var
  PktName : string;
begin
  OpenPkt:=False;

  If not DirOpened then exit;

  PktName:=GetPktName;
  PktType:=GetPktType(PktName);

  Case PktType of
    ptStoneAge : Packet:=New(PPacketSA,Init);
    ptType2    : Packet:=New(PPacket20,Init);
    ptType2p   : Packet:=New(PPacket2p,Init);
    ptPkt2000 : Packet:=New(PPacketY2,Init);
    ptBCL  : Packet:=New(PPacketBCL,Init);
  end;

  Packet^.FastOpen:=FastOpen;

  Packet^.OpenPkt(PktName);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPktDir.ClosePkt;
begin
  Packet^.ClosePkt;
  objDispose(Packet);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPktDir.CreateNewPkt:boolean;
Var
  PktName : string;
begin
  CreateNewPkt:=False;

  If not DirOpened then exit;

  Case PktType of
    ptStoneAge : Packet:=New(PPacketSA,Init);
    ptType2    : Packet:=New(PPacket20,Init);
    ptType2p    : Packet:=New(PPacket2p,Init);
    ptPkt2000    : Packet:=New(PPacketY2,Init);
  end;

  repeat PktName:=strUpper(PktPath+'\'+ftnPktName+'.'+GetPktExtension)
  until not dosFileExists(PktName);

  CreateNewPkt:=Packet^.CreateNewPkt(PktName);

  Packets^.Insert(New(PPacketItem,Init(strUpper(PktName))));
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPktDir.GetCount:longint;
begin
  GetCount:=0;
  If not DirOpened then exit;
  GetCount:=Packets^.Count;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPktDir.FindPkt(const Name:string):longint;
Var
  i:integer;
  TempPkt : PString;
begin
  FindPkt:=-1;

  For i:=0 to Packets^.Count-1 do
    begin
      TempPkt:=Packets^.At(i);
      If strUpper(Name)=PPacketItem(TempPkt)^.FileName^ then FindPkt:=i;
    end;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPktDir.ChangeExtension(const NewExtension:string);
Var
  FName : string;
  sTemp : string;
begin
  sTemp:=Packet^.PktName^;
  FName:=sTemp;
  Dec(sTemp[0],3);

  ClosePkt;

  dosRename(FName,sTemp+NewExtension);
end;

Function TPktDir.GetExt(const Pkt:word):string;
begin
  Case Pkt of
    ptPkt2000 : GetExt:='P2K';
    ptBCL : GetExt:='BCL';
    else GetExt:='PKT';
  end;
end;

{袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴}

Constructor TPacket.Init;
begin
  inherited Init;

  PktOpened:=False;
  Messages:=New(PLongIntCollection,Init($10,$10));
  PktHeader:=nil;
  PktSize:=0;

  ProductCode:=$00FE;
  Version:=0;

  PktName:=nil;

  BaseType:=btNetmail;

  CurrentMessage:=-1;

  FastOpen:=False;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Destructor TPacket.Done;
begin
  ClosePkt;
  objDispose(Messages);
  DisposeStr(PktName);

  inherited Done;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket.GetCount:longint;
begin
  GetCount:=Messages^.Count;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.OpenPkt(Pkt:string);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket.GetPktAreaType:byte;
begin
  GetPktAreaType:=BaseType;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.SetPktAreaType(at:byte);
begin
  BaseType:=At;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.ClosePkt;
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket.CreateNewPkt(Pkt:string):boolean;
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.SetPktHeaderDefaults;
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.WritePkt;
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.SetFakeNet(Fake:Integer);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.GetToAddress(var Address:TAddress);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.GetFromAddress(var Address:TAddress);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.SetToAddress(Address:TAddress);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.SetFromAddress(Address:TAddress);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket.GetProductCode:word;
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket.GetProductVersionString:string;
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket.GetPktTypeString:string;
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.OpenMsg;
begin
  MessageBody:=New(PMessageBody,Init);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.CloseMsg;
begin
  objDispose(MessageBody);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket.CreateNewMsg(UseMsgID:Boolean):boolean;
var
  DateTime : TDateTime;
begin
  MessageBody:=New(PMessageBody,Init);

  If UseMsgID then
      MessageBody^.KludgeBase^.SetKludge('MSGID:',
             ftnAddressToStrEx(NullAddress)+#32+strLower(ftnPktName));

  dtmGetDateTime(DateTime);
  SetMsgDateTime(DateTime);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.WriteMsg;
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket.GetAbsMessage:PAbsMessage;
Var
  AbsMessage : PAbsMessage;
begin
  AbsMessage:=New(PAbsMessage,Init(False,BaseType));

  AbsMessage^.Area:=NewStr(MsgArea);
  GetMsgFromAddress(AbsMessage^.FromAddress);
  GetMsgToAddress(AbsMessage^.ToAddress);
  AbsMessage^.FromName:=NewStr(GetMsgFrom);
  AbsMessage^.ToName:=NewStr(GetMsgTo);
  AbsMessage^.Subject:=NewStr(GetMsgSubj);
  AbsMessage^.Flags:=GetMsgFlags;
  GetMsgDateTime(AbsMessage^.DateTime);

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

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket.CutAbsMessage:PAbsMessage;
Var
  AbsMessage : PAbsMessage;
begin
  AbsMessage:=New(PAbsMessage,Init(False,BaseType));

  AbsMessage^.Area:=NewStr(MsgArea);
  GetMsgFromAddress(AbsMessage^.FromAddress);
  GetMsgToAddress(AbsMessage^.ToAddress);
  AbsMessage^.FromName:=NewStr(GetMsgFrom);
  AbsMessage^.ToName:=NewStr(GetMsgTo);
  AbsMessage^.Subject:=NewStr(GetMsgSubj);
  AbsMessage^.Flags:=GetMsgFlags;
  GetMsgDateTime(AbsMessage^.DateTime);

  objDispose(AbsMessage^.MessageBody);
  AbsMessage^.MessageBody:=MessageBody;
  MessageBody:=nil;

{  objDispose(AbsMessage^.MessageBody^.KludgeBase);
  AbsMessage^.MessageBody^.KludgeBase:=MessageBody^.KludgeBase;
  MessageBody^.KludgeBase:=nil;

  objDispose(AbsMessage^.MessageBody^.MsgBodyLink);
  AbsMessage^.MessageBody^.MsgBodyLink:=MessageBody^.MsgBodyLink;
  MessageBody^.MsgBodyLink:=nil;

  AbsMessage^.MessageBody^.PathLink:=MessageBody^.PathLink;
  MessageBody^.PathLink:=nil;

  AbsMessage^.MessageBody^.SeenByLink:=MessageBody^.SeenByLink;
  MessageBody^.SeenByLink:=nil;

  AbsMessage^.MessageBody^.ViaLink:=MessageBody^.ViaLink;
  MessageBody^.ViaLink:=nil;

  AbsMessage^.MessageBody^.TearLine:=MessageBody^.TearLine;
  MessageBody^.TearLine:=nil;
  AbsMessage^.MessageBody^.Origin:=MessageBody^.Origin;
  MessageBody^.Origin:=nil;}

  CutAbsMessage:=AbsMessage;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket.GetMsgArea:string;
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket.GetMsgTo:string;
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket.GetMsgFrom:string;
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket.GetPassword:string;
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.SetPassword(Pass:string);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function GetPktType(pkt:string):longint;
Var
  Sig : array[1..4] of char;
  F : file;
begin
  GetPktType:=ptNone;

  Assign(F,pkt);
{$I-}
  Reset(F,1);
  Seek(f,0);
  BlockRead(F,Sig,SizeOf(Sig));
{$I+}

  If IOResult<>0 then exit;

  If Sig='BCL'#0 then GetPktType:=ptBCL
    else GetPktType:=ptType2p;

  Close(F);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket.GetMsgHdrStream:PStream;
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.PutMsgHdrStream(HdrStream:PStream);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket.GetMsgSubj:string;
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.GetMsgDateTime(var DateTime:TDateTime);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.SetMsgDateTime(DateTime:TDateTime);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket.GetMsgFlags:word;
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.SetMsgFlags(var Flags:longint);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.GetMsgToAddress(Var Address:TAddress);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.GetMsgFromAddress(Var Address:TAddress);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.SetMsgFromAddress(Address:TAddress);
Var
 ToAddress : TAddress;
begin
  GetToAddress(ToAddress);

  If MsgArea='' then
    MessageBody^.KludgeBase^.SetKludge('INTL',
        ftnAddressToStrPointless(ToAddress)+#32+
        ftnAddressToStrPointless(Address));

  If MsgArea='' then
  If Address.Point<>0 then MessageBody^.KludgeBase^.SetKludge('FMPT',
                         strIntToStr(Address.Point)) else
                         MessageBody^.KludgeBase^.KillKludge('FMPT');


  If ftnCheckAddressString(strParser(MessageBody^.KludgeBase^.
             GetKludge('MSGID:'),1,[#32])) then
    MessageBody^.KludgeBase^.SetKludge('MSGID:',ftnAddressToStrEx(Address)+#32+
        strParser(MessageBody^.KludgeBase^.GetKludge('MSGID:'),2,[#32]));
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.SetMsgToAddress(Address:TAddress);
Var
 FromAddress : TAddress;
begin
  GetFromAddress(FromAddress);

  If MsgArea='' then
    MessageBody^.KludgeBase^.SetKludge('INTL',
        ftnAddressToStrPointless(Address)+#32+
        ftnAddressToStrPointless(FromAddress));

  If MsgArea='' then
  If Address.Point<>0 then MessageBody^.KludgeBase^.SetKludge('TOPT',
                         strIntToStr(Address.Point)) else
                         MessageBody^.KludgeBase^.KillKludge('TOPT');

  If ftnCheckAddressString(strParser(MessageBody^.KludgeBase^.
             GetKludge('REPLY:'),1,[#32])) then
    MessageBody^.KludgeBase^.SetKludge('REPLY:',ftnAddressToStrEx(Address)+#32+
        strParser(MessageBody^.KludgeBase^.GetKludge('REPLY:'),2,[#32]));
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.SetMsgTo(const ToName:string);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.SetMsgFrom(const FromName:string);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.SetMsgSubj(const Subject:string);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.SetMsgArea(const Area:string);
var
  sTemp : string;
begin
  sTemp:=strUpper(Area);
  If sTemp='NETMAIL' then sTemp:='';
  MsgArea:=sTemp;
end;

Function TPacket.GetMsgBodyStream:PStream;
begin
  GetMsgBodyStream:=MessageBody^.GetMsgBodyStream;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket.GetMsgSeenbys(var Addresses:PAddressCollection);
var
  iTemp:longint;
  i:integer;
  sTemp:string;
  s:string;
  PrevAddress:TAddress;
  TempAddress:PAddress;
begin
  If MessageBody^.SeenByLink=nil then exit;

  MessageBody^.SeenByLink^.Seek(0);

  GetMsgFromAddress(PrevAddress);

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

Procedure TPacket.GetMsgPaths(var Addresses:PAddressCollection);
var
  iTemp:longint;
  i:integer;
  sTemp:string;
  s:string;
  PrevAddress:TAddress;
  TempAddress:PAddress;
begin
  If MessageBody^.PathLink=nil then exit;

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

Procedure TPacket.SetAbsMessage(const AbsMessage:PAbsMessage;
         const Invalidate:boolean);
begin
  If AbsMessage^.Area<>nil then SetMsgArea(AbsMessage^.Area^);
  If AbsMessage^.FromName<>nil then SetMsgFrom(AbsMessage^.FromName^);
  If AbsMessage^.ToName<>nil then SetMsgTo(AbsMessage^.ToName^);
  If AbsMessage^.Subject<>nil then SetMsgSubj(AbsMessage^.Subject^);

  SetMsgDateTime(AbsMessage^.DateTime);
  SetMsgFlags(AbsMessage^.Flags);

  objDispose(MessageBody^.KludgeBase);
  MessageBody^.KludgeBase:=AbsMessage^.MessageBody^.KludgeBase;
  If Invalidate then
    AbsMessage^.MessageBody^.KludgeBase:=nil;

  objDispose(MessageBody^.MsgBodyLink);
  MessageBody^.MsgBodyLink:=AbsMessage^.MessageBody^.MsgBodyLink;
  If Invalidate then
    AbsMessage^.MessageBody^.MsgBodyLink:=nil;

  MessageBody^.PathLink:=AbsMessage^.MessageBody^.PathLink;
  If Invalidate then
    AbsMessage^.MessageBody^.PathLink:=nil;

  MessageBody^.SeenByLink:=AbsMessage^.MessageBody^.SeenByLink;
  If Invalidate then
    AbsMessage^.MessageBody^.SeenByLink:=nil;

  MessageBody^.ViaLink:=AbsMessage^.MessageBody^.ViaLink;
  If Invalidate then
    AbsMessage^.MessageBody^.ViaLink:=nil;

  MessageBody^.TearLine:=AbsMessage^.MessageBody^.TearLine;
  If Invalidate then
    AbsMessage^.MessageBody^.TearLine:=nil;
  MessageBody^.Origin:=AbsMessage^.MessageBody^.Origin;
  If Invalidate then
    AbsMessage^.MessageBody^.Origin:=nil;

  SetMsgFromAddress(AbsMessage^.FromAddress);
  SetMsgToAddress(AbsMessage^.ToAddress);
end;

Procedure TPacket.Flush;
begin
  PktLink^.Flush;
end;

end.
