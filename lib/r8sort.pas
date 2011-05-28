{
 Sorting Stuff.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
}
Unit r8sort;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  objects,
  r8str,
  r8objs,
  r8ftn;

Type

  TCompareFunc = Function (f,s:pointer):longint;

Procedure srtSort(First,Last:longint;Data:PCollection;
     srtCompare:TCompareFunc);

implementation

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

end.