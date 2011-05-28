{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
{$F+}
Unit Sort;

interface

Uses
  objects,
  r8str,
  r8objs,
  r8ftn;

Type
  TCompareFunc = Function (f,s:pointer):integer;

Procedure srtSort(First,Last:longint;Data:PCollection;
   srtCompare:TCompareFunc);

Function srtCompareLInts(f,s:pointer):integer;
Function srtCompareAreas(f,s:pointer):integer;
Function srtCompareNodes(f,s:pointer):integer;
Function srtCompareNodelists(f,s:pointer):integer;
Function srtCompareAddr(f,s:pointer):integer;
Function srtCompareAddr2D(f,s:pointer):integer;

Function srtCompareStrings(f,s:string):integer;
Function srtCompareAddresses(f,s:TAddress):integer;

implementation
Uses
  nodes,
  areas;

Procedure srtSort(First,Last:longint;Data:PCollection;
   srtCompare:TCompareFunc);
Var
  i,j : longint;
  FP, SP, TP, TP2 : pointer;
begin
  i:=First;
  j:=Last;

  FP:=Data^.At((First+Last)div 2);

  repeat

    TP:=Data^.At(i);
    While srtCompare(TP,FP)=-1 do
      begin
       Inc(i);
       TP:=Data^.At(i);
      end;

    TP:=Data^.At(j);
    While srtCompare(TP,FP)=1 do
      begin
       Dec(j);
       TP:=Data^.At(j);
      end;

    If i<=j then
     begin
       SP:=Data^.At(i);

       TP:=Data^.At(i);
       TP2:=Data^.At(j);
       Data^.AtDelete(i);
       Data^.AtInsert(i,TP2);

       Data^.AtDelete(j);
       Data^.AtInsert(j,SP);

       Inc (i);
       Dec (j);
     end;

  until i>j;

  If j>First then srtSort(First,j,Data,srtCompare);
  If i<Last then srtSort(i,Last,Data,srtCompare);
end;

Function srtCompareLInts(f,s:pointer):integer;
begin
  If PLongint(F)^>PLongint(S)^ Then srtCompareLInts:=1;
  If PLongint(F)^<PLongint(S)^ Then srtCompareLInts:=-1;
  If PLongint(F)^=PLongint(S)^ Then srtCompareLInts:=0;
end;

Function srtCompareAreas(f,s:pointer):integer;
begin
  srtCompareAreas:=srtCompareStrings(PArea(F)^.Name^,PArea(S)^.Name^);
end;

Function srtCompareNodes(f,s:pointer):integer;
begin
  srtCompareNodes:=srtCompareAddresses(PNode(F)^.Address,PNode(S)^.Address);
end;

Function srtCompareNodelists(f,s:pointer):integer;
Var
  FP, SP : Pointer;
begin
  FP:=PNodelistItem(F)^.Node;
  SP:=PNodelistItem(S)^.Node;

  srtCompareNodelists:=srtCompareAddresses(PNode(FP)^.Address,
                PNode(SP)^.Address);
end;

Function srtCompareAddr(f,s:pointer):integer;
begin
  srtCompareAddr:=srtCompareAddresses(PAddress(F)^,PAddress(S)^);
end;

Function srtCompareAddr2D(f,s:pointer):integer;
var
 A1,A2 : tAddress;
begin
  A1:=PAddress(F)^;
  A2:=PAddress(S)^;
  A1.Zone:=0;
  A2.Zone:=0;
  srtCompareAddr2D:=srtCompareAddresses(A1,A2);
end;

Function srtCompareStrings(f,s:string):integer;
var
 i:integer;
begin
  f:=strUpper(f);
  s:=strUpper(s);

  srtCompareStrings:=0;

  If f=s then exit;

  i:=1;
  While f[i]=s[i] do inc(i);

  If Ord(F[i])>Ord(S[i]) then srtCompareStrings:=1;
  If Ord(F[i])<Ord(S[i]) then srtCompareStrings:=-1;
end;

Function srtCompareAddresses(f,s:TAddress):integer;
begin
  If F.Zone<S.Zone then srtCompareAddresses:=-1 else
  If F.Zone>S.Zone then srtCompareAddresses:=1 else
  If F.Net<S.Net then srtCompareAddresses:=-1 else
  If F.Net>S.Net then srtCompareAddresses:=1 else
  If F.Node<S.Node then srtCompareAddresses:=-1 else
  If F.Node>S.Node then srtCompareAddresses:=1 else
  If F.Point<S.Point then srtCompareAddresses:=-1 else
  If F.Point>S.Point then srtCompareAddresses:=1 else
     srtCompareAddresses:=0;
end;

end.
