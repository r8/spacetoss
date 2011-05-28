{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
  {$PackRecords 1}
{$ENDIF}
Unit r8Pkt2p;

interface

Uses
  r8ftn,
  r8pkt,
  r8dtm,
  strings,
  r8str,
  r8pktsa;

Type
  T2pPktHeader = record
    OrigNode : word;
    DestNode : word;

    Year     : word;
    Month    : word;
    Day      : word;
    Hour     : word;
    Minute   : word;
    Second   : word;

    Baud     : word;

    Sign     : word;

    OrigNet  : integer;
    DestNet  : word;

    ProductCodeLow : byte;
    ProductRevisionMaj : byte;

    Password : array[1..8] of char;

    QOrigZone  : word;
    QDestZone  : word;

    AuxNet : integer;

    CWValidationCopy : word;

    ProductCodeHigh : byte;
    ProductRevisionMin : byte;

    CapabilityWord : word;

    OrigZone  : word;
    DestZone  : word;

    OrigPoint  : word;
    DestPoint  : word;

    ProductData : array[1..4] of char;
  end;

  TPacket2p = object(TPacketSA)
    Constructor Init;
    Destructor Done;virtual;

    Procedure SetPktHeaderDefaults;virtual;
    Procedure SetFakeNet(Fake:Integer);virtual;
    Procedure GetToAddress(var Address:TAddress);virtual;
    Procedure GetFromAddress(var Address:TAddress);virtual;
    Procedure SetToAddress(Address:TAddress);virtual;
    Procedure SetFromAddress(Address:TAddress);virtual;
    Function GetPassword:string;virtual;
    Procedure SetPassword(Pass:string);virtual;
    Function GetProductCode:word;virtual;
    Function GetProductVersionString:string;virtual;
    Function GetPktTypeString:string;virtual;
  private
    Pkt2pHeader : T2pPktHeader;
  end;

  PPacket2p = ^TPacket2p;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

implementation

{袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴}

Constructor TPacket2p.Init;
begin
  inherited Init;

  PktType:=ptType2p;
  PktHeader:=@Pkt2pHeader;
  PktHeaderSize:=SizeOf(Pkt2pHeader);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Destructor TPacket2p.Done;
begin
  inherited Done;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket2p.SetPktHeaderDefaults;
var
  DateTime : TDateTime;
begin
  dtmGetDateTime(DateTime);

  Pkt2pHeader.Year:=DateTime.Year;
  Pkt2pHeader.Month:=DateTime.Month-1;
  Pkt2pHeader.Day:=DateTime.Day;
  Pkt2pHeader.Hour:=DateTime.Hour;
  Pkt2pHeader.Minute:=DateTime.Minute;
  Pkt2pHeader.Second:=DateTime.Sec;

  Pkt2pHeader.Sign:=2;

  Pkt2pHeader.ProductCodeLow:=Lo(ProductCode);
  Pkt2pHeader.ProductRevisionMaj:=Hi(Version);

  Pkt2pHeader.ProductCodeHigh:=Hi(ProductCode);
  Pkt2pHeader.ProductRevisionMin:=Lo(Version);

  Pkt2pHeader.CapabilityWord:=$0001;
  Pkt2pHeader.CWValidationCopy:=$0100;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket2p.SetFakeNet(Fake:Integer);
begin
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket2p.GetToAddress(var Address:TAddress);
begin
  Address.Zone:=Pkt2pHeader.DestZone;
  Address.Net:=Pkt2pHeader.DestNet;
  Address.Node:=Pkt2pHeader.DestNode;
  Address.Point:=Pkt2pHeader.DestPoint;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket2p.SetToAddress(Address:TAddress);
begin
  Pkt2pHeader.DestZone:=Address.Zone;
  Pkt2pHeader.DestNet:=Address.Net;
  Pkt2pHeader.DestNode:=Address.Node;
  Pkt2pHeader.DestPoint:=Address.Point;
  Pkt2pHeader.QDestZone:=Address.Zone;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket2p.GetFromAddress(var Address:TAddress);
begin
  Address.Zone:=Pkt2pHeader.OrigZone;
  Address.Net:=Pkt2pHeader.OrigNet;
  Address.Node:=Pkt2pHeader.OrigNode;
  Address.Point:=Pkt2pHeader.OrigPoint;

  If (Address.Point<>0) and (Address.Net=-1)
     then Address.Net:=Pkt2pHeader.AuxNet;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket2p.SetFromAddress(Address:TAddress);
begin
  Pkt2pHeader.OrigZone:=Address.Zone;
  Pkt2pHeader.OrigNet:=Address.Net;
  Pkt2pHeader.OrigNode:=Address.Node;
  Pkt2pHeader.OrigPoint:=Address.Point;
  Pkt2pHeader.QOrigZone:=Address.Zone;

(*
  If Address.Point<>0 then
    begin
      Pkt2pHeader.AuxNet:=Address.Net;
      Pkt2pHeader.OrigNet:=-1;
    end;
*)
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket2p.GetPassword:string;
Var
  sTemp:string[8];
begin
  sTemp:=#0#0#0#0#0#0#0#0;
  Move(Pkt2pHeader.Password,sTemp[1],8);
  GetPassword:=strTrimB(strUpper(sTemp),[#0]);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket2p.SetPassword(Pass:string);
begin
  FillChar(Pkt2pHeader.Password,SizeOf(Pkt2pHeader.Password),#0);

  Move(Pass[1],Pkt2pHeader.Password,Length(Pass));
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket2p.GetProductCode:word;
begin
  GetProductCode:=Pkt2pHeader.ProductCodeHigh*256
            +Pkt2pHeader.ProductCodeLow;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket2p.GetProductVersionString:string;
begin
  GetProductVersionString:=strIntToStr(Pkt2pHeader.ProductRevisionMaj)
              +'.'+strPadL(strIntToStr(Pkt2pHeader.ProductRevisionMin)
              ,'0',2);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket2p.GetPktTypeString:string;
begin
  GetPktTypeString:='Type 2+';
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

end.