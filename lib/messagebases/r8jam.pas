{
 Jam Bases Stuff.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
 PackIsNeeded
}
Unit r8jam;

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
  r8objs,
  r8dtm,
  r8crc,
  r8str,
  r8ftn,
  r8msgb,

  objects;

const

{Флаги}
  jamPrivate   = $00000004;
  jamCrash     = $00000100;
  jamReceived  = $00000008;
  jamSent      = $00000010;
  jamAttach    = $00002000;
  jamTransit   = $00000002;
  jamOrphan    = $00040000;
  jamKill      = $00000020;
  jamLocal     = $00000001;
  jamHold      = $00000080;
  jamFRq       = $00001000;
  jamRRq       = $00010000;
  jamARq       = $00020000;

{Типы баз}
  jambtLocal     = $00800000;
  jambtEchomail  = $01000000;
  jambtNetmail   = $02000000;

  jamDeleted     = $80000000;

Type

  TJamHeader = record
    Sig : longint;
    DateCreated : longint;
    UpdateCounter : longint;
    ActiveMessages : longint;
    PasswordCRC : longint;
    BaseMsgNum : longint;
    Reserved : array[1..1000] of char;
  end;

  TJamMessageHeader = record
    Sig : longint;
    Revision : integer;
    Reserved : integer;
    SubfieldLength : longint;
    TimesRead : longint;
    MSGIDCrc : longint;
    REPLYCrc : longint;
    ReplyTo : longint;
    Reply1st : longint;
    ReplyNext : longint;
    DateWritten : longint;
    DateReceived : longint;
    DateProcessed : longint;
    MessageNumber : longint;
    Attribute : longint;
    Attribute2 : longint;
    Offset : longint;
    TxtLen : longint;
    PasswordCRC : longint;
    Cost : longint;
  end;

  TJamIndex = record
    CRC : longint;
    OffSet : longint;
  end;

  TJamSubFieldHeader = record
    LoID : word;
    HoID : word;
    DatLen : longint;
  end;

  TJamLastRead = record
    UserCRC : longint;
    UserID : longint;
    LastReadMsg : longint;
    HighReadMsg : longint;
  end;

  TJamBase  = object(TMessageBase)
    JamHeader : TJamHeader;
    JamMessageHeader : TJamMessageHeader;
    JamIndex : TJamIndex;

    JamHeaderLink : PStream;
    JamDataLink   : PStream;
    JamIndexLink : PStream;
    JamLastReadLink : PStream;

    MsgFrom : string[35];
    MsgTo : string[35];
    MsgSubject : string[80];
    MsgFromAddress : TAddress;
    MsgToAddress : TAddress;

    Constructor Init;
    Destructor  Done; virtual;

    Procedure Open(const ABasePath:string);virtual;
    Procedure Create(const ABasePath:string);virtual;
    Procedure Close;virtual;

    Function GetCount:longint;virtual;

    Procedure CreateMessage(UseMsgID:Boolean);virtual;
    Procedure OpenHeader;virtual;
    Procedure OpenMessage;virtual;
    Procedure WriteMessage;virtual;
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

    Function PackIsNeeded:boolean;virtual;

    Procedure Seek(const i:longint);virtual;
    Procedure SeekNext;virtual;
    Procedure SeekPrev;virtual;

    Procedure Flush;virtual;

    Procedure ReadLastreads;virtual;
    Procedure WriteLastreads;virtual;

    Procedure SetJamHeaderDefaults;
    Procedure SetMsgHeaderDefaults;

    Function GetSize:longint;virtual;

    Procedure WriteSubfield(const SubFieldType:longint;const S:string;
             const St:PStream);
    Function ReadSubfield(var SubFieldType:longint;const St:PStream):string;
    Procedure WriteJamHeader;
  end;
  PJamBase  =  ^TJamBase;

implementation

Constructor TJamBase.Init;
begin
  inherited Init;
end;

Destructor TJamBase.Done;
begin
  inherited Done;
end;

