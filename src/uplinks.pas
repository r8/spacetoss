{
 Uplinks Stuff for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.

 Читалку конфигов внести в объект как в AreaBase
}
Unit Uplinks;

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
  r8alst,
  r8mail,

  poster,
  lng,
  elist,

  objects;

Type

  TUplink = object(TObject)
    Address : TAddress;
    UseAka  : TAddress;

    AreafixName : PString;
    AreafixPassword : PString;
    AutocreateGroup : string[1];

    Arealist   : TArealistRec;
    AutoDesc : TArealistRec;

    ForwardLevel  : word;
    UnConditional : boolean;

    Requests : PStringsCollection;

    Constructor Init;
    Destructor Done;virtual;
  end;
  PUplink = ^TUplink;

  TUplinkCollection = object(TCollection)
    Procedure FreeItem(Item:pointer);virtual;
  end;
  PUplinkCollection = ^TUplinkCollection;

  TUplinkBase = object(TObject)
    Uplinks : PUplinkCollection;

    Constructor Init;
    Destructor Done;virtual;

    Procedure AddUplink(Uplink:PUplink);
    Function FindUplink(Address:TAddress):pointer;
  end;
  PUplinkBase = ^TUplinkBase;

implementation

Uses
  r8elst,
  r8sqlst,
  r8felst,
  r8bcl,
  r8xofl,

  global;

Constructor TUplink.Init;
begin
  inherited Init;

  Requests:=New(PStringsCollection,Init($10,$10));

  AreafixName:=nil;
  AreafixPassword:=nil;

  Arealist.List:=nil;
  AutoDesc.List:=nil;
end;

Destructor TUplink.Done;
var
  MsgPoster  : PMsgPoster;
  BodyLink : PStream;
  NetBase : PMessageBase;

  Procedure ProcessString(P:pointer);far;
  begin
    If P<>nil then objStreamWriteLn(BodyLink,PString(P)^);
  end;
begin
  If Requests^.Count>0 then
    begin
      NetBase:=EchoQueue^.OpenBase(NetmailArea);
      NetBase^.SetBaseType(btNetmail);

      BodyLink:=New(PMemoryStream,Init(0,cBuffSize));
      MsgPoster:=New(PMsgPoster,Init(NetBase));

      MsgPoster^.FromName:=NewStr('SpaceToss');

      If AreafixName<>nil then MsgPoster^.ToName:=NewStr(AreafixName^);
      If AreafixPassword<>nil then MsgPoster^.Subj:=NewStr(AreafixPassword^);

      MsgPoster^.ToAddress:=Address;
      MsgPoster^.FromAddress:=UseAka;

      Requests^.ForEach(@ProcessString);
      MsgPoster^.Body:=BodyLink;

      MsgPoster^.Post;
      objDispose(MsgPoster);
    end;

  objDispose(Requests);
  If AutoDesc.ListType<>ltNone then objDispose(AutoDesc.List);

  DisposeStr(AreafixName);
  DisposeStr(AreafixPassword);

  inherited Done;
end;

Procedure TUplinkCollection.FreeItem(Item:pointer);
begin
  If Item<>nil then objDispose(Item);
end;

Constructor TUplinkBase.Init;
begin
  inherited Init;

  Uplinks:=New(PUplinkCollection,Init($10,$10));
end;

Destructor TUplinkBase.Done;
begin
  objDispose(Uplinks);

  inherited Done;
end;

Procedure TUplinkBase.AddUplink(Uplink:PUplink);
begin
  Uplinks^.Insert(Uplink);
end;

Function TUplinkBase.FindUplink(Address:TAddress):Pointer;
  Function Match(P:pointer):boolean;far;
  Var
    TempUplink : PUplink absolute P;
  begin
    Match:=ftnAddressCompare(Address,TempUplink^.Address)=0;
  end;
begin
  FindUplink:=Uplinks^.FirstThat(@Match);
end;

end.
