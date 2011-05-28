{
 MessageBases Engine stuff.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
}
Unit r8mbe;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  r8mail,
  r8dos,
  r8msg,
  r8sqh,
  r8jam,

  r8str,
  r8objs,

  objects;

const
  mbeCount = 3;
  mbePrefixes : array[0..mbeCount-1] of string[3] = ('MSG','SQH','JAM');

Type

  TMessageBasesEngine = object(TObject)
    Status : longint;

    Constructor Init;
    Destructor  Done; virtual;

    Function OpenBase(const ABase:string):pointer;
    Function CreateBase(const ABase:string):pointer;
    Function OpenOrCreateBase(const ABase:string):pointer;
    Procedure DisposeBase(var Base:PMessageBase);

    Procedure KillMessageBase(const BasePath:string);
    Procedure RenameMessageBase(const BasePath, NewName:string);

    Function CheckPrefix(const APrefix:string):boolean;

    Function BaseExists(const ABase:string):boolean;

    Procedure Reset;
   end;
  PMessageBasesEngine = ^TMessageBasesEngine;

implementation

Constructor TMessageBasesEngine.Init;
begin
  inherited Init;
  Status:=0;
end;

Destructor  TMessageBasesEngine.Done;
begin
  inherited Done;
end;

Function TMessageBasesEngine.OpenBase(const ABase:string):pointer;
Var
  sTemp : string;
  Base : PMessageBase;
begin
  OpenBase:=nil;
  If Status<>0 then exit;

  sTemp:=strUpper(Copy(ABase,1,3));

  If sTemp='MSG' then
    begin
      Base:=New(PMsgBase,Init);
      sTemp:=Copy(ABase,4,Length(ABase)-3);
    end
    else
  If sTemp='SQH' then
    begin
      Base:=New(PSqhBase,Init);
      sTemp:=Copy(ABase,4,Length(ABase)-3);
    end
    else
  If sTemp='JAM' then
    begin
      Base:=New(PJamBase,Init);
      sTemp:=Copy(ABase,4,Length(ABase)-3);
    end
    else exit;

  Base^.Open(sTemp);
  Status:=Base^.Status;

  If Status<>0 then
    begin
      DisposeBase(Base);
      exit;
    end;

  OpenBase:=Base;
end;

Function TMessageBasesEngine.CreateBase(const ABase:string):pointer;
Var
  sTemp : string;
  Base : PMessageBase;
begin
  CreateBase:=nil;
  If Status<>0 then exit;

  sTemp:=strUpper(Copy(ABase,1,3));
  If sTemp='MSG' then
    begin
      Base:=New(PMsgBase,Init);
      sTemp:=Copy(ABase,4,Length(ABase)-3);
    end else
  If sTemp='SQH' then
    begin
      Base:=New(PSqhBase,Init);
      sTemp:=Copy(ABase,4,Length(ABase)-3);
    end
    else
  If sTemp='JAM' then
    begin
      Base:=New(PJamBase,Init);
      sTemp:=Copy(ABase,4,Length(ABase)-3);
    end
    else exit;

  Base^.Create(sTemp);
  Status:=Base^.Status;

  If Status<>0 then
    begin
      DisposeBase(Base);
      exit;
    end;

  CreateBase:=Base;
end;

Function TMessageBasesEngine.OpenOrCreateBase(const ABase:string):pointer;
var
  P:pointer;
begin
  OpenOrCreateBase:=nil;

  P:=OpenBase(ABase);

  If Status=mlBaseLocked then exit;

  Reset;
  If P=nil then P:=CreateBase(ABase);

  OpenOrCreateBase:=P;
end;

Procedure TMessageBasesEngine.DisposeBase(var Base:PMessageBase);
begin
{  If Pointer(Base)=Pointer(HudsonBase)
  then Base:=nil
  else objDispose(Base);}

  objDispose(Base);
end;

Function TMessageBasesEngine.CheckPrefix(const APrefix:string):boolean;
Var
  i : longint;
begin
  CheckPrefix:=True;

  For i:=0 to mbeCount-1 do
    If APrefix=mbePrefixes[i] then exit;

  CheckPrefix:=False;
end;

Procedure TMessageBasesEngine.Reset;
begin
  Status:=0;
end;

Function TMessageBasesEngine.BaseExists(const ABase:string):boolean;
Var
  sTemp : string;
begin
  If Status<>0 then exit;
  BaseExists:=True;

  sTemp:=strUpper(Copy(ABase,1,3));
  If sTemp='MSG' then
    begin
      sTemp:=Copy(ABase,4,Length(ABase)-3);
      If dosDirExists(sTemp) then exit;
    end else
  If sTemp='SQH' then
    begin
      sTemp:=Copy(ABase,4,Length(ABase)-3);
      If dosFileExists(sTemp+'.SQD') then exit;
    end
    else
  If sTemp='JAM' then
    begin
      sTemp:=Copy(ABase,4,Length(ABase)-3);
      If dosFileExists(sTemp+'.JHR') then exit;
    end;

  BaseExists:=False;
end;

Procedure TMessageBasesEngine.KillMessageBase(const BasePath:string);
Var
  sTemp : string;
begin
  sTemp:=strUpper(Copy(BasePath,1,3));

  If sTemp='MSG' then
    begin
      sTemp:=Copy(BasePath,4,Length(BasePath)-3);
    end
  else
  If sTemp='JAM' then
    begin
      sTemp:=Copy(BasePath,4,Length(BasePath)-3);
      dosErase(sTemp+'.JHR');
      dosErase(sTemp+'.JDT');
      dosErase(sTemp+'.JDX');
    end
  else
  If sTemp='SQH' then
    begin
      sTemp:=Copy(BasePath,4,Length(BasePath)-3);
      dosErase(sTemp+'.SQD');
      dosErase(sTemp+'.SQI');
    end else exit;
end;

Procedure TMessageBasesEngine.RenameMessageBase(const BasePath,NewName:string);
Var
  sTemp : string;
begin
  sTemp:=strUpper(Copy(BasePath,1,3));

  If sTemp='MSG' then
    begin
      sTemp:=Copy(BasePath,4,Length(BasePath)-3);
    end
  else
  If sTemp='JAM' then
    begin
      sTemp:=Copy(BasePath,4,Length(BasePath)-3);
      dosRename(sTemp+'.JHR',dosGetPath(sTemp)+'\'+NewName+'.JHR');
      dosRename(sTemp+'.JDT',dosGetPath(sTemp)+'\'+NewName+'.JDT');
      dosRename(sTemp+'.JDX',dosGetPath(sTemp)+'\'+NewName+'.JDX');
      dosRename(sTemp+'.JLR',dosGetPath(sTemp)+'\'+NewName+'.JLR');
    end
  else
  If sTemp='SQH' then
    begin
      sTemp:=Copy(BasePath,4,Length(BasePath)-3);
      dosRename(sTemp+'.SQD',dosGetPath(sTemp)+'\'+NewName+'.SQD');
      dosRename(sTemp+'.SQI',dosGetPath(sTemp)+'\'+NewName+'.SQI');
      dosRename(sTemp+'.SQL',dosGetPath(sTemp)+'\'+NewName+'.SQL');
    end else exit;
end;

end.
