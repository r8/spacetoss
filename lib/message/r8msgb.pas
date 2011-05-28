{
 MessageBody stuff.
 (c) by Sergey Storchay (2:462/117@fidonet), 2000-2001.
}
Unit r8msgb;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  r8ftn,
  r8objs,
  strings,
  r8str,
  objects;

Type

  TKludge = record
    Name : PString;
    Value : PString;
  end;
  PKludge = ^TKludge;

  TKludgeCollection = object(TCollection)
    Procedure FreeItem(Item:pointer);virtual;
  end;
  PKludgeCollection = ^TKludgeCollection;

  TKludgeBase = object(TObject)
    Kludges : PKludgeCollection;

    Constructor Init;
    Destructor Done;virtual;

    Procedure AddKludge(const AName,AValue:string);
    Function FindKludge(const Name:string):pointer;
    Procedure SetKludge(const AName,AValue:string);
    Function GetKludge(const Name:string):string;
    Procedure KillKludge(const Name:string);

    Procedure WriteKludges(S:PStream);
    Procedure CopyFrom(const K:pointer);
  end;
  PKludgeBase = ^TKludgeBase;

  TMessageBody = object(TObject)
    MsgBodyLink : PStream;
    PathLink : PStream;
    SeenByLink : PStream;
    ViaLink : PStream;

    KludgeBase : PKludgeBase;

    Origin : PString;
    TearLine : PString;

    Constructor Init;
    Destructor Done;virtual;

    Procedure AddToMsgBodyStream(const S:PStream);
    Function GetMsgBodyStream:PStream;virtual;
    Function GetMsgBodyStreamEx:PStream;virtual;

    Function GetMsgRawBodyStream:PStream;
    Function GetMsgPathStream:PStream;
    Function GetMsgSeenByStream:PStream;
    Function GetMsgViaStream:PStream;

    Procedure SetMsgPathStream(const S:PStream);virtual;
    Procedure SetMsgSeenByStream(const S:PStream);virtual;
    Procedure SetMsgViaStream(const S:PStream);virtual;

    Procedure PutMsgPathStream(const S:PStream);virtual;
    Procedure PutMsgSeenByStream(const S:PStream);virtual;
    Procedure PutMsgViaStream(const S:PStream);virtual;

    Function GetMsgStringPChar:PChar;
    Function GetMsgString:string;
    Procedure PutMsgString(const S:string);
    Procedure PutMsgStringPChar(const S:PChar);
    Function EndOfMessage:boolean;
    Procedure SetPos(const i:longint);

    Procedure SetTearLine(const ATearline : string);
    Procedure SetOrigin(const AOrigin : string);
  end;

  PMessageBody = ^TMessageBody;

implementation

Procedure TKludgeCollection.FreeItem(Item:pointer);
begin
  If Item=nil then exit;

  If PKludge(Item)^.Name<>nil then DisposeStr(PKludge(Item)^.Name);
  If PKludge(Item)^.Value<>nil then DisposeStr(PKludge(Item)^.Value);
  Dispose(PKludge(Item));
end;

Constructor TKludgeBase.Init;
begin
  inherited Init;

  Kludges:=New(PKludgeCollection, Init($10,$10));
end;

Destructor TKludgeBase.Done;
begin
  objDispose(Kludges);

  inherited Done;
end;

Procedure TKludgeBase.AddKludge(const AName,AValue:string);
Var
  TempKludge : PKludge;
begin
  TempKludge:=New(PKludge);

  TempKludge^.Name:=NewStr(AName);
  TempKludge^.Value:=NewStr(AValue);

  Kludges^.Insert(TempKludge);
end;

Function TKludgeBase.FindKludge(const Name:string):pointer;
Var
  TempKludge : PKludge;
  sTemp : string;
  i:longint;
begin
  FindKludge:=nil;

  sTemp:=strUpper(Name);
  For i:=0 to Kludges^.Count-1 do
    begin
      TempKludge:=Kludges^.At(i);

      If ((TempKludge^.Name<>nil) and (sTemp=strUpper(TempKludge^.Name^))) or
         ((TempKludge^.Name=nil) and (sTemp='')) then
        begin
          FindKludge:=TempKludge;
          exit;
        end;
    end;
