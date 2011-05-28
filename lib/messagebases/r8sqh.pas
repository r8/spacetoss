{
  Squish MessageBase stuff.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
 FindFreeFrame
 Deleteuntil max
 Framelen<>MsgLen (выплывает из findfree)
}
Unit r8sqh;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
 {$PackRecords 1}
{$ENDIF}

interface

Uses
  r8mail,

  r8dos,
  r8dtm,
  r8objs,
  r8msgb,
  r8ftn,
  r8str,

  dos,
  strings,
  objects;

const
  sqhFrameId      = $AFAE4453;


{Frame types}
  sqhFrameMessage = $0000;
  sqhFrameFree    = $0001;

  sqhScanned      = $10000;

  sqhbtEchomail   = $000A0000;

{Offsets in frame header}
  sqhNextFrameOffset = 4;
  sqhPrevFrameOffset = 8;

Type

  TSqhAddress = record
    Zone, Net, Node, Point : word;
  end;

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

  TSqhFrame = record
    Id : longint;
    NextFrame   : longint;
    PrevFrame   : longint;
    FrameLength : longint;
    MsgLength   : longint;
    ControlLength : longint;
    FrameType : word;
    Reserved: word;
  end;

  TSqhIndex = record
    Offset : longint;
    Uid    : longint;
    Hash   : longint;
  end;

  TSqhMessageHeader = record
    Attribute : longint;
    MsgFrom : array[1..36] of char;
    MsgTo : array[1..36] of char;
    Subj : array[1..72] of char;
    OrigAddress : TSqhAddress;
    DestAddress : TSqhAddress;
    DateWritten : longint;
    DateArrived : longint;
    UtcOffset : word;
    ReplyTo: longint;
    Replies: array[1..9] of longint;
    Uid : longint;
    AzDate : array[1..20] of char;
  end;

  TSqhBase  = object(TMessageBase)
    SqhHeader : TSqhHeader;
    SqhMessageHeader : TSqhMessageHeader;
    SqhFrame : TSqhFrame;
    SqhIndex : TSqhIndex;

    SqhDataLink  : PStream;
    SqhIndexLink : PStream;
    SqhLastreadLink : PStream;

    Constructor Init;
    Destructor  Done; virtual;

    Procedure Open(const ABasePath:string);virtual;
    Procedure Create(const ABasePath:string);virtual;
    Procedure Close;virtual;

    Function GetCount:longint;virtual;

    Procedure CreateMessage(UseMsgID:Boolean);virtual;
    Procedure OpenMessage;virtual;
    Procedure WriteMessage;virtual;
    Procedure OpenHeader;virtual;
    Procedure WriteHeader;virtual;
    Procedure KillMessage;virtual;

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

    Function GetTimesRead:longint;virtual;
    Procedure SetTimesRead(const TR:longint);virtual;

    Procedure Seek(const i:longint);virtual;
    Procedure SeekNext;virtual;
    Procedure SeekPrev;virtual;

    Procedure Flush;virtual;

    Function FindFreeFrame:longint;

    Procedure SetNextFrame(const FrameOffset:longint;NextOffset:longint);
    Procedure SetPrevFrame(const FrameOffset:longint;PrevOffset:longint);
    Procedure SetNextAndPrevFrame(const FrameOffset:longint;NextOffset, PrevOffset:longint);

    Procedure SetSqhHeaderDefaults;
    Procedure SetMsgHeaderDefaults;
    Procedure WriteSqhHeader;

    Function SwapLong(l:longint):longint;
    Function GetHash(S:string):longint;

    Function PackIsNeeded:boolean;virtual;

    Procedure SetHighWater(const l:longint);
    Procedure SeekByUid(UID:longint);

    Procedure ReadLastreads;virtual;
    Procedure WriteLastreads;virtual;

    Function GetSize:longint;virtual;
    Procedure GetIndexes;

    Procedure Reset;virtual;
  end;
  PSqhBase = ^TSqhBase;

implementation

Constructor TSqhBase.Init;
begin
  inherited Init;

  SqhLastReadLink:=nil;
end;

Destructor TSqhBase.Done;
begin
  inherited Done;
end;

Procedure TSqhBase.GetIndexes;
Var
  StreamSize : longint;
  TempSqhIndex : TSqhIndex;
  lTemp : ^longint;
  i : longint;
