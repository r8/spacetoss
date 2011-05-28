{
 ProgressBar Stuff for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
}
Unit PrBar;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  r8str,
  crt;

Var
  Max : longint;
  Now : longint;
  Counter : longint;

Procedure ProcessStart(const AreaName:string;const NumbOfMsgs:longint);
Procedure ProcessInc;
Procedure ProcessStop(const S:string);

implementation

Procedure ProcessStart(const AreaName:string;const NumbOfMsgs:longint);
begin
  GotoXY(1,WhereY);
  TextColor(7);
  Write(' ');
  Write(strPadR(AreaName,'ù',39));
  Write(' [                     ]');
  Counter:=0;
  Max:=NumbOfMsgs;
  Now:=0;
  GotoXY(43,WhereY);
  TextColor(10);
end;

Procedure ProcessInc;
Var
  i : longint;
  i2 : longint;
begin
  Inc(Counter);

  i2:=Trunc(20 / Max * Counter);
  If i2<>Now then
    begin
      Write('*');
      Now:=i2;
    end;
end;

Procedure ProcessStop(const S:string);
begin
  TextColor(7);
  GotoXY(42,WhereY);
  WriteLn(strPadR(S,#32,30));
end;

end.