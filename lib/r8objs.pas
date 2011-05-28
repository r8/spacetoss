{
 Additional objects.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
 search
 countlines
}
Unit r8objs;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}
{$R-}

interface

Uses
  r8str,

  strings,
  objects;

const

{Buffer size}
  cBuffSize = $1000;

Type

  TBuffer = array[0..0] of char;
  PBuffer = ^TBuffer;

  PLongInt = ^LongInt;

  TLongIntCollection = object(TCollection)
    Procedure FreeItem(Item:pointer);virtual;
  end;
  PLongIntCollection = ^TLongIntCollection;

  TStringsCollection = object(TCollection)
    Procedure FreeItem(item:pointer);virtual;
  end;
  PStringsCollection = ^TStringsCollection;

Procedure objDispose(Var P);

Function objStreamRead(const S:PStream;const C:TCharset;const MaxBuff:longint):PChar;
Function objStreamReadBack(const S:PStream;const C:TCharset;const MaxBuff:longint):PChar;

Function objStreamReadLn(const S:PStream):string;
Function objStreamReadLnZero(const S:PStream):string;
Function objStreamReadLnCr(const S:PStream):string;
Function objStreamReadLnBack(const S:PStream):string;

Function objStreamReadStr(const S:PStream):string;
Procedure objStreamWriteStr(const St:PStream;const S:string);

Procedure objStreamWrite(const St:PStream;S:string);
Procedure objStreamWriteLn(const St:PStream;const S:string);

Procedure objStreamWritePChar(const St:PStream;const P:PChar);

Function objStreamInsertStr(const St:PStream;S:string):PStream;
Function objStreamInsert(const St:PStream;P:PChar):PStream;

Function objStreamSearchChar(S:PStream;Chars:TCharset):longint;
Function objStreamSearchCharBack(S:PStream;Chars:TCharset):longint;

Function objStreamCountLines(S:PStream):longint;

procedure AssignStr(var P:PString;const S:string);

implementation

Procedure TLongIntCollection.FreeItem(Item:pointer);
begin
  If Pointer(Item)<>nil then Dispose(PLongInt(Item));
end;

Procedure TStringsCollection.FreeItem(Item:pointer);
begin
  If Item<>nil then DisposeStr(PString(Item));
end;

Procedure objDispose(Var P);
begin
  If Pointer(P)<>nil then Dispose(PObject(P),Done);
  Pointer(P):=nil;
end;

Function objStreamReadLn(const S:PStream):string;
Var
  pTemp : PChar;
