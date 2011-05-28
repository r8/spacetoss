{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
  {$PackRecords 1}
{$ENDIF}
Unit r8Pkt20;

interface

Uses
  r8pkt,
  r8dtm,
  r8pktsa,
  r8ftn,
  strings,
  r8str,
  objects;

Type

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

  T20PktHeader = record
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

    OrigNet  : word;
    DestNet  : word;

    ProductCodeLow : byte;
    ProductRevisionMaj : byte;

    Password : array[1..8] of char;

    QOrigZone  : word;
    QDestZone  : word;

    Fill : array[1..4] of byte;

    ProductCodeHigh : byte;
    ProductRevisionMin : byte;

    CapabilityWord : word;

    OrigZone  : word;
    DestZone  : word;

    OrigPoint  : word;
    DestPoint  : word;

    ProductData : array[1..4] of char;
  end;

  P20PktHeader = ^TSAPktHeader;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

  TPacket20 = object(TPacketSA)
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
    Pkt20Header : T20PktHeader;
  end;

  PPacket20 = ^TPacket20;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

implementation

{袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴}

Constructor TPacket20.Init;
begin
  inherited Init;

  PktType:=ptType2;
  PktHeader:=@Pkt20Header;
  PktHeaderSize:=SizeOf(Pkt20Header);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Destructor TPacket20.Done;
begin
  inherited Done;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket20.SetPktHeaderDefaults;
var
  DateTime : TDateTime;
begin
  dtmGetDateTime(DateTime);

  Pkt20Header.Year:=DateTime.Year;
  Pkt20Header.Month:=DateTime.Month-1;
  Pkt20Header.Day:=DateTime.Day;
  Pkt20Header.Hour:=DateTime.Hour;
  Pkt20Header.Minute:=DateTime.Minute;
  Pkt20Header.Second:=DateTime.Sec;

  Pkt20Header.Sign:=2;

  Pkt20Header.ProductCodeLow:=Lo(ProductCode);
  Pkt20Header.ProductRevisionMaj:=Hi(Version);

  Pkt20Header.ProductCodeHigh:=Hi(ProductCode);
  Pkt20Header.ProductRevisionMin:=Lo(Version);

  Pkt20Header.CapabilityWord:=1;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket20.SetFakeNet(Fake:Integer);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket20.GetToAddress(var Address:TAddress);
begin
  Address.Zone:=Pkt20Header.DestZone;
  Address.Net:=Pkt20Header.DestNet;
  Address.Node:=Pkt20Header.DestNode;
  Address.Point:=Pkt20Header.DestPoint;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket20.SetToAddress(Address:TAddress);
begin
  Pkt20Header.DestZone:=Address.Zone;
  Pkt20Header.DestNet:=Address.Net;
  Pkt20Header.DestNode:=Address.Node;
  Pkt20Header.DestPoint:=Address.Point;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket20.GetFromAddress(var Address:TAddress);
begin
  Address.Zone:=Pkt20Header.OrigZone;
  Address.Net:=Pkt20Header.OrigNet;
  Address.Node:=Pkt20Header.OrigNode;
  Address.Point:=Pkt20Header.OrigPoint;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket20.SetFromAddress(Address:TAddress);
begin
  Pkt20Header.OrigZone:=Address.Zone;
  Pkt20Header.OrigNet:=Address.Net;
  Pkt20Header.OrigNode:=Address.Node;
  Pkt20Header.OrigPoint:=Address.Point;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket20.GetPassword:string;
Var
  sTemp:string[8];
begin
  sTemp:=#0#0#0#0#0#0#0#0;
  Move(Pkt20Header.Password,sTemp[1],8);
  GetPassword:=strTrimB(strUpper(sTemp),[#0]);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TPacket20.SetPassword(Pass:string);
begin
  FillChar(Pkt20Header.Password,SizeOf(Pkt20Header.Password),#0);

  Move(Pass[1],Pkt20Header.Password,Length(Pass));
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket20.GetProductCode:word;
begin
  GetProductCode:=Pkt20Header.ProductCodeHigh*256
            +Pkt20Header.ProductCodeLow;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket20.GetProductVersionString:string;
begin
  GetProductVersionString:=strIntToStr(Pkt20Header.ProductRevisionMaj)
              +'.'+strPadL(strIntToStr(Pkt20Header.ProductRevisionMin)
              ,'0',2);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TPacket20.GetPktTypeString:string;
begin
  GetPktTypeString:='Type 2.0';
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

end.