Procedure TJamBase.Open(const ABasePath:string);
begin
  If Status<>mlOk then exit;

  If not dosDirExists(dosGetPath(ABasePath)) then
    begin
      Status:=mlPathNotFound;
      exit;
    end;

  Status:=mlCantOpenOrCreateBase;
  BasePath:=NewStr(ABasePath);

  If not dosFileExists(BasePath^+'.jdt') then exit;
  If not dosFileExists(BasePath^+'.jdx') then exit;
  If not dosFileExists(BasePath^+'.jhr') then exit;

  Status:=mlBaseLocked;

  JamHeaderLink:=New(PBufStream,Init(BasePath^+'.jhr',
     fmOpen or fmReadWrite or fmDenyWrite,cBuffSize));
  JamDataLink:=New(PBufStream,Init(BasePath^+'.jdt',
     fmOpen or fmReadWrite or fmDenyWrite,cBuffSize));
  JamIndexLink:=New(PBufStream,Init(BasePath^+'.jdx',
     fmOpen or fmReadWrite or fmDenyWrite,cBuffSize));

  If IOResult<>0 then exit;

  If (JamDataLink^.Status<>stOK)
     or (JamIndexLink^.Status<>stOK)
     or (JamHeaderLink^.Status<>stOK) then exit;

  JamHeaderLink^.Seek(0);
  JamHeaderLink^.Read(JamHeader,SizeOf(JamHeader));

  If IOResult<>0 then exit;

  Status:=mlOk;
end;

Procedure TJamBase.Create(const ABasePath:string);
Var
  F : file;
begin
  If Status<>mlOk then exit;

  If not dosDirExists(dosGetPath(ABasePath)) then dosMkDir(ABasePath);

  Status:=mlCantOpenOrCreateBase;

  Assign(F,ABasePath+'.jhr');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;
  SetJamHeaderDefaults;
  BlockWrite(F,JamHeader,SizeOf(JamHeader));
  System.Close(F);

  Assign(F,ABasePath+'.jdt');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;
  System.Close(F);

  Assign(F,ABasePath+'.jdx');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;
  System.Close(F);

  Status:=mlOk;
  Open(ABasePath);
end;

Procedure TJamBase.Close;
begin
  objDispose(JamHeaderLink);
  objDispose(JamDataLink);
  objDispose(JamIndexLink);
  objDispose(JamLastReadLink);
end;

Function TJamBase.GetCount:longint;
begin
  If Status<>mlOk then exit;

  GetCount:=JamHeader.ActiveMessages;
end;

Procedure TJamBase.CreateMessage(UseMsgID:Boolean);
begin
  If Status<>mlOk then exit;
  If MessageOpened then exit;

  inherited CreateMessage(UseMsgID);

  SetMsgHeaderDefaults;
  Inc(JamHeader.ActiveMessages);

  MessageOpened:=True;
end;

Procedure TJamBase.OpenHeader;
begin
  JamIndexLink^.Seek((CurrentMessage-1)*8);
  JamIndexLink^.Read(JamIndex,SizeOf(JamIndex));

  JamHeaderLink^.Seek(JamIndex.Offset);
  JamHeaderLink^.Read(JamMessageHeader,SizeOf(JamMessageHeader));
end;

Procedure TJamBase.OpenMessage;
Var
  sTemp : string;
  lTemp : longint;
