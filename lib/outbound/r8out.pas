{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit r8out;

interface

Uses
  r8ftn,
  r8dtm,
  r8dos,
  r8arc,
  r8objs,
  r8pkt2p,
  r8outcmn,
  r8str,
  objects;

const
  outNone     = $00000000;
  outBSO      = $00000001;
  outTBOX     = $00000002;
  outTLBOX    = $00000004;
  outAMA      = $00000005;
  outDiskPoll = $00000006;

Type

 TOutbound = object(TObject)
   OutDir : PString;

   ArcEngine : PArcEngine;

   Addresses : POutAddressCollection;
   Files : POutFileCollection;

   Constructor Init;
   Destructor Done;virtual;

   Function GetOutType:word;virtual;

   Function FindAddress(Address:TAddress):integer;
   Procedure AddToQueue(FileName:string;Address:TAddress;Flavour:word);

   Procedure OpenDir(DirName:string);virtual;
   Procedure SetDefZone(DefZ:word);virtual;
   Procedure AddToBundle(FileName:string;FromAddress,ToAddress:TAddress;ArcType:string
          ;Flavour:word;MaxSize:longint);virtual;
   Procedure Attach(FileName:string;FromAddress,ToAddress:TAddress;Flavour:word);virtual;
   Function GetBundleName(Path:string;FromAddress,ToAddress:TAddress;Flavour:word;
         var BExists:boolean;MaxSize:longint):string;virtual;

   Function GetPacket(Address:TAddress;Flavour:word):PPacket2p;virtual;

   Procedure SetBusy(Address:TAddress);virtual;
   Procedure RemoveBusy(Address:TAddress);virtual;
   Function GetBusy(Address:TAddress):boolean;virtual;
 end;

 POutbound = ^TOutbound;

implementation

Constructor TOutbound.Init;
begin
  inherited Init;

   Addresses:=New(POutAddressCollection,Init($10,$10));
   Files:=New(POutFileCollection,Init($10,$10));

   OutDir:=nil;
end;

Destructor TOutbound.Done;
begin
  objDispose(Addresses);
  objDispose(Files);

  DisposeStr(OutDir);

  inherited Done;
end;

Procedure TOutbound.OpenDir(DirName:string);
begin
  Abstract;
end;

Procedure TOutbound.AddToBundle(FileName:string;FromAddress,ToAddress:TAddress;ArcType:string
    ;Flavour:word;MaxSize:longint);
begin
  Abstract;
end;

Procedure TOutbound.SetDefZone(DefZ:word);
begin
end;

Function TOutbound.FindAddress(Address:TAddress):integer;
Var
  i:integer;
  TempAddress : POutAddress;
begin
  FindAddress:=-1;

  For i:=0 to Addresses^.Count-1 do
    begin
      TempAddress:=Addresses^.At(i);
      If ftnAddressCompare(TempAddress^.Address,Address)=0 then
        begin
          FindAddress:=i;
          exit;
        end;
    end;
end;

Procedure TOutbound.AddToQueue(FileName:string;Address:TAddress;
              Flavour:word);
Var
  i:integer;
  TempAddress : POutAddress;
  TempFile : POutFile;
begin
  i:=FindAddress(Address);

  If i=-1 then
    begin
      TempAddress:=New(POutAddress,Init);
      TempAddress^.Address:=Address;
      Addresses^.Insert(TempAddress);
      i:=Addresses^.Count-1;
    end;

  TempAddress:=Addresses^.At(i);

  TempFile:=New(POutFile,Init);
  TempFile^.Name:=NewStr(strUpper(FileName));
  TempFile^.Flavour:=Flavour;
  TempFile^.Addresses^.Insert(TempAddress);

  TempAddress^.Files^.Insert(TempFile);
  Files^.Insert(TempFile);
end;

Function TOutbound.GetBundleName(Path:string;FromAddress,ToAddress:TAddress;Flavour:word;
         var BExists:boolean;MaxSize:longint):string;
Var
  sTemp:string;
  i:longint;
  TempAddress : POutAddress;
  TempFile : POutFile;
begin
  sTemp:=Path+'\'+ftnSqBundle(FromAddress,ToAddress)+'.'+BundleExt[dtmGetWDay]+'0';

  i:=FindAddress(ToAddress);

  If i=-1 then
    begin
      BExists:=False;
      GetBundleName:=sTemp;
      AddToQueue(sTemp,ToAddress,Flavour);
      exit;
    end;

  TempAddress:=Addresses^.At(i);

  While 1=1 do
    begin

      i:=TempAddress^.FindFile(sTemp);
      If i=-1 then
        begin
          BExists:=False;
          GetBundleName:=sTemp;
          AddToQueue(sTemp,ToAddress,Flavour);
          exit;
        end;

      TempFile:=TempAddress^.Files^.At(i);

      If (TempFile^.Flavour=Flavour) and (dosFileSize(sTemp)<=MaxSize)
             then break;

      i:=Pos(sTemp[Length(sTemp)],BundleLastChar);
      If i<>Length(sTemp) then sTemp[Length(sTemp)]:=BundleLastChar[i+1]
       else
        begin
          Dec(sTemp[0],3);
          i:=dtmGetWDay;
          if i<>6 then sTemp:=sTemp+BundleExt[i+1]+'0'
              else sTemp:=sTemp+BundleExt[0]+'0';
        end;
    end;

  BExists:=True;
  GetBundleName:=sTemp;
end;

Function TOutbound.GetOutType:word;
begin
  GetOutType:=outNone;
end;

Function TOutbound.GetPacket(Address:TAddress;Flavour:word):PPacket2p;
begin
  Abstract;
end;

Procedure TOutbound.Attach(FileName:string;FromAddress,ToAddress:TAddress;Flavour:word);
begin
  Abstract;
end;

Procedure TOutbound.SetBusy(Address:TAddress);
begin
end;

Procedure TOutbound.RemoveBusy(Address:TAddress);
begin
end;

Function TOutbound.GetBusy(Address:TAddress):boolean;
begin
  GetBusy:=False;
end;

end.
