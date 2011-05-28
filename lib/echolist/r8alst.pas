{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
Unit r8alst;

interface

Uses
  r8objs,
  objects;

const
  ltNone      = $00;
  ltEcholist  = $01;
  ltBCL       = $02;
  ltFastecho  = $03;
  ltxOfcElist = $04;
  ltSquish    = $05;
  ltUnknown   = $10;

  alstOk            = $00000000;
  alstCantOpenFile  = $00000001;

Type

  TEArealistItem = object(TObject)
    AreaName : PString;
    AreaDesc : PString;

    Constructor Init(const _Name, _Desc : string);
    Destructor Done;virtual;
  end;
  PEArealistItem = ^TEArealistItem;

  TListAreasCollection = object(TSortedCollection)
    Procedure FreeItem(Item:pointer);virtual;
{$IFDEF VER70}
    Function Compare(Key1, Key2: Pointer):Integer;virtual;
{$ELSE}
    Function Compare(Key1, Key2: Pointer):LongInt;virtual;
{$ENDIF}
  end;
  PListAreasCollection = ^TListAreasCollection;

  TArealist = object(TObject)
    Status : longint;

    FileName : PString;
    ListAreas : PListAreasCollection;

    Constructor Init;
    Destructor Done;virtual;

    Procedure SetFileName(const _FileName:string);

    Procedure Read;virtual;
    Function FindArea(S:String):longint;
    Function GetDesc(Name:string):string;
  end;
  PArealist = ^TArealist;

implementation

Constructor TEArealistItem.Init(const _Name, _Desc : string);
begin
  inherited Init;

  AreaName:=NewStr(_Name);
  AreaDesc:=NewStr(_Desc);
end;

Destructor TEArealistItem.Done;
begin
  DisposeStr(AreaName);
  DisposeStr(AreaDesc);

  inherited Done;
end;

Procedure TListAreasCollection.FreeItem(Item:pointer);
begin
  objDispose(PEArealistItem(Item));
end;

{$IFDEF VER70}
Function TListAreasCollection.Compare(Key1, Key2: Pointer):Integer;
{$ELSE}
Function TListAreasCollection.Compare(Key1, Key2: Pointer):LongInt;
{$ENDIF}
Var
  S1,S2:String;
begin
  S1:=PEAreaListItem(Key1)^.AreaName^;
  S2:=PEAreaListItem(Key2)^.AreaName^;

  If S1>S2 then Compare:=1 else
  If S1<S2 then Compare:=-1 else
  Compare:=0;
end;

Constructor TArealist.Init;
begin
  inherited Init;

  FileName:=nil;
  Status:=alstOk;

  ListAreas:=New(PListAreasCollection,Init($100,$100));
end;

Destructor TArealist.Done;
begin
  DisposeStr(FileName);
  objDispose(ListAreas);

  inherited Done;
end;

Procedure TArealist.SetFileName(const _FileName:string);
begin
  DisposeStr(FileName);

  FileName:=NewStr(_FileName);
end;

Procedure TArealist.Read;
begin
  Abstract;
end;

Function TArealist.FindArea(S:String):longint;
Var
  TempAreaItem : PEAreaListItem;

{$IFDEF VER70}
  i : integer;
{$ELSE}
  i : longint;
{$ENDIF}
begin
  FindArea:=-1;

  TempAreaItem:=New(PEAreaListItem,Init(S,' '));
  If ListAreas^.Search(TempAreaItem,i) then FindArea:=i;

  objDispose(TempAreaItem);
end;

Function TArealist.GetDesc(Name:string):string;
var
  i : integer;
  TempArea : PEAreaListItem;
begin
  GetDesc:='';

  i:=FindArea(Name);
  If i=-1 then exit;

  TempArea:=ListAreas^.At(i);
  GetDesc:=TempArea^.AreaDesc^;
end;

end.
