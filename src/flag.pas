{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
Unit Flag;

interface
Uses
  global,
  crt,
  r8dos;

Procedure OpenFlag;
Procedure CloseFlag;

implementation

Procedure OpenFlag;
Var
  f:text;
  Opened : boolean;
begin
  Opened:=False;

  If dosFileExists(HomeDir+'\spctoss.bsy') then
    begin
      TextColor(7);
      WriteLn;
      Writeln('Another copy of spctoss or spctool is running');
      FreeObjects;
      Opened:=True;
    end;

  Assign(f,HomeDir+'\spctoss.bsy');
  Rewrite(f);
  Close(f);

  If Opened then Halt(1);
end;

Procedure CloseFlag;
begin
  dosErase(HomeDir+'\spctoss.bsy');
end;

end.