end;

Procedure TKludgeBase.SetKludge(const AName,AValue:string);
Var
  TempKludge : PKludge;
begin
  TempKludge:=FindKludge(AName);

  If TempKludge=nil then AddKludge(AName,AValue) else
    begin
      If TempKludge^.Value<>nil then DisposeStr(TempKludge^.Value);
      TempKludge^.Value:=NewStr(AValue);
    end;
end;

Function TKludgeBase.GetKludge(const Name:string):string;
Var
  TempKludge:PKludge;
begin
  GetKludge:='';

  TempKludge:=FindKludge(Name);

  If TempKludge=nil then exit;

  If TempKludge^.Value<>nil then GetKludge:=TempKludge^.Value^;
end;

Procedure TKludgeBase.KillKludge(const Name:string);
Var
  TempKludge : Pointer;
begin
  TempKludge:=FindKludge(Name);
  If TempKludge<>nil then Kludges^.Delete(TempKludge);
end;

Procedure TKludgeBase.WriteKludges(S:PStream);
   Procedure WriteKludge(P:pointer);far;
   Var
     sTemp:string;
   begin
     sTemp:=#1;
     If PKludge(P)^.Name<>nil
         then sTemp:=sTemp+PKludge(P)^.Name^;
     If PKludge(P)^.Value<>nil
         then sTemp:=sTemp+#32+PKludge(P)^.Value^;
     objStreamWriteLn(S,sTemp);
   end;
begin
  Kludges^.ForEach(@WriteKludge);
end;

Procedure TKludgeBase.CopyFrom(const K:pointer);
   Procedure CopyKludge(P:pointer);far;
   Var
     Name  : string;
     Value : string;
   begin
     Name:='';
     Value:='';

     If PKludge(P)^.Name<>nil
         then Name:=PKludge(P)^.Name^;
     If PKludge(P)^.Value<>nil
         then Value:=PKludge(P)^.Value^;

     AddKludge(Name,Value);
   end;
begin
  PKludgeBase(K)^.Kludges^.ForEach(@CopyKludge);
end;

Constructor TMessageBody.Init;
begin
  inherited Init;

  KludgeBase:=New(PKludgeBase,Init);
  MsgBodyLink:=New(PMemoryStream,Init(0,cBuffSize));

  PathLink:=nil;
  SeenByLink:=nil;
  ViaLink:=nil;

  Origin:=nil;
  Tearline:=nil;
end;

Destructor TMessageBody.Done;
begin
  inherited Done;

  objDispose(KludgeBase);

  objDispose(MsgBodyLink);
  objDispose(PathLink);
  objDispose(SeenByLink);
  objDispose(ViaLink);

  DisposeStr(Origin);
  DisposeStr(TearLine);
end;

Procedure TMessageBody.PutMsgString(const S:string);
begin
  objStreamWriteLn(MsgBodyLink,S);
end;

Procedure TMessageBody.PutMsgStringPChar(const S:PChar);
begin
  objStreamWritePChar(MsgBodyLink,S);
  objStreamWriteLn(MsgBodyLink,'');
end;

Function TMessageBody.GetMsgBodyStreamEx:PStream;
var
  TempStream : PStream;
begin
  TempStream:=GetMsgBodyStream;

  If SeenByLink<>nil then
    begin
      SeenByLink^.Seek(0);
      TempStream^.CopyFrom(SeenByLink^,SeenByLink^.GetSize);
    end;

  If PathLink<>nil then
    begin
      PathLink^.Seek(0);
      TempStream^.CopyFrom(PathLink^,PathLink^.GetSize);
    end;

  If ViaLink<>nil then
    begin
      ViaLink^.Seek(0);
      TempStream^.CopyFrom(ViaLink^,ViaLink^.GetSize);
    end;

  GetMsgBodyStreamEx:=TempStream;
end;

Function TMessageBody.GetMsgBodyStream:PStream;
var
  TempStream : PStream;
