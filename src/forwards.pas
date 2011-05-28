{
 Request Forward Stuff for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
}
Unit Forwards;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
  {$PackRecords 1}
{$ENDIF}

interface

Uses
  r8objs,
  r8dos,
  r8dtm,
  r8ftn,

  poster,
  nodes,
  lng,

  objects;


const
  constFwdSig = 'r8fwd';

Type

  TForwardItem = packed record
    AreaName : string[50];
    UplinkAddress : TAddress;
    Address : TAddress;
    Date : longint;
  end;
  PForwardItem = ^TForwardItem;

  TForwardCollection = object(TCollection)
    Procedure FreeItem(Item:pointer);virtual;
  end;
  PForwardCollection = ^TForwardCollection;

  TForwardFile = object(TObject)
    FileName : PString;
    ForwardCollection : PForwardCollection;

    ExpireDays : longint;
    PostArea : Pointer;
    MsgPoster : PMsgPoster;

    Constructor Init(const AFileName:string);
    Destructor Done;virtual;

    Procedure AddForward(const AreaName:string;const ToAddress,FromAddress:TAddress);
    Procedure CheckForExpire;
    Function FindItem(S:string):PForwardItem;
  end;
  PForwardFile = ^TForwardFile;

implementation

Uses
  global;

Procedure TForwardCollection.FreeItem(Item:pointer);
begin
  If Item<>nil then Dispose(PForwardItem(Item));
end;

Constructor TForwardFile.Init(const AFileName:string);
var
  F : PBufStream;
  i : longint;
  TempForward : PForwardItem;
  Sig : string[5];
begin
  inherited Init;

  ForwardCollection:=New(PForwardCollection,Init($10,$10));

  FileName:=NewStr(AFileName);
  ExpireDays:=0;

  If not dosFileExists(AFileName) then exit;

  F:=New(PBufStream,Init(FileName^,fmOpen or fmRead or fmDenyAll,cBuffSize));
  If IOResult<>0 then exit;
  If F^.Status<>stOK then exit;

  F^.Read(Sig,SizeOf(Sig));
  If Sig<>constFwdSig then
    begin
      objDispose(F);
      exit;
    end;

  i:=F^.GetSize;
  While F^.GetPos<i-1 do
    begin
      New(TempForward);
      F^.Read(TempForward^,SizeOf(TempForward^));
      ForwardCollection^.Insert(TempForward);
    end;
  objDispose(F);
end;

Destructor TForwardFile.Done;
var
  F : PBufStream;
  i : longint;
  Sig : string[5];

  Procedure WriteItem(P:pointer);far;
  begin
    F^.Write(PForwardItem(P)^,SizeOf(TForwardItem));
  end;
begin
  CheckForExpire;
  dosErase(FileName^);

  If ForwardCollection^.Count>0  then
    begin
      F:=New(PBufStream,Init(FileName^,fmCreate or fmWrite or fmDenyAll,cBuffSize));
      Sig:=constFwdSig;
      F^.Write(Sig,SizeOf(Sig));
      ForwardCollection^.ForEach(@WriteItem);
      objDispose(F);
    end;

  objDispose(ForwardCollection);
  DisposeStr(FileName);
  inherited Done;
end;

Procedure TForwardFile.AddForward(const AreaName:string;const ToAddress,FromAddress:TAddress);
var
  TempForward : PForwardItem;
begin
  New(TempForward);

  FillChar(TempForward^,SizeOf(TempForward^),#0);
  TempForward^.AreaName:=AreaName;

  TempForward^.Address:=FromAddress;
  TempForward^.UplinkAddress:=ToAddress;
  TempForward^.Date:=dtmGetDateTimeUnix;

  ForwardCollection^.Insert(TempForward);
end;

Procedure TForwardFile.CheckForExpire;
var
  Date : longint;
  i:longint;

  Function CheckItem(ForwardItem:PForwardItem):boolean;far;
  var
    TempNode : PNode;
    Body : PStream;
    NetBase : Pointer;
  begin
    CheckItem:=False;
    If (Date-ForwardItem^.Date) div 86400<=ExpireDays then exit;

    CheckItem:=True;

    TempNode:=NodeBase^.FindNode(ForwardItem^.Address);
    If TempNode=nil then exit;

    Body:=New(PMemoryStream,Init(0,cBuffSize));

    LngFile^.AddVar(ForwardItem^.AreaName);
    objStreamWriteLn(Body,LngFile^.GetString(LongInt(lngExpiredForward)));

    NetBase:=EchoQueue^.OpenBase(PostArea);
    MsgPoster:=New(PMsgPoster,Init(NetBase));

    MsgPoster^.FromName:=NewStr('Areafix');

    If TempNode^.SysopName<>nil then
      MsgPoster^.ToName:=NewStr(TempNode^.SysopName^) else
        MsgPoster^.ToName:=NewStr('SysOp');

    MsgPoster^.Subj:=NewStr(LngFile^.GetString(LongInt(lngExpiredForwardSubj)));

    MsgPoster^.FromAddress:=TempNode^.UseAKA;
    MsgPoster^.ToAddress:=TempNode^.Address;
    MsgPoster^.Body:=Body;
    MsgPoster^.CutBytes:=MsgSplitSize;

    MsgPoster^.Post;
    objDispose(MsgPoster);
  end;
begin
  Date:=dtmGetDateTimeUnix;
  i:=0;

  While i<=ForwardCollection^.Count-1 do
    begin
      If CheckItem(ForwardCollection^.At(i)) then
        begin
          ForwardCollection^.AtFree(i);
          Dec(i);
        end;
      Inc(i);
    end;
end;

Function TForwardFile.FindItem(S:string):PForwardItem;
  Function CheckItem(ForwardItem:PForwardItem):boolean;far;
  begin
    CheckItem:=ForwardItem^.AreaName=S;
  end;
begin
  FindItem:=ForwardCollection^.FirstThat(@CheckItem);
end;

end.