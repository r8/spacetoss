{

  После создания директориии сделать chdir в неё,
  чтобы она залочилась и мейлер не смог её удалить.
  и слишком много повторяющегося кода. Выделить в процедуру.
}
{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit r8tbox;

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

 TTBOX = object(TOutbound)
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

 PTBOX = ^TTBOX;

implementation

Constructor TTBOX.Init;
begin
  inherited Init;
end;

Destructor TTBOX.Done;
begin
  inherited Done;
end;

Procedure TTBOX.ScanNode(DirName:string);
Var
  Flavour : word;
  sTemp:string;
  FileName : string;
  SR:Searchrec;
  Address : TAddress;
begin
  FileName:=dosGetFileName(DirName);
  sTemp:=strParser(FileName,2,['.']);

  if Length(sTemp)=2 then Flavour:=flvNormal
   else
    begin
      Case sTemp[3] of
       'H' : Flavour:=flvHold;
       'F' : Flavour:=flvNormal;
       'D' : Flavour:=flvDirect;
       'C' : Flavour:=flvCrash;
      end;
     Dec(FileName[0]);
    end;

  ftnTBoxToAddress(fileName,Address);

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

Procedure TTBOX.OpenDir(DirName:string);
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

Procedure TTBOX.AddToBundle(FileName:string;FromAddress,ToAddress:TAddress;ArcType:string;
              Flavour:word;MaxSize:longint);
Var
  BoxName : string;
  BundleName:string;
  BExists:boolean;
begin
  BoxName:=ftnAddressToTBox(ToAddress);

  Case Flavour of
    flvHold   : BoxName:=BoxName+'H';
    flvCrash  : BoxName:=BoxName+'C';
    flvDirect : BoxName:=BoxName+'D';
    flvImmediate : BoxName:=BoxName+'I';
  end;

  BoxName:=OutDir^+'\'+BoxName;

  If not dosDirExists(BoxName)
    then dosMkDir(BoxName);
  ChDir(BoxName);

  Bundlename:=GetBundleName(BoxName,FromAddress,ToAddress,flavour,
              BExists,MaxSize);

  ArcEngine^.Add(BundleName,Filename,ArcType);
end;

Function TTBOX.GetOutType:word;
begin
  GetOutType:=outTBOX;
end;

Function TTBOX.GetPacket(Address:TAddress;Flavour:word):PPacket2p;
Var
  BoxName : string;
  PktName : string;
  TempPacket : PPacket2p;
begin
  BoxName:=ftnAddressToTBox(Address);

  Case Flavour of
    flvHold   : BoxName:=BoxName+'H';
    flvCrash  : BoxName:=BoxName+'C';
    flvDirect : BoxName:=BoxName+'D';
    flvImmediate : BoxName:=BoxName+'I';
  end;

  BoxName:=OutDir^+'\'+BoxName;

  If not dosDirExists(BoxName)
    then dosMkDir(BoxName);
  ChDir(BoxName);

  repeat PktName:=strUpper(BoxName+'\'+ftnPktName+'.PKT')
  until not dosFileExists(PktName);

  TempPacket:=New(PPacket2p,Init);
  TempPacket^.FastOpen:=True;

  TempPacket^.CreateNewPkt(PktName);

  GetPacket:=TempPacket;
end;

Procedure TTBOX.Attach(FileName:string;FromAddress,ToAddress:TAddress;Flavour:word);
Var
  sTemp:string;
  BoxName : string;
begin
  BoxName:=ftnAddressToTBox(ToAddress);

  Case Flavour of
    flvHold   : BoxName:=BoxName+'H';
    flvCrash  : BoxName:=BoxName+'C';
    flvDirect : BoxName:=BoxName+'D';
    flvImmediate : BoxName:=BoxName+'I';
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
