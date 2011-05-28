{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit r8bso;

interface

Uses
  dos,
  r8out,
  r8pkt2p,
  r8outcmn,
  r8str,
  r8dos,
  r8ftn,
  objects;

Type

 TBSO = object(TOutbound)
   DefZone:Word;

   Constructor Init;
   Destructor Done;virtual;

   Function GetOutType:word;virtual;

   Procedure OpenDir(DirName:string);virtual;
   Procedure SetDefZone(DefZ:word);virtual;

   Procedure ScanZone(DirName:string;Zone:word);
   Procedure ScanNode(DirName:string;Zone,Net,Node:word);

   Procedure ParsLo(LoName:string;Address:TAddress);

   Procedure AddToBundle(FileName:string;FromAddress,ToAddress:TAddress;ArcType:string
       ;Flavour:word;MaxSize:longint);virtual;
   Procedure Attach(FileName:string;FromAddress,ToAddress:TAddress;Flavour:word);virtual;

   Function GetPacket(Address:TAddress;Flavour:word):PPacket2p;virtual;

   Procedure SetBusy(Address:TAddress);virtual;
   Procedure RemoveBusy(Address:TAddress);virtual;
   Function GetBusy(Address:TAddress):boolean;virtual;
 end;

 PBSO = ^TBSO;

implementation

Constructor TBSO.Init;
begin
  inherited Init;
end;

Destructor TBSO.Done;
begin
  inherited Done;
end;

Procedure TBSO.ParsLo(LoName:string;Address:TAddress);
var
 T:text;
 Flavour : word;
 sTemp:string;
begin
  Case LoName[Length(LoName)-2] of
    'H' : Flavour:=flvHold;
    'F' : Flavour:=flvNormal;
    'D' : Flavour:=flvDirect;
    'C' : Flavour:=flvCrash;
   else exit;
   end;
  Assign(T,LoName);
  Reset(T);

  While not Eof(T) do
    begin
      ReadLn(T,sTemp);
      If (sTemp[1]='#') or
         (sTemp[1]='^')
        then sTemp:=Copy(sTemp,2,Length(sTemp)-1);
      AddToQueue(sTemp,Address,Flavour);
    end;

  Close(T);
end;

Procedure TBSO.ScanNode(DirName:string;Zone,Net,Node:word);
Var
  SR:Searchrec;
  TempAddress:TAddress;
  sTemp:string;
begin

  FindFirst(DirName+'\*.?lo',AnyFile-Directory,SR);
  While DosError=0 do
    begin
      sTemp:=strParser(SR.Name,1,['.']);

      TempAddress.Zone:=Zone;
      TempAddress.Net:=Net;
      TempAddress.Node:=Node;
      TempAddress.Point:=strHexToInt(sTemp);

      ParsLo(strUpper(DirName+'\'+SR.Name),TempAddress);
      FindNext(SR);
    end;
{$IFNDEF VER70}
  FindClose(SR);
{$ENDIF}
end;


Procedure TBSO.ScanZone(DirName:string;Zone:word);
Var
  SR:Searchrec;
  TempAddress:TAddress;
  sTemp:string;
  Node, Net:word;
begin
  FindFirst(DirName+'\*.?lo',AnyFile-Directory,SR);
  While DosError=0 do
    begin
      sTemp:=strParser(SR.Name,1,['.']);

      TempAddress.Zone:=Zone;
      TempAddress.Net:=strHexToInt(Copy(sTemp,1,4));
      TempAddress.Node:=strHexToInt(Copy(sTemp,5,4));
      TempAddress.Point:=0;

      ParsLo(strUpper(DirName+'\'+SR.Name),TempAddress);
      FindNext(SR);
    end;
{$IFNDEF VER70}
  FindClose(SR);
{$ENDIF}

  FindFirst(DirName+'\*.PNT',Directory,SR);
  While DosError=0 do
    begin
      sTemp:=SR.Name;

      Dec(sTemp[0],4);

      Net:=strHexToInt(Copy(sTemp,1,4));
      Node:=strHexToInt(Copy(sTemp,5,4));

      ScanNode(DirName+'\'+SR.Name,Zone,Net,Node);
      FindNext(SR);
    end;
{$IFNDEF VER70}
  FindClose(SR);
{$ENDIF}
end;

Procedure TBSO.OpenDir(DirName:string);
Var
  SR:Searchrec;
  Zone:word;
begin
  OutDir:=NewStr(DirName);

  FindFirst(DirName+'.*',Directory,SR);
  While DosError=0 do
    begin

      If SR.Name[Length(SR.Name)-3]<>'.' then Zone:=DefZone
       else  Zone:=strHexToInt(Copy(SR.Name,Length(SR.Name)-2,3));

      ScanZone(dosGetPath(DirName)+'\'+SR.Name,Zone);
      FindNext(SR);
    end;
{$IFNDEF VER70}
  FindClose(SR);
{$ENDIF}
end;

Procedure TBSO.SetDefZone(DefZ:word);
begin
  DefZone:=DefZ;
end;

Procedure TBSO.AddToBundle(FileName:string;FromAddress,ToAddress:TAddress;ArcType:string;
              Flavour:word;MaxSize:longint);
Var
  CloName : string;
  Clo:text;
  BundleName:string;
  BExists:boolean;
begin
  CloName:=OutDir^;

  If ToAddress.Zone<>defZone
     then CloName:=CloName+'.'+strPadL(strWordToHex(ToAddress.Zone),'0',3);

  CloName:=CloName+'\'+strPadL(strWordToHex(ToAddress.Net),'0',4)
           +strPadL(strWordToHex(ToAddress.Node),'0',4);

  If ToAddress.Point<>0 then CloName:=CloName+'.PNT\'
     +strPadL(strLongToHex(ToAddress.Point),'0',8);

  Case Flavour of
    flvNormal : CloName:=CloName+'.FLO';
    flvHold   : CloName:=CloName+'.HLO';
    flvCrash  : CloName:=CloName+'.CLO';
    flvDirect : CloName:=CloName+'.DLO';
    flvImmediate : CloName:=CloName+'.ILO';
  end;

  If not dosDirExists(dosGetPath(CloName))
    then dosMkDir(dosGetPath(CloName));

  Bundlename:=GetBundleName(dosGetPath(CloName),FromAddress,ToAddress,flavour,
              BExists,MaxSize);

  If not BExists then
    begin
      Assign(Clo,CloName);
      If dosFileExists(CloName) then Append(Clo) else Rewrite(Clo);
      Writeln(Clo,#94,BundleName);
      Close(Clo);
    end;

  ArcEngine^.Add(BundleName,Filename,ArcType);
end;

Function TBSO.GetOutType:word;
begin
  GetOutType:=outBSO;
end;

Function TBSO.GetPacket(Address:TAddress;Flavour:word):PPacket2p;
Var
  PktName : string;
  TempPacket : PPacket2p;
begin
  PktName:=OutDir^;

  If Address.Zone<>defZone
     then PktName:=PktName+'.'+strPadL(strWordToHex(Address.Zone),'0',3);

  PktName:=PktName+'\'+strPadL(strWordToHex(Address.Net),'0',4)
     +strPadL(strWordToHex(Address.Node),'0',4);

  If Address.Point<>0 then PktName:=PktName+'.PNT\'
     +strPadL(strWordToHex(Address.Point),'0',8);

  Case Flavour of
    flvNormal : PktName:=PktName+'.OUT';
    flvHold   : PktName:=PktName+'.HUT';
    flvCrash  : PktName:=PktName+'.CUT';
    flvDirect : PktName:=PktName+'.DUT';
    flvImmediate : PktName:=PktName+'.IUT';
  end;

  If not dosDirExists(dosGetPath(PktName))
    then dosMkDir(dosGetPath(PktName));

  TempPacket:=New(PPacket2p,Init);
  TempPacket^.FastOpen:=True;

  If dosFileExists(PktName) then TempPacket^.OpenPkt(PktName)
    else TempPacket^.CreateNewPkt(PktName);

  GetPacket:=TempPacket;
end;

Procedure TBSO.Attach(FileName:string;FromAddress,ToAddress:TAddress;Flavour:word);
Var
  sTemp:string;
  CloName : string;
  Clo:text;
begin
  CloName:=OutDir^;

  If ToAddress.Zone<>defZone
     then CloName:=CloName+'.'+strPadL(strWordToHex(ToAddress.Zone),'0',3);

  CloName:=CloName+'\'+strPadL(strWordToHex(ToAddress.Net),'0',4)
     +strPadL(strWordToHex(ToAddress.Node),'0',4);

  If ToAddress.Point<>0 then CloName:=CloName+'.PNT\'
     +strPadL(strWordToHex(ToAddress.Point),'0',8);

  Case Flavour of
    flvNormal : CloName:=CloName+'.FLO';
    flvHold   : CloName:=CloName+'.HLO';
    flvCrash  : CloName:=CloName+'.CLO';
    flvDirect : CloName:=CloName+'.DLO';
    flvImmediate : CloName:=CloName+'.ILO';
  end;

  If not dosDirExists(dosGetPath(CloName))
    then dosMkDir(dosGetPath(CloName));

  sTemp:=dosGetPath(CloName)+'\'+dosGetFileName(FileName);
  dosMove(FileName,sTemp);
  FileName:=sTemp;

  Assign(Clo,CloName);
  If dosFileExists(CloName) then Append(Clo) else Rewrite(Clo);
  Writeln(Clo,#94,FileName);
  Close(Clo);

  AddToQueue(FileName,ToAddress,Flavour);
end;

Procedure TBSO.SetBusy(Address:TAddress);
Var
  FlagName : string;
begin
  FlagName:=OutDir^;

  If Address.Zone<>defZone
     then FlagName:=FlagName+'.'+strPadL(strWordToHex(Address.Zone),'0',3);

  FlagName:=FlagName+'\'+strPadL(strWordToHex(Address.Net),'0',4)
     +strPadL(strWordToHex(Address.Node),'0',4);

  If Address.Point<>0 then FlagName:=FlagName+'.PNT\'
     +strPadL(strWordToHex(Address.Point),'0',8);

  FlagName:=FlagName+'.bsy';
end;

Procedure TBSO.RemoveBusy(Address:TAddress);
Var
  FlagName : string;
begin
  FlagName:=OutDir^;

  If Address.Zone<>defZone
     then FlagName:=FlagName+'.'+strPadL(strWordToHex(Address.Zone),'0',3);

  FlagName:=FlagName+'\'+strPadL(strWordToHex(Address.Net),'0',4)
     +strPadL(strWordToHex(Address.Node),'0',4);

  If Address.Point<>0 then FlagName:=FlagName+'.PNT\'
     +strPadL(strWordToHex(Address.Point),'0',8);

  dosErase(FlagName+'.bsy');
end;

Function TBSO.GetBusy(Address:TAddress):boolean;
Var
  FlagName : string;
begin
  GetBusy:=False;

  FlagName:=OutDir^;

  If Address.Zone<>defZone
     then FlagName:=FlagName+'.'+strPadL(strWordToHex(Address.Zone),'0',3);

  FlagName:=FlagName+'\'+strPadL(strWordToHex(Address.Net),'0',4)
     +strPadL(strWordToHex(Address.Node),'0',4);

  If Address.Point<>0 then FlagName:=FlagName+'.PNT\'
     +strPadL(strWordToHex(Address.Point),'0',8);

  FlagName:=FlagName+'.?sy';

  GetBusy:=dosFileExists(FlagName);
end;

end.
