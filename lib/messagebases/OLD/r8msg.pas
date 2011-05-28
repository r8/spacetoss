{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit r8Msg;

interface

Uses
  r8mail,
  r8ftn,
  r8str,
  r8dtm,
  r8dos,
  r8objs,
  dos,
  objects;

Type

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

    DateWritten : Longint;
    DateArrived : Longint;

    ReplyTo : word;
    Flags : word;
    NextReply : word;
 end;

TMsgBase = object(TMessageBase)
  MsgHeader : TMsgHdr;

  Messages : PSCollection;

  Constructor Init;
  Destructor Done;virtual;

  Function OpenBase(Path:string):boolean;virtual;
  Function CreateBase(Path:string):boolean;virtual;
  Procedure CloseBase;virtual;

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

  Procedure Flush;virtual;
private
  MessageFileLink : PDosStream;
  MessageFileName : string;
  HighestMessage : longint;
end;

PMsgBase = ^TMsgBase;

implementation

Constructor TMsgBase.Init;
begin
  inherited Init;

  Messages:=New(PSCollection,Init($10,$10));
end;

Destructor TMsgBase.Done;
begin
  objDispose(Messages);

  inherited Done;
end;

Function TMsgBase.OpenBase(Path:string):boolean;
Var
  SR:SearchRec;
  i:longint;
begin
  OpenBase:=False;

  If not dosDirExists(Path) then exit;

  DisposeStr(BasePath);
  BasePath:=NewStr(Path);
  HighestMessage:=0;

  FindFirst(BasePath^+'\*.MSG',AnyFile-Directory,SR);
  While DosError=0 do
    begin
      Messages^.Insert(NewStr(BasePath^+'\'+SR.Name));

      i:=strStrToInt(strParser(SR.Name,1,['.']));
      If i>HighestMessage Then HighestMessage:=i;

      FindNext(SR);
    end;

  OpenBase:=True;
end;

Function TMsgBase.CreateBase(Path:string):boolean;
begin
  CreateBase:=False;

  If not dosDirExists(Path) then dosMkDir(Path);

  CreateBase:=OpenBase(Path);
end;

Function TMsgBase.CreateNewMessage(UseMsgID:Boolean):boolean;
begin
  CreateNewMessage:=False;

  FillChar(MsgHeader,SizeOf(MsgHeader),#0);

  inherited CreateNewMessage(UseMsgID);

 Inc(HighestMessage);
 While dosFileExists(BasePath^+'\'
    +strIntToStr(HighestMessage)+'.msg') do Inc(HighestMessage);

  MessageFileName:=BasePath^+'\'+strIntToStr(HighestMessage)+'.msg';

  MessageFileLink:=New(PBufStream,
     Init(MessageFileName,stCreate,cBuffSize));

  Messages^.Insert(NewStr(MessageFileName));

  CreateNewMessage:=True;
end;

Procedure TMsgBase.CloseMessage;
begin
  inherited CloseMessage;

  objDispose(MessageFileLink);
end;

Function TMsgBase.WriteMessage:boolean;
var
  TempStream : PStream;
begin
  WriteMessage:=False;

  MessageFileLink^.Seek(0);
  MessageFileLink^.Write(MsgHeader,SizeOf(MsgHeader));

  TempStream:=MessageBody^.GetMsgBodyStream;

  TempStream^.Seek(0);
  MessageFileLink^.CopyFrom(TempStream^,TempStream^.GetSize);

  objStreamWriteStr(MessageFileLink,#0);

  objDispose(TempStream);

  WriteMessage:=True;
end;

Procedure TMsgBase.SetTo(const ToName:string);
begin
  FillChar(MsgHeader.MsgTo,SizeOf(MsgHeader.MsgTo),#0);

  Move(ToName[1],MsgHeader.MsgTo,Length(ToName));
end;

function TMsgBase.GetTo:string;
Var
  sTemp:string;
begin
  sTemp[0]:=Chr(SizeOf(MsgHeader.MsgTo));
  Move(MsgHeader.MsgTo,sTemp[1],SizeOf(MsgHeader.MsgTo));
  GetTo:=strTrimR(sTemp,[#0]);
end;

Procedure TMsgBase.SetFrom(const FromName:string);
begin
  FillChar(MsgHeader.MsgFrom,SizeOf(MsgHeader.MsgFrom),#0);

  Move(FromName[1],MsgHeader.MsgFrom,Length(FromName));
end;

function TMsgBase.GetFrom:string;
Var
  sTemp:string;
begin
  sTemp[0]:=Chr(SizeOf(MsgHeader.MsgFrom));
  Move(MsgHeader.MsgFrom,sTemp[1],SizeOf(MsgHeader.MsgFrom));
  GetFrom:=strTrimR(sTemp,[#0]);
end;

Procedure TMsgBase.SetSubj(const Subject:string);
begin
  FillChar(MsgHeader.MsgSubj,SizeOf(MsgHeader.MsgSubj),#0);

  Move(Subject[1],MsgHeader.MsgSubj,Length(Subject));
end;

Function TMsgBase.GetSubj:string;
Var
  sTemp:string;
begin
  sTemp[0]:=Chr(SizeOf(MsgHeader.MsgSubj));
  Move(MsgHeader.MsgSubj,sTemp[1],SizeOf(MsgHeader.MsgSubj));
  GetSubj:=strTrimB(sTemp,[#0,#32]);
end;

Procedure TMsgBase.SetDateArrived(MDateTime:TDateTime);
Var
  TempDateTime : DateTime;
begin
  TempDateTime.Year:=MDateTime.Year;
  TempDateTime.Month:=MDateTime.Month;
  TempDateTime.Day:=MDateTime.Day;
  TempDateTime.Hour:=MDateTime.Hour;
  TempDateTime.Min:=MDateTime.Minute;
  TempDateTime.Sec:=MDateTime.Sec;

  PackTime(TempDateTime,MsgHeader.DateArrived)
end;

Procedure TMsgBase.GetDateWritten(var MDateTime:TDateTime);
Var
  sTemp:string;
  S : string[20];
  i:integer;
begin
  S[0]:=#19;
  Move(MsgHeader.DateTime,S[1],19);

  MDateTime.Day:=strStrToInt(strParser(S,1,[#32]));

  sTemp:=strParser(S,2,[#32]);
  MDateTime.Month:=dtmStrToMonth(sTemp);

  MDateTime.Year:=strStrToInt(strParser(S,3,[#32]));
  If MDateTime.Year<70 then MDateTime.Year:=2000+MDateTime.Year
                 else MDateTime.Year:=1900+MDateTime.Year;

  sTemp:=strParser(S,4,[#32]);

  MDateTime.Hour:=strStrToInt(strParser(sTemp,1,[':']));
  MDateTime.Minute:=strStrToInt(strParser(sTemp,2,[':']));
  MDateTime.Sec:=strStrToInt(strParser(sTemp,3,[':']));
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TMsgBase.SetDateWritten(MDateTime:TDateTime);
begin
   ftnSetFTNDateTime(MDateTime,MsgHeader.DateTime);
end;


Procedure TMsgBase.GetDateArrived(var MDateTime:TDateTime);
Var
  TempDateTime : DateTime;
begin
  UnPackTime(MsgHeader.DateArrived, TempDateTime);

  MDateTime.Year:=TempDateTime.Year;
  MDateTime.Month:=TempDateTime.Month;
  MDateTime.Month:=TempDateTime.Month;
  MDateTime.Day:=TempDateTime.Day;
  MDateTime.Hour:=TempDateTime.Hour;
  MDateTime.Minute:=TempDateTime.Min;
  MDateTime.Sec:=TempDateTime.Sec;
end;

Procedure TMsgBase.SetFlags(Flags:longint);
begin
  MsgHeader.Flags:=Flags;
end;

Procedure TMsgBase.GetFlags(Var Flags:longint);
begin
  Flags:=MsgHeader.Flags;
end;

Procedure TMsgBase.SetFromAddress(Address:TAddress);
begin
  inherited SetFromAddress(Address);

  MsgHeader.OrigNet:=Address.Net;
  MsgHeader.OrigNode:=Address.Node;
end;

Procedure TMsgBase.SetToAddress(Address:TAddress);
begin
  inherited SetToAddress(Address);

  MsgHeader.DestNet:=Address.Net;
  MsgHeader.DestNode:=Address.Node;
end;

Procedure TMsgBase.GetFromAddress(Var Address:TAddress);
Var
  sTemp:string;
begin
  Address:=NullAddress;

  sTemp:=MessageBody^.KludgeBase^.GetKludge('MSGID:');
  sTemp:=strParser(sTemp,1,[#32]);
  If ftnCheckAddrString(sTemp) then
    begin
      ftnStrtoAddress(sTemp,Address);

      sTemp:=strParser(sTemp,1,[':']);
      Address.Zone:=strStrToInt(sTemp);
    end;

  Address.Net:=MsgHeader.OrigNet;
  Address.Node:=MsgHeader.OrigNode;

  sTemp:=MessageBody^.KludgeBase^.GetKludge('FMPT');
  If sTemp<>'' then Address.Point:=strStrToInt(sTemp);

  If Address.Zone=0 then Address.Zone:=2;
end;

Procedure TMsgBase.GetToAddress(Var Address:TAddress);
Var
  sTemp:string;
begin
  sTemp:=MessageBody^.KludgeBase^.GetKludge('INTL');
  sTemp:=strParser(sTemp,1,[#32]);
  sTemp:=strParser(sTemp,1,[':']);
  Address.Zone:=strStrToInt(sTemp);

  Address.Net:=MsgHeader.DestNet;
  Address.Node:=MsgHeader.DestNode;

  sTemp:=MessageBody^.KludgeBase^.GetKludge('TOPT');
  If sTemp='' then Address.Point:=0 else Address.Point:=strStrToInt(sTemp);

  If Address.Zone=0 then Address.Zone:=2;
end;

Procedure TMsgBase.CloseBase;
begin
end;

Function TMsgBase.GetCount:longint;
begin
  GetCount:=Messages^.Count;
end;

Function TMsgBase.OpenMsg:boolean;
Var
  pTemp:PString;
  TempStream : PStream;
  c : char;
  Locked : boolean;
  SR : SearchRec;
  F:file;
{$IFDEF VIRTUALPASCAL}
  Attr : longint;
{$ELSE}
  Attr : word;
{$ENDIF}
begin
  OpenMsg:=False;

  If MsgOpened then exit;

  pTemp:=Messages^.At(CurrentMessage);
  MessageFileName:=pTemp^;

  Locked:=False;

  FindFirst(MessageFileName,Anyfile-ReadOnly,SR);
  If DosError<>0 then
    begin
      Locked:=True;
      Assign(F, MessageFileName);
      GetFAttr(F, Attr);
      Attr:=Attr xor ReadOnly;
    end;

  MessageFileLink:=New(PBufStream,Init(MessageFileName,stOpen,cBuffSize));

  MessageFileLink^.Seek(0);
  MessageFileLink^.Read(MsgHeader,SizeOf(MsgHeader));

  If Locked then SetFlag(flgLocked);

  inherited OpenMsg;

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

  OpenMsg:=True;
  MsgOpened:=True;
end;

Procedure TMsgBase.KillMessage;
begin
  CloseMessage;

  dosErase(MessageFileName);

  Messages^.AtFree(CurrentMessage);

  Dec(CurrentMessage);
end;

Procedure TMsgBase.Flush;
begin
end;

end.
