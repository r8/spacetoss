{
 SpaceToss macros.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
}
Unit Macro;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  r8dtm,
  r8ftn,
  r8objs,

  objects;



Type

TMacroModifier = object(TObject)
  Constructor Init;
  Destructor Done;virtual;

  Procedure DoMacros;
  Procedure PutNils;
  Procedure FreeMacros;

  Procedure SetOAddress(const AAddress:TAddress);
  Procedure SetDAddress(const AAddress:TAddress);
  Procedure SetAddress(const AAddress:TAddress);

  Procedure SetAreaName(const S:string);
  Procedure SetAreaDesc(const S:string);

  Procedure SetGroupName(const S:string);
  Procedure SetGroupDesc(const S:string);

  Procedure SetArcName(const S:string);
  Procedure SetCurrentArc(const S:string);

  Procedure SetMode(const S:string);
private
  OAddress,
  DAddress,
  Address,

  GroupName,
  GroupDesc,

  AreaName,
  AreaDesc,

  ArcName,
  CurrentArc,

  Mode : PString;
end;

PMacroModifier = ^TMacroModifier;

implementation
Uses
  global;

Constructor TMacroModifier.Init;
begin
  inherited Init;

  PutNils;
end;

Destructor TMacroModifier.Done;
begin
  FreeMacros;

  inherited Done;
end;

Procedure TMacroModifier.DoMacros;
Var
   DateTime : TDateTime;
begin
  If OAddress<>nil
    then MacroEngine^.ModifyMacro('OADDRESS',OAddress^)
      else MacroEngine^.ModifyMacro('OADDRESS','');
  If DAddress<>nil
    then MacroEngine^.ModifyMacro('DADDRESS',DAddress^)
      else MacroEngine^.ModifyMacro('DADDRESS','');
  If Address<>nil
    then MacroEngine^.ModifyMacro('ADDRESS',Address^)
      else MacroEngine^.ModifyMacro('ADDRESS','');

  If GroupName<>nil
    then MacroEngine^.ModifyMacro('GROUPNAME',GroupName^)
      else MacroEngine^.ModifyMacro('GROUPNAME','');
  If GroupDesc<>nil
    then MacroEngine^.ModifyMacro('GROUPDESC',GroupDesc^)
      else MacroEngine^.ModifyMacro('GROUPDESC','');

  If AreaName<>nil
    then MacroEngine^.ModifyMacro('AREANAME',AreaName^)
      else MacroEngine^.ModifyMacro('AREANAME','');
  If AreaDesc<>nil
    then MacroEngine^.ModifyMacro('AREADESC',AreaDesc^)
      else MacroEngine^.ModifyMacro('AREADESC','');

  If ArcName<>nil
    then MacroEngine^.ModifyMacro('ARCNAME',ArcName^)
      else MacroEngine^.ModifyMacro('ARCNAME','');
  If CurrentArc<>nil
    then MacroEngine^.ModifyMacro('CURRENTARC',CurrentArc^)
      else MacroEngine^.ModifyMacro('CURRENTARC','');

  If Mode<>nil
    then MacroEngine^.ModifyMacro('MODE',Mode^)
      else MacroEngine^.ModifyMacro('MODE','');

  MacroEngine^.ModifyMacro('PID',constPid);

  dtmGetDateTime(DateTime);
  MacroEngine^.ModifyMacro('DATE',dtmDate2String(DateTime,'/',False,False));
  MacroEngine^.ModifyMacro('TIME',dtmTime2String(DateTime,':',False,False));
end;

Procedure TMacroModifier.PutNils;
begin
  OAddress:=nil;
  DAddress:=nil;
  Address:=nil;

  GroupName:=nil;
  GroupDesc:=nil;

  AreaName:=nil;
  AreaDesc:=nil;

  ArcName:=nil;
  CurrentArc:=nil;

  Mode:=nil;
end;

Procedure TMacroModifier.FreeMacros;
begin
  DisposeStr(OAddress);
  DisposeStr(DAddress);
  DisposeStr(Address);

  DisposeStr(GroupName);
  DisposeStr(GroupDesc);

  DisposeStr(AreaName);
  DisposeStr(AreaDesc);

  DisposeStr(ArcName);
  DisposeStr(CurrentArc);

  DisposeStr(Mode);

  PutNils;
end;

Procedure TMacroModifier.SetOAddress(const AAddress:TAddress);
begin
  AssignStr(OAddress,ftnAddressToStrEx(AAddress));
end;

Procedure TMacroModifier.SetDAddress(const AAddress:TAddress);
begin
  AssignStr(DAddress,ftnAddressToStrEx(AAddress));
end;

Procedure TMacroModifier.SetAddress(const AAddress:TAddress);
begin
  AssignStr(Address,ftnAddressToStrEx(AAddress));
end;

Procedure TMacroModifier.SetAreaName(const S:string);
begin
  AssignStr(AreaName,S);
end;

Procedure TMacroModifier.SetAreaDesc(const S:string);
begin
  AssignStr(AreaDesc,S);
end;

Procedure TMacroModifier.SetGroupName(const S:string);
begin
  AssignStr(GroupName,S);
end;

Procedure TMacroModifier.SetGroupDesc(const S:string);
begin
  AssignStr(GroupDesc,S);
end;

Procedure TMacroModifier.SetArcName(const S:string);
begin
  AssignStr(ArcName,S);
end;

Procedure TMacroModifier.SetCurrentArc(const S:string);
begin
  AssignStr(CurrentArc,S);
end;

Procedure TMacroModifier.SetMode(const S:string);
begin
  AssignStr(Mode,S);
end;

end.