begin
  StreamSize:=SqhIndexLink^.GetSize;
  SqhIndexLink^.Seek(0);

  For i:=1  to (StreamSize div SizeOf(SqhIndex)) do
    begin
      SqhIndexLink^.Read(TempSqhIndex,SizeOf(TSqhIndex));

      New(lTemp);
      lTemp^:=TempSqhIndex.UID;
      Indexes^.Insert(lTemp);
    end;
end;

Procedure TSqhBase.Open(const ABasePath:string);
begin
  If Status<>mlOk then exit;

  If not dosDirExists(dosGetPath(ABasePath)) then
    begin
      Status:=mlPathNotFound;
      exit;
    end;

  Status:=mlCantOpenOrCreateBase;
  BasePath:=NewStr(ABasePath);

  If not dosFileExists(BasePath^+'.sqd') then exit;
  If not dosFileExists(BasePath^+'.sqi') then exit;

  Status:=mlBaseLocked;

  SqhDataLink:=New(PBufStream,Init(BasePath^+'.sqd',
     fmOpen or fmReadWrite or fmDenyWrite,cBuffSize));
  SqhIndexLink:=New(PBufStream,Init(BasePath^+'.sqi',
     fmOpen or fmReadWrite or fmDenyWrite,cBuffSize));

  If IOResult<>0 then exit;

  If (SqhDataLink^.Status<>stOK)
     or (SqhIndexLink^.Status<>stOK) then exit;

  SqhDataLink^.Seek(0);
  SqhDataLink^.Read(SqhHeader,SizeOf(SqhHeader));

  If IOResult<>0 then exit;

  Status:=mlOk;

  GetIndexes;
end;

Procedure TSqhBase.Create(const ABasePath:string);
Var
  F : file;
begin
  If Status<>mlOk then exit;

  If not dosDirExists(dosGetPath(ABasePath)) then dosMkDir(ABasePath);

  Status:=mlCantOpenOrCreateBase;

  Assign(F,ABasePath+'.sqd');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;
  SetSqhHeaderDefaults;
  BlockWrite(F,SqhHeader,SizeOf(SqhHeader));
  System.Close(F);

  Assign(F,ABasePath+'.sqi');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;
  System.Close(F);

  Status:=mlOk;
  Open(ABasePath);
end;

Procedure TSqhBase.Close;
begin
  objDispose(SqhDataLink);
  objDispose(SqhIndexLink);
  objDispose(SqhLastReadLink);
end;

Function TSqhBase.GetCount:longint;
begin
  If Status<>mlOk then exit;

  GetCount:=SqhHeader.NumbOfMsgs;
end;

Procedure TSqhBase.CreateMessage(UseMsgID:Boolean);
begin
  If Status<>mlOk then exit;
  If MessageOpened then exit;

  inherited CreateMessage(UseMsgID);

  SetMsgHeaderDefaults;
  SqhIndexLink^.Seek(SqhIndexLink^.GetSize);

  MessageOpened:=True;
end;

Procedure TSqhBase.OpenMessage;
Var
  lTemp : longint;
  pTemp : PChar;
  sTemp : string;