begin
  TempStream:=New(PMemoryStream,Init(0,cBuffSize));

  KludgeBase^.WriteKludges(TempStream);

  MsgBodyLink^.Seek(0);
  TempStream^.CopyFrom(MsgBodyLink^,MsgBodyLink^.GetSize);

  If TearLine<>nil then objStreamWriteLn(TempStream,TearLine^);
  If Origin<>nil then objStreamWriteLn(TempStream,Origin^);

  GetMsgBodyStream:=TempStream;
end;

Function TMessageBody.GetMsgRawBodyStream:PStream;
var
  TempStream : PStream;
begin
  GetMsgRawBodyStream:=nil;
  If MsgBodyLink=nil then exit;

  TempStream:=New(PMemoryStream,Init(0,cBuffSize));

  MsgBodyLink^.Seek(0);
  TempStream^.CopyFrom(MsgBodyLink^,MsgBodyLink^.GetSize);
  GetMsgRawBodyStream:=TempStream;
end;

Function TMessageBody.GetMsgPathStream:PStream;
var
  TempStream : PStream;
begin
  GetMsgPathStream:=nil;
  If PathLink=nil then exit;

  TempStream:=New(PMemoryStream,Init(0,cBuffSize));

  PathLink^.Seek(0);
  TempStream^.CopyFrom(PathLink^,PathLink^.GetSize);
  GetMsgPathStream:=TempStream;
end;

Function TMessageBody.GetMsgViaStream:PStream;
var
  TempStream : PStream;
begin
  GetMsgViaStream:=nil;
  If ViaLink=nil then exit;

  TempStream:=New(PMemoryStream,Init(0,cBuffSize));

  ViaLink^.Seek(0);
  TempStream^.CopyFrom(ViaLink^,ViaLink^.GetSize);
  GetMsgViaStream:=TempStream;
end;

Function TMessageBody.GetMsgSeenByStream:PStream;
var
  TempStream : PStream;
begin
  GetMsgSeenByStream:=nil;
  If SeenByLink=nil then exit;

  TempStream:=New(PMemoryStream,Init(0,cBuffSize));

  SeenByLink^.Seek(0);
  TempStream^.CopyFrom(SeenByLink^,SeenByLink^.GetSize);
  GetMsgSeenByStream:=TempStream;
end;

Procedure TMessageBody.SetMsgPathStream(const S:PStream);
begin
  objDispose(PathLink);
  PathLink:=S;
end;

Procedure TMessageBody.SetMsgViaStream(const S:PStream);
begin
  objDispose(ViaLink);
  ViaLink:=S;
end;

Procedure TMessageBody.SetMsgSeenByStream(const S:PStream);
begin
  objDispose(SeenByLink);
  SeenByLink:=S;
end;

Procedure TMessageBody.PutMsgPathStream(const S:PStream);
begin
  objDispose(PathLink);

  S^.Seek(0);
  PathLink:=New(PMemoryStream,Init(0,cBuffSize));;
  PathLink^.CopyFrom(S^,S^.GetSize);
end;

Procedure TMessageBody.PutMsgViaStream(const S:PStream);
begin
  objDispose(ViaLink);

  S^.Seek(0);
  ViaLink:=New(PMemoryStream,Init(0,cBuffSize));;
  ViaLink^.CopyFrom(S^,S^.GetSize);
end;

Procedure TMessageBody.PutMsgSeenByStream(const S:PStream);
begin
  objDispose(SeenByLink);

  S^.Seek(0);
  SeenByLink:=New(PMemoryStream,Init(0,cBuffSize));;
  SeenByLink^.CopyFrom(S^,S^.GetSize);
end;

