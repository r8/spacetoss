{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
  {$PackRecords 1}
{$ENDIF}
Unit r8smb;

interface

Uses
  objects,
  r8ftn,
  r8dtm,
  r8objs,
  r8dos,
  strings,
  r8crc,
  r8mail;

const
  smbBlockLen = 256;

  smbEmail        = $0001;
  smbHyperAlloc   = $0002;

  smbPrivate      = $0001;
  smbRead         = $0002;
  smbPermanent    = $0004;
  smbLocked       = $0008;
  smbDelete       = $0010;
  smbAnonymous    = $0020;
  smbKillRead     = $0040;
  smbModerated    = $0080;
  smbValidated    = $0100;

  smbFrq          = $0001;
  smbFileAtt      = $0002;
  smbTruncFile    = $0004;
  smbKillFile     = $0008;
  smbRRq          = $0010;
  smbCRq          = $0020;
  smbNoDisp       = $0040;

  smbLocal        = $0001;
  smbTransit      = $0002;
  smbSent         = $0004;
  smbKillSent     = $0008;
  smbArchiveSent  = $0010;
  smbHold         = $0020;
  smbCrash        = $0040;
  smbImmediate    = $0080;
  smbDirect       = $0100;
  smbGate         = $0200;
  smbOrphan       = $0400;
  smbFPU          = $0800;
  smbTypeLocal    = $1000;
  smbTypeEcho     = $2000;
  smbTypeNet      = $4000;

  smbTextBody     = $00;
  smbTextTail     = $02;

smbhfSENDER              = $00;
smbhfSENDERAGENT         = $01;
smbhfSENDERNETTYPE       = $02;
smbhfSENDERNETADDR       = $03;
smbhfSENDEREXT           = $04;
smbhfSENDERPOS           = $05;
smbhfSENDERORG           = $06;

smbhfAUTHOR              = $10;
smbhfAUTHORAGENT         = $11;
smbhfAUTHORNETTYPE       = $12;
smbhfAUTHORNETADDR       = $13;
smbhfAUTHOREXT           = $14;
smbhfAUTHORPOS           = $15;
smbhfAUTHORORG           = $16;

smbhfREPLYTO             = $20;
smbhfREPLYTOAGENT        = $21;
smbhfREPLYTONETTYPE      = $22;
smbhfREPLYTONETADDR      = $23;
smbhfREPLYTOEXT          = $24;
smbhfREPLYTOPOS          = $25;
smbhfREPLYTOORG          = $26;

smbhfRECIPIENT           = $30;
smbhfRECIPIENTAGENT      = $31;
smbhfRECIPIENTNETTYPE    = $32;
smbhfRECIPIENTNETADDR    = $33;
smbhfRECIPIENTEXT        = $34;
smbhfRECIPIENTPOS        = $35;
smbhfRECIPIENTORG        = $36;

smbhfFORWARDTO           = $40;
smbhfFORWARDTOAGENT      = $41;
smbhfFORWARDTONETTYPE    = $42;
smbhfFORWARDTONETADDR    = $43;
smbhfFORWARDTOEXT        = $44;
smbhfFORWARDTOPOS        = $45;
smbhfFORWARDTOORG        = $46;

smbhfFORWARDED           = $48;

smbhfRECEIVEDBY          = $50;
smbhfRECEIVEDBYAGENT     = $51;
smbhfRECEIVEDBYNETTYPE   = $52;
smbhfRECEIVEDBYNETADDR   = $53;
smbhfRECEIVEDBYEXT       = $54;
smbhfRECEIVEDBYPOS       = $55;
smbhfRECEIVEDBYORG       = $56;

smbhfRECEIVED            = $58;

smbhfSUBJECT             = $60;
smbhfSUMMARY             = $61;
smbhfCOMMENT             = $62;
smbhfCARBONCOPY          = $63;
smbhfGROUP               = $64;
smbhfEXPIRATION          = $65;
smbhfPRIORITY            = $66;

smbhfFILEATTACH          = $70;
smbhfDESTFILE            = $71;
smbhfFILEATTACHLIST      = $72;
smbhfDESTFILELIST        = $73;
smbhfFILEREQUEST         = $74;
smbhfFILEPASSWORD        = $75;
smbhfFILEREQUESTLIST     = $76;
smbhfFILEPASSWORDLIST    = $77;

smbhfIMAGEATTACH         = $80;
smbhfANIMATTACH          = $81;
smbhfFONTATTACH          = $82;
smbhfSOUNDATTACH         = $83;
smbhfPRESENTATTACH       = $84;
smbhfVIDEOATTACH         = $85;
smbhfAPPDATAATTACH       = $86;

smbhfIMAGETRIGGER        = $90;
smbhfANIMTRIGGER         = $91;
smbhfFONTTRIGGER         = $92;
smbhfSOUNDTRIGGER        = $93;
smbhfPRESENTTRIGGER      = $94;
smbhfVIDEOTRIGGER        = $95;
smbhfAPPDATATRIGGER      = $96;

smbhfFIDOCTRL            = $a0;
smbhfFIDOAREA            = $a1;
smbhfFIDOSEENBY          = $a2;
smbhfFIDOPATH            = $a3;
smbhfFIDOMSGID           = $a4;
smbhfFIDOREPLYID         = $a5;
smbhfFIDOPID             = $a6;
smbhfFIDOFLAGS           = $a7;

smbhfRFC822HEADER        = $b0;
smbhfRFC822MSGID         = $b1;
smbhfRFC822REPLYID       = $b2;

smbhfUNKNOWN             = $f1;
smbhfUNKNOWNASCII        = $f2;
mbdfUNUSED              = $ff;

ZeroArray : array[1..256] of char = (
#0,#0,#0,#0,#0,#0,
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
  TSMBTime = record
    Time : longint;
    Zone : word;
  end;

  TSMBIndex = record
    ToName    : word;
    FromName  : word;
    Subj      : word;
    Attr      : word;
    Offset    : longint;
    Number    : longint;
    Time      : longint;
  end;

  TSMBBaseHeader = record
    Id    : array[1..4] of char;
    Vers  : word;
    Len   : word;
  end;

  TSMBBaseStatus = record
    LastMsg    : longint;
    TotalMsgs  : longint;
    HeaderOffs : longint;
    MaxCRCs    : longint;
    MaxMSGs    : longint;
    MaxAge     : word;
    Attr       : word;
  end;

  TSMBMessageHeader = record
    Id    : array[1..4] of char;
    MsgType : word;
    Vers          : word;
    Len           : word;
    Attr          : word;
    AuxAttr       : longint;
    NetAttr       : longint;
    DateWritten   : TSMBTime;
    DateReceived  : TSMBTime;
    Number : longint;
    ReplyTo : longint;
    ReplyNext : longint;
    Reply1st  : longint;
    Recvd : array[1..16] of byte;
    Offset : longint;
    NumbOfFields : word;
  end;

  TDataField = record
    DataType : word;
    Offset : longint;
    Len : longint;
  end;

  TSmbBase = object(TMessageBase)
    SMBHeader :  TSMBBaseHeader;
    SMBStatus :  TSMBBaseStatus;
    SMBMsgHeader :  TSMBMessageHeader;

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

    Function OpenMsg:boolean;virtual;
    Function CreateNewMessage(UseMsgID:Boolean):boolean;virtual;
    Procedure CloseMessage;virtual;
    Function WriteMessage:boolean;virtual;

    Procedure SetTo(const ToName:string);virtual;
    Procedure SetFrom(const FromName:string);virtual;
    Procedure SetSubj(const Subject:string);virtual;
    Procedure SetDateWritten(MDateTime:TDateTime);virtual;
    Procedure GetDateWritten(var MDateTime:TDateTime);virtual;
    Procedure SetDateArrived(MDateTime:TDateTime);virtual;

    Procedure SetFlags(Flags:longint);virtual;

    Procedure SetFromAddress(Address:TAddress);virtual;
    Procedure SetToAddress(Address:TAddress);virtual;
    Procedure GetFromAddress(var Address:TAddress);virtual;
    Procedure GetToAddress(var Address:TAddress);virtual;

    Procedure Flush;virtual;

    Procedure SetHDRDefaults;
    Procedure SetMsgHdrDefaults;

    Procedure WriteHeaderField(Ft:word;Data:string;S:PStream);
  private
    SMBHeaderLink : PBufStream;
    SMBDataLink : PBufStream;
    SMBIndexLink: PBufStream;
    SMBDataAllocationLink: PBufStream;
    SMBHeaderAllocationLink: PBufStream;
  end;

  PSmbBase = ^TSmbBase;

implementation

Constructor TSmbBase.Init;
begin
  inherited Init;
end;

Destructor TSmbBase.Done;
begin
  objDispose(SMBHeaderLink);
  objDispose(SMBIndexLink);
  objDispose(SMBDataAllocationLink);
  objDispose(SMBHeaderAllocationLink);
  objDispose(SMBDataLink);

  inherited Done;
end;

Function TSmbBase.CreateBase(Path:string):boolean;
Var
  f:file;
begin
  CreateBase:=False;

  If not dosDirExists(dosGetPath(Path)) then dosMkDir(dosGetPath(Path));

  Assign(f,Path+'.SHD');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;
  SetHDRDefaults;
  BlockWrite(F,SMBHeader,SizeOf(SMBHeader));
  BlockWrite(F,SMBStatus,SizeOf(SMBStatus));
  Close(F);

  Assign(f,Path+'.SID');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;
  Close(F);

  Assign(f,Path+'.SDT');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;
  Close(F);

  Assign(f,Path+'.SDA');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;
  Close(F);

  Assign(f,Path+'.SHA');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;
  Close(F);

  Assign(f,Path+'.SHA');
{$I-}
  Rewrite(F,1);
{$I+}
  If IOResult<>0 then exit;
  Close(F);

  CreateBase:=OpenBase(Path);
end;

Procedure TSmbBase.SetHDRDefaults;
begin
  SMBHeader.Id[1]:='S';
  SMBHeader.Id[2]:='M';
  SMBHeader.Id[3]:='B';
  SMBHeader.Id[4]:=#26;

  SMBHeader.Vers:=$0121;
  SMBHeader.Len:=SizeOf(SMBHeader)+SizeOf(SMBStatus);

  SMBStatus.LastMsg:=0;
  SMBStatus.TotalMsgs:=0;
  SMBStatus.HeaderOffs:=0;
  SMBStatus.MaxCRCs:=$FFFF;
  SMBStatus.MaxMSGs:=$FFFF;
  SMBStatus.MaxAge:=$FF;
  SMBStatus.Attr:=0;
end;

Procedure TSMBBase.CloseBase;
begin
  CloseMessage;
end;

Function TSMBBase.OpenBase(Path:string):boolean;
begin
  OpenBase:=False;

  If not dosDirExists(dosGetPath(Path)) then exit;

  DisposeStr(BasePath);
  BasePath:=NewStr(Path);

  If not dosFileExists(Path+'.SHD') then exit;
  If not dosFileExists(Path+'.SID') then exit;
  If not dosFileExists(Path+'.SDT') then exit;

  SMBHeaderLink:=New(PBufStream,Init(Path+'.SHD',stOpen,$1000));
  SMBIndexLink:=New(PBufStream,Init(Path+'.SID',stOpen,$1000));
  SMBDataLink:=New(PBufStream,Init(Path+'.SDT',stOpen,$1000));

  If (SMBHeaderLink^.Status<>stOK)
     or (SMBDataLink^.Status<>stOK)
     or (SMBIndexLink^.Status<>stOK) then exit;

  If IOResult<>0 then exit;

  SMBHeaderLink^.Seek(0);
  SMBHeaderLink^.Read(SMBHeader,SizeOf(SMBHeader));
  SMBHeaderLink^.Read(SMBStatus,SizeOf(SMBStatus));

  If ((SMBStatus.Attr and smbHyperAlloc)<>smbHyperAlloc)
     and
   ((not dosFileExists(Path+'.SDA')) and (not dosFileExists(Path+'.SHA')))
             then exit;

  SMBDataAllocationLink:=New(PBufStream,Init(Path+'.SDA',stOpen,$1000));
  SMBHeaderAllocationLink:=New(PBufStream,Init(Path+'.SHA',stOpen,$1000));

  If (SMBDataAllocationLink^.Status<>stOK) then exit;
  If (SMBHeaderAllocationLink^.Status<>stOK) then exit;
  If IOResult<>0 then exit;

  OpenBase:=True;
end;

Function TSMBBase.CreateNewMessage(UseMsgID:Boolean):boolean;
begin
  CreateNewMessage:=False;
  If MsgOpened then exit;

  inherited CreateNewMessage(UseMsgID);

  SetMsgHdrDefaults;

  Inc(SMBStatus.LastMsg);
  Inc(SMBStatus.TotalMsgs);

  CreateNewMessage:=True;
end;

Procedure TSMBBase.CloseMessage;
begin
  inherited CloseMessage;

  MsgOpened:=False;
end;

Procedure TSMBBase.SetMsgHdrDefaults;
begin
  FillChar(SMBMsgHeader,SizeOf(SMBMsgHeader),#0);
  SMBMsgHeader.Id[1]:='S';
  SMBMsgHeader.Id[2]:='H';
  SMBMsgHeader.Id[3]:='D';
  SMBMsgHeader.Id[4]:=#$1A;

  SMBMsgHeader.MsgType:=0;
  SMBMsgHeader.Vers:=$0121;

  SMBMsgHeader.Number:=SMBStatus.LastMsg+1;
end;

Procedure TSMBBase.SetTo(const ToName:string);
begin
  MsgTo:=ToName;
end;

Procedure TSMBBase.SetFrom(const FromName:string);
begin
  MsgFrom:=FromName;
end;

Procedure TSMBBase.SetSubj(const Subject:string);
begin
  MsgSubject:=Subject;
end;

Function TSMBBase.WriteMessage:boolean;
Var
  iTemp : longint;
  NOB : longint;
  NOF : longint;
  AllocatedHeader : byte;
  AllocatedData : word;
  sTemp : string;
  pTemp : PChar;
  TempStream : PStream;

  SMBIndex : TSMBIndex;
  SMBDataField : TDataField;
begin
  WriteMessage:=False;

  TempStream:=New(PMemoryStream,Init(0,cBuffSize));
  TempStream^.Seek(0);

  objStreamWriteStr(TempStream,#0#0);

  iTemp:=MessageBody^.MsgBodyLink^.GetSize;
  MessageBody^.MsgBodyLink^.Seek(0);

  While MessageBody^.MsgBodyLink^.GetPos<iTemp-1 do
    begin
      pTemp:=objStreamReadStrPChar(MessageBody^.MsgBodyLink,$1000);

      objStreamWriteStrPChar(TempStream,pTemp);
      objStreamWriteStr(TempStream,#13#10);
      StrDispose(pTemp);
    end;

  If MessageBody^.TearLine<>nil then
         objStreamWriteStr(TempStream,MessageBody^.TearLine^+#13#10);
  If MessageBody^.Origin<>nil then
         objStreamWriteStr(TempStream,MessageBody^.Origin^+#13#10);

  SMBHeaderLink^.Seek(0);
  SMBHeaderLink^.Write(SMBHeader,SizeOf(SMBHeader));
  SMBHeaderLink^.Write(SMBStatus,SizeOf(SMBStatus));

{=========================================================================}

  If (SMBStatus.Attr and smbHyperAlloc)=smbHyperAlloc
    then SMBMsgHeader.Offset:=SMBDataLink^.GetSize
   else
     begin
       NOB:=TempStream^.GetSize div smbBlockLen;
       If NOB*smbBlockLen<>TempStream^.GetSize
           then Inc(NOB);

       iTemp:=SMBDataAllocationLink^.GetSize;
       SMBDataAllocationLink^.Seek(0);
       NOF:=0;

     If SMBDataAllocationLink^.GetSize>0 then
       While SMBDataAllocationLink^.GetPos<iTemp-1 do
         begin
           SMBDataAllocationLink^.Read(AllocatedData,SizeOf(AllocatedData));
           If AllocatedData=0 then Inc(NOF) else NOF:=0;

           If NOF=NOB then
             begin
               SMBDataAllocationLink^.Seek(SMBDataAllocationLink^.GetPos-
                       SizeOf(AllocatedData)*NOF);
               break;
             end;
         end;

         SMBMsgHeader.Offset:=(SMBDataAllocationLink^.GetPos div 2)
                                          * smbBlockLen;

         AllocatedData:=1;

         For iTemp:=1 to NOB
               do SMBDataAllocationLink^.Write(AllocatedData,SizeOf(AllocatedData));
     end;

{=========================================================================}

  SMBDataLink^.Seek(SMBMsgHeader.Offset);

  TempStream^.Seek(0);

  iTemp:=TempStream^.GetSize;
  SMBDataLink^.CopyFrom(TempStream^,iTemp);
  SMBDataLink^.Write(ZeroArray,256-(iTemp-(iTemp div 256)*256));

  SMBDataField.DataType:=smbTextBody;
  SMBDataField.Offset:=0;
  SMBDataField.Len:=iTemp;

  objDispose(TempStream);

{=========================================================================}

  TempStream:=New(PMemoryStream,Init(0,cBuffSize));

  TempStream^.Seek(0);
  TempStream^.Write(SMBDataField,SizeOf(SMBDataField));
  SMBMsgHeader.NumbOfFields:=1;

  WriteHeaderField(smbhfSender,MsgFrom,TempStream);
  WriteHeaderField(smbhfSenderNetType,#0#2,TempStream);
  WriteHeaderField(smbhfSenderNetAddr,ftnAddressToStr(MsgFromAddress),
                   TempStream);

  WriteHeaderField(smbhfRecipient,MsgTo,TempStream);
  WriteHeaderField(smbhfRecipientNetType,#0#2,TempStream);
  WriteHeaderField(smbhfRecipientNetAddr,ftnAddressToStr(MsgToAddress),
                   TempStream);

  WriteHeaderField(smbhfSubject,MsgSubject,TempStream);

  SMBMsgHeader.Len:=SizeOf(SMBMsgHeader)+TempStream^.GetSize;

  {=========================================================================}

  If (SMBStatus.Attr and smbHyperAlloc)=smbHyperAlloc
    then SMBIndex.Offset:=SMBHeaderLink^.GetSize
   else
     begin
       NOB:=SMBMsgHeader.Len div smbBlockLen;
       If NOB*smbBlockLen<>SMBMsgHeader.Len
           then Inc(NOB);

       iTemp:=SMBHeaderAllocationLink^.GetSize;
       SMBHeaderAllocationLink^.Seek(0);
       NOF:=0;

     If SMBHeaderAllocationLink^.GetSize>0 then
       While SMBHeaderAllocationLink^.GetPos<iTemp-1 do
         begin
           SMBHeaderAllocationLink^.Read(AllocatedHeader,SizeOf(AllocatedHeader));
           If AllocatedHeader=0 then Inc(NOF) else NOF:=0;

           If NOF=NOB then
             begin
               SMBHeaderAllocationLink^.Seek(SMBHeaderAllocationLink^.GetPos-
                       SizeOf(AllocatedHeader)*NOF);
               break;
             end;
         end;

       SMBIndex.Offset:=(SMBHeaderAllocationLink^.GetPos)
                                          * smbBlockLen;

       SMBIndex.Offset:=SMBIndex.Offset+SMBHeader.Len;

       AllocatedHeader:=1;

       For iTemp:=1 to NOB
             do SMBHeaderAllocationLink^.Write(AllocatedHeader,SizeOf(AllocatedHeader));
     end;

{=========================================================================}

  SMBHeaderLink^.Seek(SMBIndex.Offset);
  SMBHeaderLink^.Write(SMBMsgHeader,SizeOf(SMBMsgHeader));

  TempStream^.Seek(0);
  SMBHeaderLink^.CopyFrom(TempStream^,TempStream^.GetSize);

  iTemp:=SMBMsgHeader.Len;
  SMBHeaderLink^.Write(ZeroArray,256-(iTemp-(iTemp div 256)*256));

  objDispose(TempStream);

  SMBIndex.Number:=SMBMsgHeader.Number;
  SMBIndex.ToName:=crcStringCRC16(MsgTo);
  SMBIndex.FromName:=crcStringCRC16(MsgFrom);
  SMBIndex.Subj:=crcStringCRC16(MsgSubject);
  SMBIndex.Attr:=SMBMsgHeader.Attr;
  SMBIndex.Time:=SMBMsgHeader.DateReceived.Time;

  SMBIndexLink^.Seek(SMBIndexLink^.GetSize);
  SMBIndexLink^.Write(SMBIndex,SizeOf(SMBIndex));

{=========================================================================}

  WriteMessage:=True;
end;

Procedure TSMBBase.SetDateWritten(MDateTime:TDateTime);
begin
  SMBMsgHeader.DateWritten.Time:=dtmDateToUnix(MDateTime);
end;

Procedure TSMBBase.GetDateWritten(var MDateTime:TDateTime);
begin
  dtmUnixToDate(SMBMsgHeader.DateWritten.Time, MDateTime);
end;

Procedure TSMBBase.SetDateArrived(MDateTime:TDateTime);
begin
  SMBMsgHeader.DateReceived.Time:=dtmDateToUnix(MDateTime);
end;

Procedure TSMBBase.SetFlags(Flags:longint);
begin
  SMBMsgHeader.NetAttr:=0;

  If (Flags and flgPrivate)=flgPrivate
      then SMBMsgHeader.Attr:=SMBMsgHeader.Attr or smbPrivate;

  If (Flags and flgCrash)=flgCrash
      then SMBMsgHeader.NetAttr:=SMBMsgHeader.Attr or smbCrash;

  If (Flags and flgReceived)=flgReceived
      then SMBMsgHeader.NetAttr:=SMBMsgHeader.Attr or smbRead;

  If (Flags and flgSent)=flgSent
      then SMBMsgHeader.NetAttr:=SMBMsgHeader.NetAttr or smbSent;

  If (Flags and flgTransit)=flgTransit
      then SMBMsgHeader.NetAttr:=SMBMsgHeader.NetAttr or smbTransit;

  If (Flags and flgOrphan)=flgOrphan
      then SMBMsgHeader.NetAttr:=SMBMsgHeader.NetAttr or smbOrphan;

  If (Flags and flgKill)=flgKill
      then SMBMsgHeader.NetAttr:=SMBMsgHeader.NetAttr or smbKillSent;

  If (Flags and flgLocal)=flgLocal
      then SMBMsgHeader.Attr:=SMBMsgHeader.NetAttr or smbLocal;

  If (Flags and flgHold)=flgHold
      then SMBMsgHeader.NetAttr:=SMBMsgHeader.NetAttr or smbHold;

  If (Flags and flgFRq)=flgFRq
      then SMBMsgHeader.NetAttr:=SMBMsgHeader.NetAttr or smbFRq;

  If (Flags and flgRRq)=flgRRq
      then SMBMsgHeader.NetAttr:=SMBMsgHeader.NetAttr or smbRRq;

end;

Function TSMBBase.OpenMsg:boolean;
Var
  SMBIndex : TSMBIndex;
  i : longint;
begin
  OpenMsg:=False;

  If MsgOpened then exit;

  SMBIndexLink^.Seek(CurrentMessage*SizeOf(TSMBIndex));
  SMBIndexLink^.Read(SMBIndex,SizeOf(TSMBIndex));

  SMBHeaderLink^.Seek(SMBIndex.Offset);
  SMBHeaderLink^.Read(SMBMsgHeader,SizeOf(SMBMsgHeader));

  inherited OpenMsg;

  OpenMsg:=True;
  MsgOpened:=True;
end;

Procedure TSMBBase.SetFromAddress(Address:TAddress);
begin
  inherited SetFromAddress(Address);

  MsgFromAddress:=Address;
end;

Procedure TSMBBase.SetToAddress(Address:TAddress);
begin
  inherited SetToAddress(Address);

  MsgToAddress:=Address;
end;

Procedure TSMBBase.GetFromAddress(Var Address:TAddress);
begin
  Address:=MsgFromAddress;
end;

Procedure TSMBBase.GetToAddress(Var Address:TAddress);
begin
  Address:=MsgToAddress;
end;

Procedure TSMBBase.Flush;
begin
  SMBHeaderLink^.Flush;
  SMBIndexLink^.Flush;
end;

Procedure TSMBBase.WriteHeaderField(Ft:word;Data:string;S:PStream);
begin
  S^.Write(FT,SizeOf(FT));
  FT:=Length(Data);
  S^.Write(FT,SizeOf(FT));
  objStreamWriteStr(S,Data);
end;

end.
