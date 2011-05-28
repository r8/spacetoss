{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit r8ama;

interface

Uses
  dos,
  r8out,
  r8pkt2p,
  r8outcmn,
  r8str,
  r8dos,
  r8ftn,
  r8mail,
  r8mbe,
  objects;

Type

 TAMA = object(TOutbound)
   MessageBase : PMessageBase;
   QueuePath : PString;

   Constructor Init;
   Destructor Done;virtual;

   Function GetOutType:word;virtual;

   Procedure OpenDir(DirName:string);virtual;

   Procedure AddToBundle(FileName:string;FromAddress,ToAddress:TAddress;ArcType:string
       ;Flavour:word;MaxSize:longint);virtual;
   Procedure Attach(FileName:string;FromAddress,ToAddress:TAddress;Flavour:word);virtual;
   Function GetPacket(Address:TAddress;Flavour:word):PPacket2p;virtual;

   Procedure OpenMessageBase;virtual;
 end;

 PAMA = ^TAMA;

implementation

Constructor TAMA.Init;
begin
  inherited Init;

  QueuePath:=nil;
  MessageBase:=nil;
end;

Destructor TAMA.Done;
begin
  DisposeStr(QueuePath);

  inherited Done;
end;

Procedure TAMA.OpenDir(DirName:string);
Var
  i : longint;

  Flavour : word;
  Address : tAddress;
  FileName : string;
begin
  OpenMessageBase;

  If MessageBase=nil then exit;

  OutDir:=NewStr(DirName);

  For i:=1 to MessageBase^.GetCount do
    begin
      MessageBase^.Seek(i);
      MessageBase^.OpenMessage;

      If not MessageBase^.CheckFlag(flgAttach) then
        begin
          MessageBase^.CloseMessage;
          continue;
        end;

      Flavour:=flvNormal;
      If MessageBase^.CheckFlag(flgHold) then Flavour:=flvHold;
      If MessageBase^.CheckFlag(flgCrash) then Flavour:=flvCrash;

      MessageBase^.GetToAddress(Address);
      FileName:=MessageBase^.GetSubj;
      AddToQueue(FileName,Address,Flavour);

      MessageBase^.CloseMessage;
    end;
end;

Procedure TAMA.AddToBundle(FileName:string;FromAddress,ToAddress:TAddress;ArcType:string;
              Flavour:word;MaxSize:longint);
Var
  BundleName:string;
  BExists:boolean;
begin
  Bundlename:=GetBundleName(OutDir^,FromAddress,ToAddress,Flavour,
              BExists,MaxSize);

  If not BExists then
    begin
      OpenMessageBase;

      MessageBase^.CreateMessage(True);

      MessageBase^.SetFlag(flgAttach);
      MessageBase^.SetFlag(flgLocal);
      MessageBase^.SetFlag(flgKill);

      If Flavour=flvHold  then MessageBase^.SetFlag(flgHold);
      If Flavour=flvCrash then MessageBase^.SetFlag(flgCrash);

      MessageBase^.SetToAddress(ToAddress);
      MessageBase^.SetFromAddress(FromAddress);
      MessageBase^.SetTo('SysOp');
      MessageBase^.SetFrom('SpaceToss');

      MessageBase^.SetSubj(BundleName);

      MessageBase^.WriteMessage;
      MessageBase^.CloseMessage;
    end;

  ArcEngine^.Add(BundleName,Filename,ArcType);
end;

Function TAMA.GetOutType:word;
begin
  GetOutType:=outAMA;
end;

Function TAMA.GetPacket(Address:TAddress;Flavour:word):PPacket2p;
Var
  PktName : string;
  TempPacket : PPacket2p;
begin
  If not dosDirExists(QueuePath^)
    then dosMkDir(QueuePath^);

  repeat PktName:=strUpper(QueuePath^+'\'+ftnPktName+'.QQQ')
  until not dosFileExists(PktName);

  TempPacket:=New(PPacket2p,Init);
  TempPacket^.FastOpen:=True;

  TempPacket^.CreateNewPkt(PktName);

  GetPacket:=TempPacket;
end;

Procedure TAMA.Attach(FileName:string;FromAddress,ToAddress:TAddress;Flavour:word);
Var
  sTemp:string;
begin
  sTemp:=OutDir^+'\'+dosGetFileName(FileName);
  dosMove(FileName,sTemp);
  FileName:=sTemp;

  MessageBase^.CreateMessage(True);

  MessageBase^.SetFlag(flgAttach);
  MessageBase^.SetFlag(flgLocal);
  MessageBase^.SetFlag(flgKill);

  If Flavour=flvHold  then MessageBase^.SetFlag(flgHold);
  If Flavour=flvCrash then MessageBase^.SetFlag(flgCrash);

  MessageBase^.SetToAddress(ToAddress);
  MessageBase^.SetFromAddress(FromAddress);
  MessageBase^.SetTo('SysOp');
  MessageBase^.SetFrom('SpaceToss');

  MessageBase^.SetSubj(FileName);

  MessageBase^.WriteMessage;
  MessageBase^.CloseMessage;

  AddToQueue(FileName,ToAddress,Flavour);
end;

Procedure TAMA.OpenMessageBase;
begin
end;

end.
