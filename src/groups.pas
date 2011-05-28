{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit Groups;

interface

Uses
  r8objs,
  areas;

Type

  TGroup = object(TArea)
    EchoDesc : string[100];

    ItemBase : PAreaBase;

    Constructor Init(_Name:string);
    Destructor Done;virtual;
  end;

  PGroup = ^TGroup;

  TGroupBase = object(TAreaBase)
    Constructor Init;
    Destructor Done;virtual;
  end;

  PGroupBase = ^TGroupBase;

implementation

Constructor TGroup.Init(_Name:string);
Var
  S : string[1];
begin
  S:=_Name;
  inherited Init(S);

  ItemBase:=New(PAreaBase,Init);
end;

Destructor TGroup.Done;
begin
  ItemBase^.Areas^.DeleteAll;
  objDispose(ItemBase);

  inherited Done;
end;

Constructor TGroupBase.Init;
begin
  inherited Init;
end;

Destructor TGroupBase.Done;
begin
  inherited Done;
end;

end.