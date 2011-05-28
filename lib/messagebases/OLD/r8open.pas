{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit r8open;

interface

Uses
  r8str,
  r8msg,
  r8dos,
  r8jam,
  r8smb,
  r8sqh,
  r8hud,
  r8objs,
  r8mail;

Var
  HudsonBase : PHudsonBase;
  HudsonPath : string;

Function OpenMessageBase(BasePath:string;var Base:PMessageBase):boolean;
Function OpenOrCreateMessageBase(BasePath:string;var Base:PMessageBase):boolean;

Procedure KillMessageBase(BasePath:string);
Procedure RenameMessageBase(BasePath:string;NewName:string);

Procedure DisposeBase(Base:PMessageBase);

implementation

Function OpenMessageBase(BasePath:string;var Base:PMessageBase):boolean;
Var
  sTemp : string;
begin
  OpenMessageBase:=False;

  sTemp:=strUpper(Copy(BasePath,1,3));

  If sTemp='MSG' then
    begin
      Base:=New(PMsgBase,Init);
      sTemp:=Copy(BasePath,4,Length(BasePath)-3);
    end
  else
  If sTemp='JAM' then
    begin
      Base:=New(PJamBase,Init);
      sTemp:=Copy(BasePath,4,Length(BasePath)-3);
    end
  else
  If sTemp='SQH' then
    begin
      Base:=New(PSqhBase,Init);
      sTemp:=Copy(BasePath,4,Length(BasePath)-3);
    end
  else
  If sTemp='SMB' then
    begin
      Base:=New(PSmbBase,Init);
      sTemp:=Copy(BasePath,4,Length(BasePath)-3);
    end
  else

  If sTemp='HUD' then
    begin

      If HudsonBase=nil then
        begin
          HudsonBase:=New(PHudsonBase,Init);
          If not HudsonBase^.OpenHudsonBase(HudsonPath) then
            begin
              objDispose(HudsonBase);
              Base:=HudsonBase;
              exit;
            end;
        end;

      Base:=HudsonBase;
      sTemp:=Copy(BasePath,4,Length(BasePath)-3);

      If not Base^.OpenBase(sTemp) then exit;

      OpenMessageBase:=True;
      Exit
    end
  else
    begin
      objDispose(Base);
      exit;
    end;

  If not Base^.OpenBase(sTemp) then
    begin
      objDispose(Base);
      exit;
    end;

  OpenMessageBase:=True;
end;

Function CreateMessageBase(BasePath:string;var Base:PMessageBase):boolean;
Var
  sTemp : string;
begin
  CreateMessageBase:=False;

  sTemp:=strUpper(Copy(BasePath,1,3));

  If sTemp='MSG' then
    begin
      Base:=New(PMsgBase,Init);
      sTemp:=Copy(BasePath,4,Length(BasePath)-3);
    end
    else
  If sTemp='JAM' then
    begin
      Base:=New(PJamBase,Init);
      sTemp:=Copy(BasePath,4,Length(BasePath)-3);
    end
  else
  If sTemp='SQH' then
    begin
      Base:=New(PSqhBase,Init);
      sTemp:=Copy(BasePath,4,Length(BasePath)-3);
    end
  else
  If sTemp='SMB' then
    begin
      Base:=New(PSmbBase,Init);
      sTemp:=Copy(BasePath,4,Length(BasePath)-3);
    end
  else
  If sTemp='HUD' then
    begin

      If HudsonBase=nil then
        begin
          HudsonBase:=New(PHudsonBase,Init);
          If not HudsonBase^.CreateHudsonBase(HudsonPath) then
            begin
              objDispose(HudsonBase);
              Base:=HudsonBase;
              exit;
            end;
        end;

      Base:=HudsonBase;

      sTemp:=Copy(BasePath,4,Length(BasePath)-3);

      If not Base^.OpenBase(sTemp) then exit;

      CreateMessageBase:=True;
      Exit
    end
  else
    begin
      objDispose(Base);
      exit;
    end;

  If not Base^.CreateBase(sTemp) then
    begin
      objDispose(Base);
      exit;
    end;

  CreateMessageBase:=True;
end;

Function OpenOrCreateMessageBase(BasePath:string;var Base:PMessageBase):boolean;
Var
  bTemp:boolean;
begin
  bTemp:=OpenMessageBase(BasePath,Base);
  If Not bTemp then bTemp:=CreateMessageBase(BasePath,Base);
  OpenOrCreateMessageBase:=bTemp;
end;

Procedure KillMessageBase(BasePath:string);
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

Procedure RenameMessageBase(BasePath:string;NewName:string);
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
    end
  else
  If sTemp='SQH' then
    begin
      sTemp:=Copy(BasePath,4,Length(BasePath)-3);
      dosRename(sTemp+'.SQD',dosGetPath(sTemp)+'\'+NewName+'.SQD');
      dosRename(sTemp+'.SQI',dosGetPath(sTemp)+'\'+NewName+'.SQI');
    end else exit;
end;

Procedure DisposeBase(Base:PMessageBase);
begin
  If Pointer(Base)=Pointer(HudsonBase)
  then Base:=nil
  else objDispose(Base);
end;

begin
  HudsonBase:=nil;
end.