begin
  OpenHeader;

  inherited OpenMessage;

  lTemp:=SqhDataLink^.GetPos;
  SqhDataLink^.Seek(lTemp+1);

  While SqhDataLink^.GetPos<lTemp+SqhFrame.ControlLength do
    begin
      pTemp:=objStreamRead(SqhDataLink,[#1,#0],SqhFrame.ControlLength);
      sTemp:=StrPas(pTemp);
      MessageBody^.KludgeBase^.SetKludge(strParser(sTemp,1,[#32]),
        Copy(sTemp,Pos(#32,sTemp)+1,Length(sTemp)-Pos(#32,sTemp)));
      StrDispose(pTemp);
    end;

  MessageBody^.MsgBodyLink^.Seek(0);
  MessageBody^.MsgBodyLink^.CopyFrom(SqhDataLink^,SqhFrame.MsgLength
                -SqhFrame.ControlLength-SizeOf(SqhMessageHeader));
end;

Procedure TSqhBase.OpenHeader;
begin
  SqhIndexLink^.Seek((CurrentMessage-1)*SizeOf(SqhIndex));
  SqhIndexLink^.Read(SqhIndex,SizeOf(SqhIndex));

  SqhDataLink^.Seek(SqhIndex.Offset);
  SqhDataLink^.Read(SqhFrame,SizeOf(SqhFrame));
  SqhDataLink^.Read(SqhMessageHeader,SizeOf(SqhMessageHeader));
end;

Procedure TSqhBase.WriteHeader;
begin
  SqhIndexLink^.Seek((CurrentMessage-1)*SizeOf(SqhIndex));
  SqhIndexLink^.Read(SqhIndex,SizeOf(SqhIndex));

  SqhDataLink^.Seek(SqhIndex.Offset);
  SqhDataLink^.Write(SqhFrame,SizeOf(SqhFrame));
  SqhDataLink^.Write(SqhMessageHeader,SizeOf(SqhMessageHeader));
end;

Procedure TSqhBase.WriteMessage;
Var
  Offset : longint;
  TempStream : PStream;
  i : longint;
  TempKludge : PKludge;
  sTemp : string;
  TempDateTime : TDateTime;
  TempIndex : TSqhIndex;
  lTemp : PLongint;
begin
  If Status<>mlOk then exit;
  If not MessageOpened then exit;

  Offset:=FindFreeFrame;

  If SqhFrame.PrevFrame<>0 then
    begin
      SetNextFrame(SqhFrame.PrevFrame,Offset);
    end
  else SqhHeader.FirstFrame:=Offset;

  If SqhFrame.NextFrame<>0 then
    begin
      SetPrevFrame(SqhFrame.NextFrame,Offset);
    end
  else SqhHeader.LastFrame:=Offset;

  TempStream:=New(PMemoryStream,Init(0,cBuffSize));
  For i:=0 to MessageBody^.KludgeBase^.Kludges^.Count-1 do
    begin
      TempKludge:=MessageBody^.KludgeBase^.Kludges^.At(i);
      sTemp:=#1;
      If TempKludge^.Name<>nil then sTemp:=sTemp+TempKludge^.Name^;
      If TempKludge^.Value<>nil then sTemp:=sTemp+#32+TempKludge^.Value^;
      objStreamWrite(TempStream,sTemp);
    end;
  objStreamWrite(TempStream,#0);
  SqhFrame.ControlLength:=TempStream^.GetSize;

  MessageBody^.MsgBodyLink^.Seek(0);
  TempStream^.CopyFrom(MessageBody^.MsgBodyLink^,
                  MessageBody^.MsgBodyLink^.GetSize);

  If MessageBody^.TearLine<>nil
      then objStreamWriteLn(TempStream,MessageBody^.TearLine^);
  If MessageBody^.Origin<>nil
      then objStreamWriteLn(TempStream,MessageBody^.Origin^);

  If MessageBody^.SeenByLink<>nil then
    begin
      MessageBody^.SeenByLink^.Seek(0);
      TempStream^.CopyFrom(MessageBody^.SeenByLink^,MessageBody^.SeenByLink^.GetSize);
    end;

  If MessageBody^.PathLink<>nil then
    begin
      MessageBody^.PathLink^.Seek(0);
      TempStream^.CopyFrom(MessageBody^.PathLink^,MessageBody^.PathLink^.GetSize);
    end;

  If MessageBody^.ViaLink<>nil then
    begin
      MessageBody^.ViaLink^.Seek(0);
      TempStream^.CopyFrom(MessageBody^.ViaLink^,MessageBody^.ViaLink^.GetSize);
    end;

  SqhFrame.FrameLength:=TempStream^.GetSize
       +SizeOf(SqhMessageHeader);
  SqhFrame.MsgLength:=SqhFrame.FrameLength;

  dtmGetDateTime(TempDateTime);
  SetDateArrived(TempDateTime);

  Case BaseType of
    btEchomail : SqhMessageHeader.Attribute:=SqhMessageHeader.Attribute
                                                   or sqhbtEchomail;
  end;

  SqhDataLink^.Seek(Offset);
  SqhDataLink^.Write(SqhFrame,SizeOf(SqhFrame));
  SqhDataLink^.Write(SqhMessageHeader,SizeOf(SqhMessageHeader));

  TempStream^.Seek(0);
  SqhDataLink^.CopyFrom(TempStream^,TempStream^.GetSize);
  objDispose(TempStream);

  If Offset=SqhHeader.EndFrame then SqhHeader.EndFrame:=SqhDataLink^.GetSize;
  WriteSqhHeader;

  TempIndex.Uid:=SqhMessageHeader.Uid;
  TempIndex.Offset:=Offset;
  TempIndex.Hash:=GetHash(GetTo);

  SqhIndexLink^.Write(TempIndex,SizeOf(TempIndex));

  New(lTemp);
  lTemp^:=SqhMessageHeader.Uid;
  Indexes^.Insert(lTemp);
end;

Procedure TSqhBase.SetNextFrame(const FrameOffset:longint;NextOffset:longint);
begin
  SqhDataLink^.Seek(FrameOffset+sqhNextFrameOffset);
  SqhDataLink^.Write(NextOffset,SizeOf(NextOffset));
end;

Procedure TSqhBase.SetPrevFrame(const FrameOffset:longint;PrevOffset:longint);
begin
  SqhDataLink^.Seek(FrameOffset+sqhPrevFrameOffset);
  SqhDataLink^.Write(PrevOffset,SizeOf(PrevOffset));
end;

Procedure TSqhBase.SetNextAndPrevFrame(const FrameOffset:longint;NextOffset, PrevOffset:longint);
begin
  SqhDataLink^.Seek(FrameOffset+sqhNextFrameOffset);
  SqhDataLink^.Write(NextOffset,SizeOf(NextOffset));
  SqhDataLink^.Write(PrevOffset,SizeOf(PrevOffset));
end;

Procedure TSqhBase.SetSubj(const Subject:string);
begin
  FillChar(SqhMessageHeader.Subj,SizeOf(SqhMessageHeader.Subj),#0);

  Move(Subject[1],SqhMessageHeader.Subj,Length(Subject));
end;

Function TSqhBase.GetSubj:string;
Var
  sTemp : string;
begin
  sTemp[0]:=Chr(SizeOf(SqhMessageHeader.Subj));
  Move(SqhMessageHeader.Subj,sTemp[1],SizeOf(SqhMessageHeader.Subj));
  GetSubj:=strTrimR(sTemp,[#0]);
end;

Procedure TSqhBase.SetTo(const ToName:string);
begin
  FillChar(SqhMessageHeader.MsgTo,SizeOf(SqhMessageHeader.MsgTo),#0);

  Move(ToName[1],SqhMessageHeader.MsgTo,Length(ToName));
end;

function TSqhBase.GetTo:string;
Var
  sTemp : string;
begin
  sTemp[0]:=Chr(SizeOf(SqhMessageHeader.MsgTo));
  Move(SqhMessageHeader.MsgTo,sTemp[1],SizeOf(SqhMessageHeader.MsgTo));
  GetTo:=strTrimR(sTemp,[#0]);
end;

Procedure TSqhBase.SetFrom(const FromName:string);
begin
  FillChar(SqhMessageHeader.MsgFrom,SizeOf(SqhMessageHeader.MsgFrom),#0);

  Move(FromName[1],SqhMessageHeader.MsgFrom,Length(FromName));
end;

function TSqhBase.GetFrom:string;
Var
  sTemp:string;
begin
  sTemp[0]:=Chr(SizeOf(SqhMessageHeader.MsgFrom));
  Move(SqhMessageHeader.MsgFrom,sTemp[1],SizeOf(SqhMessageHeader.MsgFrom));
  GetFrom:=strTrimR(sTemp,[#0]);
end;

Procedure TSqhBase.SetDateWritten(const ADateTime:TDateTime);
Var
  TempDateTime : DateTime;
  lTemp : longint;
begin
  TempDateTime.Year:=ADateTime.Year;
  TempDateTime.Month:=ADateTime.Month;
  TempDateTime.Day:=ADateTime.Day;
  TempDateTime.Hour:=ADateTime.Hour;
  TempDateTime.Min:=ADateTime.Minute;
  TempDateTime.Sec:=ADateTime.Sec;

  PackTime(TempDateTime,lTemp);
  SqhMessageHeader.DateWritten:=SwapLong(lTemp);
  dtmDateToFTN(ADateTime,SqhMessageHeader.AzDate);
end;

Procedure TSqhBase.SetDateArrived(const ADateTime:TDateTime);
Var
  TempDateTime : DateTime;
  lTemp : longint;
begin
  TempDateTime.Year:=ADateTime.Year;
  TempDateTime.Month:=ADateTime.Month;
  TempDateTime.Day:=ADateTime.Day;
  TempDateTime.Hour:=ADateTime.Hour;
  TempDateTime.Min:=ADateTime.Minute;
  TempDateTime.Sec:=ADateTime.Sec;

  PackTime(TempDateTime,lTemp);
  SqhMessageHeader.DateArrived:=SwapLong(lTemp);
end;

Procedure TSqhBase.GetDateWritten(var ADateTime:TDateTime);
Var
  TempDateTime : DateTime;
  lTemp : longint;
begin
  lTemp:=SwapLong(SqhMessageHeader.DateWritten);
  UnPackTime(lTemp, TempDateTime);

  ADateTime.Year:=TempDateTime.Year;
  ADateTime.Month:=TempDateTime.Month;
  ADateTime.Month:=TempDateTime.Month;
  ADateTime.Day:=TempDateTime.Day;
  ADateTime.Hour:=TempDateTime.Hour;
  ADateTime.Minute:=TempDateTime.Min;
  ADateTime.Sec:=TempDateTime.Sec;
end;

Procedure TSqhBase.GetDateArrived(var ADateTime:TDateTime);
Var
  TempDateTime : DateTime;
  lTemp : longint;
begin
  lTemp:=SwapLong(SqhMessageHeader.DateArrived);
  UnPackTime(lTemp, TempDateTime);

  ADateTime.Year:=TempDateTime.Year;
  ADateTime.Month:=TempDateTime.Month;
  ADateTime.Month:=TempDateTime.Month;
  ADateTime.Day:=TempDateTime.Day;
  ADateTime.Hour:=TempDateTime.Hour;
  ADateTime.Minute:=TempDateTime.Min;
  ADateTime.Sec:=TempDateTime.Sec;
end;

Procedure TSqhBase.SetFlags(const Flags:longint);
begin
  SqhMessageHeader.Attribute:=Flags;
  If (Flags and flgSent)=flgSent then
     SqhMessageHeader.Attribute:=SqhMessageHeader.Attribute or sqhScanned;
end;

Procedure TSqhBase.GetFlags(Var Flags:longint);
begin
  Flags:=SqhMessageHeader.Attribute;
end;

Procedure TSqhBase.SetFromAddress(const Address:TAddress);
begin
  inherited SetFromAddress(Address);

  SqhMessageHeader.OrigAddress.Zone:=Address.Zone;
  SqhMessageHeader.OrigAddress.Net:=Address.Net;
  SqhMessageHeader.OrigAddress.Node:=Address.Node;
  SqhMessageHeader.OrigAddress.Point:=Address.Point;
end;

Procedure TSqhBase.GetFromAddress(var Address:TAddress);
begin
  Address.Zone:=SqhMessageHeader.OrigAddress.Zone;
  Address.Net:=SqhMessageHeader.OrigAddress.Net;
  Address.Node:=SqhMessageHeader.OrigAddress.Node;
  Address.Point:=SqhMessageHeader.OrigAddress.Point;
end;

Procedure TSqhBase.SetToAddress(const Address:TAddress);
begin
  inherited SetToAddress(Address);

  SqhMessageHeader.DestAddress.Zone:=Address.Zone;
  SqhMessageHeader.DestAddress.Net:=Address.Net;
  SqhMessageHeader.DestAddress.Node:=Address.Node;
  SqhMessageHeader.DestAddress.Point:=Address.Point;
end;

Procedure TSqhBase.GetToAddress(var Address:TAddress);
begin
  Address.Zone:=SqhMessageHeader.DestAddress.Zone;
  Address.Net:=SqhMessageHeader.DestAddress.Net;
  Address.Node:=SqhMessageHeader.DestAddress.Node;
  Address.Point:=SqhMessageHeader.DestAddress.Point;
end;

Procedure TSqhBase.Seek(const i:longint);
begin
  If Status<>mlOk then exit;

  CurrentMessage:=i;
end;

Procedure TSqhBase.SeekNext;
begin
  If Status<>mlOk then exit;

  Status:=mlOutOfMessages;

  If CurrentMessage+1>Indexes^.Count then exit;

  Inc(CurrentMessage);
  Status:=mlOk;
end;

Procedure TSqhBase.SeekPrev;
begin
  If Status<>mlOk then exit;

  Status:=mlOutOfMessages;

  If CurrentMessage-1<1 then exit;

  Dec(CurrentMessage);
  Status:=mlOk;
end;

Procedure TSqhBase.Flush;
begin
  SqhDataLink^.Flush;
  SqhIndexLink^.Flush;
end;

Function TSqhBase.FindFreeFrame:longint;
begin
  FindFreeFrame:=SqhHeader.EndFrame;
end;

Procedure TSqhBase.SetSqhHeaderDefaults;
begin
  FillChar(SqhHeader,SizeOf(SqhHeader),#0);
  With SqhHeader do
    begin
      Len:=SizeOf(SqhHeader);
      Uid:=$01;
      EndFrame:=SizeOf(TSqhHeader);
      HdrSize:=SizeOf(TSqhFrame);
    end;
end;

Procedure TSqhBase.SetMsgHeaderDefaults;
begin
  FillChar(SqhMessageHeader,SizeOf(SqhMessageHeader),#0);
  FillChar(SqhFrame,SizeOf(SqhFrame),#0);

  SqhMessageHeader.Uid:=SqhHeader.Uid;
  Inc(SqhHeader.Uid);
  Inc(SqhHeader.NumbOfMsgs);
  SqhHeader.HighMsg:=SqhHeader.NumbOfMsgs;

  SqhFrame.Id:=sqhFrameID;
  SqhFrame.FrameType:=sqhFrameMessage;
  SqhFrame.NextFrame:=0;
  SqhFrame.PrevFrame:=SqhHeader.LastFrame;
end;

Procedure  TSqhBase.WriteSqhHeader;
begin
  SqhDataLink^.Seek(0);
  SqhDataLink^.Write(SqhHeader,SizeOf(SqhHeader));
end;

Function TSqhBase.SwapLong(l:longint):longint;
begin
  SwapLong:=(l shr 16)+((l and $FFFF) shl 16);
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

Procedure TSqhBase.SetHighWater(const l:longint);
var
  pTemp : PLongint;
begin
  if (l-1<0) or (l-1>Indexes^.Count) then SqhHeader.HighWater:=0 else
      begin
        pTemp:=Indexes^.At(l-1);
        SqhHeader.HighWater:=pTemp^;
      end;

  WriteSqhHeader;
end;

Procedure TSqhBase.SeekByUid(UID:longint);
begin
  CurrentMessage:=GetCount+1;

  While true do
    begin
      SeekPrev;
      If (Status<>mlOk) or (PLongint(Indexes^.At(CurrentMessage-1))^<=Uid)
        then break;
    end;
end;

Procedure TSqhBase.Reset;
begin
  inherited Reset;

  SqhDataLink^.Reset;
  SqhIndexLink^.Reset;
end;

Procedure TSqhBase.KillMessage;
var
  TempStream : PStream;
  lTemp : longint;
begin
  If Status<>mlOk then exit;

  If SqhFrame.PrevFrame<>0 then
    begin
      SetNextFrame(SqhFrame.PrevFrame,SqhFrame.NextFrame);
    end
  else SqhHeader.FirstFrame:=SqhFrame.NextFrame;

  If SqhFrame.NextFrame<>0 then
    begin
      SetPrevFrame(SqhFrame.NextFrame,SqhFrame.PrevFrame);
    end
  else SqhHeader.LastFrame:=SqhFrame.PrevFrame;

  If SqhHeader.LastFreeFrame<>0 then
    begin
      SetNextFrame(SqhHeader.LastFreeFrame,SqhIndex.Offset);
      SqhFrame.PrevFrame:=SqhHeader.LastFreeFrame;
    end;
  If SqhHeader.FreeFrame=0
    then SqhHeader.FreeFrame:=SqhIndex.Offset;

  SqhHeader.LastFreeFrame:=SqhIndex.Offset;
  SqhFrame.NextFrame:=0;

  SqhFrame.FrameType:=sqhFrameFree;

  SqhDataLink^.Seek(SqhIndex.Offset);
  SqhDataLink^.Write(SqhFrame,SizeOf(SqhFrame));
  SqhDataLink^.Write(SqhMessageHeader,SizeOf(SqhMessageHeader));

  lTemp:=SqhIndexLink^.GetSize;
  TempStream:=New(PMemoryStream,Init(0,cBuffSize));

  SqhIndexLink^.Seek(0);

  TempStream^.CopyFrom(SqhIndexLink^,(CurrentMessage-1)*SizeOf(SqhIndex));
  SqhIndexLink^.Seek(CurrentMessage*SizeOf(SqhIndex));
  TempStream^.CopyFrom(SqhIndexLink^,lTemp-(CurrentMessage*SizeOf(SqhIndex)));

  SqhIndexLink^.Seek(0);
  TempStream^.Seek(0);
  SqhIndexLink^.Truncate;
  SqhIndexLink^.CopyFrom(TempStream^,TempStream^.GetSize);

  objDispose(TempStream);

  If SqhHeader.NumbOfMsgs<>0 then Dec(SqhHeader.NumbOfMsgs);
  SqhHeader.HighMsg:=SqhHeader.NumbOfMsgs;

  WriteSqhHeader;

  Indexes^.AtFree(CurrentMessage-1);

  SeekPrev;

  Status:=mlOk;
end;

Procedure TSqhBase.ReadLastreads;
Var
  L,L2 : longint;
  TempLastRead : PLastRead;
begin
  If SqhLastReadLink=nil then
    begin
      SqhLastReadLink:=New(PBufStream,Init(BasePath^+'.sql',
         fmOpen or fmReadWrite or fmDenyWrite,cBuffSize));

      If IOResult<>0 then exit;
      If SqhLastReadLink^.Status<>stOK then exit;
    end;

  L:=SqhLastReadLink^.GetSize;

  While SqhLastReadLink^.GetPos<L-1 do
    begin
      TempLastread:=New(PLastRead);
      SqhLastReadLink^.Read(L2,SizeOf(L2));

      With TempLastRead^ do
        begin
          UserCRC:=-1;
          UserID:=LastReads^.Count;
          L2:=SearchForIndex(L2);
          If LastReadMsg=-1 then  LastReadMsg:=0;
          LastReadMsg:=L2;
          HighReadMsg:=L2;
        end;

      LastReads^.Insert(TempLastRead);
    end;

  objDispose(SqhLastReadLink);
end;

Procedure TSqhBase.WriteLastreads;
Var
  L : longint;

  Procedure WriteLastread(P:pointer);far;
  Var
    TempLastread : PLastread absolute P;
    pTemp : PLongint;
  begin
    if  (TempLastread^.LastReadMsg-1<0)
      or (TempLastread^.LastReadMsg-1>Indexes^.Count) then TempLastread^.LastReadMsg:=0 else
        begin
          pTemp:=Indexes^.At(TempLastread^.LastReadMsg-1);
          TempLastread^.LastReadMsg:=pTemp^;
        end;

    SqhLastReadLink^.Write(TempLastread^.LastReadMsg,SizeOf(TempLastread^.LastReadMsg));
  end;
begin
  dosErase(BasePath^+'.sql');

  SqhLastReadLink:=New(PBufStream,Init(BasePath^+'.sql',
         stCreate,cBuffSize));

  If IOResult<>0 then exit;
  If SqhLastReadLink^.Status<>stOK then exit;

  L:=0;
  If Lastreads^.Count=0 then SqhLastReadLink^.Write(L,SizeOf(L))
    else  LastReads^.ForEach(@WriteLastread);

  objDispose(SqhLastReadLink);
end;

Function TSqhBase.PackIsNeeded:boolean;
begin
  PackIsNeeded:=False;

  If SqhHeader.FreeFrame<>0
                    then PackIsNeeded:=True;
end;

Function TSqhBase.GetSize:longint;
begin
  GetSize:=SqhDataLink^.GetSize+SqhIndexLink^.GetSize;
end;

Function TSqhBase.GetTimesRead:longint;
begin
  If Status<>mlOk then exit;

  GetTimesRead:=0;
end;

Procedure TSqhBase.SetTimesRead(const TR:longint);
begin
  If Status<>mlOk then exit;
end;

end.