begin
  pTemp:=objStreamRead(S,[#13,#0],cBuffSize);
  objStreamReadLn:=StrPas(pTemp);
  StrDispose(pTemp);
end;

Function objStreamReadLnZero(const S:PStream):string;
Var
  pTemp : PChar;
begin
  pTemp:=objStreamRead(S,[#0],cBuffSize);
  objStreamReadLnZero:=StrPas(pTemp);
  StrDispose(pTemp);
end;

Function objStreamReadLnCr(const S:PStream):string;
Var
  pTemp : PChar;
begin
  pTemp:=objStreamRead(S,[#13],cBuffSize);
  objStreamReadLnCr:=StrPas(pTemp);
  StrDispose(pTemp);
end;

Function objStreamReadLnBack(const S:PStream):string;
Var
  pTemp : PChar;
begin
  pTemp:=objStreamReadBack(S,[#13],cBuffSize);
  objStreamReadLnBack:=strTrimL(StrPas(pTemp),[#10]);
  StrDispose(pTemp);
end;

Function objStreamRead(const S:PStream;const C:TCharset;const MaxBuff:longint):PChar;
Var
  Buffer : PBuffer;

  StreamSize : longint;
  StreamPos : longint;

  BuffSize : longint;

  i : longint;
  Pos : longint;

  pTemp : PChar;
begin
  objStreamRead:=nil;

  StreamSize:=S^.GetSize;
  StreamPos:=S^.GetPos;

  If (StreamSize=0) or (StreamPos=StreamSize) then exit;

  BuffSize:=MaxBuff;
  If StreamPos+BuffSize>StreamSize then BuffSize:=StreamSize-StreamPos;

  GetMem(Buffer,BuffSize);

  S^.Read(Buffer^,BuffSize);

  Pos:=-1;

  For i:=0 to BuffSize-1 do
    If Buffer^[i] in C then
      begin
        Pos:=i;
        break;
      end;

  If Pos=-1 then Pos:=BuffSize;

  GetMem(pTemp,Pos+1);
  Move(Buffer^[0],pTemp^,Pos);
  pTemp[Pos]:=#0;

  If Pos<BuffSize-1 then
       If Buffer^[Pos+1]=#10 then Inc(Pos);

  FreeMem(Buffer,BuffSize);

  S^.Seek(StreamPos+Pos+1);

  objStreamRead:=pTemp;
end;

Function objStreamReadBack(const S:PStream;const C:TCharset;const MaxBuff:longint):PChar;
Var
  Buffer : PBuffer;

  StreamSize : longint;
  StreamPos : longint;

  BuffSize : longint;

  i : longint;
  Pos : longint;

  pTemp : PChar;
begin
  objStreamReadBack:=nil;

  StreamSize:=S^.GetSize;
  StreamPos:=S^.GetPos;

  If (StreamSize=0) or (StreamPos=0) then exit;

  BuffSize:=MaxBuff;
  If StreamPos-BuffSize<0 then BuffSize:=StreamPos;

  GetMem(Buffer,BuffSize);

  S^.Seek(StreamPos-Buffsize);
  S^.Read(Buffer^,BuffSize);

  Pos:=-1;

  For i:=BuffSize-1 downto 0 do
    If Buffer^[i] in C then
      begin
        Pos:=i;
        break;
      end;

  GetMem(pTemp,(BuffSize-Pos));
  Move(Buffer^[Pos+1],pTemp^,(BuffSize-1)-Pos);
  pTemp[(BuffSize-1)-Pos]:=#0;

  FreeMem(Buffer,BuffSize);

  S^.Seek(StreamPos-(BuffSize-Pos));

  objStreamReadBack:=pTemp;
end;

Function objStreamReadStr(const S:PStream):string;
Var
  pTemp : PString;
begin
  objStreamReadStr:='';

  pTemp:=S^.ReadStr;
  If pTemp<>nil then
    begin
      objStreamReadStr:=pTemp^;
      DisposeStr(pTemp);
    end;
end;

Procedure objStreamWriteStr(const St:PStream;const S:string);
Var
  pTemp : PString;
begin
  pTemp:=NewStr(S);
  St^.WriteStr(pTemp);
  DisposeStr(pTemp);
end;

Procedure objStreamWrite(const St:PStream;S:string);
begin
  St^.Write(S[1],Length(S));
end;

Procedure objStreamWriteLn(const St:PStream;const S:string);
begin
  objStreamWrite(St,S+#13);
end;

Procedure objStreamWritePChar(const St:PStream;const P:PChar);
begin
  If StrLen(P)=0 then exit;
  St^.Write(P^,StrLen(P));
end;

Function objStreamInsertStr(const St:PStream;S:string):PStream;
Var
  P:Pointer;
begin
  S:=S+#0;
  P:=@S[1];

  objStreamInsertStr:=objStreamInsert(St,P);
end;

Function objStreamInsert(const St:PStream;P:PChar):PStream;
Var
  Size : longint;
  Buffer : PBuffer;
begin
  objStreamInsert:=St;

  If StrLen(P)=0 then exit;

  Size:=St^.GetSize;

  GetMem(Buffer,Size);

  If Size>0 then
    begin
      St^.Seek(0);
      St^.Read(Buffer^,Size);
    end;

  St^.Seek(0);
  St^.Truncate;
  St^.Reset;

  St^.Write(P^,StrLen(P));
  If Size>0 then  St^.Write(Buffer^,Size);

  FreeMem(Buffer,Size);
end;

Function objStreamSearchChar(S:PStream;Chars:TCharset):longint;
Type
  TBuffer = array[1..cBuffSize] of char;
Var
  Buffer:^TBuffer;
  BufferLen:longint;
  i : longint;
  StreamSize : longint;
  TempPos : longint;
begin
  objStreamSearchChar:=-1;

  TempPos:=S^.GetPos;
  StreamSize:=S^.GetSize;

  New(Buffer);

  While S^.GetPos<StreamSize-1 do
    begin
      BufferLen:=SizeOf(Buffer^);

      If StreamSize-S^.GetPos-1<BufferLen
        then BufferLen:=StreamSize-1-S^.GetPos;

      S^.Read(Buffer^,BufferLen);

      For i:=1 to BufferLen do if Buffer^[i] in Chars then
        begin
          objStreamSearchChar:=S^.GetPos-(BufferLen-i);
          Dispose(Buffer);
          S^.Seek(TempPos);
          exit;
        end;
    end;

  Dispose(Buffer);
  S^.Seek(TempPos);
end;

Function objStreamSearchCharBack(S:PStream;Chars:TCharset):longint;
Type
  TBuffer = array[1..cBuffSize] of char;
Var
  Buffer:^TBuffer;
  BufferLen:longint;
  TempPos : longint;
  i : longint;
begin
  objStreamSearchCharBack:=-1;

  TempPos:=S^.GetPos;

  New(Buffer);

  While S^.GetPos>0 do
    begin
      BufferLen:=SizeOf(Buffer^);

      If S^.GetPos+1<BufferLen
        then BufferLen:=S^.GetPos+1;

      S^.Seek(S^.GetPos-BufferLen);
      S^.Read(Buffer^,BufferLen);

      For i:=1 to BufferLen do if Buffer^[i] in Chars then
        begin
          objStreamSearchCharBack:=S^.GetPos-(BufferLen-i);
          Dispose(Buffer);
          S^.Seek(TempPos);
          exit;
        end;
    end;

  Dispose(Buffer);
  S^.Seek(TempPos);
end;

Function objStreamCountLines(S:PStream):longint;
Type
  TBuffer = array[1..cBuffSize] of byte;
Var
  Buffer:^TBuffer;
  BufferLen:longint;
  i : longint;
  StreamSize : longint;
  Counter : LongInt;
begin
  StreamSize:=S^.GetSize;
  S^.Seek(0);
  Counter:=0;

  New(Buffer);

  While S^.GetPos<StreamSize-1 do
    begin
      BufferLen:=SizeOf(Buffer);

      If StreamSize-S^.GetPos-1<BufferLen
        then BufferLen:=StreamSize-1-S^.GetPos;

      S^.Read(Buffer^,BufferLen);

      For i:=1 to BufferLen do if Buffer^[i]=13 then inc(Counter);
    end;

  If Buffer^[BufferLen]<>13 then Inc(Counter);


  Dispose(Buffer);

  objStreamCountLines:=Counter;
end;

procedure AssignStr(var P:PString;const S:string);
begin
  If P<>nil then DisposeStr(P);
  P:=NewStr(S);
end;

end.
