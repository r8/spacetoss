{
 Poster Stuff for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
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
  r8cut,
  r8mail,
  r8abs,
  r8ftn,
  r8dtm,
  r8objs,
  r8pkt,
  r8str,

  objects;

Type

  TPoster = object(TCutter)
    Area : PString;

    FromName : PString;
    FromAddress : TAddress;
    ToName : PString;
    ToAddress : TAddress;
    Subj : PString;

    Body : PStream;
    PostBody : PStream;

    Origin : PString;
    TearLine : PString;
    DateTime : TDateTime;
    PID : PString;

    CutBytes : longint;

    AbsMessage : PAbsMessage;

    SplitDate : PString;
    SplitNumber : longint;
    SplitAddress : TAddress;

    Constructor Init;
    Destructor  Done; virtual;

    Procedure Post;virtual;

    Procedure GetLine(var S:PChar);virtual;
    Procedure AddLine(S:PChar);virtual;
    Procedure CreateSection;virtual;
  end;
  PPoster = ^TPoster;

  TMsgPoster = object(TPoster)
    MessageBase : PMessageBase;

    Constructor Init(const ABase:PMessageBase);
    Destructor  Done; virtual;

    Procedure CloseSection;virtual;
  end;
  PMsgPoster = ^TMsgPoster;

  TPktPoster = object(TPoster)
    PktDir : PPktDir;

    Constructor Init(const APath:string);
    Destructor  Done; virtual;

    Procedure Post;virtual;
    Procedure CloseSection;virtual;
  end;
  PPktPoster = ^TPktPoster;

implementation

Uses
  global;

Constructor TPoster.Init;
begin
  inherited Init;

  Area:=nil;

  FromName:=nil;
  ToName:=nil;
  Subj:=nil;

  Body:=nil;
  PostBody:=nil;

  Origin:=nil;

  CutBytes:=0;

  dtmGetDateTime(DateTime);

  TearLine:=NewStr('--- '+constPID);
  PID:=NewStr('PID:');

  SplitDate:=NewStr(dtmDate2String(DateTime,#32,True,True)+#32+
    dtmTime2String(DateTime,':',True,False));

  Randomize;
  SplitNumber:=Random(9999)+1;
end;

Destructor  TPoster.Done;
begin
  DisposeStr(Area);

  DisposeStr(FromName);
  DisposeStr(ToName);
  DisposeStr(Subj);

  objDispose(Body);
  objDispose(PostBody);

  DisposeStr(Origin);
  DisposeStr(TearLine);
  DisposeStr(PID);

  inherited Done;
end;

Procedure TPoster.Post;
begin
  BytesPerSection:=CutBytes;

  TotalLines:=objStreamCountLines(Body);
  TotalBytes:=Body^.GetSize;
  Body^.Seek(0);

  AddressBase^.FindNearest(FromAddress,SplitAddress);
  DoCut;
end;

Procedure TPoster.CreateSection;
Var
  sTemp:string;
  BaseType : byte;
begin
  BaseType:=btEchomail;

  If (Area=nil) or (Area^='NETMAIL')
      then BaseType:=btNetmail;

  AbsMessage:=New(PAbsMessage,Init(True,BaseType));

  AbsMessage^.FromAddress:=FromAddress;
  AbsMessage^.ToAddress:=ToAddress;

  If Area<>nil then AssignStr(AbsMessage^.Area,Area^);
  If FromName<>nil then AssignStr(AbsMessage^.FromName,FromName^);
  If ToName<>nil then AssignStr(AbsMessage^.ToName,ToName^);
  If Subj<>nil then AssignStr(AbsMessage^.Subject,Subj^);

  If TotalSections<>1 then
    begin
      If Subj<>nil then AssignStr(AbsMessage^.Subject,
      Subj^+' ['+
      strPadL(strIntToStr(CurrentSection),'0',2)
      +'/'+
      strPadL(strIntToStr(TotalSections),'0',2)
      +']');

      AbsMessage^.MessageBody^.KludgeBase^.SetKludge('SPLIT:',SplitDate^+
      strPadR(' @'+
      strIntToStr(SplitAddress.Net)+'/'+strIntToStr(SplitAddress.Node),
      #32,14)+
      strPadR(strIntToStr(SplitNumber),#32,6)+
      strPadL(strIntToStr(CurrentSection),'0',2)
      +'/'+
      strPadL(strIntToStr(TotalSections),'0',2)
      +' +++++++++++'
      );
    end;

  If Origin<>nil then AssignStr(AbsMessage^.MessageBody^.Origin,Origin^);
  If TearLine<>nil then AssignStr(AbsMessage^.MessageBody^.TearLine,TearLine^);

  If PID<>nil then AbsMessage^.MessageBody^.KludgeBase^.SetKludge(PID^,constPID);

  AbsMessage^.Flags:=flgLocal+flgPrivate;

  AbsMessage^.DateTime:=DateTime;
end;

Procedure TPoster.GetLine(var S:PChar);
begin
  S:=objStreamRead(Body,[#13,#0],$1000);
end;

Procedure TPoster.AddLine(S:PChar);
begin
  objStreamWritePChar(AbsMessage^.MessageBody^.MsgBodyLink,S);
  objStreamWrite(AbsMessage^.MessageBody^.MsgBodyLink,#13);
end;

{様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様}

Constructor TMsgPoster.Init(const ABase:PMessageBase);
begin
  inherited Init;

  MessageBase:=ABase;
end;

Destructor  TMsgPoster.Done;
begin
  inherited Done;
end;

Procedure TMsgPoster.CloseSection;
begin
  MessageBase^.CreateMessage(True);

  MessageBase^.SetAbsMessage(AbsMessage);

  If not KeepReceipts
      then MessageBase^.SetFlag(flgKill);

  MessageBase^.WriteMessage;
  MessageBase^.MessageBody:=nil;
  MessageBase^.CloseMessage;

  objDispose(AbsMessage);
end;

{様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様}

Constructor TPktPoster.Init(const APath:string);
begin
  inherited Init;

  PktDir:=New(PPktDir,Init);
  PktDir^.SetPktExtension('PKT');
  PktDir^.OpenDir(APath);
  PktDir^.PktType:=ptType2p;
end;

Destructor  TPktPoster.Done;
begin
  PktDir^.ClosePkt;
  PktDir^.CloseDir;
  objDispose(PktDir);

  inherited Done;
end;

Procedure TPktPoster.Post;
begin
  PktDir^.CreateNewPkt;
  PktDir^.Packet^.SetPktAreaType(btEchomail);

  If (Area=nil) or (Area^='NETMAIL')
      then PktDir^.Packet^.SetPktAreaType(btNetmail);

  PktDir^.Packet^.SetToAddress(NullAddress);
  PktDir^.Packet^.SetFromAddress(NullAddress);
  PktDir^.Packet^.SetPassword('');
  PktDir^.Packet^.WritePkt;

  inherited Post;
end;

Procedure TPktPoster.CloseSection;
begin
  PktDir^.Packet^.CreateNewMsg(True);
  PktDir^.Packet^.SetAbsMessage(AbsMessage,False);
  PktDir^.Packet^.WriteMsg;
  PktDir^.Packet^.MessageBody:=nil;
  PktDir^.Packet^.CloseMsg;

  objDispose(AbsMessage);
end;

end.
