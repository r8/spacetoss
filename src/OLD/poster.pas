{
 Poster Stuff for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
 Poster!!!
}
Unit Poster;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  r8objs,
  r8mail,
  r8cut,
  r8ftn,
  r8dtm,
  r8str,
  r8pkt,
  strings,
  objects;

const
  ptPkt = $00000001;
  ptMsg = $00000002;

Type

  TPosterCut = object(TCutter)
    Area : string;

    FromName : string;
    FromAddress : TAddress;
    ToName : string;
    ToAddress : TAddress;
    Subj : string;

    MessageBody : PStream;
    TempBody : PStream;

    Origin : string;
    TearLine : string;
    DateTime : TDateTime;
    PID : String;

    Constructor Init(Body:PStream);
    Destructor Done;virtual;

    Procedure GetLine(var S:PChar);virtual;
    Procedure AddLine(S:PChar);virtual;
  end;
  PPosterCut = ^TPosterCut;


  TPktCut = object(TPosterCut)
    PktDir : PPktDir;

    Constructor Init(const Dir:PString;Body:PStream);
    Destructor Done;virtual;

    Procedure CreateSection;virtual;
    Procedure CloseSection;virtual;
  end;
  PPktCut = ^TPktCut;


  TMsgCut = object(TPosterCut)
    MessageBase : PMessageBase;

    Constructor Init(const Base:PMessageBase;Body:PStream);
    Destructor Done;virtual;
    Procedure CreateSection;virtual;
    Procedure CloseSection;virtual;
  end;
  PMsgCut = ^TMsgCut;

  TPoster = object(TObject)
    PosterCut : PPosterCut;

    Area : string;

    FromName : string;
    FromAddress : TAddress;
    ToName : string;
    ToAddress : TAddress;
    Subj : string;

    CutBytes : longint;

    MessageBody : PStream;

    Origin : string;
    TearLine : string;
    DateTime : TDateTime;
    PID : String;

    Constructor Init;
    Destructor Done;virtual;

    Procedure Post(PostType:longint;PostDir:Pointer);
  end;
  PPoster = ^TPoster;

implementation

Uses
    global;

Constructor TPoster.Init;
begin
  inherited init;

  Area:='';
  TearLine:='';
  Origin:='';
  PID:='';

  CutBytes:=0;

  dtmGetDateTime(DateTime);
end;

Destructor TPoster.Done;
begin
  inherited Done;
end;

Procedure TPoster.Post(PostType:longint;PostDir:Pointer);
begin
  Case PostType of
    ptPkt : PosterCut:=New(PPktCut,Init(PString(PostDir),MessageBody));
    ptMsg : PosterCut:=New(PMsgCut,Init(PMessageBase(PostDir),MessageBody));
  end;

  PosterCut^.Area:=Area;

  PosterCut^.FromName:=FromName;
  PosterCut^.FromAddress:=FromAddress;
  PosterCut^.ToName:=ToName;
  PosterCut^.ToAddress:=ToAddress;
  PosterCut^.Subj:=Subj;

  PosterCut^.Origin:=Origin;
  PosterCut^.TearLine:=TearLine;
  PosterCut^.DateTime:=DateTime;
  PosterCut^.PID:=PID;

  PosterCut^.BytesPerSection:=CutBytes;

  PosterCut^.DoCut;
  objDispose(PosterCut);
end;

{อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ}

Constructor TPosterCut.Init(Body:PStream);
begin
  inherited Init;

  MessageBody:=Body;

  TotalLines:=objStreamCountLines(MessageBody);
  TotalBytes:=MessageBody^.GetSize;
  MessageBody^.Seek(0);

  LinesPerSection:=0;
  BytesPerSection:=0;
end;

Destructor TPosterCut.Done;
begin
  objDispose(MessageBody);

  inherited Done;
end;

