{
 ECHOMAIL.JAM Stuff.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
}
Unit eJam;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  r8dos,
  r8str,
  r8crc,
  r8objs,

  objects;

Type

  TeJamItem = record
    Hash    : longint;
    Message : longint;
  end;
  PeJamItem = ^TeJamItem;

  TeJamItemCollection = object(TSortedCollection)
    Procedure FreeItem(Item:pointer);virtual;
{$IFDEF VER70}
    Function Compare(Key1, Key2: Pointer):Integer;virtual;
{$ELSE}
    Function Compare(Key1, Key2: Pointer):LongInt;virtual;
{$ENDIF}
  end;
  PeJamItemCollection = ^TeJamItemCollection;

  TeJam = object(TObject)
    Status : longint;
    FileName : PString;
    Items : PeJamItemCollection;

    Constructor Init(const AFileName:string);
    Destructor  Done; virtual;

    Procedure ParsString(S:string);
    Function FindArea(const S:string):longint;
  end;
  PeJam = ^TeJam;

implementation

Uses
  global,

  areas;

Constructor TeJam.Init(const AFileName:string);
var
  T : text;
  sTemp : string;
begin
  inherited Init;

  Status:=-1;
  FileName:=nil;

  If not dosFileExists(AFileName) then exit;

  Assign(T,AFileName);
{$I-}
  Reset(T);
{$I+}

  If IOResult<>0 then exit;

  Items:=New(PeJamItemCollection,Init($10,$10));
  Items^.Duplicates:=True;

  While not Eof(T) do
    begin
      ReadLn(T,sTemp);
      ParsString(sTemp)
    end;

  Close(T);

  Status:=0;
  FileName:=NewStr(AFileName);
end;

Destructor  TeJam.Done;
begin
  If FileName<>nil then dosErase(FileName^);
  DisposeStr(FileName);
  objDispose(Items);

  inherited Done;
end;

Procedure TeJam.ParsString(S:string);
var
  Base : string;
  Msg : longint;

  P : PArea;
  TempItem : PeJamItem;
begin
  S:=strUpper(S);
  Base:=strParser(S,1,[#32]);

  P:=AreaBase^.FindAreaByBase(Base);
  If P=nil then exit;

  Msg:=strStrToInt(strParser(S,2,[#32]));

  TempItem:=New(PeJamItem);
  TempItem^.Hash:=crcStringCRC32(P^.Name^);
  TempItem^.Message:=Msg;
  Items^.Insert(TempItem);
end;

Procedure TeJamItemCollection.FreeItem(Item:pointer);
begin
  If Item<>nil then Dispose(PeJamItem(Item));
end;

{$IFDEF VER70}
Function TeJamItemCollection.Compare(Key1, Key2: Pointer):Integer;
{$ELSE}
Function TeJamItemCollection.Compare(Key1, Key2: Pointer):LongInt;
{$ENDIF}
Var
  A : PeJamItem absolute Key1;
  B : PeJamItem absolute Key2;
begin
  If A^.Hash>B^.Hash then Compare:=1 else
  If A^.Hash<B^.Hash then Compare:=-1 else
  Compare:=0;
end;

Function TeJam.FindArea(const S:string):longint;
var
  JamItem : TeJamItem;
{$IFDEF VER70}
  i : integer;
{$ELSE}
  i : longint;
{$ENDIF}
begin
  FindArea:=-1;

  JamItem.Hash:=crcStringCRC32(S);
  If Items^.Search(@JamItem,i) then
    begin
      FindArea:=PeJamItem(Items^.At(i))^.Message;
      Items^.AtFree(i);
    end;
end;

end.
