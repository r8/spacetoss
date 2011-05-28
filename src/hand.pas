Unit Hand;

interface

Procedure DoHand;

implementation
Uses
  nodes,
  lng,
  r8ftn,
  r8str,
  objects,
  regexp,
  global;

Var
  P:Pointer;

Procedure DoHand;

  Procedure CheckNode(P:Pointer);far;
  Var
    LinkAddress : PString;
    i : integer;
    Command : String;
    StringAddress : string;
    StringAddressFull : string;
  begin
    StringAddressFull:=ftnAddressToStr(PNode(P)^.Address);
    StringAddress:=ftnAddressToStrEx(PNode(P)^.Address);
    Command:=PString(ParamString^.Parameters^.At(ParamString^.Parameters^.Count-1))^;

    i:=Pos('#', Command);
    While i<>0 do
      begin
        Command[i]:='%';
        i:=Pos('#', Command);
      end;

     For i:=0 to ParamString^.Parameters^.Count-2 do
      begin
        LinkAddress:=ParamString^.Parameters^.At(i);

        If (GrepCheck(StringAddressFull,LinkAddress^,False)) or
          (GrepCheck(StringAddress,LinkAddress^,False))
             then  Areafix^.CreateMessage(P,Command);
      end;

  end;

begin
  If ParamString^.Parameters^.Count<2
     then ErrorOut(LngFile^.GetString(LongInt(lngIncorrectNumberofParams)));

  NodeBase^.Nodes^.ForEach(@CheckNode);

  P:=Areafix^.CopyBase;
  Areafix^.CopyBase:=nil;
  Areafix^.ScanNetmail;
  Areafix^.CopyBase:=P;
end;

end.