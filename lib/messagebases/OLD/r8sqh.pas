{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
  {$PackRecords 1}
{$ENDIF}
Unit r8sqh;

interface

Uses
  objects,
  r8dos,
  r8objs,
  r8str,
  r8ftn,
  r8dtm,
  dos,
  strings,
  r8mail;

const
  sqhFrameID      = $AFAE4453;
  sqhFrameMessage = $0000;
  sqhFrameFree    = $0001;

  sqhScanned      = $10000;

  sqhbtEchomail   = $000A0000;

Type
  TSqhHeader = record
    Len : word;
    Reserved1 : word;
    NumbOfMsgs : longint;
    HighMsg : longint;
    SkipMsg : longint;
    HighWater : longint;
    Uid : longint;
    Base : array[1..80] of char;
    FirstFrame : longint;
    LastFrame : longint;
    FreeFrame : longint;
    LastFreeFrame : longint;
    EndFrame : longint;
    MaxMsgs : longint;
    KeepDays : word;
    HdrSize : word;
    Recerved2 : array[1..124] of char;
  end;

  TSquishFrame = record
    Id : longint;
    NextFrame   : longint;
    PrevFrame   : longint;
    FrameLength : longint;
    MsgLength   : longint;
    ControlLength : longint;
    FrameType : word;
    Reserved: word;
  end;

  TSquishIndex = record
    Offset : longint;
    Uid    : longint;
    Hash   : longint;
  end;

  TSqMsgHdr = record
    Attribute : longint;
    MsgFrom : array[1..36] of char;
    MsgTo : array[1..36] of char;
    Subj : array[1..72] of char;
    OrigAddress : TSimpleAddress;
    DestAddress : TSimpleAddress;
    DateWritten : longint;
    DateArrived : longint;
    UtcOffset : word;
    ReplyTo: longint;
    Replies: array[1..9] of longint;
    Uid : longint;
    AzDate : array[1..20] of char;
  end;


  TSqhBase = object(TMessageBase)
    SqhHeader : TSqhHeader;
    SqhMsgHdr : TSqMsgHdr;
    SquishFrame : TSquishFrame;

    Constructor Init;
    Destructor Done;virtual;

    Function OpenBase(Path:string):boolean;virtual;
    Function CreateBase(Path:string):boolean;virtual;
    Procedure CloseBase;virtual;

    Procedure GetBaseTime(var BaseTime:TDateTime);virtual;

    Function GetSize:longint;virtual;

    Function GetCount:longint;virtual;

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
    Function GetLastRead:longint;virtual;
    Procedure SetLastRead(lr:longint);virtual;

    Procedure Flush;virtual;

    Function GetRawMessage:pointer;virtual;
    Procedure PutRawMessage(P:pointer);virtual;
    Function PackIsNeeded:boolean;virtual;

    Procedure SetHDRDefaults;
    Procedure SetMsgHdrDefaults;
    Procedure  WriteSqhHeader;
    Function SwapLong(l:longint):longint;
    Function GetHash(S:string):longint;
  private
    SquishDataLink : PBufStream;
    SquishIndexLink: PBufStream;
  end;

  PSqhBase = ^TSqhBase;

  TSqhRawMessage = record
    Index : TSquishIndex;
    Frame : TSquishFrame;
    Header : TSqMsgHdr;
    Message : PStream;
  end;

  PSqhRawMessage = ^TSqhRawMessage;

implementation

Constructor TSqhBase.Init;
begin
  inherited Init;
end;

Destructor TSqhBase.Done;
begin
  inherited Done;

  objDispose(SquishDataLink);
  objDispose(SquishIndexLink);

  CloseMessage;
end;

Function TSqhBase.OpenBase(Path:string):boolean;
begin
  OpenBase:=False;

  If not dosDirExists(dosGetPath(Path)) then exit;

  DisposeStr(BasePath);
  BasePath:=NewStr(Path);

  If not dosFileExists(Path+'.SQD') then exit;
  If not dosFileExists(Path+'.SQI') then exit;

  SquishDataLink:=New(PBufStream,Init(Path+'.SQD',stOpen,cBuffSize));
  SquishIndexLink:=New(PBufStream,Init(Path+'.SQI',stOpen,cBuffSize));

  If (SquishDataLink^.Status<>stOK)
     or (SquishIndexLink^.Status<>stOK) then exit;

  If IOResult<>0 then exit;

  SquishDataLink^.Seek(0);
  SquishDataLink^.Read(SqhHeader,SizeOf(SqhHeader));

  OpenBase:=True;
end;

Function TSqhBase.CreateBase(Path:string):boolean;
Var
  f:file;
begin
  CreateBase:=False;

  If not dosDirExists(dosGetPath(Path)) then dosMkDir(dosGetPath(Path));

  Assign(f,Path+'.SQD');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;
  SetHDRDefaults;
  BlockWrite(F,SqhHeader,SizeOf(SqhHeader));
  Close(F);

  Assign(f,Path+'.SQI');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;
  Close(F);

  CreateBase:=OpenBase(Path);
end;

Procedure TSqhBase.CloseBase;
begin
  CloseMessage;
end;

Procedure TSqhBase.SetHDRDefaults;
begin
  FillChar(SqhHeader,SizeOf(SqhHeader),#0);
  With SqhHeader do
    begin
      Len:=SizeOf(SqhHeader);
      Uid:=$01;
      EndFrame:=SizeOf(TSqhHeader);
      HdrSize:=SizeOf(TSquishFrame);
    end;
end;

Function TSqhBase.CreateNewMessage(UseMsgID:Boolean):boolean;
begin
  CreateNewMessage:=False;

  inherited CreateNewMessage(UseMsgID);

  If MsgOpened then exit;

  SetMsgHdrDefaults;

  Inc(SqhHeader.NumbOfMsgs);
  SqhHeader.HighMsg:=SqhHeader.NumbOfMsgs;
  Inc(SqhHeader.Uid);

  CreateNewMessage:=True;
end;

Procedure TSqhBase.CloseMessage;
begin
  inherited CloseMessage;
end;

Procedure TSqhBase.SetMsgHdrDefaults;
begin
  FillChar(SqhMsgHdr,SizeOf(SqhMsgHdr),#0);
  FillChar(SquishFrame,SizeOf(SquishFrame),#0);

  SquishFrame.Id:=sqhFrameID;
  SquishFrame.FrameType:=sqhFrameMessage;

  SqhMsgHdr.Uid:=SqhHeader.Uid;

  If SqhHeader.LastFrame<>0 then SquishFrame.PrevFrame:=SqhHeader.LastFrame;
end;

Procedure TSqhBase.SetSubj(const Subject:string);
begin
  FillChar(SqhMsgHdr.Subj,SizeOf(SqhMsgHdr.Subj),#0);

  Move(Subject[1],SqhMsgHdr.Subj,Length(Subject));
end;

Function TSqhBase.GetSubj:string;
Var
  sTemp:string;
begin
  sTemp[0]:=Chr(SizeOf(SqhMsgHdr.Subj));
  Move(SqhMsgHdr.Subj,sTemp[1],SizeOf(SqhMsgHdr.Subj));
  GetSubj:=strTrimR(sTemp,[#0]);
end;

Procedure TSqhBase.SetTo(const ToName:string);
begin
  FillChar(SqhMsgHdr.MsgTo,SizeOf(SqhMsgHdr.MsgTo),#0);

  Move(ToName[1],SqhMsgHdr.MsgTo,Length(ToName));
end;

function TSqhBase.GetTo:string;
Var
  sTemp:string;
begin
  sTemp[0]:=Chr(SizeOf(SqhMsgHdr.MsgTo));
  Move(SqhMsgHdr.MsgTo,sTemp[1],SizeOf(SqhMsgHdr.MsgTo));
  GetTo:=strTrimR(sTemp,[#0]);
end;

Procedure TSqhBase.SetFrom(const FromName:string);
begin
  FillChar(SqhMsgHdr.MsgFrom,SizeOf(SqhMsgHdr.MsgFrom),#0);

  Move(FromName[1],SqhMsgHdr.MsgFrom,Length(FromName));
end;

function TSqhBase.GetFrom:string;
Var
  sTemp:string;
begin
  sTemp[0]:=Chr(SizeOf(SqhMsgHdr.MsgFrom));
  Move(SqhMsgHdr.MsgFrom,sTemp[1],SizeOf(SqhMsgHdr.MsgFrom));
  GetFrom:=strTrimR(sTemp,[#0]);
end;

Procedure TSqhBase.SetDateWritten(MDateTime:TDateTime);
Var
  TempDateTime : DateTime;
  lTemp : longint;
begin
  TempDateTime.Year:=MDateTime.Year;
  TempDateTime.Month:=MDateTime.Month;
  TempDateTime.Day:=MDateTime.Day;
  TempDateTime.Hour:=MDateTime.Hour;
  TempDateTime.Min:=MDateTime.Minute;
  TempDateTime.Sec:=MDateTime.Sec;

  PackTime(TempDateTime,lTemp);
  SqhMsgHdr.DateWritten:=SwapLong(lTemp);
  ftnSetFTNDateTime(MDateTime,SqhMsgHdr.AzDate);
end;

Procedure TSqhBase.SetDateArrived(MDateTime:TDateTime);
Var
  TempDateTime : DateTime;
  lTemp : longint;
begin
  TempDateTime.Year:=MDateTime.Year;
  TempDateTime.Month:=MDateTime.Month;
  TempDateTime.Day:=MDateTime.Day;
  TempDateTime.Hour:=MDateTime.Hour;
  TempDateTime.Min:=MDateTime.Minute;
  TempDateTime.Sec:=MDateTime.Sec;

  PackTime(TempDateTime,lTemp);
  SqhMsgHdr.DateArrived:=SwapLong(lTemp);
end;

Procedure TSqhBase.GetDateWritten(var MDateTime:TDateTime);
Var
  TempDateTime : DateTime;
  lTemp : longint;
begin
  lTemp:=SwapLong(SqhMsgHdr.DateWritten);
  UnPackTime(lTemp, TempDateTime);

  MDateTime.Year:=TempDateTime.Year;
  MDateTime.Month:=TempDateTime.Month;
  MDateTime.Month:=TempDateTime.Month;
  MDateTime.Day:=TempDateTime.Day;
  MDateTime.Hour:=TempDateTime.Hour;
  MDateTime.Minute:=TempDateTime.Min;
  MDateTime.Sec:=TempDateTime.Sec;
end;

Procedure TSqhBase.GetDateArrived(var MDateTime:TDateTime);
Var
  TempDateTime : DateTime;
  lTemp : longint;
begin
  lTemp:=SwapLong(SqhMsgHdr.DateArrived);
  UnPackTime(lTemp, TempDateTime);

  MDateTime.Year:=TempDateTime.Year;
  MDateTime.Month:=TempDateTime.Month;
  MDateTime.Month:=TempDateTime.Month;
  MDateTime.Day:=TempDateTime.Day;
  MDateTime.Hour:=TempDateTime.Hour;
  MDateTime.Minute:=TempDateTime.Min;
  MDateTime.Sec:=TempDateTime.Sec;
end;

Procedure TSqhBase.SetFlags(Flags:longint);
begin
  SqhMsgHdr.Attribute:=Flags;
  If (Flags and flgSent)=flgSent then
     SqhMsgHdr.Attribute:=SqhMsgHdr.Attribute or sqhScanned;
end;

Procedure TSqhBase.GetFlags(Var Flags:longint);
begin
  Flags:=SqhMsgHdr.Attribute;
end;

Procedure TSqhBase.SetFromAddress(Address:TAddress);
begin
  inherited SetFromAddress(Address);

  SqhMsgHdr.OrigAddress.Zone:=Address.Zone;
  SqhMsgHdr.OrigAddress.Net:=Address.Net;
  SqhMsgHdr.OrigAddress.Node:=Address.Node;
  SqhMsgHdr.OrigAddress.Point:=Address.Point;
end;

Procedure TSqhBase.GetFromAddress(var Address:TAddress);
begin
  Address.Zone:=SqhMsgHdr.OrigAddress.Zone;
  Address.Net:=SqhMsgHdr.OrigAddress.Net;
  Address.Node:=SqhMsgHdr.OrigAddress.Node;
  Address.Point:=SqhMsgHdr.OrigAddress.Point;
end;

Procedure TSqhBase.SetToAddress(Address:TAddress);
begin
  inherited SetToAddress(Address);

  SqhMsgHdr.DestAddress.Zone:=Address.Zone;
  SqhMsgHdr.DestAddress.Net:=Address.Net;
  SqhMsgHdr.DestAddress.Node:=Address.Node;
  SqhMsgHdr.DestAddress.Point:=Address.Point;
end;

Procedure TSqhBase.GetToAddress(var Address:TAddress);
begin
  Address.Zone:=SqhMsgHdr.DestAddress.Zone;
  Address.Net:=SqhMsgHdr.DestAddress.Net;
  Address.Node:=SqhMsgHdr.DestAddress.Node;
  Address.Point:=SqhMsgHdr.DestAddress.Point;
end;

Function TSqhBase.GetCount:longint;
begin
  GetCount:=SqhHeader.NumbOfMsgs;
end;

Function TSqhBase.OpenMsg:boolean;
Var
  SquishIndex : TSquishIndex;
  ControlData : PStream;
  TempStream : PStream;
  iTemp:longint;
  pTemp:PChar;
  sTemp:string;
begin
  OpenMsg:=False;

  If MsgOpened then exit;

  SquishIndexLink^.Seek(CurrentMessage*SizeOf(SquishIndex));
  SquishIndexLink^.Read(SquishIndex,SizeOf(SquishIndex));

  SquishDataLink^.Seek(SquishIndex.Offset);
  SquishDataLink^.Read(SquishFrame,SizeOf(SquishFrame));
  SquishDataLink^.Read(SqhMsgHdr,SizeOf(SqhMsgHdr));

  inherited OpenMsg;

  ControlData:=New(PMemoryStream,Init(0,cBuffSize));
  ControlData^.CopyFrom(SquishDataLink^,SquishFrame.ControlLength);

  TempStream:=New(PMemoryStream,Init(0,cBuffSize));

  iTemp:=ControlData^.GetSize;
  ControlData^.Seek(1);

  While ControlData^.GetPos<iTemp-1 do
    begin
      pTemp:=objStreamReadStrEx(ControlData,iTemp,[#1]);
      sTemp:=StrPas(pTemp);
      objStreamWriteStr10(TempStream,#1+sTemp);
      StrDispose(pTemp);
    end;

  MessageBody^.AddToMsgBodyStream(TempStream);

  objDispose(TempStream);
  objDispose(ControlData);

  MessageBody^.MsgBodyLink^.CopyFrom(SquishDataLink^,SquishFrame.MsgLength
                -SquishFrame.ControlLength-SizeOf(SqhMsgHdr)-1);

  OpenMsg:=True;
  MsgOpened:=True;
end;

Function TSqhBase.WriteMessage:boolean;
Var
  SquishIndex : TSquishIndex;
  TempDateTime : TDateTime;
  MessageOffset : longint;
  TempFrame : TSquishFrame;
  TempStream : PStream;
  i : integer;
  TempKludge : PKludge;
begin
  TempFrame:=SquishFrame;
  If MsgOpened then KillMessage;
  SquishFrame:=TempFrame;

  MessageOffset:=SqhHeader.EndFrame;
  SquishDataLink^.Seek(MessageOffset);
  SquishDataLink^.Write(SquishFrame,SizeOf(SquishFrame));

  If SquishFrame.PrevFrame=0 then
      SqhHeader.FirstFrame:=MessageOffset;

  If SquishFrame.NextFrame=0 then
      SqhHeader.LastFrame:=MessageOffset;

  If SquishFrame.PrevFrame<>0 then
    begin
      SquishDataLink^.Seek(SquishFrame.PrevFrame);
      SquishDataLink^.Read(TempFrame,SizeOf(TempFrame));

      TempFrame.NextFrame:=MessageOffset;

      SquishDataLink^.Seek(SquishFrame.PrevFrame);
      SquishDataLink^.Write(TempFrame,SizeOf(TempFrame));
    end;

  If SquishFrame.NextFrame<>0 then
    begin
      SquishDataLink^.Seek(SquishFrame.NextFrame);
      SquishDataLink^.Read(TempFrame,SizeOf(TempFrame));

      TempFrame.PrevFrame:=MessageOffset;

      SquishDataLink^.Seek(SquishFrame.NextFrame);
      SquishDataLink^.Write(TempFrame,SizeOf(TempFrame));
    end;

  SquishDataLink^.Seek(MessageOffset);
  SquishDataLink^.Write(SquishFrame,SizeOf(SquishFrame));

  dtmGetDateTime(TempDateTime);
  SetDateArrived(TempDateTime);

  Case BaseType of
    btEchomail : SqhMsgHdr.Attribute:=SqhMsgHdr.Attribute
                                                   or sqhbtEchomail;
  end;

  SquishDataLink^.Write(SqhMsgHdr,SizeOf(SqhMsgHdr));

  TempStream:=New(PMemoryStream,Init(0,cBuffSize));

  for i:=0 to MessageBody^.KludgeBase^.Kludges^.Count-1 do
    begin
      TempKludge:=MessageBody^.KludgeBase^.Kludges^.At(i);
      objStreamWriteStr(TempStream,
            #1+TempKludge^.Name+#32+TempKludge^.Value);
    end;
  objStreamWriteStr(TempStream,#0);

  Squishframe.ControlLength:=TempStream^.GetSize;

  TempStream^.Seek(0);
  SquishDataLink^.CopyFrom(TempStream^,SquishFrame.ControlLength);

  objDispose(TempStream);

  TempStream:=New(PMemoryStream,Init(0,cBuffSize));
  MessageBody^.MsgBodyLink^.Seek(0);
  TempStream^.CopyFrom(MessageBody^.MsgBodyLink^,
                  MessageBody^.MsgBodyLink^.GetSize);

  If MessageBody^.TearLine<>nil then objStreamWriteStr10(TempStream,
                                         MessageBody^.TearLine^);
  If MessageBody^.Origin<>nil then objStreamWriteStr10(TempStream,
                                          MessageBody^.Origin^);

  If BaseType=btNetmail then
    begin
      MessageBody^.ViaLink^.Seek(0);
      TempStream^.CopyFrom(MessageBody^.ViaLink^,MessageBody^.ViaLink^.GetSize);
    end;

  If BaseType=btEchomail then
    begin
      MessageBody^.SeenByLink^.Seek(0);
      TempStream^.CopyFrom(MessageBody^.SeenByLink^,MessageBody^.SeenByLink^.GetSize);
      MessageBody^.PathLink^.Seek(0);
      TempStream^.CopyFrom(MessageBody^.PathLink^,MessageBody^.PathLink^.GetSize);
    end;

  TempStream^.Seek(0);
  SquishDataLink^.CopyFrom(TempStream^,TempStream^.GetSize);

  SquishFrame.FrameLength:=TempStream^.GetSize
       +SquishFrame.ControlLength+SizeOf(SqhMsgHdr)+1;
  SquishFrame.MsgLength:=SquishFrame.FrameLength;

  objDispose(TempStream);

  SquishDataLink^.Seek(MessageOffset);
  SquishDataLink^.Write(SquishFrame,SizeOf(SquishFrame));

  SquishIndex.Uid:=SqhMsgHdr.UID;
  SquishIndex.Offset:=MessageOffset;
  SquishIndex.Hash:=GetHash(GetTo);

  If MsgOpened
     then SquishIndexLink^.Seek(CurrentMessage*SizeOf(SquishIndex))
       else SquishIndexLink^.Seek(SquishIndexLink^.GetSize);


  SquishIndexLink^.Write(SquishIndex,SizeOf(SquishIndex));

  SquishDataLink^.Seek(SquishDataLink^.GetSize);
  objStreamWriteStr(SquishDataLink,#0);
  SqhHeader.EndFrame:=SquishDataLink^.GetSize;

  WriteSqhHeader;
end;

Procedure  TSqhBase.WriteSqhHeader;
begin
  SquishDataLink^.Seek(0);
  SquishDataLink^.Write(SqhHeader,SizeOf(SqhHeader));
end;

Function TSqhBase.SwapLong(l:longint):longint;
begin
  SwapLong:=(l shr 16)+((l and $FFFF) shl 16);
end;

Function TSqhBase.GetSize:longint;
begin
  GetSize:=SquishDataLink^.GetSize+SquishIndexLink^.GetSize;
end;

Function TSqhBase.GetHash(S:string):longint;
Var
  hash : longint;
  i : integer;
  lTemp : longint;
begin
  hash:=0;
  S:=r8Str.strLower(S);

  For i:=1 to length(S) do
   begin
     hash:=(hash shl 4)+Ord(S[i]);
     lTemp:=hash and $F0000000;
     if lTemp<>0 then
             hash:=(hash or (lTemp shr 24)) or lTemp;
   end;

  GetHash:=hash and $7FFFFFFF;
end;

Procedure TSqhBase.KillMessage;
Var
  TempFrame : TSquishFrame;
  TempSquishHeader : TSqMsgHdr;
  SquishIndex : TSquishIndex;
  TempStream : PStream;
begin
  SquishIndexLink^.Seek(CurrentMessage*SizeOf(SquishIndex));
  SquishIndexLink^.Read(SquishIndex,SizeOf(SquishIndex));

  If not MsgOpened then
    begin
      SquishDataLink^.Seek(SquishIndex.Offset);
      SquishDataLink^.Read(SquishFrame,SizeOf(SquishFrame));

      TempStream:=New(PMemoryStream,Init(0,cBuffSize));
      SquishIndexLink^.Seek(0);

      TempStream^.CopyFrom(SquishIndexLink^,CurrentMessage*SizeOf(SquishIndex));
      SquishIndexLink^.Seek((CurrentMessage+1)*SizeOf(SquishIndex));
      If SquishIndexLink^.Status<>stOK then
        begin
          SquishIndexLink^.Reset;
          SquishIndexLink^.Seek(SquishIndexLink^.GetSize);
        end;
      TempStream^.CopyFrom(SquishIndexLink^,SquishIndexLink^.GetSize-SquishIndexLink^.GetPos);

      TempStream^.Seek(0);
      SquishIndexLink^.Seek(0);

      SquishIndexLink^.Truncate;
      SquishIndexLink^.CopyFrom(TempStream^,TempStream^.GetSize);

      objDispose(TempStream);

      Dec(SqhHeader.NumbOfMsgs);
      Dec(CurrentMessage);
      SqhHeader.HighMsg:=SqhHeader.NumbOfMsgs;
    end;

  SquishFrame.FrameType:=sqhFrameFree;

  If SquishFrame.PrevFrame<>0 then
    begin
      SquishDataLink^.Seek(SquishFrame.PrevFrame);
      SquishDataLink^.Read(TempFrame,SizeOf(TempFrame));
      SquishDataLink^.Read(TempSquishHeader,SizeOf(TempSquishHeader));
      TempFrame.NextFrame:=SquishFrame.NextFrame;
      SquishDataLink^.Seek(SquishFrame.PrevFrame);
      SquishDataLink^.Write(TempFrame,SizeOf(TempFrame));

{      If TempFrame.NextFrame=0 then
        begin
          SqhHeader.UID:=TempSquishHeader.UID+1;
        end;}
    end
    else SqhHeader.FirstFrame:=SquishFrame.NextFrame;

  If SquishFrame.NextFrame<>0 then
    begin
      SquishDataLink^.Seek(SquishFrame.NextFrame);
      SquishDataLink^.Read(TempFrame,SizeOf(TempFrame));
      SquishDataLink^.Read(TempSquishHeader,SizeOf(TempSquishHeader));
      TempFrame.PrevFrame:=SquishFrame.PrevFrame;
      SquishDataLink^.Seek(SquishFrame.NextFrame);
      SquishDataLink^.Write(TempFrame,SizeOf(TempFrame));

{      If TempFrame.NextFrame=0 then
        begin
          SqhHeader.UID:=TempSquishHeader.UID+1;
        end;}
    end
    else SqhHeader.LastFrame:=SquishFrame.PrevFrame;

  SquishFrame.PrevFrame:=SqhHeader.LastFreeFrame;
  SquishFrame.NextFrame:=0;

  If SqhHeader.FreeFrame=0 then
    begin
      SqhHeader.FreeFrame:=SquishIndex.Offset;
    end;

  If SqhHeader.LastFreeFrame<>0 then
   begin
     SquishDataLink^.Seek(SqhHeader.LastFreeFrame);
     SquishDataLink^.Read(TempFrame,SizeOf(TempFrame));
     TempFrame.NextFrame:=SquishIndex.Offset;
     SquishDataLink^.Seek(SqhHeader.LastFreeFrame);
     SquishDataLink^.Write(TempFrame,SizeOf(TempFrame));
   end;

  SqhHeader.LastFreeFrame:=SquishIndex.Offset;

  SquishDataLink^.Seek(SquishIndex.Offset);
  SquishDataLink^.Write(SquishFrame,SizeOf(SquishFrame));

  WriteSqhHeader;
end;

Procedure TSqhBase.GetBaseTime(var BaseTime:TDateTime);
Var
  T:longint;
  TempDateTime : DateTime;
  F:file;
begin
  Assign(F,BasePath^+'.SQD');
  Reset(F);
  GetFTime(F,T);

  UnPackTime(T, TempDateTime);

  BaseTime.Year:=TempDateTime.Year;
  BaseTime.Month:=TempDateTime.Month;
  BaseTime.Month:=TempDateTime.Month;
  BaseTime.Day:=TempDateTime.Day;
  BaseTime.Hour:=TempDateTime.Hour;
  BaseTime.Minute:=TempDateTime.Min;
  BaseTime.Sec:=TempDateTime.Sec;

  Close(F);
end;

Procedure TSqhBase.Flush;
begin
  SquishDataLink^.Flush;
  SquishIndexLink^.Flush;
end;

Function TSqhBase.GetRawMessage:pointer;
Var
  SqhRawMessage : PSqhRawMessage;
begin
  SqhRawMessage:=New(PSqhRawMessage);

  SquishIndexLink^.Seek(CurrentMessage*SizeOf(SqhRawMessage^.Index));
  SquishIndexLink^.Read(SqhRawMessage^.Index,SizeOf(SqhRawMessage^.Index));

  SquishDataLink^.Seek(SqhRawMessage^.Index.Offset);
  SquishDataLink^.Read(SqhRawMessage^.Frame,SizeOf(SqhRawMessage^.Frame));
  SquishDataLink^.Read(SqhRawMessage^.Header,SizeOf(SqhRawMessage^.Header));

  SqhRawMessage^.Message:=New(PMemoryStream,Init(0,cBuffSize));
  SqhRawMessage^.Message^.CopyFrom(SquishDataLink^,
              SqhRawMessage^.Frame.MsgLength-1
              -SizeOf(SqhRawMessage^.Header));

  SqhRawMessage^.Header.ReplyTo:=0;
  FillChar(SqhRawMessage^.Header.Replies,
        SizeOf(SqhRawMessage^.Header.Replies),#0);

  GetRawMessage:=SqhRawMessage;
end;

Procedure TSqhBase.PutRawMessage(P:pointer);
Var
  SqhRawMessage : PSqhRawMessage absolute P;
  TempFrame : TSquishFrame;
  MessageOffset : longint;
begin
  MessageOffset:=SqhHeader.EndFrame;

  SqhRawMessage^.Frame.PrevFrame:=SqhHeader.LastFrame;
  SqhRawMessage^.Frame.NextFrame:=0;

  If SqhRawMessage^.Frame.PrevFrame=0 then
      SqhHeader.FirstFrame:=MessageOffset;

  If SqhRawMessage^.Frame.PrevFrame<>0 then
    begin
      SquishDataLink^.Seek(SqhRawMessage^.Frame.PrevFrame);
      SquishDataLink^.Read(TempFrame,SizeOf(TempFrame));

      TempFrame.NextFrame:=MessageOffset;

      SquishDataLink^.Seek(SqhRawMessage^.Frame.PrevFrame);
      SquishDataLink^.Write(TempFrame,SizeOf(TempFrame));
    end;

  SqhRawMessage^.Header.UID:=SqhHeader.Uid;
  SqhRawMessage^.Index.UID:=SqhHeader.Uid;

  SquishDataLink^.Seek(MessageOffset);
  SquishDataLink^.Write(SqhRawMessage^.Frame,SizeOf(SqhRawMessage^.Frame));
  SquishDataLink^.Write(SqhRawMessage^.Header,
                            SizeOf(SqhRawMessage^.Header));

  SqhRawMessage^.Message^.Seek(0);
  SquishDataLink^.CopyFrom(SqhRawMessage^.Message^,
              SqhRawMessage^.Frame.MsgLength-1
              -SizeOf(SqhRawMessage^.Header));

  SqhRawMessage^.Index.Offset:=MessageOffset;
  SquishIndexLink^.Seek(SquishIndexLink^.GetSize);
  SquishIndexLink^.Write(SqhRawMessage^.Index,SizeOf(SqhRawMessage^.Index));

  SquishDataLink^.Seek(SquishDataLink^.GetSize);
  objStreamWriteStr(SquishDataLink,#0);
  SqhHeader.EndFrame:=SquishDataLink^.GetSize;

  Inc(SqhHeader.NumbOfMsgs);
  SqhHeader.HighMsg:=SqhHeader.NumbOfMsgs;
  Inc(SqhHeader.Uid);
  SqhHeader.LastFrame:=MessageOffset;

  WriteSqhHeader;

  objDispose(SqhRawMessage^.Message);
  Dispose(SqhRawMessage);
end;

Function TSqhBase.PackIsNeeded:boolean;
begin
  PackIsNeeded:=False;

  If SqhHeader.FreeFrame<>0
                    then PackIsNeeded:=True;
end;

Function TSqhBase.GetLastRead:longint;
Var
  F : file of longint;
  lr:longint;
begin
  lr:=0;

  Assign(F,BasePath^+'.SQL');
{$I-}
  ReSet(F);
{$I+}

  If IOResult=0 then
    begin
      System.Seek(F,0);
{$I-}
      Read(F,lr);
{$I+}
      If IOResult<>0 then lr:=0;
      Close(F);
    end;

  If (lr>GetCount+1) or (lr<0) then lr:=0;

  GetLastRead:=lr;
end;

Procedure TSqhBase.SetLastRead(lr:longint);
Var
  F:file of longint;
begin
  If (lr>GetCount+1) or (lr<0) then lr:=0;

  Assign(F,BasePath^+'.JLR');
  ReWrite(F);
  System.Seek(F,0);
  Write(F,lr);
  Close(F);
end;


end.
