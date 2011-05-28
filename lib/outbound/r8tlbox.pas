{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit r8tlbox;

interface

Uses
  dos,
  r8out,
  r8outcmn,
  r8pkt2p,
  r8str,
  r8dos,
  r8ftn,
  objects;

Type

 TTLBOX = object(TOutbound)
   Constructor Init;
   Destructor Done;virtual;

   Function GetOutType:word;virtual;

   Procedure OpenDir(DirName:string);virtual;
   Procedure ScanNode(DirName:string);

   Procedure AddToBundle(FileName:string;FromAddress,ToAddress:TAddress;ArcType:string
       ;Flavour:word;MaxSize:longint);virtual;
   Procedure Attach(FileName:string;FromAddress,ToAddress:TAddress;Flavour:word);virtual;
   Function GetPacket(Address:TAddress;Flavour:word):PPacket2p;virtual;
 end;

 PTLBOX = ^TTLBOX;

implementation

Constructor TTLBOX.Init;
begin
  inherited Init;
end;

Destructor TTLBOX.Done;
begin
  inherited Done;
end;

Procedure TTLBOX.ScanNode(DirName:string);
Var
  Flavour : word;
  sTemp:string;
  FileName : string;
  SR:Searchrec;
  Address : TAddress;
begin
  FileName:=dosGetFileName(DirName);

  Flavour:=flvNormal;

  Case FileName[Length(FileName)] of
    'H' : Flavour:=flvHold;
    'D' : Flavour:=flvDirect;
    'C' : Flavour:=flvCrash;
   end;

  If Flavour<>flvNormal then Dec(FileName[0],2);

  ftnTLBoxToAddress(fileName,Address);

  FindFirst(DirName+'\*.*',AnyFile-Directory,SR);
  While DosError=0 do
    begin
      sTemp:=DirName+'\'+SR.Name;
      AddToQueue(sTemp,Address,Flavour);
      FindNext(SR);
    end;
{$IFNDEF VER70}
  FindClose(SR);
{$ENDIF}
end;

Procedure TTLBOX.OpenDir(DirName:string);
Var
  SR:Searchrec;
begin
  OutDir:=NewStr(DirName);

  FindFirst(DirName+'.*',Directory,SR);
  While DosError=0 do
    begin
      ScanNode(dosGetPath(DirName)+'\'+SR.Name);
      FindNext(SR);
    end;
{$IFNDEF VER70}
  FindClose(SR);
{$ENDIF}
end;

Procedure TTLBOX.AddToBundle(FileName:string;FromAddress,ToAddress:TAddress;ArcType:string;
              Flavour:word;MaxSize:longint);
Var
  BoxName : string;
  BundleName:string;
  BExists:boolean;
begin
  BoxName:=ftnAddressToTLBox(ToAddress);

  Case Flavour of
    flvHold   : BoxName:=BoxName+'.H';
    flvCrash  : BoxName:=BoxName+'.C';
    flvDirect : BoxName:=BoxName+'.D';
    flvImmediate : BoxName:=BoxName+'.I';
  end;

  BoxName:=OutDir^+'\'+BoxName;

  If not dosDirExists(BoxName)
    then dosMkDir(BoxName);
  ChDir(BoxName);

  BoxName:=dosGetShortName(BoxName);

  Bundlename:=GetBundleName(BoxName,FromAddress,ToAddress,flavour,
              BExists,MaxSize);

  ArcEngine^.Add(BundleName,Filename,ArcType);
end;

Function TTLBOX.GetOutType:word;
begin
  GetOutType:=outTLBOX;
end;

Function TTLBOX.GetPacket(Address:TAddress;Flavour:word):PPacket2p;
Var
  BoxName : string;
  PktName : string;
  TempPacket : PPacket2p;
begin
  BoxName:=ftnAddressToTLBox(Address);

  Case Flavour of
    flvHold   : BoxName:=BoxName+'.H';
    flvCrash  : BoxName:=BoxName+'.C';
    flvDirect : BoxName:=BoxName+'.D';
    flvImmediate : BoxName:=BoxName+'.I';
  end;

  BoxName:=OutDir^+'\'+BoxName;

  If not dosDirExists(BoxName)
    then dosMkDir(BoxName);
  ChDir(BoxName);

  BoxName:=dosGetShortName(BoxName);

  repeat PktName:=strUpper(BoxName+'\'+ftnPktName+'.PKT')
  until not dosFileExists(PktName);

  TempPacket:=New(PPacket2p,Init);
  TempPacket^.FastOpen:=True;

  TempPacket^.CreateNewPkt(PktName);

  GetPacket:=TempPacket;
end;

Procedure TTLBOX.Attach(FileName:string;FromAddress,ToAddress:TAddress;Flavour:word);
Var
  sTemp:string;
  BoxName : string;
begin
  BoxName:=ftnAddressToTLBox(ToAddress);

  Case Flavour of
    flvHold   : BoxName:=BoxName+'.H';
    flvCrash  : BoxName:=BoxName+'.C';
    flvDirect : BoxName:=BoxName+'.D';
    flvImmediate : BoxName:=BoxName+'.I';
  end;

  BoxName:=OutDir^+'\'+BoxName;

  If not dosDirExists(BoxName)
    then dosMkDir(BoxName);
  ChDir(BoxName);

  sTemp:=BoxName+'\'+dosGetFileName(FileName);
  dosMove(FileName,sTemp);
  FileName:=sTemp;

  AddToQueue(FileName,ToAddress,Flavour);
end;

end.
