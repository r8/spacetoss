{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
Unit r8msgb;

interface

Uses
  r8ftn,
  r8objs,
  strings,
  r8str,
  objects;

Type
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
    Procedure AddToMsgBodyStream(S:PStream);
    Function GetMsgBodyStream:PStream;virtual;
    Function GetMsgBodyStreamLite:PStream;virtual;
    Procedure PutMsgPathStream(S:PStream);virtual;
    Procedure PutMsgSeenByStream(S:PStream);virtual;

    Function GetMsgStringPChar:PChar;
    Function GetMsgString:string;
    Procedure PutMsgString(S:string);
    Procedure PutMsgStringPChar(S:PChar);
    Function EndOfMessage:boolean;
    Procedure SetPos(i:longint);

    Procedure SetTearLine(const _Tearline : string);
    Procedure SetOrigin(const _Origin : string);
  end;

  PMessageBody = ^TMessageBody;

implementation

Constructor TMessageBody.Init;
begin
  inherited Init;

  MsgBodyLink:=New(PMemoryStream,Init(0,cBuffSize));
  PathLink:=New(PMemoryStream,Init(0,cBuffSize));
  SeenByLink:=New(PMemoryStream,Init(0,cBuffSize));
  ViaLink:=New(PMemoryStream,Init(0,cBuffSize));
  KludgeBase:=New(PKludgeBase,Init);

  Origin:=nil;
  Tearline:=nil;
end;

Destructor TMessageBody.Done;
begin
  inherited Done;

  objDispose(MsgBodyLink);
  objDispose(PathLink);
  objDispose(SeenByLink);
  objDispose(ViaLink);
  objDispose(KludgeBase);

  DisposeStr(Origin);
  DisposeStr(TearLine);
end;

Procedure TMessageBody.PutMsgString(S:string);
begin
  objStreamWriteStr10(MsgBodyLink,S);
end;

Procedure TMessageBody.PutMsgStringPChar(S:PChar);
begin
  objStreamWriteStrPChar(MsgBodyLink,S);
  objStreamWriteStr10(MsgBodyLink,'');
end;

Function TMessageBody.GetMsgBodyStream:PStream;
var
  TempStream : PStream;
  i : longint;
  TempKludge : PKludge;
begin
  TempStream:=GetMsgBodyStreamLite;

  If SeenByLink^.GetSize>0 then
    begin
      SeenByLink^.Seek(0);
      TempStream^.CopyFrom(SeenByLink^,SeenByLink^.GetSize);
    end;

  If PathLink^.GetSize>0 then
    begin
      PathLink^.Seek(0);
      TempStream^.CopyFrom(PathLink^,PathLink^.GetSize);
    end;

  If ViaLink^.GetSize>0 then
    begin
      ViaLink^.Seek(0);
      TempStream^.CopyFrom(ViaLink^,ViaLink^.GetSize);
    end;

  GetMsgBodyStream:=TempStream;
end;

Function TMessageBody.GetMsgBodyStreamLite:PStream;
var
  TempStream : PStream;
  i : longint;
  TempKludge : PKludge;
begin
  TempStream:=New(PMemoryStream,Init(0,cBuffSize));

  For i:=0 to KludgeBase^.Kludges^.Count-1 do
    begin
      TempKludge:=KludgeBase^.Kludges^.At(i);
      objStreamWriteStr(TempStream,
         #1+TempKludge^.Name+#32+TempKludge^.Value+#13);
    end;

  MsgBodyLink^.Seek(0);
  TempStream^.CopyFrom(MsgBodyLink^,MsgBodyLink^.GetSize);

  If TearLine<>nil then objStreamWriteStr10(TempStream,TearLine^);
  If Origin<>nil then objStreamWriteStr10(TempStream,Origin^);

  GetMsgBodyStreamLite:=TempStream;
end;

Procedure TMessageBody.PutMsgPathStream(S:PStream);
begin
  objDispose(PathLink);
  PathLink:=New(PMemoryStream,Init(0,cBuffSize));

  S^.Seek(0);
  PathLink^.Seek(0);
  PathLink^.CopyFrom(S^,S^.GetSize);
end;

Procedure TMessageBody.PutMsgSeenByStream(S:PStream);
begin
  objDispose(SeenByLink);

  SeenByLink:=New(PMemoryStream,Init(0,cBuffSize));

  S^.Seek(0);
  SeenByLink^.Seek(0);
  SeenByLink^.CopyFrom(S^,S^.GetSize);
end;

Function TMessageBody.GetMsgStringPChar:PChar;
begin
  GetMsgStringPChar:=objStreamReadStrPChar(MsgBodylink,$1000);
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

Procedure TMessageBody.SetPos(i:longint);
begin
  MsgBodyLink^.Seek(i);
end;

Procedure TMessageBody.AddToMsgBodyStream(S:PStream);
Var
  pTemp : PChar;
  sTemp : string;
  lTemp : longint;

  StreamSize : longint;

  TextStart : longint;
  TextEnd : longint;

  SeenByStart : longint;
  SeenByEnd : longint;

  Kludge : string;
begin
  TextStart:=-1;
  TextEnd:=-1;
  SeenByStart:=-1;
  SeenByEnd:=-1;

  S^.Seek(0);
  MsgBodyLink^.Seek(MsgBodyLink^.GetSize);

  StreamSize:=S^.GetSize;


{Разбор  клуджей}
  While S^.GetPos<StreamSize-1 do
    begin
      TextStart:=S^.GetPos;

      pTemp:=objStreamReadStrPChar(S,500);
      sTemp:=strUpper(StrPas(pTemp));
      sTemp:=strUpper(sTemp);

      If sTemp[1]=#1 then
        begin
          sTemp:=StrPas(pTemp);
          sTemp:=strTrimL(sTemp,[#1]);

          Kludge:=strUpper(strParser(sTemp,1,[#32]));

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

      pTemp:=objStreamReadStrBackPChar(S,100);
      sTemp:=strUpper(StrPas(pTemp));

      If (Copy(sTemp,1,4)='--- ') or (sTemp='---') then
        begin
          DisposeStr(TearLine);
          TearLine:=NewStr(StrPas(pTemp));
          StrDispose(pTemp);
          continue;
        end;

      If Copy(sTemp,1,10)=' * ORIGIN:' then
        begin
          DisposeStr(Origin);
          Origin:=NewStr(StrPas(pTemp));
          StrDispose(pTemp);
          continue;
        end;

      If (Copy(sTemp,1,4)=#1'VIA')
        or (Copy(sTemp,1,5)=#1'RECD')
        or (Copy(sTemp,1,10)=#1'FORWARDED')
      then
        begin
          ViaLink:=objStreamInsertStr(ViaLink,StrPas(pTemp)+#13);
          StrDispose(pTemp);
          continue;
        end;

      If Copy(sTemp,1,6)=#1'PATH:' then
        begin
          PathLink:=objStreamInsertStr(PathLink,StrPas(pTemp)+#13);
          StrDispose(pTemp);
          SeenByEnd:=S^.GetPos+1;
          continue;
        end;

      If Copy(sTemp,1,8)='SEEN-BY:' then
        begin
          StrDispose(pTemp);
          SeenByStart:=S^.GetPos+1;
          continue;
        end;

       StrDispose(pTemp);
       break;
    end;

  If TextStart=-1 then exit;
  S^.Seek(TextStart);
  MsgBodyLink^.CopyFrom(S^,TextEnd-TextStart);
  objStreamWriteStr(MsgBodyLink,#13);

  If SeenByStart=-1 then exit;
  S^.Seek(SeenByStart);
  SeenByLink^.CopyFrom(S^,SeenByEnd-SeenByStart);
end;


Procedure TMessageBody.SetTearLine(const _Tearline : string);
begin
  DisposeStr(TearLine);
  TearLine:=NewStr(_TearLine);
end;

Procedure TMessageBody.SetOrigin(const _Origin : string);
begin
  DisposeStr(Origin);
  Origin:=NewStr(_Origin);
end;


end.
