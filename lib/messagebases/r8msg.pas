{
 FIDO/Opus MessageBase stuff.
 (c) by Sergey Storchay (2:462/117@fidonet), 2000-2001.
}
Unit r8msg;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
 {$PackRecords 1}
{$ENDIF}

interface

Uses
  dos,
  objects,

  r8mail,

  r8sort,
  r8ftn,
  r8str,
  r8objs,
  r8dtm,
  r8dos;

type

  TMsgHdr = record
    MsgFrom   : array[1..36] of char;
    MsgTo     : array[1..36] of char;
    MsgSubj   : array[1..72] of char;
    DateTime  : array[1..20] of char;

    TimesRead : word;
    DestNode  : word;
    OrigNode  : word;
    Cost : word;
    OrigNet : word;
    DestNet : word;

    DateWritten : longint;
    DateArrived : longint;

    ReplyTo : word;
    Flags : word;
    NextReply : word;
  end;

  TMsgBase  = object(TMessageBase)
    MessageHeader : TMsgHdr;
    MessageFileLink : PStream;
    MsgLastReadLink : PStream;

    Constructor Init;
    Destructor  Done; virtual;

    Procedure Open(const ABasePath:string);virtual;
    Procedure Create(const ABasePath:string);virtual;
    Procedure Close;virtual;

    Function GetCount:longint;virtual;
    Procedure GetIndexes;

    Procedure CreateMessage(UseMsgID:Boolean);virtual;
    Procedure OpenMessage;virtual;
    Procedure OpenHeader;virtual;
    Procedure WriteMessage;virtual;
    Procedure WriteHeader;virtual;
    Procedure CloseMessage;virtual;
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

    Procedure ReadLastreads;virtual;
    Procedure WriteLastreads;virtual;

    Function PackIsNeeded:boolean;virtual;
    Procedure Renumber;

    Procedure Flush;virtual;
   end;
  PMsgBase  =  ^TMsgBase;

implementation

Function CompareLongint(Key1, Key2: Pointer):longint;far;
Var
  A : PLongint absolute Key1;
  B : PLongint absolute Key2;
begin
  If A^>B^ then CompareLongint:=1 else
  If A^<B^ then CompareLongint:=-1 else
  CompareLongint:=0;
end;

Constructor TMsgBase.Init;
begin
  inherited Init;
end;

Destructor TMsgBase.Done;
begin
  inherited Done;
end;

Procedure TMsgBase.Open(const ABasePath:string);
begin
  If Status<>mlOk then exit;

  If not dosDirExists(ABasePath) then
    begin
      Status:=mlPathNotFound;
      exit;
    end;

  BasePath:=NewStr(ABasePath);
  CurrentMessage:=-1;

  GetIndexes;
end;

Procedure TMsgBase.Create(const ABasePath:string);
begin
  If Status<>mlOk then exit;

  If not dosDirExists(ABasePath) then dosMkDir(ABasePath);

  Open(ABasePath);
end;

Procedure TMsgBase.Close;
begin
  objDispose(MessageFileLink);
  objDispose(MsgLastReadLink);
end;

Function TMsgBase.GetCount:longint;
begin
  GetCount:=-1;
  If Status<>mlOk then exit;

  GetCount:=Indexes^.Count;
end;

Procedure TMsgBase.GetIndexes;
Var
  SR : SearchRec;
  i : longint;
  lTemp : ^longint;
begin
  i:=0;

  FindFirst(BasePath^+'\*.MSG',AnyFile-Directory,SR);
  While DosError=0 do
    begin
      i:=strStrToInt(strParser(SR.Name,1,['.']));

      New(lTemp);
      lTemp^:=i;
      Indexes^.Insert(lTemp);

      FindNext(SR);
    end;
{$IFNDEF VER70}
  FindClose(SR);
{$ENDIF}

  If Indexes^.Count>1 then srtSort(0,Indexes^.Count-1,Indexes,CompareLongint);
end;

Procedure TMsgBase.CreateMessage(UseMsgID:Boolean);
Var
 i : longint;