Procedure TPosterCut.GetLine(var S:PChar);
begin
  S:=objStreamRead(MessageBody,[#13,#0],$1000);
end;

Procedure TPosterCut.AddLine(S:PChar);
begin
  objStreamWritePChar(TempBody,S);
  objStreamWrite(TempBody,#13);
end;

{อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ}

Constructor TPktCut.Init(const Dir:PString;Body:PStream);
begin
  inherited Init(Body);

  PktDir:=New(PPktDir,Init);
  PktDir^.SetPktExtension('PKT');
  PktDir^.OpenDir(Dir^);
  DisposeStr(Dir);
  PktDir^.PktType:=ptType2p;

  PktDir^.CreateNewPkt;
  PktDir^.Packet^.SetPktAreaType(btEchomail);

  If (Area='NETMAIL') or (Area='')
      then PktDir^.Packet^.SetPktAreaType(btNetmail);

  PktDir^.Packet^.SetToAddress(NullAddress);
  PktDir^.Packet^.SetFromAddress(NullAddress);
  PktDir^.Packet^.SetPassword('');
  PktDir^.Packet^.WritePkt;
end;

Destructor TPktCut.Done;
begin
  PktDir^.ClosePkt;
  PktDir^.CloseDir;
  objDispose(PktDir);

  inherited Done;
end;

Procedure TPktCut.CreateSection;
Var
  sTemp:string;
begin
  PktDir^.Packet^.CreateNewMsg(True);

  PktDir^.Packet^.SetMsgTo(ToName);
  PktDir^.Packet^.SetMsgFrom(FromName);
  PktDir^.Packet^.SetMsgArea(Area);
  PktDir^.Packet^.SetMsgDateTime(DateTime);

  sTemp:=Subj;

  If TotalSections<>1 then sTemp:=sTemp+' ['
        +strIntToStr(CurrentSection)+'/'
        +strIntToStr(TotalSections)+']';

  PktDir^.Packet^.SetMsgSubj(sTemp);

  TempBody:=New(PMemoryStream,Init(0,cBuffSize));
end;

Procedure TPktCut.CloseSection;
begin
  PktDir^.Packet^.MessageBody^.AddToMsgBodyStream(TempBody);
  objDispose(TempBody);

  PktDir^.Packet^.SetMsgFromAddress(FromAddress);
  PktDir^.Packet^.SetMsgToAddress(ToAddress);

  If Origin<>'' then  PktDir^.Packet^.MessageBody^.SetOrigin(Origin);
  If TearLine<>'' then  PktDir^.Packet^.MessageBody^.SetTearLine(TearLine);

  If PID<>'' then
       PktDir^.Packet^.MessageBody^.KludgeBase^.SetKludge(PID,constPID);

  PktDir^.Packet^.WriteMsg;
  PktDir^.Packet^.CloseMsg;
end;

{อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ}

Constructor TMsgCut.Init(const Base:PMessageBase;Body:PStream);
begin
  inherited Init(Body);

  MessageBase:=Base;
  MessageBase^.SetBaseType(btEchomail);

  If (Area='NETMAIL') or (Area='')
        then MessageBase^.SetbaseType(btNetmail);
end;

Destructor TMsgCut.Done;
begin
  inherited Done;
end;

Procedure TMsgCut.CreateSection;
Var
  sTemp:string;
begin
  MessageBase^.CreateMessage(True);

  MessageBase^.SetTo(ToName);
  MessageBase^.SetFrom(FromName);
  MessageBase^.SetDateWritten(DateTime);

  sTemp:=Subj;

  If TotalSections<>1 then sTemp:=sTemp+' ['
        +strIntToStr(CurrentSection)+'/'
        +strIntToStr(TotalSections)+']';

  MessageBase^.SetSubj(sTemp);

  TempBody:=New(PMemoryStream,Init(0,cBuffSize));
end;

Procedure TMsgCut.CloseSection;
begin
  MessageBase^.MessageBody^.AddToMsgBodyStream(TempBody);
  objDispose(TempBody);

  MessageBase^.SetFromAddress(FromAddress);
  MessageBase^.SetToAddress(ToAddress);

  MessageBase^.SetFlag(flgLocal);
  MessageBase^.SetFlag(flgPrivate);

  If not KeepReceipts
      then MessageBase^.SetFlag(flgKill);

  If Origin<>'' then  MessageBase^.MessageBody^.SetOrigin(Origin);
  If TearLine<>'' then  MessageBase^.MessageBody^.SetTearLine(TearLine);

  If PID<>'' then
       MessageBase^.MessageBody^.KludgeBase^.SetKludge(PID,constPID);

  MessageBase^.WriteMessage;
  MessageBase^.CloseMessage;
end;

end.
