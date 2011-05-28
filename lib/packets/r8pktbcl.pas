{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
  {$PackRecords 1}
{$ENDIF}
Unit r8PktBCL;

interface
Uses
  objects,
  r8objs,

  r8ftn,
  r8bcl,
  r8pkt;

Type

  TPacketBCL = object(TPacket)
    BCLFile : PBCL;

    Constructor Init;
    Destructor Done;virtual;

    Procedure OpenPkt(Pkt:string);virtual;
    Procedure ClosePkt;virtual;

    Procedure GetToAddress(var Address:TAddress);virtual;
    Procedure GetFromAddress(var Address:TAddress);virtual;
  end;
  PPacketBCL = ^TPacketBCL;

{ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ}

implementation

{ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ}

Constructor TPacketBCL.Init;
begin
  inherited Init;
end;

Destructor TPacketBCL.Done;
begin
  inherited Done;
end;

Procedure TPacketBCL.OpenPkt(Pkt:string);
begin
  BCLFile:=New(PBCL,Init);

  BCLFile^.SetFileName(Pkt);
  BCLFile^.Read;
end;

Procedure TPacketBCL.ClosePkt;
begin
  objDispose(BCLFile);
end;

Procedure TPacketBCL.GetToAddress(var Address:TAddress);
begin
  BCLFile^.GetAddressDest(Address);
end;

Procedure TPacketBCL.GetFromAddress(var Address:TAddress);
begin
  BCLFile^.GetAddress(Address);
end;

end.
