{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
  {$PackRecords 1}
{$ENDIF}
Unit r8ftn;

Interface
Uses
  dos,
  objects,
  crt,
  r8dtm,
  r8crc,
  r8str,
  r8objs,
  r8dos;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

const
  BundleExt : array[0..6] of string[2] = ('SU','MO','TU','WE','TH','FR','SA');
  BundleLastChar : string = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  AddressChars : set of char = ['0'..'9',':','/','.'];

{Flavours}
  flvNormal     = $00;
  flvHold       = $01;
  flvDirect     = $02;
  flvCrash      = $03;
  flvImmediate  = $04;

{Basetype}
  btNetmail  = $01;
  btEchomail = $02;
  btLocal    = $03;
  btBadmail  = $04;
  btDupemail = $05;

{Echotype}
  etPassThrough = $00;
  etMsg         = $01;
  etJam         = $02;
  etSquish      = $03;
  etSMB         = $04;
  etHudson      = $05;

{Message flags}
  flgNone       = $00000;
  flgPrivate    = $00001;
  flgCrash      = $00002;
  flgReceived   = $00004;
  flgSent       = $00008;
  flgAttach     = $00010;
  flgTransit    = $00020;
  flgOrphan     = $00040;
  flgKill       = $00080;
  flgLocal      = $00100;
  flgHold       = $00200;
  flgFRq        = $00800;
  flgRRq        = $01000;
  flgRRc        = $02000;
  flgARq        = $04000;
  flgURq        = $08000;
  flgLocked     = $10000;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Type

  TEchoType = record
    Storage : byte;
    Path : string;
  end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  TAddress = record
    Zone, Net, Node, Point : integer;
    domain : string[8];
  end;
  PAddress = ^TAddress;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  TAddressCollection = object(TCollection)
    Procedure FreeItem(item:pointer);virtual;
  end;
  PAddressCollection = ^TAddressCollection;

  TAddressSortedCollection = object(TSortedCollection)
    Procedure FreeItem(item:pointer);virtual;
{$IFDEF VER70}
    Function Compare(Key1, Key2: Pointer):Integer;virtual;
{$ELSE}
    Function Compare(Key1, Key2: Pointer):LongInt;virtual;
{$ENDIF}
    Procedure Insert(Item:pointer);virtual;
  end;
  PAddressSortedCollection = ^TAddressSortedCollection;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  TAddressBase = object(TObject)
    MainAddress : PAddress;
    Adresses : PAddressSortedCollection;

    Constructor Init;
    Destructor Done;virtual;

    Procedure AddAddress(const Address:TAddress);
    Procedure GetAddress(N:integer;var Address:TAddress);
    Function FindAddress(Address:TAddress):pointer;
    Procedure FindNearest(Address:TAddress;var NearestAddress:TAddress);
    Procedure GetFrom(A:PCollection);
  end;

  PAddressBase = ^TAddressBase;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

const
  NullAddress :
     TAddress = (Zone : 0; Net : 0; Node : 0; Point : 0; Domain : '');
  InvAddress :
     TAddress = (Zone : -1; Net : -1; Node : -1; Point : -1; Domain : '');

{Pkt Stuff}
Function ftnPktName:string;

{Filebox Stuff}
Function ftnAddressToTBox(const Address:TAddress):string;
Procedure ftnTBoxToAddress(const TBox:string;var Address:TAddress);
Function ftnAddressToTLBox(const Address:TAddress):string;
Procedure ftnTLBoxToAddress(const TLBox:string;var Address:TAddress);

{Address Stuff}
Function ftnAddressCompare(const First,Second:TAddress):longint;

Procedure ftnClearAddress(var Address:TAddress);
Function ftnIsAddressCleared(const Address:TAddress):boolean;
Procedure ftnInvalidateAddress(var Address:TAddress);
Function ftnIsAddressInvalidated(const Address:TAddress):boolean;

Function ftnCheckAddressString(S:string):boolean;

Function ftnStrToAddress(S:string;var Address:TAddress):boolean;
Function ftnAddressToStr(const Address:TAddress):string;
Function ftnAddressToStrPointless(const Address:TAddress):string;
Function ftnAddressToStrEx(const Address:TAddress):string;
Function ftnAddressToStrExDomain(const Address:TAddress):string;

Function ftnNewAddress(const Address:TAddress):PAddress;

Procedure ftnAddressList(const S:PStream;Addresses:PCollection;
         FirstWord:string;ShowZone:boolean;MaxSize:longint);
Procedure ftnParsTechInfo(const S:PStream;const Addresses:PCollection;
         const MainAddress:TAddress);

{Files stuff}
Function ftnIsArcmail(F:string):boolean;
Function ftnSqBundle(const A,B:TAddress):string;

implementation

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{Pkt Stuff}

Var
  LastPacket : string;

Function ftnPktName:string;
Var
  l:longint;
  s:string;
begin
  repeat
    randomize;
    l:=dtmGetDateTimeUnix+random(100)*10;
    s:=strLongToHex(l);
  until s<>LastPacket;

  LastPacket:=s;
  ftnPktName:=s;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{Filebox Stuff}

Function ftnAddressToTBox(const Address:TAddress):string;
begin
  ftnAddressToTBox:='';
  If (Address.Zone=0) or (Address.Net=0) or (Address.Node=0) then exit;

  ftnAddressToTBox:=strPadL(strLongToAny(Address.Zone,32),'0',2)+
    strPadL(strLongToAny(Address.Net,32),'0',3)+
    strPadL(strLongToAny(Address.Node,32),'0',3)+
    '.'+strPadL(strLongToAny(Address.Point,32),'0',2);
end;

Procedure ftnTBoxToAddress(const TBox:string;var Address:TAddress);
begin
  Address.Zone:=strAnyToLong(Copy(TBox,1,2),32);
  Address.Net:=strAnyToLong(Copy(TBox,3,3),32);
  Address.Node:=strAnyToLong(Copy(TBox,6,3),32);
  Address.Point:=strAnyToLong(Copy(TBox,Pos('.',TBox)+1,2),32);
end;

Function ftnAddressToTLBox(const Address:TAddress):string;
begin
  ftnAddressToTLBox:=strIntToStr(Address.Zone)+'.'+
    strIntToStr(Address.Net)+'.'+
    strIntToStr(Address.Node)+'.'+
    strIntToStr(Address.Point);
end;

Procedure ftnTLBoxToAddress(const TLBox:string;var Address:TAddress);
Var
  sTemp : string;
begin
  sTemp:=TLBox;

  sTemp[Pos('.',sTemp)]:=':';
  sTemp[Pos('.',sTemp)]:='/';
  While not (sTemp[byte(sTemp[0])] in ['0'..'9']) do Dec(sTemp[0]);

  ftnStrToAddress(sTemp,Address);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{Address stuff}

Function ftnAddressCompare(const First,Second:TAddress):longint;
begin
  If First.Zone<Second.Zone then ftnAddressCompare:=-1 else
  If First.Zone>Second.Zone then ftnAddressCompare:=1 else
  If First.Net<Second.Net then ftnAddressCompare:=-1 else
  If First.Net>Second.Net then ftnAddressCompare:=1 else
  If First.Node<Second.Node then ftnAddressCompare:=-1 else
  If First.Node>Second.Node then ftnAddressCompare:=1 else
  If First.Point<Second.Point then ftnAddressCompare:=-1 else
  If First.Point>Second.Point then ftnAddressCompare:=1 else
     ftnAddressCompare:=0;
end;

Procedure ftnClearAddress(var Address:TAddress);
begin
  FillChar(Address,SizeOf(Address),#0);
end;

Function ftnIsAddressCleared(const Address:TAddress):boolean;
begin
  ftnIsAddressCleared:=False;

  If (Address.Zone=0)
  and (Address.Net=0)
  and (Address.Node=0)
  and (Address.Point=0)
     then ftnIsAddressCleared:=True;
end;

Procedure ftnInvalidateAddress(var Address:TAddress);
begin
  Address.Zone:=-1;
  Address.Net:=-1;
  Address.Node:=-1;
  Address.Point:=-1;
end;

Function ftnIsAddressInvalidated(const Address:TAddress):boolean;
begin
  ftnIsAddressInvalidated:=False;

  If (Address.Zone=-1)
  and (Address.Net=-1)
  and (Address.Node=-1)
  and (Address.Point=-1)
     then ftnIsAddressInvalidated:=True;
end;

Function ftnCheckAddressString(S:string):boolean;
Var
  i : byte;
begin
  ftnCheckAddressString:=False;

  If S='' then exit;

  If Pos('@',S)<>0 then S[0]:=Chr(Pos('@',S)-1);

  For i:=1 to Length(S) do
      If not (S[i] in AddressChars) then exit;

  ftnCheckAddressString:=True;
end;

{ From wizard.pas by sergey korowkin aka sk (2:6033/27@fidonet)}
Function ftnStrToAddress(S:string;var Address:TAddress):boolean;
Var
  i : byte;
begin
  ftnStrToAddress:=False;

  If not ftnCheckAddressString(S) then exit;

  Address.domain:='';

  If S[1] in ['/', ':'] then Delete(S, 1, 1);

  i:=Pos('@',S);
  If i<>0 then
    begin
      Address.domain:=Copy(S,i+1,Length(S)-i-1);
      S[0]:=Chr(i-1);
    end;

  If Pos(':', S)=0 then
    If Pos('/', S)=0 then
      If Pos('.', S)=1 then
        begin
          Delete(S, 1, 1);

          Address.Point:=strStrToInt(S);
          ftnStrToAddress:=True;
        end
      else
        begin
          Address.Node:=strStrToInt(strParser(S,1,['.']));
          Address.Point:=strStrToInt(strParser(S,2,['.']));
          ftnStrToAddress:=True;
        end
    else
      begin
        Address.Net:=strStrToInt(strParser(S,1, ['/']));
        Address.Node:=strStrToInt(strParser(S,2,['/', '.']));
        Address.Point:=strStrToInt(strParser(S,3,['/', '.']));
        ftnStrToAddress:=True;
      end
  else
    If Pos('/',S)<>0 then
      begin
        Address.Zone:=strStrToInt(strParser(S,1,[':','/', '.']));
        Address.Net:=strStrToInt(strParser(S,2,[':','/', '.']));
        Address.Node:=strStrToInt(strParser(S,3,[':','/', '.']));
        Address.Point:=strStrToInt(strParser(S,4,[':','/', '.']));
        ftnStrToAddress:=True;
      end
    else
      begin
        Address.Zone:=strStrToInt(strParser(S,1, [':','/', '.']));
        Address.Net:=strStrToInt(strParser(S,2,[':','/', '.']));
        ftnStrToAddress:=True;
      end;
end;

Function ftnAddressToStr(const Address:TAddress):string;
begin
  ftnAddressToStr:=strIntToStr(Address.Zone)+':'+
                   strIntToStr(Address.Net)+'/'+
                   strIntToStr(Address.Node)+'.'+
                   strIntToStr(Address.Point);
end;

Function ftnAddressToStrPointless(const Address:TAddress):string;
begin
  ftnAddressToStrPointless:=strIntToStr(Address.Zone)+':'+
                   strIntToStr(Address.Net)+'/'+
                   strIntToStr(Address.Node);
end;

Function ftnAddressToStrEx(const Address:TAddress):string;
begin
  If Address.Point=0 then
      ftnAddressToStrEx:=ftnAddressToStrPointless(Address)
  else
      ftnAddressToStrEx:=ftnAddressToStr(Address);
end;

Function ftnAddressToStrExDomain(const Address:TAddress):string;
Var
  sTemp:string;
begin
  sTemp:=ftnAddressToStrEx(Address);
  ftnAddressToStrExDomain:=sTemp+'@'+Address.Domain;
end;

Function ftnNewAddress(const Address:TAddress):PAddress;
Var
  TempAddress : PAddress;
begin
  TempAddress:=New(PAddress);
  TempAddress^:=Address;
  ftnNewAddress:=TempAddress;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{Address parsing stuff}

Procedure ftnAddressList(const S:PStream;Addresses:PCollection;
         FirstWord:string;ShowZone:boolean;MaxSize:longint);
Var
  sTemp : string;
  sTemp1 : string;
  i:longint;
  TempAddress:PAddress;
  PrevAddress : TAddress;
begin
  objStreamWrite(S,FirstWord);

  PrevAddress.Zone:=-1;
  PrevAddress.Net:=-1;
  PrevAddress.Node:=-1;
  PrevAddress.Point:=-1;

  sTemp1:='';

  For i:=0 to Addresses^.Count-1 do
    begin
      TempAddress:=Addresses^.At(i);
      sTemp:='';

      If ShowZone then
        If TempAddress^.Zone<>PrevAddress.Zone
          then sTemp:=sTemp+strIntToStr(TempAddress^.Zone)+':';

     If (TempAddress^.Net<>PrevAddress.Net)
     or (Length(sTemp)+Length(sTemp1)+
          Length(FirstWord)+Length(strIntToStr(TempAddress^.Net))>75)
       then sTemp:=sTemp+strIntToStr(TempAddress^.Net)+'/';

     If (TempAddress^.Node<>PrevAddress.Node)
       then sTemp:=sTemp+strIntToStr(TempAddress^.Node)
       else If (TempAddress^.Net<>PrevAddress.Net)
       then sTemp:=sTemp+strIntToStr(TempAddress^.Node);

     If (TempAddress^.Point<>PrevAddress.point) and (TempAddress^.Point<>0)
       then sTemp:=sTemp+'.'+strIntToStr(TempAddress^.Point);

     If Length(sTemp)+Length(sTemp1)+Length(FirstWord)>MaxSize then
       begin
         objStreamWrite(S,sTemp1);
         sTemp1:='';
         objStreamWrite(S,#13+FirstWord);
       end;

     sTemp:=sTemp+#32;

     sTemp1:=sTemp1+sTemp;
     PrevAddress:=TempAddress^;
    end;
  objStreamWriteLn(S,sTemp1);
end;

Procedure ftnParsTechInfo(const S:PStream;const Addresses:PCollection;
         const MainAddress:TAddress);
Var
  Size : longint;
  i : word;
  sTemp:string;
  St:string;
  PrevAddress:TAddress;
  TempAddress:PAddress;
begin
  If S=nil then exit;

  S^.Seek(0);

  PrevAddress:=MainAddress;

  Size:=S^.GetSize;
  While S^.GetPos<Size-1 do
    begin
      sTemp:=strTrimR(objStreamReadLn(S),[#32]);

      i:=2;
      St:=strParser(sTemp,i,[#32]);
      While St<>'' do
        begin
          TempAddress:=ftnNewAddress(PrevAddress);

          ftnStrToAddress(St,TempAddress^);
          Addresses^.Insert(TempAddress);

          PrevAddress:=TempAddress^;

          Inc(i);
          St:=strParser(sTemp,i,[#32]);
        end;
    end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{Files stuff}

Function ftnIsArcmail(F:string):boolean;
Var
  i : word;
begin
  ftnIsArcmail:=false;

  F:=Copy(strUpper(F),Length(F)-2,2);

  For i:=0 to 6 do If F=BundleExt[i] then ftnIsArcmail:=true;
end;

Function ftnSqBundle(const A,B:TAddress):string;
begin
  If (A.Point=0) and (B.Point=0) then
    ftnSqBundle:=strPadL(strLongToHex(A.Net-B.Net),'0',4)
      +strPadL(strLongToHex(A.Node-B.Node),'0',4)
  else
    If (A.Point=0) and (B.Point<>0) then
      ftnSqBundle:='0000'+strPadL(strLongToHex(A.Point-B.Point),'0',4)
    else
      If (A.Point<>0) and (B.Point=0) then
        ftnSqBundle:=strPadL(strLongToHex(A.Node-B.Node),'0',4)
          +strPadL(strLongToHex(A.Point-B.Point),'0',4)
      else
        ftnSqBundle:=strPadL(strLongToHex(A.Node-B.Node),'0',4)
          +strPadL(strLongToHex(A.Point-B.Point),'0',4);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TAddressCollection.FreeItem(item:pointer);
Begin
  If Item<>nil then Dispose(PAddress(Item));
End;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Constructor TAddressBase.Init;
begin
  inherited Init;

  Adresses:=New(PAddressSortedCollection,Init($10,$10));
end;

Destructor TAddressBase.Done;
begin
  objDispose(Adresses);

  inherited Done;
end;

Procedure TAddressBase.AddAddress(const Address:TAddress);
Var
  TempAddress : PAddress;
begin
  TempAddress:=New(PAddress);
  TempAddress^:=Address;

  Adresses^.Insert(TempAddress);
  If Adresses^.Count=1 then MainAddress:=TempAddress;
end;

Procedure TAddressBase.GetAddress(N:integer;var Address:TAddress);
Var
  TempAddress : PAddress;
begin
  TempAddress:=Adresses^.At(N);

  If TempAddress=nil then exit;

  Address:=TempAddress^;
end;

Function TAddressBase.FindAddress(Address:TAddress):pointer;
Var
  TempAddress : PAddress;
{$IFDEF VER70}
  i:integer;
{$ELSE}
  i:longint;
{$ENDIF}
begin
  FindAddress:=nil;

  If Adresses^.Search(@Address,i) then FindAddress:=Adresses^.At(i);
end;

Procedure TAddressBase.FindNearest(Address:TAddress;
                     var NearestAddress:TAddress);
Var
  TempAddress : PAddress;
  i:integer;
begin
  ftnInvalidateAddress(NearestAddress);

  for i:=0 to Adresses^.Count-1 do
    begin
      TempAddress:=Adresses^.At(i);

      If TempAddress^.Zone=Address.Zone then
        begin

          If TempAddress^.Net=Address.Net then
            begin
              If TempAddress^.Node=Address.Node
                then
                  begin
                    If (NearestAddress.Node=TempAddress^.Node)
                      and (Nearestaddress.Point=0) and
                      (TempAddress^.Point<>0) then continue;
                    NearestAddress:=TempAddress^
                  end
                else If NearestAddress.Node<>Address.Node
                    then
                     begin
                    If (NearestAddress.Node=TempAddress^.Node)
                      and (Nearestaddress.Point=0) and
                      (TempAddress^.Point<>0) then continue;
                    NearestAddress:=TempAddress^
                  end
            end
            else If NearestAddress.Net<>Address.Net
                then NearestAddress:=TempAddress^;
        end;
    end;

  If ftnIsAddressInvalidated(NearestAddress)
    then
      begin
        NearestAddress:=MainAddress^;
      end;
end;

Procedure TAddressBase.GetFrom(A:PCollection);
Var
  TempAddress : PAddress;
  i:integer;
begin
  For i:=0 to A^.Count-1 do
    begin
      TempAddress:=A^.At(i);
      AddAddress(TempAddress^);
    end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TAddressSortedCollection.FreeItem(Item:pointer);
Begin
  If Item<>nil then Dispose(PAddress(Item));
End;

{$IFDEF VER70}
Function TAddressSortedCollection.Compare(Key1, Key2: Pointer):Integer;
{$ELSE}
Function TAddressSortedCollection.Compare(Key1, Key2: Pointer):LongInt;
{$ENDIF}
begin
  Compare:=ftnAddressCompare(PAddress(Key1)^,PAddress(Key2)^);
end;

Procedure TAddressSortedCollection.Insert(Item:pointer);
Var
  i : longint;
begin
  i:=Count;
  inherited Insert(Item);
  If Count=i then FreeItem(Item);
end;

begin
  LastPacket:='1';
End.
