{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit r8dsk;

interface

Uses
  dos,
  r8out,
  r8pkt2p,
  r8outcmn,
  r8str,
  r8dos,
  r8ftn,
  r8mbe,
  objects;

Type

 TDiskPoll = object(TOutbound)
   Constructor Init;
   Destructor Done;virtual;

   Function GetOutType:word;virtual;

   Procedure OpenDir(DirName:string);virtual;

   Procedure AddToBundle(FileName:string;FromAddress,ToAddress:TAddress;ArcType:string
       ;Flavour:word;MaxSize:longint);virtual;
   Procedure Attach(FileName:string;FromAddress,ToAddress:TAddress;Flavour:word);virtual;
   Function GetPacket(Address:TAddress;Flavour:word):PPacket2p;virtual;
 end;

 PDiskPoll = ^TDiskPoll;

implementation

Constructor TDiskPoll.Init;
begin
  inherited Init;
end;

Destructor TDiskPoll.Done;
begin
  inherited Done;
end;

Procedure TDiskPoll.OpenDir(DirName:string);
Var
  SR:SearchRec;
  sTemp:string;
begin
  OutDir:=NewStr(DirName);

  FindFirst(DirName+'\*.*',AnyFile-Directory,SR);
  While DosError=0 do
    begin
      sTemp:=DirName+'\'+SR.Name;
      AddToQueue(sTemp,NullAddress,flvNormal);
      FindNext(SR);
    end;
{$IFNDEF VER70}
  FindClose(SR);
{$ENDIF}
end;

Procedure TDiskPoll.AddToBundle(FileName:string;FromAddress,ToAddress:TAddress;ArcType:string;
              Flavour:word;MaxSize:longint);
Var
  BundleName:string;
  BExists:boolean;
begin
  Bundlename:=GetBundleName(OutDir^,FromAddress,ToAddress,flvNormal,
              BExists,MaxSize);

  ArcEngine^.Add(BundleName,Filename,ArcType);
end;

Function TDiskPoll.GetOutType:word;
begin
  GetOutType:=outDiskPoll;
end;

Function TDiskPoll.GetPacket(Address:TAddress;Flavour:word):PPacket2p;
Var
  PktName : string;
  TempPacket : PPacket2p;
begin
  If not dosDirExists(OutDir^)
    then dosMkDir(OutDir^);

  repeat PktName:=strUpper(OutDir^+'\'+ftnPktName+'.PKT')
  until not dosFileExists(PktName);

  TempPacket:=New(PPacket2p,Init);
  TempPacket^.FastOpen:=True;

  TempPacket^.CreateNewPkt(PktName);

  GetPacket:=TempPacket;
end;

Procedure TDISKPOLL.Attach(FileName:string;FromAddress,ToAddress:TAddress;Flavour:word);
Var
  sTemp:string;
begin
  sTemp:=OutDir^+'\'+dosGetFileName(FileName);
  dosMove(FileName,sTemp);
  FileName:=sTemp;

  AddToQueue(FileName,ToAddress,Flavour);
end;

end.
