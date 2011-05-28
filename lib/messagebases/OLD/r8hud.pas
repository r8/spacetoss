{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
  {$PackRecords 1}
{$ENDIF}
Unit r8hud;

interface

Uses
  objects,
  r8objs,
  r8dos,
  r8ftn,
  strings,
  r8str,
  r8dtm,
  r8mail;

const

  hudDeleted  = $01;
  hudUnsent   = $02;
  hudNetmail  = $04;
  hudPrivate  = $08;
  hudReceived = $10;
  hudUnmoved  = $20;
  hudLocal    = $40;

  hudKill     = $01;
  hudSent     = $02;
  hudFile     = $04;
  hudCrash    = $08;
  hudReceipt  = $10;
  hudAudit    = $20;
  hudReturn   = $40;

ZeroArray : array[1..255] of char = (
#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0,
#0,#0,#0,#0,#0,#0,#0,#0,#0,#0
);

Type

THudsonMsgInfo = record
  LowMsg: Word;
  HighMsg: Word;
  Active: Word;
  AreaActive: Array[1..200] of Word;
end;

THudsonIndex = record
  MsgNum : word;
  Board : byte;
end;

THudsonToIndex = record
  MsgTo : string[35];
end;

THudsonHdr = Record
  MsgNum: System.Word;
  ReplyTo: System.Word;
  Replies: System.Word;
  Extra: System.Word;
  StartRec: System.Word;
  NumRecs: System.Word;
  DestNet: System.Integer;
  DestNode: System.Integer;
  OrigNet: System.Integer;
  OrigNode: System.Integer;
  DestZone: Byte;
  OrigZone: Byte;
  Cost: System.Word;
  MsgAttr: System.byte;
  NetAttr: System.byte;
  Board : Byte;
  PostTime: String[5];
  PostDate: String[8];
  MsgTo: String[35];
  MsgFrom: String[35];
  Subj: String[72];
end;

THudsonBase = object(TMessageBase)
  MsgInfo : THudsonMsgInfo;
  MsgHeader : THudsonHdr;

  CurrentBoard : longint;
  BoardIndex : PLintCollection;

  Constructor Init;
  Destructor Done;virtual;

  Function OpenHudsonBase(Path:string):boolean;
  Function CreateHudsonBase(Path:string):boolean;

  Function OpenBase(Path:string):boolean;virtual;
  Procedure CloseBase;virtual;

  Function GetCount:longint;virtual;

  Function OpenMsg:boolean;virtual;
  Function CreateNewMessage(UseMsgID:Boolean):boolean;virtual;
  Function WriteMessage:boolean;virtual;
  Procedure KillMessage;virtual;

  Procedure SetDateWritten(MDateTime:TDateTime);virtual;
  Procedure GetDateWritten(var MDateTime:TDateTime);virtual;
  Procedure SetTo(const ToName:string);virtual;
  Function GetTo:string;virtual;
  Procedure SetFrom(const FromName:string);virtual;
  Function GetFrom:string;virtual;
  Procedure SetSubj(const Subject:string);virtual;
  Function GetSubj:string;virtual;

  Procedure SetFlags(Flags:longint);virtual;
  Procedure GetFlags(var Flags:longint);virtual;

  Procedure SetFromAddress(Address:TAddress);virtual;
  Procedure SetToAddress(Address:TAddress);virtual;
  Procedure GetFromAddress(var Address:TAddress);virtual;
  Procedure GetToAddress(var Address:TAddress);virtual;

  Procedure  SetMsgHdrDefaults;
  Procedure WriteMsgInfo;

  Procedure Flush;virtual;
private
  HudsonMsgInfoLink : PBufStream;
  HudsonIndexLink : PBufStream;
  HudsonToIndexLink : PBufStream;
  HudsonMsgHdrLink : PBufStream;
  HudsonMsgTxtLink : PBufStream;
end;

PHudsonBase = ^THudsonBase;

implementation

Constructor THudsonBase.Init;
begin
  inherited Init;
end;

Destructor THudsonBase.Done;
begin
  objDispose(HudsonMsgInfoLink);
  objDispose(HudsonIndexLink);
  objDispose(HudsonToIndexLink);
  objDispose(HudsonMsgHdrLink);
  objDispose(HudsonMsgTxtLink);

  inherited Done;
end;

Function THudsonBase.OpenHudsonBase(Path:string):boolean;
begin
  OpenHudsonBase:=False;

  If not dosDirExists(Path) then exit;

  DisposeStr(BasePath);
  BasePath:=NewStr(Path);

  If not dosFileExists(Path+'\MSGINFO.BBS') then exit;
  If not dosFileExists(Path+'\MSGIDX.BBS') then exit;
  If not dosFileExists(Path+'\MSGTOIDX.BBS') then exit;
  If not dosFileExists(Path+'\MSGHDR.BBS') then exit;
  If not dosFileExists(Path+'\MSGTXT.BBS') then exit;

  HudsonMsgInfoLink:=New(PBufStream,Init(Path+'\MSGINFO.BBS',stOpen,$1000));
  HudsonIndexLink:=New(PBufStream,Init(Path+'\MSGIDX.BBS',stOpen,$1000));
  HudsonToIndexLink:=New(PBufStream,Init(Path+'\MSGTOIDX.BBS',stOpen,$1000));
  HudsonMsgHdrLink:=New(PBufStream,Init(Path+'\MSGHDR.BBS',stOpen,$1000));
  HudsonMsgTxtLink:=New(PBufStream,Init(Path+'\MSGTXT.BBS',stOpen,$1000));

  If (HudsonMsgInfoLink^.Status<>stOK) or
     (HudsonIndexLink^.Status<>stOK) or
     (HudsonToIndexLink^.Status<>stOK) or
     (HudsonMsgHdrLink^.Status<>stOK) or
     (HudsonMsgTxtLink^.Status<>stOK)
     then exit;

  If IOResult<>0 then exit;

  HudsonMsgInfoLink^.Seek(0);
  HudsonMsgInfoLink^.Read(MsgInfo,SizeOf(MsgInfo));

  OpenHudsonBase:=True;
end;

Function THudsonBase.CreateHudsonBase(Path:string):boolean;
Var
  f:file;
begin
  CreateHudsonBase:=False;

  If not dosDirExists(Path) then dosMkDir(Path);

  Assign(f,Path+'\MSGINFO.BBS');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;

  FillChar(MsgInfo,SizeOf(MsgInfo),#0);
  BlockWrite(F,MsgInfo,SizeOf(MsgInfo));
  Close(F);

  Assign(f,Path+'\MSGIDX.BBS');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;
  Close(F);

  Assign(f,Path+'\MSGHDR.BBS');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;
  Close(F);

  Assign(f,Path+'\MSGTOIDX.BBS');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;
  Close(F);

  Assign(f,Path+'\MSGTXT.BBS');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;
  Close(F);

  CreateHudsonBase:=OpenHudsonBase(Path);
end;

Function THudsonBase.OpenBase(Path:string):boolean;
Var
 i:longint;
 iTemp:longint;
 HudsonIndex : THudsonIndex;
begin
  OpenBase:=False;

  For i:=1 to Length(Path) do
    If not (Path[i] in ['0'..'9']) then exit;

  CurrentBoard:=strStrToInt(Path);

  BoardIndex:=New(PLintCollection,Init($10,$10));

  i:=HudsonIndexLink^.GetSize;
  HudsonIndexLink^.Seek(0);

  iTemp:=0;
  While HudsonIndexLink^.GetPos<i-1 do
    begin
      Inc(iTemp);
      HudsonIndexLink^.Read(HudsonIndex,SizeOf(HudsonIndex));
      If HudsonIndex.MsgNum=$FFFF then continue;
      If HudsonIndex.Board=CurrentBoard
          then BoardIndex^.Insert(objNewLint(iTemp));
    end;
  HudsonIndexLink^.Reset;

  OpenBase:=True;
end;

Procedure THudsonBase.CloseBase;
begin
  objDispose(BoardIndex);
  CloseMessage;
end;

Function THudsonBase.GetCount:longint;
begin
  GetCount:=MsgInfo.AreaActive[CurrentBoard];
end;

Function THudsonBase.OpenMsg:boolean;
Var
  lTemp:LInt;
  TempStream : PStream;
  i:integer;
  pTemp : PString;
begin
  OpenMsg:=False;

  If MsgOpened then exit;

  lTemp:=BoardIndex^.At(CurrentMessage);

  HudsonMsgHdrLink^.Seek((lTemp^-1) * SizeOf(MsgHeader));
  HudsonMsgHdrLink^.Read(MsgHeader,SizeOf(MsgHeader));

  inherited OpenMsg;

  TempStream:=New(pMemorystream,Init(0,cBuffSize));
  HudsonMsgTxtLink^.Seek(MsgHeader.StartRec * 256);

  For i:=1 to MsgHeader.NumRecs do
    begin
      pTemp:=HudsonMsgTxtLink^.ReadStr;
      If pTemp<>nil then objStreamWriteStr(TempStream,pTemp^);
      DisposeStr(pTemp);
    end;

  MessageBody^.AddToMsgBodyStream(TempStream);
  objDispose(TempStream);

  OpenMsg:=True;
  MsgOpened:=True;
end;

Function THudsonBase.GetFrom:string;
begin
  GetFrom:=MsgHeader.MsgFrom;
end;

Function THudsonBase.GetTo:string;
begin
  GetTo:=MsgHeader.MsgTo;
end;

Procedure THudsonBase.SetTo(const ToName:string);
begin
  MsgHeader.MsgTo:=ToName;
end;

Procedure THudsonBase.SetFrom(const FromName:string);
begin
  MsgHeader.MsgFrom:=FromName;
end;

Function THudsonBase.CreateNewMessage(UseMsgID:Boolean):boolean;
begin
  CreateNewMessage:=False;

  SetMsgHdrDefaults;

  inherited CreateNewMessage(UseMsgID);

  If MsgOpened then exit;

  CreateNewMessage:=True;
end;

Procedure  THudsonBase.SetMsgHdrDefaults;
begin
 FillChar(MsgHeader,SizeOf(MsgHeader),#0);

 With MsgHeader do
   begin
     MsgNum:=MsgInfo.HighMsg+1;
     Board:=CurrentBoard;
   end;
end;

Procedure THudsonBase.SetDateWritten(MDateTime:TDateTime);
Var
  sTemp:string;
begin
  MsgHeader.PostTime:=dtmTime2String(MDateTime,':',False,False);
  sTemp:=dtmDate2String(MDateTime,'-',False,True);
  MsgHeader.PostDate:=strParser(sTemp,2,['-'])+'-'
       +strParser(sTemp,1,['-'])+'-'
       +strParser(sTemp,3,['-']);
end;

Procedure THudsonBase.GetDateWritten(var MDateTime:TDateTime);
Var
  sTemp:string;
begin
  MDateTime.Day:=strStrToInt(strParser(MsgHeader.PostDate,2,['-']));
  MDateTime.Month:=strStrToInt(strParser(MsgHeader.PostDate,1,['-']));
  MDateTime.Year:=strStrToInt(strParser(MsgHeader.PostDate,3,['-']));

  If MDateTime.Year<70 then MDateTime.Year:=2000+MDateTime.Year
                 else MDateTime.Year:=1900+MDateTime.Year;

  MDateTime.Hour:=strStrToInt(strParser(MsgHeader.PostTime,1,[':']));
  MDateTime.Minute:=strStrToInt(strParser(MsgHeader.PostTime,2,[':']));
  MDateTime.Sec:=0;
end;

Function THudsonBase.WriteMessage:boolean;
Var
  HudsonIndex : THudsonIndex;
  HudsonToIndex : THudsonToIndex;
  sTemp : string;
  pTemp : pChar;
  TempStream : PStream;
  iTemp : longint;
begin

  HudsonIndex.MsgNum:=MsgHeader.MsgNum;
  HudsonIndex.Board:=CurrentBoard;

  If not MsgOpened then
    begin
      MsgInfo.HighMsg:=MsgHeader.MsgNum;
      Inc(MsgInfo.Active);
      Inc(MsgInfo.AreaActive[CurrentBoard]);

      HudsonIndexLink^.Reset;
      HudsonIndexLink^.Seek(HudsonIndexLink^.GetSize);
      HudsonIndexLink^.Write(HudsonIndex,SizeOf(HudsonIndex));

      HudsonToIndex.MsgTo:=MsgHeader.MsgTo;
      HudsonToIndexLink^.Reset;
      HudsonToIndexLink^.Seek(HudsonToIndexLink^.GetSize);
      HudsonToIndexLink^.Write(HudsonToIndex,SizeOf(HudsonToIndex));
    end;

  HudsonMsgTxtLink^.Reset;
  HudsonMsgTxtLink^.Seek(HudsonMsgTxtLink^.GetSize);
  MsgHeader.StartRec:=HudsonMsgTxtLink^.GetPos div 256;

  TempStream:=MessageBody^.GetMsgBodyStream;
  TempStream^.Seek(0);

  iTemp:=TempStream^.GetSize;
  While TempStream^.GetPos<iTemp-1 do
    begin
      sTemp:=objStreamReadString(TempStream);
      HudsonMsgTxtLink^.WriteStr(@sTemp);
      HudsonMsgTxtLink^.Write(ZeroArray,255-Length(sTemp));
      Inc(MsgHeader.NumRecs);
    end;

  objDispose(TempStream);

  Case BaseType of
      btEchomail : MsgHeader.MsgAttr:=MsgHeader.MsgAttr and not(hudNetmail);
      btNetmail  : MsgHeader.MsgAttr:=MsgHeader.MsgAttr and hudNetmail;
      btLocal    : MsgHeader.MsgAttr:=MsgHeader.MsgAttr and not(hudNetmail);
    end;

  HudsonMsgHdrLink^.Reset;
  If MsgOpened
     then HudsonMsgHdrLink^.Seek(HudsonMsgHdrLink^.GetPos-SizeOf(MsgHeader))
     else  HudsonMsgHdrLink^.Seek(HudsonMsgHdrLink^.GetSize);
  HudsonMsgHdrLink^.Write(MsgHeader,SizeOf(MsgHeader));

  WriteMsgInfo;
end;

Procedure THudsonBase.SetFromAddress(Address:TAddress);
begin
  inherited SetFromAddress(Address);

  MsgHeader.OrigZone:=Address.Zone;
  MsgHeader.OrigNet:=Address.Net;
  MsgHeader.OrigNode:=Address.Node;
end;

Procedure THudsonBase.SetToAddress(Address:TAddress);
begin
  inherited SetToAddress(Address);

  MsgHeader.DestZone:=Address.Zone;
  MsgHeader.DestNet:=Address.Net;
  MsgHeader.DestNode:=Address.Node;
end;

Procedure THudsonBase.GetFromAddress(Var Address:TAddress);
Var
  sTemp:string;
begin
  Address.Zone:=MsgHeader.OrigZone;
  Address.Net:=MsgHeader.OrigNet;
  Address.Node:=MsgHeader.OrigNode;

  sTemp:=MessageBody^.KludgeBase^.GetKludge('FMPT');
  If sTemp<>'' then Address.Point:=strStrToInt(sTemp);
end;

Procedure THudsonBase.GetToAddress(Var Address:TAddress);
Var
  sTemp:string;
begin
  Address.Zone:=MsgHeader.DestZone;
  Address.Net:=MsgHeader.DestNet;
  Address.Node:=MsgHeader.DestNode;

  sTemp:=MessageBody^.KludgeBase^.GetKludge('TOPT');
  If sTemp<>'' then Address.Point:=strStrToInt(sTemp);
end;

Procedure THudsonBase.WriteMsgInfo;
begin
  HudsonMsgInfoLink^.Seek(0);
  HudsonMsgInfoLink^.Write(MsgInfo,SizeOf(MsgInfo));
end;

Procedure THudsonBase.SetSubj(const Subject:string);
begin
  MsgHeader.Subj:=Subject;
end;

Function THudsonBase.GetSubj:string;
begin
  GetSubj:=MsgHeader.Subj;
end;


Procedure THudsonBase.SetFlags(Flags:longint);
begin
  MsgHeader.MsgAttr:=0;
  MsgHeader.NetAttr:=0;

  If (Flags and flgPrivate)=flgPrivate
      then MsgHeader.MsgAttr:=MsgHeader.MsgAttr or hudPrivate;

  If (Flags and flgCrash)=flgCrash
      then MsgHeader.NetAttr:=MsgHeader.NetAttr or hudCrash;

  If (Flags and flgReceived)=flgReceived
      then MsgHeader.MsgAttr:=MsgHeader.MsgAttr or hudReceived;

  If (Flags and flgSent)=flgSent
      then MsgHeader.NetAttr:=MsgHeader.NetAttr or hudSent;

  If (Flags and flgKill)=flgKill
      then MsgHeader.NetAttr:=MsgHeader.NetAttr or hudKill;

  If (Flags and flgLocal)=flgLocal
      then MsgHeader.MsgAttr:=MsgHeader.MsgAttr or hudLocal;

  If (Flags and flgRRq)=flgRRq
      then MsgHeader.MsgAttr:=MsgHeader.MsgAttr or hudReceipt;

  If (Flags and flgARq)=flgARq
      then MsgHeader.MsgAttr:=MsgHeader.MsgAttr or hudAudit;
end;

Procedure THudsonBase.GetFlags(var Flags:longint);
begin
  Flags:=0;

  If (MsgHeader.MsgAttr and hudPrivate)=hudPrivate
      then Flags:=Flags or flgPrivate;

  If (MsgHeader.NetAttr and hudCrash)=hudCrash
      then Flags:=Flags or flgCrash;

  If (MsgHeader.MsgAttr and hudReceived)=hudReceived
      then Flags:=Flags or flgReceived;

  If (MsgHeader.NetAttr and hudSent)=hudSent
      then Flags:=Flags or flgSent;

  If (MsgHeader.NetAttr and hudKill)=hudKill
      then Flags:=Flags or flgKill;

  If (MsgHeader.MsgAttr and hudLocal)=hudLocal
      then Flags:=Flags or flgLocal;

  If (MsgHeader.MsgAttr and hudReceipt)=hudReceipt
      then Flags:=Flags or flgRRq;

  If (MsgHeader.MsgAttr and hudAudit)=hudAudit
      then Flags:=Flags or flgARq;

end;

Procedure THudsonBase.Flush;
begin
  HudsonMsgInfoLink^.Flush;
  HudsonIndexLink^.Flush;
  HudsonToIndexLink^.Flush;
  HudsonMsgHdrLink^.Flush;
  HudsonMsgTxtLink^.Flush;
end;

Procedure THudsonBase.KillMessage;
Var
  HudsonIndex : THudsonIndex;
  HudsonToIndex : THudsonToIndex;
begin
  MsgHeader.MsgAttr:=MsgHeader.MsgAttr or hudDeleted;

  MsgInfo.HighMsg:=MsgHeader.MsgNum-1;
  Dec(MsgInfo.Active);
  Dec(MsgInfo.AreaActive[CurrentBoard]);

  HudsonIndexLink^.Seek(HudsonIndexLink^.GetPos-SizeOf(HudsonIndex));
  HudsonIndex.MsgNum:=$FFFF;
  HudsonIndexLink^.Write(HudsonIndex,SizeOf(HudsonIndex));

  HudsonMsgHdrLink^.Reset;
  HudsonMsgHdrLink^.Seek(HudsonMsgHdrLink^.GetPos-SizeOf(MsgHeader));
  HudsonMsgHdrLink^.Write(MsgHeader,SizeOf(MsgHeader));

  HudsonToIndex.MsgTo:='deleted';
  HudsonToIndexLink^.Reset;
  HudsonToIndexLink^.Seek(HudsonToIndexLink^.GetPos-SizeOf(HudsonToIndex));
  HudsonToIndexLink^.Write(HudsonToIndex,SizeOf(HudsonToIndex));

  WriteMsgInfo;

  Dec(CurrentMessage);

  CloseMessage;
end;

end.