begin
  If Status<>mlOk then exit;
  If MessageOpened then exit;

  FillChar(MessageHeader,SizeOf(MessageHeader),#0);

  inherited CreateMessage(UseMsgID);

  If Indexes^.Count=0 then i:=1 else i:=PLongint(Indexes^.At(Indexes^.Count-1))^+1;

  MessageFileLink:=New(PBufStream,Init(BasePath^+'\'
    +strIntToStr(i)+'.msg',
            fmCreate or fmReadWrite or fmDenyAll,cBuffSize));

  If MessageFileLink^.Status<>stOk then
    begin
      Status:=mlCantOpenOrCreateMessage;
      exit;
    end;

  MessageOpened:=True;
end;

Procedure TMsgBase.OpenHeader;
Var
  FileName : string;
  SR : SearchRec;
begin
  If not MessageOpened then
    begin
      FileName:=BasePath^+'\'+strIntToStr(PLongInt(Indexes^.At(CurrentMessage-1))^)+'.msg';

      FindFirst(FileName,Anyfile-ReadOnly-Directory,SR);
      If DosError<>0 then
        begin
          Status:=mlCantOpenOrCreateMessage;
          exit;
        end;
    {$IFNDEF VER70}
      FindClose(SR);
    {$ENDIF}

      MessageFileLink:=New(PBufStream,Init(FileName,
                     fmOpen or fmReadWrite or fmDenyAll, cBuffSize));
    end;

  MessageFileLink^.Seek(0);
  MessageFileLink^.Read(MessageHeader,SizeOf(MessageHeader));

  If not MessageOpened then
      objDispose(MessageFileLink);
end;

Procedure TMsgBase.WriteHeader;
Var
  FileName : string;
  SR : SearchRec;
begin
  If not MessageOpened then
    begin
      FileName:=BasePath^+'\'+strIntToStr(PLongInt(Indexes^.At(CurrentMessage-1))^)+'.msg';

      FindFirst(FileName,Anyfile-ReadOnly-Directory,SR);
      If DosError<>0 then
        begin
          Status:=mlCantOpenOrCreateMessage;
          exit;
        end;
    {$IFNDEF VER70}
      FindClose(SR);
    {$ENDIF}

      MessageFileLink:=New(PBufStream,Init(FileName,
                     fmOpen or fmReadWrite or fmDenyAll, cBuffSize));
    end;

  MessageFileLink^.Seek(0);
  MessageFileLink^.Write(MessageHeader,SizeOf(MessageHeader));

  If not MessageOpened then
      objDispose(MessageFileLink);
end;

Procedure TMsgBase.OpenMessage;
Var
  FileName : string;

  TempStream : PStream;
  c : char;
  SR : SearchRec;
  F:file;
{$IFDEF VIRTUALPASCAL}
  Attr : longint;
{$ELSE}
  Attr : word;
{$ENDIF}
begin
  If MessageOpened then exit;

  FileName:=BasePath^+'\'+strIntToStr(PLongInt(Indexes^.At(CurrentMessage-1))^)+'.msg';

  FindFirst(FileName,Anyfile-ReadOnly-Directory,SR);
  If DosError<>0 then
    begin
      Status:=mlCantOpenOrCreateMessage;
      exit;
    end;
{$IFNDEF VER70}
  FindClose(SR);
{$ENDIF}

  MessageFileLink:=New(PBufStream,Init(FileName,
                 fmOpen or fmReadWrite or fmDenyAll, cBuffSize));

  MessageFileLink^.Seek(0);
  MessageFileLink^.Read(MessageHeader,SizeOf(MessageHeader));

  inherited OpenMessage;

  TempStream:=New(PMemoryStream,Init(0,cBuffSize));

  TempStream^.Seek(0);
  TempStream^.CopyFrom(MessageFileLink^,
     MessageFileLink^.GetSize-MessageFileLink^.GetPos);

  TempStream^.Seek(TempStream^.GetSize-1);
  TempStream^.Read(c,1);
  While c=#0 do
    begin
      TempStream^.Seek(TempStream^.GetSize-1);
      TempStream^.Truncate;
      TempStream^.Seek(TempStream^.GetSize-1);
      TempStream^.Read(c,1);
    end;

  MessageBody^.AddToMsgBodyStream(TempStream);

  objDispose(TempStream);

  MessageOpened:=True;
end;

Procedure TMsgBase.WriteMessage;
Var
  TempStream : PStream;
  i : longint;
  lTemp : PLongint;
begin
  If Status<>mlOk then exit;
  If not MessageOpened then exit;

  MessageFileLink^.Seek(0);
  MessageFileLink^.Write(MessageHeader,SizeOf(MessageHeader));

  TempStream:=MessageBody^.GetMsgBodyStreamEx;

  TempStream^.Seek(0);
  MessageFileLink^.CopyFrom(TempStream^,TempStream^.GetSize);

  objStreamWrite(MessageFileLink,#0);
  objDispose(TempStream);

  If Indexes^.Count=0 then i:=1 else i:=PLongint(Indexes^.At(Indexes^.Count-1))^+1;
  New(lTemp);
  lTemp^:=i;
  Indexes^.Insert(lTemp);
end;

Procedure TMsgBase.CloseMessage;
begin
  objDispose(MessageFileLink);
  MessageOpened:=False;
end;

Procedure TMsgBase.KillMessage;
Var
  FileName : string;
begin
  If Status<>mlOk then exit;
  CloseMessage;

  FileName:=BasePath^+'\'+strIntToStr(PLongInt(Indexes^.At(CurrentMessage-1))^)+'.msg';

  dosErase(FileName);

  Indexes^.AtFree(CurrentMessage-1);

  Dec(CurrentMessage);

  Status:=mlOk;
end;

Procedure TMsgBase.SetTo(const ToName:string);
begin
  If Status<>mlOk then exit;

  FillChar(MessageHeader.MsgTo,SizeOf(MessageHeader.MsgTo),#0);

  Move(ToName[1],MessageHeader.MsgTo,Length(ToName));
end;

function TMsgBase.GetTo:string;
Var
  sTemp:string;
begin
  If Status<>mlOk then exit;

  sTemp[0]:=Chr(SizeOf(MessageHeader.MsgTo));
  Move(MessageHeader.MsgTo,sTemp[1],SizeOf(MessageHeader.MsgTo));
  GetTo:=strTrimR(sTemp,[#0]);
end;

Procedure TMsgBase.SetFrom(const FromName:string);
begin
  If Status<>mlOk then exit;

  FillChar(MessageHeader.MsgFrom,SizeOf(MessageHeader.MsgFrom),#0);

  Move(FromName[1],MessageHeader.MsgFrom,Length(FromName));
end;

function TMsgBase.GetFrom:string;
Var
  sTemp:string;
begin
  If Status<>mlOk then exit;

  sTemp[0]:=Chr(SizeOf(MessageHeader.MsgFrom));
  Move(MessageHeader.MsgFrom,sTemp[1],SizeOf(MessageHeader.MsgFrom));
  GetFrom:=strTrimR(sTemp,[#0]);
end;

Procedure TMsgBase.SetSubj(const Subject:string);
begin
  If Status<>mlOk then exit;

  FillChar(MessageHeader.MsgSubj,SizeOf(MessageHeader.MsgSubj),#0);

  Move(Subject[1],MessageHeader.MsgSubj,Length(Subject));
end;

Function TMsgBase.GetSubj:string;
Var
  sTemp:string;
begin
  If Status<>mlOk then exit;

  sTemp[0]:=Chr(SizeOf(MessageHeader.MsgSubj));
  Move(MessageHeader.MsgSubj,sTemp[1],SizeOf(MessageHeader.MsgSubj));
  GetSubj:=strTrimB(sTemp,[#0,#32]);
end;

Procedure TMsgBase.SetFromAddress(const Address:TAddress);
begin
  If Status<>mlOk then exit;

  inherited SetFromAddress(Address);

  MessageHeader.OrigNet:=Address.Net;
  MessageHeader.OrigNode:=Address.Node;
end;

Procedure TMsgBase.SetToAddress(const Address:TAddress);
begin
  If Status<>mlOk then exit;

  inherited SetToAddress(Address);

  MessageHeader.DestNet:=Address.Net;
  MessageHeader.DestNode:=Address.Node;
end;

Procedure TMsgBase.GetFromAddress(Var Address:TAddress);
Var
  sTemp:string;
begin
  If Status<>mlOk then exit;

  Address:=NullAddress;

  sTemp:=MessageBody^.KludgeBase^.GetKludge('MSGID:');
  sTemp:=strParser(sTemp,1,[#32]);

  If ftnCheckAddressString(sTemp) then ftnStrtoAddress(sTemp,Address) else
    begin
      sTemp:=strParser(strParser(MessageBody^.KludgeBase^.GetKludge('INTL'),
          2,[#32]),1,[':']);
      Address.Zone:=strStrToInt(sTemp);

      Address.Net:=MessageHeader.OrigNet;
      Address.Node:=MessageHeader.OrigNode;

      sTemp:=MessageBody^.KludgeBase^.GetKludge('FMPT');
      If sTemp<>'' then Address.Point:=strStrToInt(sTemp);
    end;

  If Address.Zone=0 then Address.Zone:=2;
end;

Procedure TMsgBase.GetToAddress(Var Address:TAddress);
Var
  sTemp:string;
  TempAddress : TAddress;
begin
  If Status<>mlOk then exit;

  Address:=NullAddress;

  sTemp:=MessageBody^.KludgeBase^.GetKludge('REPLYTO:');
  sTemp:=strParser(sTemp,1,[#32]);

  If ftnCheckAddressString(sTemp) then ftnStrtoAddress(sTemp,Address) else
    begin
      sTemp:=strParser(strParser(MessageBody^.KludgeBase^.GetKludge('INTL'),
            1,[#32]),1,[':']);
      Address.Zone:=strStrToInt(sTemp);

      Address.Net:=MessageHeader.DestNet;
      Address.Node:=MessageHeader.DestNode;

      sTemp:=MessageBody^.KludgeBase^.GetKludge('TOPT');
      If sTemp<>'' then Address.Point:=strStrToInt(sTemp);
    end;

  If Address.Zone=0 then Address.Zone:=2;
end;

Procedure TMsgBase.SetDateWritten(const ADateTime:TDateTime);
begin
  If Status<>mlOk then exit;

   dtmDateToFTN(ADateTime,MessageHeader.DateTime);
end;


Procedure TMsgBase.SetDateArrived(const ADateTime:TDateTime);
Var
  TempDateTime : DateTime;
begin
  If Status<>mlOk then exit;

  TempDateTime.Year:=ADateTime.Year;
  TempDateTime.Month:=ADateTime.Month;
  TempDateTime.Day:=ADateTime.Day;
  TempDateTime.Hour:=ADateTime.Hour;
  TempDateTime.Min:=ADateTime.Minute;
  TempDateTime.Sec:=ADateTime.Sec;

  PackTime(TempDateTime,MessageHeader.DateArrived)
end;

Procedure TMsgBase.GetDateWritten(var ADateTime:TDateTime);
Var
  sTemp:string;
  S : string[20];
  i:integer;
begin
  If Status<>mlOk then exit;

  S[0]:=#19;
  Move(MessageHeader.DateTime,S[1],19);

  ADateTime.Day:=strStrToInt(strParser(S,1,[#32]));

  sTemp:=strParser(S,2,[#32]);
  ADateTime.Month:=dtmStrToMonth(sTemp);

  ADateTime.Year:=strStrToInt(strParser(S,3,[#32]));
  If ADateTime.Year<70 then ADateTime.Year:=2000+ADateTime.Year
                 else ADateTime.Year:=1900+ADateTime.Year;

  sTemp:=strParser(S,4,[#32]);

  ADateTime.Hour:=strStrToInt(strParser(sTemp,1,[':']));
  ADateTime.Minute:=strStrToInt(strParser(sTemp,2,[':']));
  ADateTime.Sec:=strStrToInt(strParser(sTemp,3,[':']));
end;

Procedure TMsgBase.GetDateArrived(var ADateTime:TDateTime);
Var
  TempDateTime : DateTime;
begin
  If Status<>mlOk then exit;

  UnPackTime(MessageHeader.DateArrived, TempDateTime);

  ADateTime.Year:=TempDateTime.Year;
  ADateTime.Month:=TempDateTime.Month;
  ADateTime.Month:=TempDateTime.Month;
  ADateTime.Day:=TempDateTime.Day;
  ADateTime.Hour:=TempDateTime.Hour;
  ADateTime.Minute:=TempDateTime.Min;
  ADateTime.Sec:=TempDateTime.Sec;
end;

Procedure TMsgBase.SetFlags(const Flags:longint);
begin
  If Status<>mlOk then exit;

  MessageHeader.Flags:=Flags;
end;

Procedure TMsgBase.GetFlags(var Flags:longint);
begin
  If Status<>mlOk then exit;

  Flags:=MessageHeader.Flags;
end;

Procedure TMsgBase.Flush;
begin
  If Status<>mlOk then exit;
end;

Procedure TMsgBase.Seek(const i:longint);
begin
  If Status<>mlOk then exit;

  CurrentMessage:=i;
end;

Procedure TMsgBase.SeekNext;
begin
  If Status<>mlOk then exit;

  Status:=mlOutOfMessages;

  If CurrentMessage+1>Indexes^.Count then exit;

  Inc(CurrentMessage);
  Status:=mlOk;
end;

Procedure TMsgBase.SeekPrev;
begin
  If Status<>mlOk then exit;

  Status:=mlOutOfMessages;

  If CurrentMessage-1<1 then exit;

  Dec(CurrentMessage);
  Status:=mlOk;
end;

Procedure TMsgBase.ReadLastreads;
Var
  L : longint;
  W : word;
  TempLastRead : PLastRead;
begin
  If MsgLastReadLink=nil then
    begin
      MsgLastReadLink:=New(PBufStream,Init(BasePath^+'\lastread',
         fmOpen or fmReadWrite or fmDenyWrite,cBuffSize));

      If IOResult<>0 then exit;
    end;

  L:=MsgLastReadLink^.GetSize;

  While MsgLastReadLink^.GetPos<L-1 do
    begin
      TempLastread:=New(PLastRead);
      MsgLastReadLink^.Read(W,SizeOf(W));

      With TempLastRead^ do
        begin
          UserCRC:=-1;
          UserID:=LastReads^.Count;
          LastReadMsg:=SearchForIndex(W);
          if LastReadMsg=-1 then  LastReadMsg:=0;
          HighReadMsg:=LastReadMsg;
        end;

      LastReads^.Insert(TempLastRead);
    end;

  objDispose(MsgLastReadLink);
end;

Procedure TMsgBase.WriteLastreads;
Var
  W : word;

  Procedure WriteLastread(P:pointer);far;
  Var
    TempLastread : PLastread absolute P;
    pTemp : PLongint;
    W : word;
  begin
    if  (TempLastread^.LastReadMsg-1<0)
      or (TempLastread^.LastReadMsg-1>Indexes^.Count) then W:=0 else
        begin
          pTemp:=Indexes^.At(TempLastread^.LastReadMsg-1);
          W:=pTemp^;
        end;
    MsgLastReadLink^.Write(W,SizeOf(W));
  end;
begin
  dosErase(BasePath^+'\lastread');

  MsgLastReadLink:=New(PBufStream,Init(BasePath^+'\lastread',
         stCreate,cBuffSize));

  If IOResult<>0 then exit;
  If MsgLastReadLink^.Status<>stOK then exit;

  W:=0;
  If Lastreads^.Count=0 then MsgLastReadLink^.Write(W,SizeOf(W))
    else  LastReads^.ForEach(@WriteLastread);

  objDispose(MsgLastReadLink);
end;

Function TMsgBase.PackIsNeeded:boolean;
begin
  PackIsNeeded:=True;
end;

Function TMsgBase.GetTimesRead:longint;
begin
  If Status<>mlOk then exit;

  GetTimesRead:=MessageHeader.TimesRead;
end;

Procedure TMsgBase.SetTimesRead(const TR:longint);
begin
  If Status<>mlOk then exit;

  MessageHeader.TimesRead:=TR;
end;

Procedure TMsgBase.Renumber;
var
  i : longint;
begin
  For  i:=0  to Indexes^.Count-1 do
    begin
      If PLongInt(Indexes^.At(i))^<>i+1 then
          dosRename(BasePath^+'\'
            +strIntToStr(PLongInt(Indexes^.At(i))^)+'.msg',
              BasePath^+'\'+strIntToStr(i+1)+'.msg');
    end;

  Indexes^.FreeAll;
  GetIndexes;
end;

end.
