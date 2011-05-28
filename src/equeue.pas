{
 EchoQueue Stuff for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
}
Unit EQueue;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  areas,
  lng,

  r8str,
  r8objs,
  r8ftn,

  dos,
  objects;

type

  TEchoQueue = object(TObject)
    Echoes : PAreaCollection;

    Constructor Init;
    Destructor Done;virtual;
    Function OpenBase(const Area:PArea):pointer;
    Procedure CloseLastBase;
    Procedure CloseBases;
  end;
  PEchoQueue = ^TEchoQueue;

implementation

Uses
  global;

Constructor TEchoQueue.Init;
begin
  inherited Init;

  Echoes:=New(PAreaCollection,Init($20,$20));
end;

Destructor TEchoQueue.Done;
begin
  LngFile^.AddVar(strintToStr(Echoes^.Count));
  LogFile^.SendStr(LngFile^.GetString(LongInt(lngClosingBases)),'#');

  CloseBases;

  objDispose(Echoes);

  inherited Done;
end;

Function TEchoQueue.OpenBase(const Area:PArea):pointer;
begin
  OpenBase:=nil;

  If Area^.MessageBase<>nil then
    begin
      OpenBase:=Area^.MessageBase;
      exit;
    end;

  While true do
    begin
      Area^.MessageBase:=MessageBasesEngine^.OpenOrCreateBase(Area^.Echotype.Path);
      If Area^.MessageBase<>nil then break;
      MessageBasesEngine^.Reset;
      If (DosError<>4) or (Echoes^.Count=0) then exit;
      CloseLastBase;
    end;

  Area^.MessageBase^.SetBaseType(btEchomail);
  Echoes^.Insert(Area);
  OpenBase:=Area^.MessageBase;
end;

Procedure TEchoQueue.CloseLastBase;
begin
  MessageBasesEngine^.DisposeBase(PArea(Echoes^.At(Echoes^.Count-1))^.MessageBase);
  Echoes^.AtDelete(Echoes^.Count-1);
end;

Procedure TEchoQueue.CloseBases;
begin
  Echoes^.CloseBases;
  Echoes^.DeleteAll;
end;

end.
