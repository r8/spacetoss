{
 Areafix ModeSaver for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
}
Unit ModSav;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
  {$PackRecords 1}
{$ENDIF}

interface

Uses
  r8ftn,
  r8dos,
  r8objs,

  objects;

const
  constModSavSig = 'r8ms';


Type

  TModeElement = record
    Address  : TAddress;
    AreaName : string[50];
    Mode     : word;
  end;
  PModeElement = ^TModeElement;

  TModeCollection = object(TSortedCollection)
    Procedure FreeItem(Item:pointer);virtual;
{$IFDEF VER70}
    Function Compare(Key1, Key2: Pointer):Integer;virtual;
{$ELSE}
    Function Compare(Key1, Key2: Pointer):LongInt;virtual;
{$ENDIF}
  end;
  PModeCollection = ^TModeCollection;

  TModeSaver = object(TObject)
    FileName : PString;
    ModeCollection : PModeCollection;

    Constructor Init(const AFileName : string);
    Destructor  Done; virtual;

    Procedure AddMode(const Address:TAddress;const Area:string;const Mode:word);
    Function GetMode(const Address:TAddress;const Area:string):word;
  end;
  PModeSaver = ^TModeSaver;

implementation

Uses
  areas;

Constructor TModeSaver.Init(const AFileName : string);
Var
  F : PBufStream;
  i : longint;
  Sig : string[4];
  TempMode : PModeElement;
begin
  inherited Init;

  ModeCollection:=New(PModeCollection,Init($10,$10));

  FileName:=NewStr(AFileName);

  If not dosFileExists(AFileName) then exit;

  F:=New(PBufStream,Init(FileName^,fmOpen or fmRead or fmDenyAll,cBuffSize));

  i:=F^.GetSize;

  F^.Read(Sig,SizeOf(Sig));
  If Sig<>constModSavSig then
    begin
      objDispose(F);
      exit;
    end;

  While F^.GetPos<i-1 do
    begin
      TempMode:=New(PModeElement);
      F^.Read(TempMode^,SizeOf(TempMode^));
      ModeCollection^.Insert(TempMode);
    end;

  objDispose(F);
end;

Destructor  TModeSaver.Done;
Var
  F : PBufStream;
  Sig : string[4];
  TempMode : PModeElement;

  Procedure WriteMode(P:pointer);far;
  begin
    F^.Write(PModeElement(P)^,SizeOf(TModeElement));
  end;
begin
  dosErase(FileName^);

  If ModeCollection^.Count>0 then
    begin
      F:=New(PBufStream,Init(FileName^,fmCreate or fmWrite or fmDenyAll,
           cBuffSize));

      Sig:=constModSavSig;
      F^.Write(Sig,SizeOf(Sig));

      ModeCollection^.ForEach(@WriteMode);
      objDispose(F);
    end;

  DisposeStr(FileName);
  objDispose(ModeCollection);

  inherited Done;
end;

Procedure TModeSaver.AddMode(const Address:TAddress;const Area:string;const Mode:word);
var
  TempMode : PModeElement;
{$IFDEF VER70}
  i : integer;
{$ELSE}
  i : longint;
{$ENDIF}
begin
  TempMode:=New(PModeElement);

  TempMode^.Address:=Address;
  TempMode^.AreaName:=Area;
  TempMode^.Mode:=Mode;

  If ModeCollection^.Search(TempMode,i)
    then ModeCollection^.AtFree(i);
  ModeCollection^.AtInsert(i,TempMode);
end;

Function TModeSaver.GetMode(const Address:TAddress;const Area:string):word;
var
  TempMode : PModeElement;
{$IFDEF VER70}
  i : integer;
{$ELSE}
  i : longint;
{$ENDIF}
begin
  TempMode:=New(PModeElement);

  TempMode^.Address:=Address;
  TempMode^.AreaName:=Area;

  GetMode:=modWrite+modRead;

  If ModeCollection^.Search(TempMode,i) then
    begin
      GetMode:=PModeElement(ModeCollection^.At(i))^.Mode;
      ModeCollection^.AtFree(i);
    end;

  Dispose(TempMode);
end;

{$IFDEF VER70}
Function TModeCollection.Compare(Key1, Key2: Pointer):Integer;
{$ELSE}
Function TModeCollection.Compare(Key1, Key2: Pointer):LongInt;
{$ENDIF}
Var
  A : PModeElement absolute Key1;
  B : PModeElement absolute Key2;
{$IFDEF VER70}
  i : integer;
{$ELSE}
  i : longint;
{$ENDIF}
begin
  i:=ftnAddressCompare(A^.Address,B^.Address);

  If i<>0 then Compare:=i else
    If A^.AreaName>B^.AreaName then Compare:=1 else
    If A^.AreaName<B^.AreaName then Compare:=-1 else
    Compare:=0;
end;

Procedure TModeCollection.FreeItem(Item:pointer);
begin
  If Item<>nil then Dispose(PModeElement(Item));
end;

end.