Function TMessageBody.GetMsgStringPChar:PChar;
begin
  GetMsgStringPChar:=objStreamRead(MsgBodylink,[#13,#0],$1000);
end;

Function TMessageBody.GetMsgString:string;
Var
  PTemp:Pchar;
begin
  pTemp:=GetMsgStringPChar;
  GetMsgString:=StrPas(pTemp);
  StrDispose(pTemp);
end;

Function TMessageBody.EndOfMessage:boolean;
begin
  EndOfMessage:=True;

  If MsgBodyLink^.GetPos<MsgBodyLink^.GetSize-1 then EndOfMessage:=False;
end;

Procedure TMessageBody.SetPos(const i:longint);
begin
  MsgBodyLink^.Seek(i);
end;

Procedure TMessageBody.AddToMsgBodyStream(const S:PStream);
Var
  pTemp : PChar;
  sTemp : string;
  sTemp2 : string;

  StreamSize : longint;

  TextStart : longint;
  TextEnd : longint;

  SeenByStart : longint;
  SeenByEnd : longint;

  c : char;
begin
  TextStart:=-1;
  TextEnd:=-1;
  SeenByStart:=-1;
  SeenByEnd:=-1;

  S^.Seek(S^.GetSize-1);
  S^.Read(c,1);
  If c=#10 then
    begin
      S^.Seek(S^.GetSize-1);
      S^.Truncate;
      S^.Reset;
    end;

  S^.Seek(0);
  MsgBodyLink^.Seek(MsgBodyLink^.GetSize);

  StreamSize:=S^.GetSize;

{Разбор  клуджей}
  While S^.GetPos<StreamSize-1 do
    begin
      TextStart:=S^.GetPos;

      pTemp:=objStreamRead(S,[#13,#0],255);
      sTemp:=strUpper(StrPas(pTemp));

      If (sTemp[1]=#1) and (sTemp[2]<>#32) then
        begin
          sTemp:=StrPas(pTemp);
          sTemp:=strTrimL(sTemp,[#1]);

          KludgeBase^.SetKludge(strParser(sTemp,1,[#32]),
               Copy(sTemp,Pos(#32,sTemp)+1,Length(sTemp)-Pos(#32,sTemp)+1));

          StrDispose(pTemp);
          TextStart:=-1;
          continue;
        end
        else
        begin
          StrDispose(pTemp);
          break;
        end;
    end;

  S^.Seek(StreamSize-1);
  SeenByEnd:=StreamSize-1;

  While S^.GetPos>0 do
    begin
      TextEnd:=S^.GetPos;

      pTemp:=objStreamReadBack(S,[#13],100);
      sTemp2:=strTrimL(StrPas(pTemp),[#10,#32]);
      sTemp:=strUpper(sTemp2);
      StrDispose(pTemp);

      If (Copy(sTemp,1,4)='--- ') or (sTemp='---') then
        begin
          DisposeStr(TearLine);
          TearLine:=NewStr(sTemp2);
          continue;
        end;

      If Copy(sTemp,1,10)=' * ORIGIN:' then
        begin
          DisposeStr(Origin);
          Origin:=NewStr(sTemp2);
          continue;
        end;

      If (Copy(sTemp,1,4)=#1'VIA')
        or (Copy(sTemp,1,5)=#1'RECD')
        or (Copy(sTemp,1,10)=#1'FORWARDED')
      then
        begin
          If ViaLink=nil then ViaLink:=New(PMemoryStream,Init(0,cBuffSize));
          ViaLink:=objStreamInsertStr(ViaLink,sTemp2+#13);
          continue;
        end;

      If Copy(sTemp,1,6)=#1'PATH:' then
        begin
          If PathLink=nil then PathLink:=New(PMemoryStream,Init(0,cBuffSize));
          PathLink:=objStreamInsertStr(PathLink,sTemp2+#13);
          SeenByEnd:=S^.GetPos+1;
          continue;
        end;

      If Copy(sTemp,1,8)='SEEN-BY:' then
        begin
          SeenByStart:=S^.GetPos+1;
          continue;
        end;

       break;
    end;

  If TextStart=-1 then exit;
  S^.Seek(TextStart);
  MsgBodyLink^.CopyFrom(S^,TextEnd-TextStart);
  objStreamWrite(MsgBodyLink,#13);

  If SeenByStart=-1 then exit;
  S^.Seek(SeenByStart);
  If SeenByLink=nil then SeenByLink:=New(PMemoryStream,Init(0,cBuffSize));
  SeenByLink^.CopyFrom(S^,SeenByEnd-SeenByStart);
end;

Procedure TMessageBody.SetTearLine(const ATearline : string);
begin
  DisposeStr(TearLine);
  TearLine:=NewStr(ATearLine);
end;

Procedure TMessageBody.SetOrigin(const AOrigin : string);
begin
  DisposeStr(Origin);
  Origin:=NewStr(AOrigin);
end;


end.
