{
 Netmail Stuff for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2002.
}
Unit Netmail;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  objects;

type

  TNetmailManager = object(TObject)
    Constructor Init;
    Destructor Done;virtual;

    Procedure DoImport;
    Procedure DoExport;
  end;
  PNetmailManager = ^TNetmailManager;

implementation

Constructor TNetmailManager.Init;
begin
  inherited Init;
end;

Destructor TNetmailManager.Done;
begin
  inherited Done;
end;

Procedure TNetmailManager.DoImport;
begin
end;

Procedure TNetmailManager.DoExport;
begin
end;

begin
end.