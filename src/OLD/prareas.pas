Unit PrAreas;

interface

Uses
  r8str,
  crt;

Var
  Max : integer;
  Now : integer;
  Counter : integer;

Procedure ProcessStart(AreaName:string;NumbOfMsgs:integer);
Procedure ProcessInc;
Procedure ProcessStop(S:string);

implementation

Procedure ProcessStart(AreaName:string;NumbOfMsgs:integer);
begin
  GotoXY(1,WhereY);
  TextColor(7);
  Write(' ');
  Write(strPadRight(AreaName,'ù',39));
  Write(' [                     ]');
  Counter:=0;
  Max:=NumbOfMsgs;
  Now:=0;
  GotoXY(43,WhereY);
  TextColor(10);
end;

Procedure ProcessInc;
Var
  i : integer;
  i2 : integer;
begin
  Inc(Counter);

  i2:=Trunc(20 / Max * Counter);
  If i2<>Now then
    begin
      Write('*');
      Now:=i2;
    end;
end;

Procedure ProcessStop(S:string);
begin
  TextColor(7);
  GotoXY(42,WhereY);
  WriteLn(strPadRight(S,#32,30));
end;

end.