{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
  {$PackRecords 1}
{$ENDIF}
Unit r8Jam;

interface

Uses
  r8mail,
  dos,
  r8ftn,
  r8dtm,
  r8dos,
  r8objs,
  r8str,
  r8crc,
  objects;

Const

 jamflgPrivate   = $00000004;
 jamflgCrash     = $00000100;
 jamflgReceived  = $00000008;
 jamflgSent      = $00000010;
 jamflgAttach    = $00002000;
 jamflgTransit   = $00000002;
 jamflgOrphan    = $00040000;
 jamflgKill      = $00000020;
 jamflgLocal     = $00000001;
 jamflgHold      = $00000080;
 jamflgFRq       = $00001000;
 jamflgRRq       = $00010000;
 jamflgARq       = $00020000;

 jambtLocal     = $00800000;
 jambtEchomail  = $01000000;
 jambtNetmail   = $02000000;

 jamDeleted     = $80000000;

Type

 TJamHDRHeader = record
   Sig            : longint;
   DateCreated    : longint;
   UpdateCounter  : longint;
   ActiveMessages : longint;
   PasswordCRC    : longint;
   BaseMsgNum     : longint;
   Reserved       : array[1..1000] of char;
 end;

 TJamMsgHeader = record
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

TJamBase = object(TMessageBase)
  JamHDRHeader : TJamHDRHeader;
  JamMsgHeader : TJamMsgHeader;

  MsgFrom : string[35];
  MsgTo : string[35];
  MsgSubject : string[80];
  MsgFromAddress : TAddress;
  MsgToAddress : TAddress;

  Constructor Init;
  Destructor Done;virtual;

  Function OpenBase(Path:string):boolean;virtual;
  Function CreateBase(Path:string):boolean;virtual;
  Procedure CloseBase;virtual;

  Procedure GetBaseTime(var BaseTime:TDateTime);virtual;

  Function GetSize:longint;virtual;

  Function GetCount:longint;virtual;

  Function OpenMsg:boolean;virtual;
  Function CreateNewMessage(UseMsgID:Boolean):boolean;virtual;
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
  Procedure GetDateWritten(var MDateTime:TDateTime);virtual;
  Procedure SetDateArrived(MDateTime:TDateTime);virtual;
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
  Procedure WriteHDRHeader;
  Procedure WriteSubfield(SubFieldType:longint;S:string);
  Procedure RebuildIndex;
private
  JamHeaderLink : PBufStream;
  JamDataLink : PBufStream;
  JamIndexLink : PBufStream;
end;

PJamBase = ^TJamBase;

TJamRawMessage = record
  Header : TJamMsgHeader;
  Index  : TJamIndex;
  SubFields : PStream;
  Body : PStream;
end;

PJamRawMessage = ^TJamRawMessage;

implementation

Constructor TJamBase.Init;
begin
  inherited Init;
end;

Destructor TJamBase.Done;
begin
  inherited Done;
  objDispose(JamHeaderLink);
  objDispose(JamDataLink);
  objDispose(JamIndexLink);
  CloseMessage;
end;

Function TJamBase.OpenBase(Path:string):boolean;
begin
  JamHeaderLink:=nil;
  JamDataLink:=nil;
  JamIndexLink:=nil;

  OpenBase:=False;

  If not dosDirExists(dosGetPath(Path)) then exit;

  DisposeStr(BasePath);
  BasePath:=NewStr(Path);

  If not dosFileExists(Path+'.JHR') then exit;
  If not dosFileExists(Path+'.JDT') then exit;
  If not dosFileExists(Path+'.JDX') then exit;

  JamHeaderLink:=New(PBufStream,Init(Path+'.JHR',stOpen,cBuffSize));
  JamDataLink:=New(PBufStream,Init(Path+'.JDT',stOpen,cBuffSize));
  JamIndexLink:=New(PBufStream,Init(Path+'.JDX',stOpen,cBuffSize));

  If (JamHeaderLink^.Status<>stOK)
     or (JamDataLink^.Status<>stOK)
     or (JamIndexLink^.Status<>stOK) then exit;

  If IOResult<>0 then exit;

  JamHeaderLink^.Seek(0);
  JamHeaderLink^.Read(JamHDRHeader,SizeOf(JamHDRHeader));

  If (JamIndexLink^.GetSize div 8)<>JamHDRHeader.ActiveMessages
       then RebuildIndex;

  OpenBase:=True;
end;

Function TJamBase.CreateBase(Path:string):boolean;
Var
  f:file;
begin
  CreateBase:=False;

  If not dosDirExists(dosGetPath(Path)) then dosMkDir(dosGetPath(Path));

  Assign(f,Path+'.JHR');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;

  SetHDRDefaults;
  BlockWrite(F,JamHDRHeader,SizeOf(JamHDRHeader));
  Close(F);

  Assign(f,Path+'.JDT');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;
  Close(F);

  Assign(f,Path+'.JDX');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;
  Close(F);

  CreateBase:=OpenBase(Path);
end;

Function TJamBase.CreateNewMessage(UseMsgID:Boolean):boolean;
begin
  CreateNewMessage:=False;

  inherited CreateNewMessage(UseMsgID);

  If MsgOpened then exit;

  SetMsgHdrDefaults;

  Inc(JamHDRHeader.ActiveMessages);

  CreateNewMessage:=True;
end;

Procedure TJamBase.CloseMessage;
begin
  inherited CloseMessage;
end;

Function TJamBase.WriteMessage:boolean;
Var
  JamIndex : TJamIndex;
  TempKludge : PKludge;
  TempStream : PStream;
  i : longint;
  TempFlag:longint;
  TempDateTime : TDateTime;
  sTemp : string;
  sTemp2 : string;
begin
  WriteHDRHeader;

  If MsgOpened then
    begin
      TempFlag:=JamMsgHeader.Attribute;

      JamIndexLink^.Seek(CurrentMessage*8);
      JamIndexLink^.Read(JamIndex,SizeOf(JamIndex));

      JamMsgHeader.Attribute:=TempFlag or jamDeleted;

      JamHeaderLink^.Seek(JamIndex.Offset);
      JamHeaderLink^.Write(JamMsgHeader,SizeOf(JamMsgHeader));

      JamMsgHeader.Attribute:=TempFlag;
    end;

  Case BaseType of
    btEchomail : JamMsgHeader.Attribute:=JamMsgHeader.Attribute
                                                   or jambtEchomail;
    btNetmail : JamMsgHeader.Attribute:=JamMsgHeader.Attribute
                                                   or jambtNetmail;
    btLocal : JamMsgHeader.Attribute:=JamMsgHeader.Attribute
                                                   or jambtLocal;
    end;

  dtmGetDateTime(TempDateTime);
  SetDateArrived(TempDateTime);
  JamMsgHeader.DateProcessed:=JamMsgHeader.DateReceived;

  JamHeaderLink^.Seek(JamHeaderLink^.GetSize);
  JamIndex.Offset:=JamHeaderLink^.GetPos;
  JamIndex.CRC:=crcStringCRC32(strLower(MsgTo));
  JamHeaderLink^.Write(JamMsgHeader,SizeOf(JamMsgHeader));
  JamMsgHeader.SubfieldLength:=0;

  TempStream:=New(PMemoryStream,Init(0,cBuffSize));
  MessageBody^.MsgBodyLink^.Seek(0);
  TempStream^.CopyFrom(MessageBody^.MsgBodyLink^,
                           MessageBody^.MsgBodyLink^.GetSize);

  If MessageBody^.TearLine<>nil then
         objStreamWriteStr10(TempStream,MessageBody^.TearLine^);
  If MessageBody^.Origin<>nil then
         objStreamWriteStr10(TempStream,MessageBody^.Origin^);

  JamDataLink^.Seek(JamDataLink^.GetSize);
  JamMsgHeader.Offset:=JamDataLink^.GetPos;
  JamMsgHeader.TxtLen:=TempStream^.GetSize;
  TempStream^.Seek(0);
  JamDataLink^.CopyFrom(TempStream^,JamMsgHeader.TxtLen);

  objDispose(TempStream);

  WriteSubField(0,ftnAddresstoStrEx(MsgFromAddress));
  WriteSubField(1,ftnAddresstoStrEx(MsgToAddress));
  WriteSubField(2,MsgFrom);
  WriteSubField(3,MsgTo);
  WriteSubField(6,MsgSubject);

  for i:=0 to MessageBody^.KludgeBase^.Kludges^.Count-1 do
    begin
      TempKludge:=MessageBody^.KludgeBase^.Kludges^.At(i);

      If strUpper(TempKludge^.Name)='MSGID:'
         then WriteSubField(4,TempKludge^.Value)
         else
      If strUpper(TempKludge^.Name)='REPLY:'
         then WriteSubField(5,TempKludge^.Value)
         else
      If strUpper(TempKludge^.Name)='PID:'
         then WriteSubField(7,TempKludge^.Value)
         else
           WriteSubField($07D0,TempKludge^.Name+#32+TempKludge^.Value);
    end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

  i:=MessageBody^.SeenByLink^.GetSize;
  MessageBody^.SeenByLink^.Seek(0);

  If i>0 then
    begin
      While MessageBody^.SeenByLink^.GetPos<i-1 do
        begin
          sTemp:=objStreamReadStr(MessageBody^.SeenByLink);
          strSplitWords(sTemp,sTemp,sTemp2);
          WriteSubField(2001,sTemp2);
        end;
    end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

  i:=MessageBody^.PathLink^.GetSize;
  MessageBody^.PathLink^.Seek(0);

  If i>0 then
    begin
      While MessageBody^.PathLink^.GetPos<i-1 do
        begin
          sTemp:=objStreamReadStr(MessageBody^.PathLink);
          strSplitWords(sTemp,sTemp,sTemp2);
          WriteSubField(2002,sTemp2);
        end;
    end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

  JamHeaderLink^.Seek(JamIndex.Offset);
  JamHeaderLink^.Write(JamMsgHeader,SizeOf(JamMsgHeader));

  If MsgOpened then JamIndexLink^.Seek(CurrentMessage*8)
                     else JamIndexLink^.Seek(JamIndexLink^.GetSize);

  JamIndexLink^.Write(JamIndex,SizeOf(JamIndex));
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

Procedure TJamBase.SetDateWritten(MDateTime:TDateTime);
begin
  JamMsgHeader.DateWritten:=dtmDateToUnix(MDateTime);
end;

Procedure TJamBase.GetDateWritten(var MDateTime:TDateTime);
begin
  dtmUnixToDate(JamMsgHeader.DateWritten, MDateTime);
end;

Procedure TJamBase.SetDateArrived(MDateTime:TDateTime);
begin
  JamMsgHeader.DateReceived:=dtmDateToUnix(MDateTime);
end;

Procedure TJamBase.GetDateArrived(var MDateTime:TDateTime);
begin
  dtmUnixToDate(JamMsgHeader.DateReceived, MDateTime);
end;

Procedure TJamBase.SetFlags(Flags:longint);
begin
  JamMsgHeader.Attribute:=0;

  If (Flags and flgPrivate)=flgPrivate
      then JamMsgHeader.Attribute:=JamMsgHeader.Attribute or jamflgPrivate;

  If (Flags and flgCrash)=flgCrash
      then JamMsgHeader.Attribute:=JamMsgHeader.Attribute or jamflgCrash;

  If (Flags and flgReceived)=flgReceived
      then JamMsgHeader.Attribute:=JamMsgHeader.Attribute or jamflgReceived;

  If (Flags and flgSent)=flgSent
      then JamMsgHeader.Attribute:=JamMsgHeader.Attribute or jamflgSent;

  If (Flags and flgTransit)=flgTransit
      then JamMsgHeader.Attribute:=JamMsgHeader.Attribute or jamflgTransit;

  If (Flags and flgOrphan)=flgOrphan
      then JamMsgHeader.Attribute:=JamMsgHeader.Attribute or jamflgOrphan;

  If (Flags and flgKill)=flgKill
      then JamMsgHeader.Attribute:=JamMsgHeader.Attribute or jamflgKill;

  If (Flags and flgLocal)=flgLocal
      then JamMsgHeader.Attribute:=JamMsgHeader.Attribute or jamflgLocal;

  If (Flags and flgHold)=flgHold
      then JamMsgHeader.Attribute:=JamMsgHeader.Attribute or jamflgHold;

  If (Flags and flgFRq)=flgFRq
      then JamMsgHeader.Attribute:=JamMsgHeader.Attribute or jamflgFRq;

  If (Flags and flgRRq)=flgRRq
      then JamMsgHeader.Attribute:=JamMsgHeader.Attribute or jamflgRRq;

  If (Flags and flgARq)=flgARq
      then JamMsgHeader.Attribute:=JamMsgHeader.Attribute or jamflgARq;

end;

Procedure TJamBase.GetFlags(var Flags:longint);
begin
  Flags:=0;

  If (JamMsgHeader.Attribute and jamflgPrivate)=jamflgPrivate
      then Flags:=Flags or flgPrivate;

  If (JamMsgHeader.Attribute and jamflgCrash)=jamflgCrash
      then Flags:=Flags or flgCrash;

  If (JamMsgHeader.Attribute and jamflgReceived)=jamflgReceived
      then Flags:=Flags or flgReceived;

  If (JamMsgHeader.Attribute and jamflgSent)=jamflgSent
      then Flags:=Flags or flgSent;

  If (JamMsgHeader.Attribute and jamflgAttach)=jamflgAttach
      then Flags:=Flags or flgAttach;

  If (JamMsgHeader.Attribute and jamflgTransit)=jamflgTransit
      then Flags:=Flags or flgTransit;

  If (JamMsgHeader.Attribute and jamflgOrphan)=jamflgOrphan
      then Flags:=Flags or flgOrphan;

  If (JamMsgHeader.Attribute and jamflgKill)=jamflgKill
      then Flags:=Flags or flgKill;

  If (JamMsgHeader.Attribute and jamflgLocal)=jamflgLocal
      then Flags:=Flags or flgLocal;

  If (JamMsgHeader.Attribute and jamflgHold)=jamflgHold
      then Flags:=Flags or flgHold;

  If (JamMsgHeader.Attribute and jamflgPrivate)=jamflgFrq
      then Flags:=Flags or flgFrq;

  If (JamMsgHeader.Attribute and jamflgRRq)=jamflgRRq
      then Flags:=Flags or flgRRq;

  If (JamMsgHeader.Attribute and jamflgARq)=jamflgARq
      then Flags:=Flags or flgARq;
end;

Procedure TJamBase.SetFromAddress(Address:TAddress);
begin
  inherited SetFromAddress(Address);

  MsgFromAddress:=Address;
end;

Procedure TJamBase.SetToAddress(Address:TAddress);
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

Procedure TJamBase.CloseBase;
begin
  CloseMessage;
end;

Function TJamBase.GetCount:longint;
begin
  GetCount:=JamHDRHeader.ActiveMessages;
end;

Function TJamBase.OpenMsg:boolean;
Var
  JamIndex : TJamIndex;
  JamSubField : TJamSubfieldHeader;
  tempStream : PMemoryStream;
  sTemp:string;
begin
  OpenMsg:=False;

  If MsgOpened then exit;

  JamIndexLink^.Seek(CurrentMessage*8);
  JamIndexLink^.Read(JamIndex,SizeOf(JamIndex));

  JamHeaderLink^.Seek(JamIndex.Offset);
  JamHeaderLink^.Read(JamMsgHeader,SizeOf(JamMsgHeader));

  inherited OpenMsg;

  While JamHeaderLink^.GetPos<
    JamIndex.Offset+SizeOf(JamMsgHeader)+JamMsgHeader.SubfieldLength do
       begin
         JamHeaderLink^.Read(JamSubfield,SizeOf(JamSubfield));
         If JamSubfield.DatLen>JamMsgHeader.SubfieldLength then break;
         If JamSubfield.DatLen<0 then break;
         JamHeaderLink^.Read(sTemp[1],JamSubfield.DatLen);
         sTemp[0]:=Chr(JamSubfield.DatLen);

         Case JamSubField.LoId of
           0 :
             begin
               ftnStrToAddress(sTemp,MsgFromAddress);
             end;
           1 :
             begin
               ftnStrToAddress(sTemp,MsgToAddress);
             end;
           2 :
             begin
               MsgFrom:=sTemp;
             end;
           3 :
             begin
               MsgTo:=sTemp;
             end;
           4 :
             begin
               MessageBody^.KludgeBase^.SetKludge('MSGID:',sTemp);
             end;
           5 :
             begin
               MessageBody^.KludgeBase^.SetKludge('REPLY:',sTemp);
             end;
           6 :
             begin
               MsgSubject:=sTemp;
             end;
           7 :
             begin
               MessageBody^.KludgeBase^.SetKludge('PID:',sTemp);
             end;
           8 :
             begin
             end;
           9 :
             begin
             end;
           10 :
             begin
             end;
           11 :
             begin
             end;
           12 :
             begin
             end;
           13 :
             begin
             end;
           1000 :
             begin
             end;
           2000 :
             begin
               MessageBody^.KludgeBase^.SetKludge(strParser(sTemp,1,[#32]),Copy(sTemp,
               Pos(#32,sTemp)+1,Length(sTemp)-Pos(#32,sTemp)));
             end;
           2001 :
             begin
               objStreamWriteStr10(MessageBody^.SeenByLink,'SEEN-BY: '+sTemp);
             end;
           2002 :
             begin
               objStreamWriteStr10(MessageBody^.PathLink,#1'PATH: '+sTemp);
             end;
           2003 :
             begin
             end;
           2004 :
             begin
             end;
           else break;
         end;
       end;

  JamDataLink^.Seek(JamMsgHeader.Offset);
  MessageBody^.MsgBodyLink^.Seek(0);
  MessageBody^.MsgBodyLink^.CopyFrom(JamDataLink^,JamMsgHeader.TxtLen);

  OpenMsg:=True;
  MsgOpened:=True;
end;

Procedure TJamBase.SetHDRDefaults;
begin
  FillChar(JamHDRHeader,SizeOf(JamHDRHeader),#0);
  With JamHDRHeader do
    begin
      Sig:=$004D414A;
      UpdateCounter:=0;
      BaseMsgNum:=1;
      PasswordCRC:=$FFFFFFFF;
    end;
end;

Procedure TJamBase.SetMsgHdrDefaults;
begin
  FillChar(JamMsgHeader,SizeOf(JamMsgHeader),#0);
  With JamMsgHeader do
    begin
      Sig:=$004D414A;
      Revision:=1;
      MessageNumber:=JamHDRHeader.BaseMsgNum+(JamIndexLink^.GetSize div 8);
    end;
end;

Procedure TJamBase.WriteHDRHeader;
begin
  Inc(JamHDRHeader.UpdateCounter);
  If JamHDRHeader.UpdateCounter<0 then JamHDRHeader.UpdateCounter:=0;

  JamHeaderLink^.Seek(0);
  JamHeaderLink^.Write(JamHDRHeader,SizeOf(JamHDRHeader));
end;

Procedure TJamBase.WriteSubfield(SubFieldType:longint;S:string);
var
  TempStream : PStream;
  JamSubField : TJamSubfieldHeader;
begin
  JamSubfield.HoID:=0;
  JamSubfield.LoID:=SubFieldType;

  TempStream:=New(PMemoryStream,Init(0,cBuffSize));
  objStreamWriteStr(TempStream,S);

  JamSubField.DatLen:=TempStream^.GetSize;

  JamHeaderLink^.Write(JamSubField,SizeOf(JamSubfield));

  TempStream^.Seek(0);
  JamHeaderLink^.CopyFrom(TempStream^,JamSubfield.DatLen);

  Inc(JamMsgHeader.SubfieldLength,SizeOf(JamSubfield)+JamSubfield.DatLen);

  objDispose(TempStream);
end;

function TJamBase.GetTo:string;
begin
  GetTo:=MsgTo;
end;

function TJamBase.GetFrom:string;
begin
  GetFrom:=MsgFrom;
end;

function TJamBase.GetSubj:string;
begin
  GetSubj:=MsgSubject;
end;

Procedure TJamBase.KillMessage;
Var
  JamIndex : TJamIndex;
  TempStream : PStream;
begin
  JamMsgHeader.Attribute:=JamMsgHeader.Attribute or jamDeleted;

  JamHeaderLink^.Seek(JamIndex.Offset);
  JamHeaderLink^.Write(JamMsgHeader,SizeOf(JamMsgHeader));

  TempStream:=New(PMemoryStream,Init(0,cBuffSize));
  JamIndexLink^.Seek(0);

  TempStream^.CopyFrom(JamIndexLink^,CurrentMessage*SizeOf(JamIndex));
  JamIndexLink^.Seek((CurrentMessage+1)*SizeOf(JamIndex));
  If JamIndexLink^.Status<>stOK then
    begin
      JamIndexLink^.Reset;
      JamIndexLink^.Seek(JamIndexLink^.GetSize);
    end;
  TempStream^.CopyFrom(JamIndexLink^,JamIndexLink^.GetSize-JamIndexLink^.GetPos);

  TempStream^.Seek(0);
  JamIndexLink^.Seek(0);

  JamIndexLink^.Truncate;
  JamIndexLink^.CopyFrom(TempStream^,TempStream^.GetSize);

  objDispose(TempStream);

  Dec(CurrentMessage);

  Dec(JamHDRHeader.ActiveMessages);
  WriteHDRHeader;
end;

Procedure TJamBase.RebuildIndex;
Var
  TempIndex : TJamIndex;
  TempStream : PStream;
  iTemp : longint;
begin
  TempStream:=New(PMemoryStream, Init(0,cBuffSize));
  JamHDRHeader.ActiveMessages:=0;

  TempStream^.Seek(0);
  JamIndexLink^.Seek(0);

  iTemp:=JamIndexLink^.GetSize;

  While JamIndexLink^.GetPos<iTemp-1 do
   begin
     JamIndexLink^.Read(TempIndex,SizeOf(TempIndex));

     If TempIndex.Offset<>-1 then
       begin
         TempStream^.Write(TempIndex,SizeOf(TempIndex));
         Inc(JamHDRHeader.ActiveMessages);
       end;

   end;

  TempStream^.Seek(0);
  JamIndexLink^.Seek(0);
  JamIndexLink^.Truncate;
  JamIndexLink^.CopyFrom(TempStream^,TempStream^.GetSize);

  objDispose(TempStream);
end;

Function TJamBase.GetSize:longint;
begin
  GetSize:=JamHeaderLink^.GetSize
        +JamDataLink^.GetSize+JamIndexLink^.GetSize;
end;

Procedure TJamBase.GetBaseTime(var BaseTime:TDateTime);
Var
  T:longint;
  TempDateTime : DateTime;
  F:file;
begin
  Assign(F,BasePath^+'.JHR');
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

Procedure TJamBase.Flush;
begin
  JamHeaderLink^.Flush;
  JamDataLink^.Flush;
  JamIndexLink^.Flush;
end;

Function TJamBase.GetRawMessage:pointer;
Var
  JamRawMessage : PJamRawMessage;
begin
  JamRawMessage:=New(PJamRawMessage);

  JamIndexLink^.Seek(CurrentMessage*8);
  JamIndexLink^.Read(JamRawMessage^.Index,SizeOf(JamRawMessage^.Index));

  JamHeaderLink^.Seek(JamRawMessage^.Index.Offset);
  JamHeaderLink^.Read(JamRawMessage^.Header,SizeOf(JamRawMessage^.Header));

  JamRawMessage^.Header.ReplyTo:=0;
  JamRawMessage^.Header.Reply1st:=0;
  JamRawMessage^.Header.ReplyNext:=0;

  JamRawMessage^.Subfields:=New(PMemoryStream,Init(0,cBuffSize));
  JamRawMessage^.Subfields^.Seek(0);
  JamRawMessage^.Subfields^.CopyFrom(JamHeaderLink^,
                JamRawMessage^.Header.SubfieldLength);

  JamDataLink^.Seek(JamRawMessage^.Header.Offset);

  JamRawMessage^.Body:=New(PMemoryStream,Init(0,cBuffSize));
  JamRawMessage^.Body^.Seek(0);
  JamRawMessage^.Body^.CopyFrom(JamDataLink^,JamRawMessage^.Header.TxtLen);

  GetRawMessage:=JamRawMessage
end;

Procedure TJamBase.PutRawMessage(P:pointer);
Var
  JamRawMessage : PJamRawMessage absolute P;
begin
  JamRawMessage^.Index.Offset:=JamHeaderLink^.GetSize;
  JamIndexLink^.Seek(JamIndexLink^.GetSize);
  JamIndexLink^.Write(JamRawMessage^.Index,SizeOf(JamRawMessage^.Index));

  JamRawMessage^.Header.Offset:=JamDataLink^.GetSize;
  JamDataLink^.Seek(JamRawMessage^.Header.Offset);
  JamRawMessage^.Body^.Seek(0);
  JamDataLink^.CopyFrom(JamRawMessage^.Body^,JamRawMessage^.Header.TxtLen);

  JamHeaderLink^.Seek(JamRawMessage^.Index.Offset);
  JamHeaderLink^.Write(JamRawMessage^.Header,SizeOf(JamRawMessage^.Header));
  JamRawMessage^.Subfields^.Seek(0);
  JamHeaderLink^.CopyFrom(JamRawMessage^.Subfields^,
       JamRawMessage^.Header.SubfieldLength);

  objDispose(JamRawMessage^.Subfields);
  objDispose(JamRawMessage^.Body);
  Dispose(JamRawMessage);

  Inc(JamHDRHeader.ActiveMessages);
  WriteHDRHeader;
end;

Function TJamBase.PackIsNeeded:boolean;
begin
  PackIsNeeded:=True;
end;

Function TJamBase.GetLastRead:longint;
Var
  F:file of TJamLastRead;
  LastRead : TJamLastRead;
  lr:longint;
begin
  lr:=0;

  Assign(F,BasePath^+'.JLR');

  Reset(F);

{$I-}
  System.Seek(F,0);
  If Eof(F) then lr:=-1
    else
       While not Eof(F) do Read(F,LastRead);
{$I+}

  If IOResult<>0 then lr:=-1;

{$I-}
  Close(F);
{$I+}

  If lr<>-1 then lr:=LastRead.LastReadMsg;

  If (lr>GetCount+1) or (lr<0) then lr:=0;

  GetLastRead:=lr;
end;

Procedure TJamBase.SetLastRead(lr:longint);
Var
  F:file of TJamLastRead;
  LastRead : TJamLastRead;
begin
  If (lr>GetCount+1) or (lr<0) then lr:=0;
  FillChar(LastRead,SizeOf(TJamLastRead),#0);

  LastRead.LastReadMsg:=lr;
  LastRead.HighReadMsg:=lr;

  Assign(F,BasePath^+'.JLR');
  ReWrite(F);
  Seek(0);
  Write(F,LastRead);
  Close(F);
end;

end.
