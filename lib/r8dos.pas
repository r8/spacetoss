{.$DEFINE FORCEHOMEDIR}
{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
  {$ASMMODE intel}
{$ENDIF}
Unit r8Dos;

interface
Uses
  strings,
  objects,
  r8str,
{$IFDEF WIN32}
  windows,
{$ENDIF}
  Dos;

const
 fmCreate       : Word = $3C00;
 fmOpen         : Word = $3D00;

 fmRead         : Byte = $00;
 fmWrite        : Byte = $01;
 fmReadWrite    : Byte = $02;

 fmDenyReadWrite: Byte = $10;
 fmDenyAll      : Byte = $10;
 fmDenyWrite    : Byte = $20;
 fmDenyRead     : Byte = $30;
 fmDenyNone     : Byte = $40;
{
File sharing behavior:
          |     Second and subsequent Opens
 First    |Compat  Deny   Deny   Deny   Deny
 Open     |        All    Write  Read   None
          |R W RW R W RW R W RW R W RW R W RW
 - - - - -| - - - - - - - - - - - - - - - - -
 Compat R |Y Y Y  N N N  1 N N  N N N  1 N N
        W |Y Y Y  N N N  N N N  N N N  N N N
        RW|Y Y Y  N N N  N N N  N N N  N N N
 - - - - -|
 Deny   R |C C C  N N N  N N N  N N N  N N N
 All    W |C C C  N N N  N N N  N N N  N N N
        RW|C C C  N N N  N N N  N N N  N N N
 - - - - -|
 Deny   R |2 C C  N N N  Y N N  N N N  Y N N
 Write  W |C C C  N N N  N N N  Y N N  Y N N
        RW|C C C  N N N  N N N  N N N  Y N N
 - - - - -|
 Deny   R |C C C  N N N  N Y N  N N N  N Y N
 Read   W |C C C  N N N  N N N  N Y N  N Y N
        RW|C C C  N N N  N N N  N N N  N Y N
 - - - - -|
 Deny   R |2 C C  N N N  Y Y Y  N N N  Y Y Y
 None   W |C C C  N N N  N N N  Y Y Y  Y Y Y
        RW|C C C  N N N  N N N  N N N  Y Y Y
Legend: Y = open succeeds, N = open fails with error code 05h
        C = open fails, INT 24 generated
        1 = open succeeds if file read-only, else fails with error code
        2 = open succeeds if file read-only, else fails with INT 24
}

Var
  HomeDir  : string;
  WorkDir  : string;
  cWorkDisk : char;
  bWorkDisk : byte;

Function dosFileExists(const FileName: string): boolean;
Function dosDirExists(const FileName: string): boolean;

Function dosGetFileName(const S:string):string;
Function dosGetPath(const S:string):string;
Function dosMakeValidString(const S:string):string;
Procedure dosChangeWorkDir(const S:string);

Function dosFileSize(const S:string):longint;

Procedure dosCopy(const File1,File2:string);
Procedure dosMove(const File1,File2:string);
Procedure dosRename(File1,File2:string);
Procedure dosErase(const FileName:string);
function dosMkDir(dir: string): boolean;

Function dosExec(Name,Params:string):integer;

Function dosErrorLevel:byte;

Function dosNumbOfFiles(const FileMask,Dir:string):integer;

Function dosGetShortName(LN:string):string;

Function dosGetCommandLine:string;

implementation

var
 sTemp : string;

Function dosFileExists(const FileName: string): boolean;
var
  SR: SearchRec;
begin
  FindFirst(FileName,AnyFile-VolumeID-Directory,SR);
  dosFileExists:=DosError=0;
{$IFNDEF VER70}
  FindClose(SR);
{$ENDIF}
end;

Function dosDirExists(const FileName: string): boolean;
var
  SR: SearchRec;
  B:byte;
begin
  If ((Length(FileName)=3)or(Length(FileName)=2)) and (FileName[2]=':') then
    begin
      B:=ord(strUpCaseChar(FileName[1]))-64;
      dosDirExists:=DiskFree(B)<>-1;
    end
    else
    begin
      FindFirst(FileName,Directory,SR);
      dosDirExists:=DosError=0;
{$IFNDEF VER70}
      FindClose(SR);
{$ENDIF}
    end;
end;

Function dosGetFileName(const S:string):string;
var
    Path : PathStr;
    Dir  : DirStr;
    Name : NameStr;
    Ext  : ExtStr;
begin
  Path:=S;
  FSplit(Path,Dir,Name,Ext);
  dosGetFileName:=Name+Ext;
end;

Function dosGetPath(const S:string):string;
var
  sTemp:string;
begin
  sTemp:=S;
  If S='' then exit;

  While sTemp[Length(sTemp)]<>'\' do Dec(sTemp[0]);
  If sTemp[Length(sTemp)-1]<>':' then Dec(sTemp[0]);

  dosGetPath:=sTemp;
end;

Function dosMakeValidString(const S:string):string;
var
  sTemp:string;
  i:integer;
begin
  sTemp:=S;
  If Length(S)=0 then exit;

  If sTemp[Length(sTemp)]='\' then Dec(sTemp[0]);

  If sTemp[1]='\' then sTemp:=cWorkDisk+':'+sTemp;

  If (sTemp[2]<>':') and (sTemp[1]<>'.') then sTemp:=WorkDir+'\'+sTemp;

  If sTemp[Length(sTemp)] in [':','.'] then sTemp:=sTemp+'\';

  If Copy(sTemp,1,2)='.\'
    then sTemp:=WorkDir+'\'+Copy(sTemp,3,Length(sTemp)-2);

  If Copy(sTemp,1,3)='..\' then
    begin
      sTemp:=dosGetPath(WorkDir)+'\'+Copy(sTemp,4,Length(sTemp)-3);
      If Pos('\\',sTemp)<>0 then sTemp:=cWorkDisk+':\';
    end;

  If (sTemp[Length(sTemp)]='\') and (sTemp[Length(sTemp)-1]<>':')
    then Dec(sTemp[0]);

  dosMakeValidString:=sTemp;
end;

Procedure dosGetCurrentDrive;
Begin
  sTemp:=dosGetPath(WorkDir);
  cWorkDisk:=sTemp[1];
  bWorkDisk:=Ord(cWorkDisk)-64;
End;

Procedure dosChangeWorkDir(const S:string);
Begin
  WorkDir:=dosMakeValidString(S);
  dosGetCurrentDrive;
End;

Function dosFileSize(const S:string):longint;
Var
  F:file;
begin
  dosFileSize:=0;

{$I-}
  Assign(F,S);
  Reset(F,1);
{$I+}

  If IOResult<>0 then exit;

  dosFileSize:=FileSize(F);
  Close(F);
end;

Procedure dosCopy(const File1, File2:string);
Type
  TBuf=array[1..$FFFF] of char;
Var
  FromF,ToF: file;
  Buf: ^TBuf;
  Time: longint;
{$IFDEF VIRTUALPASCAL}
  Attr: longint;
  NumRead,NumWrItten: longint;
{$ELSE}
  Attr: word;
  NumRead,NumWrItten: word;
{$ENDIF}
begin
  If not dosFileExists(File1) then exit;
  If strUpper(File1)=strUpper(File2) then exit;

  Assign(FromF,File1);
  GetFTime(FromF,Time);
  GetFAttr(FromF,Attr);
  SetFAttr(FromF,Archive);
  Reset(FromF,1);

  Assign(ToF,File2);
  Rewrite(ToF,1);

  Seek(ToF,FileSize(ToF));
  New(Buf);

  repeat
    BlockRead(FromF,Buf^,SizeOf(Buf^),NumRead);
    BlockWrite(ToF,Buf^,NumRead,NumWrItten);
  until (NumRead=0) or (NumWritten<>NumRead);

  Dispose(buf);
  Close(FromF);
  Close(ToF);

  SetFTime(ToF,Time);
  SetFAttr(ToF,Attr);
  SetFAttr(FromF,Attr);
end;

Procedure dosMove(const File1,File2:string);
Var
  F1:file;
begin
  dosCopy(File1,File2);
  Assign(F1,File1);
  Erase(F1);
end;

Procedure dosRename(File1,File2:string);
Var
  F1:file;
begin
  If dosFileExists(File2) then dosMove(File1,File2)
    else
      begin
        Assign(F1,File1);
     {$I-}
        Rename(F1,File2);
     {$I+}
        If IOResult<>0 then exit;
      end;
end;

Procedure dosErase(const FileName:string);
Var
  F1:file;
begin
  Assign(F1,FileName);
{$I-}
  Erase(F1);
{$I+}
  If IOResult<>0 then exit;
end;

Function dosNumbOfFiles(const FileMask, Dir:string):integer;
var
  SR: SearchRec;
  Temp : integer;
begin
  Temp:=0;

  FindFirst(Dir+'\'+FileMask,AnyFile-VolumeID-Directory,SR);
  While DosError = 0 do
    begin
      Inc(Temp);
      FindNext(SR);
    end;
{$IFNDEF VER70}
  FindClose(SR);
{$ENDIF}

  dosNumbOfFiles:=Temp;
end;

Function dosErrorLevel:byte;
begin
   If DosError = 0 then dosErrorLevel:=DosExitCode
     else dosErrorLevel:=DosError;
end;

Function dosMkDir(Dir:string):boolean;
Var
  Count : integer;
begin
  Dir:=Dir+'\';

  If not dosDirExists(Dir) then
    For Count:=Pos(#58,Dir) to Length(Dir) do
      If Dir[Count]=#92 then
        begin
         {$I-}
          MkDir(Copy(Dir,1,Count-1));
         {$I+}
          If IOResult=0 then dosMkDir:=true else dosMkDir:=false;
        end;
end;

Function dosExec(Name,Params:string):integer;
Var
  sTemp : string;
begin
  Name:=strUpper(Name);

  If (Pos('.COM',Name)=0) and (Pos('.BAT',Name)=0) and
                   (Pos('.EXE',Name)=0) then
       begin
         Name:=Name+'.EXE';
         sTemp:=Name;

         If not dosFileExists(Name) then
            If not dosFileExists(HomeDir+'\'+Name) then
               sTemp:=FSearch(Name,GetEnv('PATH'))
                   else sTemp:=HomeDir+'\'+Name;

         If sTemp='' then
           begin
             Name:=Name+'.COM';
             sTemp:=Name;

             If not dosFileExists(Name) then
                If not dosFileExists(HomeDir+'\'+Name) then
                   sTemp:=FSearch(Name,GetEnv('PATH'))
                       else sTemp:=HomeDir+'\'+Name;

             If sTemp='' then
               begin
                 Name:=Name+'.BAT';
                 sTemp:=Name;

                 If not dosFileExists(Name) then
                    If not dosFileExists(HomeDir+'\'+Name) then
                       sTemp:=FSearch(Name,GetEnv('PATH'))
                           else sTemp:=HomeDir+'\'+Name;
               end;
           end;
       end;

  sTemp:=Name;

  If not dosFileExists(Name) then
     If not dosFileExists(HomeDir+'\'+Name) then
           sTemp:=FSearch(Name,GetEnv('PATH'))
               else sTemp:=HomeDir+'\'+Name;

   If Pos('.BAT',sTemp)<>0 then
     begin
       Params:='/C '+Name+' '+Params;
       sTemp:=GetEnv('COMSPEC');
     end;

   If sTemp<>'' then
     begin
        SwapVectors;
        Exec(sTemp,Params);
        dosExec:=DosExitCode;
        SwapVectors;
     end
     else dosExec:=-1;
end;

{$IFDEF WIN32}
Function dosGetShortName(LN:string):string;
Var
  sTemp : string;
  sTemp2 : string;
  Count : integer;

     Function ShortName(LN:string):string;
     Var
       FindData : TWin32FindData;
       LongName : PChar;
     begin
       GetMem(LongName,Length(LN)+1);
       StrPCopy(LongName,LN);

     {$IFDEF FPC}
       FindFirstFile(LongName, @FindData);
     {$ELSE}
       FindFirstFile(LongName, FindData);
     {$ENDIF}
       sTemp:=StrPas(@FindData.cAlternateFileName);

       If Length(sTemp)=0 then sTemp:=dosGetFileName(LN);

       sTemp2:=dosGetPath(LN);
       If sTemp2[Length(sTemp2)]<>'\' then sTemp:='\'+sTemp;
       ShortName:=sTemp2+sTemp;

       FreeMem(LongName,Length(LN)+1);
     end;

begin
  Count:=1;
  While Count<=Length(LN) do
    begin
      If (LN[Count]=#92) and (Count<>3) then
        begin
          sTemp:=ShortName(Copy(LN,1,Count-1));
          LN:=sTemp+Copy(LN,Count,Length(LN)-Count+1);
          Count:=Length(sTemp)+1;
        end;
      Inc(Count);
    end;

  dosGetShortName:=ShortName(LN);
end;
{$ELSE}
Function dosGetShortName(LN:string):string;
Var
  LongName : PChar;
  ShortName : PChar;
begin
  GetMem(LongName,Length(LN)+1);
  StrPCopy(LongName,LN);

  GetMem(ShortName,129);
asm
  push DS
  push ES
  mov AX,7160h
  mov CL, 01h
  mov CH, 00h
  lds si, LongName
  les di, ShortName
  int 21h
  pop ES
  pop DS
end;
  dosGetShortName:=StrPas(ShortName);

  FreeMem(ShortName,129);
  FreeMem(LongName,Length(LN)+1);
end;
{$ENDIF}

Function dosGetCommandLine:string;
Var
  sTemp : string;
begin
{$IFDEF WIN32}
  sTemp:=StrPas(PChar(CmdLine));
  dosGetCommandLine:=Copy(sTemp,Pos(#32,sTemp)+1,Length(sTemp)-Pos(#32,sTemp)+1);
{$ELSE}
  dosGetCommandLine:=strTrimB(PString(Ptr(PrefixSeg,$80))^,[#32]);
{$ENDIF}
end;

begin
{$IFNDEF FORCEHOMEDIR}
  HomeDir:=dosGetPath(ParamStr(0));
  WorkDir:=HomeDir;
  dosGetCurrentDrive;
  ChDir(HomeDir);
{$ENDIF}
end.