begin
  inherited OpenMessage;

  OpenHeader;

  While JamHeaderLink^.GetPos<JamIndex.Offset
     +SizeOf(JamMessageHeader)+JamMessageHeader.SubfieldLength do
       begin
         sTemp:=ReadSubfield(lTemp,JamHeaderLink);

         Case lTemp of
           0 : ftnStrToAddress(sTemp,MsgFromAddress);
           1 : ftnStrToAddress(sTemp,MsgToAddress);
           2 : MsgFrom:=sTemp;
           3 : MsgTo:=sTemp;
           4 : MessageBody^.KludgeBase^.SetKludge('MSGID:',sTemp);
           5 : MessageBody^.KludgeBase^.SetKludge('REPLY:',sTemp);
           6 : MsgSubject:=sTemp;
           7 : MessageBody^.KludgeBase^.SetKludge('PID:',sTemp);
           2000 :
             begin
               MessageBody^.KludgeBase^.SetKludge(strParser(sTemp,1,[#32]),Copy(sTemp,
               Pos(#32,sTemp)+1,Length(sTemp)-Pos(#32,sTemp)));
             end;
           2001 :
             begin
               If MessageBody^.SeenByLink=nil
                 then MessageBody^.SeenByLink:=New(PMemoryStream,Init(0,cBuffSize));
               objStreamWriteLn(MessageBody^.SeenByLink,'SEEN-BY: '+sTemp);
             end;
           2002 :
             begin
               If MessageBody^.PathLink=nil
                 then MessageBody^.PathLink:=New(PMemoryStream,Init(0,cBuffSize));
               objStreamWriteLn(MessageBody^.PathLink,#1'PATH: '+sTemp);
             end;
         end;
       end;

  JamDataLink^.Seek(JamMessageHeader.Offset);
  MessageBody^.MsgBodyLink^.Seek(0);
  MessageBody^.MsgBodyLink^.CopyFrom(JamDataLink^,JamMessageHeader.TxtLen);
end;

Procedure TJamBase.WriteMessage;
Var
  DateTime : TDateTime;
  TempStream : PStream;
  TempKludge : PKludge;
  i : longint;
  sTemp : string;
  sTemp2 : string;
begin
  dtmGetDateTime(DateTime);
  SetDateArrived(DateTime);
  JamMessageHeader.DateProcessed:=JamMessageHeader.DateReceived;

  JamHeaderLink^.Seek(JamHeaderLink^.GetSize);
  JamIndex.Offset:=JamHeaderLink^.GetPos;
  JamIndex.CRC:=crcStringCRC32(strLower(MsgTo));

  JamDataLink^.Seek(JamDataLink^.GetSize);
  JamMessageHeader.Offset:=JamDataLink^.GetPos;

  JamMessageHeader.SubfieldLength:=0;

  TempStream:=New(PMemoryStream,Init(0,cBuffSize));
  MessageBody^.MsgBodyLink^.Seek(0);
  TempStream^.CopyFrom(MessageBody^.MsgBodyLink^,
                  MessageBody^.MsgBodyLink^.GetSize);

  If MessageBody^.TearLine<>nil
      then objStreamWriteLn(TempStream,MessageBody^.TearLine^);
  If MessageBody^.Origin<>nil
      then objStreamWriteLn(TempStream,MessageBody^.Origin^);

  JamMessageHeader.TxtLen:=TempStream^.GetSize;
  TempStream^.Seek(0);
  JamDataLink^.CopyFrom(TempStream^,JamMessageHeader.TxtLen);
  objDispose(TempStream);

  TempStream:=New(PMemoryStream,Init(0,cBuffSize));
  WriteSubField(0,ftnAddresstoStrEx(MsgFromAddress),TempStream);
  WriteSubField(1,ftnAddresstoStrEx(MsgToAddress),TempStream);
  WriteSubField(2,MsgFrom,TempStream);
  WriteSubField(3,MsgTo,TempStream);
  WriteSubField(6,MsgSubject,TempStream);

  For i:=0 to MessageBody^.KludgeBase^.Kludges^.Count-1 do
    begin
      TempKludge:=MessageBody^.KludgeBase^.Kludges^.At(i);

      sTemp:='';
      If TempKludge^.Name<>nil then sTemp:=TempKludge^.Name^;

      If strUpper(sTemp)='MSGID:'
         then WriteSubField(4,TempKludge^.Value^,TempStream)
         else
      If strUpper(sTemp)='REPLY:'
         then WriteSubField(5,TempKludge^.Value^,TempStream)
         else
      If strUpper(sTemp)='PID:'
         then WriteSubField(7,TempKludge^.Value^,TempStream)
         else
           begin
             If TempKludge^.Value<>nil then sTemp:=sTemp+#32+TempKludge^.Value^;
             WriteSubField($07D0,sTemp,TempStream);
           end;
    end;

  If MessageBody^.SeenByLink<>nil then
    begin
      i:=MessageBody^.SeenByLink^.GetSize;
      MessageBody^.SeenByLink^.Seek(0);

      While MessageBody^.SeenByLink^.GetPos<i-1 do
        begin
          sTemp:=objStreamReadLn(MessageBody^.SeenByLink);
          sTemp:=Copy(sTemp,10,Length(sTemp)-9);
          WriteSubField(2001,sTemp,TempStream);
        end;
    end;

  If MessageBody^.PathLink<>nil then
    begin
      i:=MessageBody^.PathLink^.GetSize;
      MessageBody^.PathLink^.Seek(0);

      While MessageBody^.PathLink^.GetPos<i-1 do
        begin
          sTemp:=objStreamReadLn(MessageBody^.PathLink);
          sTemp:=Copy(sTemp,8,Length(sTemp)-7);
          WriteSubField(2002,sTemp,TempStream);
        end;
    end;

  JamMessageHeader.SubfieldLength:=TempStream^.GetSize;
  JamHeaderLink^.Write(JamMessageHeader,SizeOf(JamMessageHeader));
  TempStream^.Seek(0);
  JamHeaderLink^.CopyFrom(TempStream^,JamMessageHeader.SubfieldLength);
  objDispose(TempStream);

  WriteJamHeader;

  JamIndexLink^.Seek(JamIndexLink^.GetSize);
  JamIndexLink^.Write(JamIndex,SizeOf(JamIndex));
end;

Procedure TJamBase.WriteHeader;
begin
  JamIndexLink^.Seek((CurrentMessage-1)*8);
  JamIndexLink^.Read(JamIndex,SizeOf(JamIndex));

  JamHeaderLink^.Seek(JamIndex.Offset);
  JamHeaderLink^.Write(JamMessageHeader,SizeOf(JamMessageHeader));
end;

Procedure TJamBase.SetTo(const ToName:string);
begin
  MsgTo:=ToName;
end;

Procedure TJamBase.SetFrom(const FromName:string);
begin
  MsgFrom:=FromName;
end;

Procedure TJamBase.SetSubj(const Subject:string);
begin
  MsgSubject:=Subject;
end;

Function TJamBase.GetTo:string;
begin
  GetTo:=MsgTo;
end;

Function TJamBase.GetFrom:string;
begin
  GetFrom:=MsgFrom;
end;

Function TJamBase.GetSubj:string;
begin
  GetSubj:=MsgSubject;
end;

Procedure TJamBase.SetDateWritten(const ADateTime:TDateTime);
begin
  JamMessageHeader.DateWritten:=dtmDateToUnix(ADateTime);
end;

Procedure TJamBase.GetDateWritten(var ADateTime:TDateTime);
begin
  dtmUnixToDate(JamMessageHeader.DateWritten, ADateTime);
end;

Procedure TJamBase.SetDateArrived(const ADateTime:TDateTime);
begin
  JamMessageHeader.DateReceived:=dtmDateToUnix(ADateTime);
end;

Procedure TJamBase.GetDateArrived(var ADateTime:TDateTime);
begin
  dtmUnixToDate(JamMessageHeader.DateReceived, ADateTime);
end;

Procedure TJamBase.SetFlags(const Flags:longint);
begin
  JamMessageHeader.Attribute:=0;

  If (Flags and flgPrivate)=flgPrivate
      then JamMessageHeader.Attribute:=JamMessageHeader.Attribute or jamPrivate;

  If (Flags and flgCrash)=flgCrash
      then JamMessageHeader.Attribute:=JamMessageHeader.Attribute or jamCrash;

  If (Flags and flgReceived)=flgReceived
      then JamMessageHeader.Attribute:=JamMessageHeader.Attribute or jamReceived;

  If (Flags and flgSent)=flgSent
      then JamMessageHeader.Attribute:=JamMessageHeader.Attribute or jamSent;

  If (Flags and flgTransit)=flgTransit
      then JamMessageHeader.Attribute:=JamMessageHeader.Attribute or jamTransit;

  If (Flags and flgOrphan)=flgOrphan
      then JamMessageHeader.Attribute:=JamMessageHeader.Attribute or jamOrphan;

  If (Flags and flgKill)=flgKill
      then JamMessageHeader.Attribute:=JamMessageHeader.Attribute or jamKill;

  If (Flags and flgLocal)=flgLocal
      then JamMessageHeader.Attribute:=JamMessageHeader.Attribute or jamLocal;

  If (Flags and flgHold)=flgHold
      then JamMessageHeader.Attribute:=JamMessageHeader.Attribute or jamHold;

  If (Flags and flgFRq)=flgFRq
      then JamMessageHeader.Attribute:=JamMessageHeader.Attribute or jamFRq;

  If (Flags and flgRRq)=flgRRq
      then JamMessageHeader.Attribute:=JamMessageHeader.Attribute or jamRRq;

  If (Flags and flgARq)=flgARq
      then JamMessageHeader.Attribute:=JamMessageHeader.Attribute or jamARq;

end;

Procedure TJamBase.GetFlags(var Flags:longint);
begin
  Flags:=0;

  If (JamMessageHeader.Attribute and jamPrivate)=jamPrivate
      then Flags:=Flags or flgPrivate;

  If (JamMessageHeader.Attribute and jamCrash)=jamCrash
      then Flags:=Flags or flgCrash;

  If (JamMessageHeader.Attribute and jamReceived)=jamReceived
      then Flags:=Flags or flgReceived;

  If (JamMessageHeader.Attribute and jamSent)=jamSent
      then Flags:=Flags or flgSent;

  If (JamMessageHeader.Attribute and jamAttach)=jamAttach
      then Flags:=Flags or flgAttach;

  If (JamMessageHeader.Attribute and jamTransit)=jamTransit
      then Flags:=Flags or flgTransit;

  If (JamMessageHeader.Attribute and jamOrphan)=jamOrphan
      then Flags:=Flags or flgOrphan;

  If (JamMessageHeader.Attribute and jamKill)=jamKill
      then Flags:=Flags or flgKill;

  If (JamMessageHeader.Attribute and jamLocal)=jamLocal
      then Flags:=Flags or flgLocal;

  If (JamMessageHeader.Attribute and jamHold)=jamHold
      then Flags:=Flags or flgHold;

  If (JamMessageHeader.Attribute and jamPrivate)=jamFrq
      then Flags:=Flags or flgFrq;

  If (JamMessageHeader.Attribute and jamRRq)=jamRRq
      then Flags:=Flags or flgRRq;

  If (JamMessageHeader.Attribute and jamARq)=jamARq
      then Flags:=Flags or flgARq;
end;

Procedure TJamBase.SetFromAddress(const Address:TAddress);
begin
  inherited SetFromAddress(Address);

  MsgFromAddress:=Address;
end;

Procedure TJamBase.SetToAddress(const Address:TAddress);
begin
  inherited SetToAddress(Address);

  MsgToAddress:=Address;
end;

Procedure TJamBase.GetFromAddress(Var Address:TAddress);
begin
  Address:=MsgFromAddress;
end;

Procedure TJamBase.GetToAddress(Var Address:TAddress);
begin
  Address:=MsgToAddress;
end;

Procedure TJamBase.Seek(const i:longint);
begin
  If Status<>mlOk then exit;

  CurrentMessage:=i;
end;

Procedure TJamBase.SeekNext;
begin
  If Status<>mlOk then exit;

  Inc(CurrentMessage);

  JamIndexLink^.Seek((CurrentMessage-1)*8);
  If JamIndexLink^.Status<>stOk then
    begin
      Status:=mlOutOfMessages;
      exit;
    end;

  JamIndexLink^.Read(JamIndex,SizeOf(JamIndex));
  If JamIndexLink^.Status<>stOk then
    begin
      Status:=mlOutOfMessages;
      exit;
    end;

  If JamIndex.Offset=-1 then SeekNext;
end;

Procedure TJamBase.SeekPrev;
begin
  If Status<>mlOk then exit;

  Dec(CurrentMessage);

  If CurrentMessage<0 then
    begin
      Status:=mlOutOfMessages;
      exit;
    end;

  JamIndexLink^.Seek((CurrentMessage-1)*8);
  If JamIndexLink^.Status<>stOk then
    begin
      Status:=mlOutOfMessages;
      exit;
    end;

  JamIndexLink^.Read(JamIndex,SizeOf(JamIndex));
  If JamIndexLink^.Status<>stOk then
    begin
      Status:=mlOutOfMessages;
      exit;
    end;

  If JamIndex.Offset=-1 then SeekPrev;
end;

Procedure TJamBase.Flush;
begin
  JamHeaderLink^.Flush;
  JamDataLink^.Flush;
  JamIndexLink^.Flush;
end;

Procedure TJamBase.SetJamHeaderDefaults;
begin
  FillChar(JamHeader,SizeOf(JamHeader),#0);
  With JamHeader do
    begin
      Sig:=$004D414A;
      UpdateCounter:=0;
      BaseMsgNum:=1;
      PasswordCRC:=$FFFFFFFF;
    end;
end;

Procedure TJamBase.SetMsgHeaderDefaults;
begin
  FillChar(JamMessageHeader,SizeOf(JamMessageHeader),#0);
  With JamMessageHeader do
    begin
      Sig:=$004D414A;
      Revision:=1;
      MessageNumber:=JamHeader.BaseMsgNum+JamHeader.ActiveMessages;

      Case BaseType of
        btEchomail : Attribute:=Attribute or jambtEchomail;
        btNetmail : Attribute:=Attribute  or jambtNetmail;
        btLocal : Attribute:=Attribute or jambtLocal;
      end;
    end;
end;

Procedure TJamBase.WriteSubfield(const SubFieldType:longint;const S:string;
         const St:PStream);
Var
  JamSubField : TJamSubfieldHeader;
begin
  JamSubfield.HoID:=0;
  JamSubfield.LoID:=SubFieldType;

  JamSubField.DatLen:=Length(S);

  St^.Write(JamSubField,SizeOf(JamSubfield));
  objStreamWrite(St,S);
end;

Function TJamBase.ReadSubfield(var SubFieldType:longint;const St:PStream):string;
Var
  JamSubField : TJamSubfieldHeader;
  sTemp : string;
begin
  St^.Read(JamSubField,SizeOf(JamSubfield));

  SubFieldType:=JamSubfield.LoID;
  St^.Read(sTemp[1],JamSubField.DatLen);
  sTemp[0]:=Chr(JamSubField.DatLen);

  ReadSubfield:=sTemp;
end;

Procedure TJamBase.WriteJamHeader;
begin
  Inc(JamHeader.UpdateCounter);
  If JamHeader.UpdateCounter<0 then JamHeader.UpdateCounter:=0;

  JamHeaderLink^.Seek(0);
  JamHeaderLink^.Write(JamHeader,SizeOf(JamHeader));
end;

Procedure TJamBase.KillMessage;
begin
  If Status<>mlOk then exit;

  JamMessageHeader.Attribute:=JamMessageHeader.Attribute or jamDeleted;

  JamHeaderLink^.Seek(JamIndex.Offset);
  JamHeaderLink^.Write(JamMessageHeader,SizeOf(JamMessageHeader));

  JamIndex.Offset:=-1;
  JamIndexLink^.Seek((CurrentMessage-1)*SizeOf(JamIndex));
  JamIndexLink^.Write(JamIndex,SizeOf(JamIndex));

  Dec(JamHeader.ActiveMessages);
  WriteJamHeader;

  SeekPrev;

  Status:=mlOk;
end;

Procedure TJamBase.ReadLastreads;
Var
  L : longint;
  TempLastRead : PLastRead;
begin
  If JamLastReadLink=nil then
    begin
      JamLastReadLink:=New(PBufStream,Init(BasePath^+'.jlr',
         fmOpen or fmReadWrite or fmDenyWrite,cBuffSize));

      If IOResult<>0 then exit;
      If JamLastReadLink^.Status<>stOK then exit;
    end;

  L:=JamLastReadLink^.GetSize;

  While JamLastReadLink^.GetPos<L-1 do
    begin
      TempLastread:=New(PLastRead);
      JamLastReadLink^.Read(TempLastread^,SizeOf(TempLastread^));

      LastReads^.Insert(TempLastRead);
    end;

  objDispose(JamLastReadLink);
end;

Procedure TJamBase.WriteLastreads;
Var
  L : longint;
  LR : TLastread;

  Procedure WriteLastread(P:pointer);far;
  Var
    TempLastread : PLastread absolute P;
  begin
    JamLastReadLink^.Write(TempLastread^,SizeOf(TempLastread^));
  end;
begin
  dosErase(BasePath^+'.jlr');

  JamLastReadLink:=New(PBufStream,Init(BasePath^+'.jlr',
         stCreate,cBuffSize));

  If IOResult<>0 then exit;
  If JamLastReadLink^.Status<>stOK then exit;

  L:=0;
  FillChar(LR,SizeOf(LR),#0);
  If Lastreads^.Count=0 then JamLastReadLink^.Write(LR,SizeOf(LR))
    else  LastReads^.ForEach(@WriteLastread);

  objDispose(JamLastReadLink);
end;

Function TJamBase.PackIsNeeded:boolean;
begin
  PackIsNeeded:=True;
end;

Function TJamBase.GetSize:longint;
begin
  GetSize:=JamHeaderLink^.GetSize
        +JamDataLink^.GetSize+JamIndexLink^.GetSize;
end;

Function TJamBase.GetTimesRead:longint;
begin
  If Status<>mlOk then exit;

  GetTimesRead:=JamMessageHeader.TimesRead;
end;

Procedure TJamBase.SetTimesRead(const TR:longint);
begin
  If Status<>mlOk then exit;

  JamMessageHeader.TimesRead:=TR;
end;

end.
