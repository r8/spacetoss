{
 AMA Stuff for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2002.
}
Unit AMA;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  lng,

  r8ftn,
  r8ama;

Type

  TSpcAMA = object(TAMA)
    Constructor Init;
    Destructor Done;virtual;

    Procedure OpenMessageBase;virtual;
  end;
  PSpcAMA = ^TSpcAMA;

implementation

Uses
  global;

Constructor TSpcAMA.Init;
begin
  inherited Init;
end;

Destructor TSpcAMA.Done;
begin
  inherited Done;
end;

Procedure TSpcAMA.OpenMessageBase;
var
  sTemp : string;
begin
  MessageBase:=EchoQueue^.OpenBase(NetmailArea);
  MessageBase^.SetBaseType(btNetmail);

  If MessageBase=nil then
    begin
      LngFile^.AddVar(NetmailArea^.Name^);
      sTemp:=LngFile^.GetString(LongInt(lngFailedToOpenBase));
      WriteLn(sTemp);
      LogFile^.SendStr(sTemp,'!');
    end;

end;


end.
