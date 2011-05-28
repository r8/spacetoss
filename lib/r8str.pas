{
 Strings handling stuff.
 (c) by Sergey Storchay (2:462/117@fidonet), 2000-2001.
 Portions (c) by sergey korowkin aka sk (2:6033/27@fidonet), 2000.
 Portions (c) by Vladimir S. Lokhov (2:5022/18.14), 1994-2000.
 Portions (c) by TurboPower Software 1987, 1992, 1994.
}
Unit r8Str;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  objects;

const
  strLetters : set of char = ['0'..'9','A'..'Z','a'..'z','.','_'];
  strDigits  : array[0..35] of char = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  strBrackets : set of char = ['"'];

Type
  Long = record
    LowWord  : word;
    HighWord : word;
  end;

Function strUpCaseChar(C:char):char;
Function strLoCaseChar(C:char):char;
Function strUpper(S:string):string;
Function strLower(S:string):string;

Function strTrimL(const S:string;const C:TCharSet):string;
Function strTrimR(S:string;const C:TCharSet):string;
Function strTrimB(const S:string;C:TCharSet):string;

Function strPadR(const S:string;const C:char;const N:byte):string;
Function strPadL(const S:string;const C:char;const N:byte):string;

Function strRightStr(const S:string;const N:byte):string;
Function strLeftStr(const S:string;const N:byte):string;

Function strParser(const S:string;const N:word;const C:TCharSet):string;
Function strNumbOfTokens(const S:string;const C:TCharSet):word;
Function strTokenPos(const N:byte;const S:string;const C:TCharSet):word;

Function strParserEx(const S:string;const N:word;const C,Quote:TCharSet):string;
Function strNumbOfTokensEx(const S:string;const C,Quote:TCharSet):word;
Function strTokenPosEx(const N:byte;const S:string;const C,Quote:TCharSet):word;

Function strReplaceChar(S:string;const c1,c2:char):string;
Procedure strSplitWords(const S:string;Var First,Last:string);

Function strStrToInt(const S:string):longint;
Function strIntToStr(const I:longInt):string;

Function strByteToHex(const b:byte):string;
Function strWordToHex(const w:word):string;
Function strLongToHex(const l:longInt):string;

Function strHexToInt(const S:string):longint;

Function strLongToAny(l:longint;const base:byte):string;
Function strAnyToLong(const S:string;const base:byte):longint;

Function strRealToStr(R:real):string;

Function strWildcard(const Src,Mask:string):Boolean;
Function strWildCardEx(S,Wild:string):boolean;

implementation

{ From wizard.pas by sergey korowkin aka sk (2:6033/27@fidonet)}
Function strUpCaseChar(C:char):char;
begin
  case C of
    'a'..'z': C:=chr(ord(C)-(97-65));
    ' '..'¯': C:=chr(ord(C)-(160-128));
    'à'..'ï': C:=chr(ord(C)-(224-144));
    'ñ'     : C:='ð';
  end;

  strUpCaseChar:=C;
end;

{ From wizard.pas by sergey korowkin aka sk (2:6033/27@fidonet)}
Function strLoCaseChar(C:char):char;
begin
  case C of
   'A'..'Z': C:=chr(ord(C)+(97-65));
   '€'..'': C:=chr(ord(C)+(160-128));
   ''..'Ÿ': C:=chr(ord(C)+(224-144));
   'ð'     : C:='ñ';
  end;

  strLoCaseChar:=C;
end;

{ From wizard.pas by sergey korowkin aka sk (2:6033/27@fidonet)}
Procedure StUpcaseEx(var S:string);assembler;
{&USES ESI, EDI, EAX, ECX}
asm
  {$IFDEF VER70}
  push ds
  {$ENDIF}
  cld
  {$IFNDEF VER70}
  mov esi, [S]
  mov edi, [S]
  {$ELSE}
  lds si, S
  les di, S
  {$ENDIF}
  lodsb
  stosb
  {$IFNDEF VER70}
  xor ah, ah
  movzx ecx, ax
  {$ELSE}
  xor ch, ch
  mov cl, al
  {$ENDIF}
  cmp al, 0
  jz @@2
 @@1:
  lodsb

  {$IFDEF VER70}
  push ds
  push ax
  {$ELSE}
  push eax
  {$ENDIF}
  call strUpCaseChar
  {$IFDEF VER70}
  pop ds
  {$ENDIF}

  stosb
  loop @@1
 @@2:
  {$IFDEF VER70}
  pop ds
  {$ENDIF}
end;

{ From wizard.pas by sergey korowkin aka sk (2:6033/27@fidonet)}
Procedure StLocaseEx(var S:string);assembler;
{&USES ESI, EDI, EAX, ECX}
asm
  {$IFDEF VER70}
  push ds
  {$ENDIF}
  cld
  {$IFNDEF VER70}
  mov esi, [S]
  mov edi, [S]
  {$ELSE}
  lds si, S
  les di, S
  {$ENDIF}
  lodsb
  stosb
  {$IFNDEF VER70}
  xor ah, ah
  movzx ecx, ax
  {$ELSE}
  xor ch, ch
  mov cl, al
  {$ENDIF}
  cmp al, 0
  jz @@2
 @@1:
  lodsb

  {$IFDEF VER70}
  push ds
  push ax
  {$ELSE}
  push eax
  {$ENDIF}
  call strLoCaseChar
  {$IFDEF VER70}
  pop ds
  {$ENDIF}

  stosb
  loop @@1
 @@2:
  {$IFDEF VER70}
  pop ds
  {$ENDIF}
end;

{ From wizard.pas by sergey korowkin aka sk (2:6033/27@fidonet)}
Function strLower(S:string):string;
begin
{$IFDEF FPC}
  S:=LowerCase(S);
{$ELSE}
  StLocaseEx(S);
{$ENDIF}
  strLower:=S;
end;

{ From wizard.pas by sergey korowkin aka sk (2:6033/27@fidonet)}
Function strUpper(S:string):string;
begin
{$IFDEF FPC}
  S:=UpCase(S);
{$ELSE}
  StUpcaseEx(S);
{$ENDIF}
  strUpper:=S;
end;

Function strTrimL(const S:string;const C:TCharSet):string;
var
  i:integer;
begin
  i:=1;
  While S[i] in C do Inc(i);
  strTrimL:=Copy(S,i,Length(S));
end;

Function strTrimR(S:string;const C:TCharSet):string;
begin
  While (Length(S)>0) and (S[Length(S)] in C) do Dec(S[0]);
  strTrimR:=S;
end;

Function strTrimB(const S:string;C:TCharSet):string;
begin
 strTrimB:=strTrimL(strTrimR(S,C),C);
end;

Function strPadR(const S:string;const C:char;const N:byte):string;
Var
  sTemp : string;
  Len : byte absolute S;
begin
  sTemp:=S;
  sTemp[0]:=Chr(N);

  If Length(S)<N then
    begin
      Move(S[1], sTemp[1], Len);
      If Len<255 then FillChar(sTemp[Succ(Len)],N-Len,C);
    end;

  strPadR:=sTemp
end;

Function strPadL(const S:string;const C:char;const N:byte):string;
Var
  sTemp : string;
  Len : byte absolute S;
begin
  sTemp:=S;
  sTemp[0]:=Chr(N);

  If Length(S)<N then
    begin
      If Len<255 then
        begin
          Move(S[1], sTemp[Succ(Word(N))-Len], Len);
          FillChar(sTemp[1], N-Len, C);
        end;
    end
    else
    begin
      sTemp:=Copy(S,succ(length(S)-N),N);
    end;

  strPadL:=sTemp
end;

Function strNumbOfTokens(const S:string;const C:TCharSet):word;
Var
 N : word;
 i : byte;
 Len : byte absolute S;
begin
  N:=0;
  i:=1;

  While i<=Len do
    begin
      While (i<=Len) and (S[i] in C) do Inc(i);
      If i<=Len then Inc(N);
      While (i<=Len) and not(S[i] in C) do Inc(i);
    end;

  strNumbOfTokens:=N;
end;

Function strTokenPos(const N:byte;const S:string;const C:TCharSet):word;
Var
  N1 : word;
  i : byte;
  Len : byte absolute S;
begin
  N1:=0;
  i:=1;
  strTokenPos:=0;

  While (i<=Len) and (N1<>N) do
    begin
      While (i<=Len) and (S[I] in C) do Inc(I);

      If i<=Len then Inc(N1);

      If N1<>N then
        While (i<=Len) and not (S[I] in C) do Inc(i)
      else strTokenPos:=i;

    end;
end;

Function strParser(const S:string;const N:word;const C:TCharSet):string;
Var
  N1 : word;
  i,l : byte;
  Len : byte absolute S;
  sTemp : string;
begin
  N1:=0;
  i:=1;
  l:=0;
  sTemp:='';

  While (i<=Len) and (N1<>N) do
    begin
      While (i<=Len) and (S[I] in C) do Inc(I);
      If i<=Len then Inc(N1);

      While (i<=Len) and not (S[I] in C) do
        begin
          If N1=N then
            begin
              Inc(sTemp[0]);
              sTemp[byte(sTemp[0])]:=S[I];
            end;
          Inc(I);
        end;
    end;

  strParser:=sTemp;
end;

Function strNumbOfTokensEx(const S:string;const C,Quote:TCharSet):word;
Var
  Count : byte;
  i : word;
  InQuote : boolean;
  Len : byte absolute S;
begin
  Count:=0;
  i:=1;
  InQuote:=False;

  While i<=Len do
    begin
      while (i<=Len) and (not(S[i] in Quote)) and (S[i] in C) do
        begin
          if i=1 then Inc(Count);
          Inc(i);
        end;

      If i<=Len then Inc(Count);

      While (i<=Len) and ((InQuote) or (not(S[i] in C))) do
        begin
          If S[i] in Quote then InQuote:=not(InQuote);
          Inc(i);
      end;
    end;

  strNumbOfTokensEx:=Count;
end;

Function strTokenPosEx(const N:byte;const S:string;const C,Quote:TCharSet):word;
Var
  Count : byte;
  i : word;
  InQuote : boolean;
  Len : byte absolute S;
begin
  Count:=0;
  i:=1;
  InQuote:=False;
  strTokenPosEx:=0;

  While (i<=Len) and (Count<>N) do
    begin
      If (i<=Len) and (not (S[i] in Quote)) and (S[i] in C) then
        begin
          If i=1 then Inc(Count);
          Inc(i);
        end;

      If i<=Len then Inc(Count);

      If Count<>N then
        while (i<=Len) and ((InQuote) or (not(S[i] in C))) do
          begin
            if S[i] in Quote then InQuote:=not(InQuote);
            Inc(i);
          end
      else strTokenPosEx:=i;
  end;
end;

Function strParserEx(const S:string;const N:word;const C,Quote:TCharSet):string;
Var
  i : word;
  Len : byte;
  SLen : byte absolute S;
  InQuote : Boolean;
  sTemp : string;
begin
  Len:=0;
  InQuote:=False;
  sTemp:='';

  i:=strTokenPosEx(N,S,C,Quote);

  If i<>0 then
    while (i<=SLen) and ((InQuote) or (not(S[i] in C))) do
      begin
        Inc(Len);
        If S[i] in Quote then InQuote:=Not(InQuote) else
          begin
            Inc(sTemp[0]);
            sTemp[byte(sTemp[0])]:=S[i];
          end;
        Inc(i);
      end;

  strParserEx:=sTemp;
end;

Procedure strSplitWords(const S:string;Var First, Last:string);
begin
  First:=strParser(S,1,[#32,#8]);
  If Pos(#32,S)=0 then Last:='' else
         Last:=Copy(S,Pos(#32,S)+1,Length(S)-Pos(#32,S)+1);
end;

Function strStrToInt(const S:string):longint;
Var
  i:longint;
{$IFDEF VIRTUALPASCAL}
  i2 : longint;
{$ELSE}
  i2 : integer;
{$ENDIF}
begin
  Val(S,i,i2);
  strStrToInt:=i;
end;

Function strIntToStr(const i:longInt):string;
Var
  s : string;
begin
  Str(i,s);
  strIntToStr:=s;
end;

Function strRealToStr(R:real):string;
var
  C,D:longint;
  S:string;
begin
  C:=Trunc(Int(R));
  D:=Trunc(Frac(R)*100);
  strRealToStr:=strIntToStr(C)+'.'+strIntToStr(D);
end;

{
  From Object Professional 1.30.
  (c) by TurboPower Software 1987, 1992, 1994.
}
Function strByteToHex(const b:byte):string;
begin
  strByteToHex[0]:=#2;
  strByteToHex[1]:=strDigits[b shr 4];
  strByteToHex[2]:=strDigits[b and $F];
end;

{
  From Object Professional 1.30.
  (c) by TurboPower Software 1987, 1992, 1994.
}
Function strWordToHex(const w:word):string;
begin
  strWordToHex[0]:=#4;
  strWordToHex[1]:=strDigits[hi(w) shr 4];
  strWordToHex[2]:=strDigits[hi(w) and $F];
  strWordToHex[3]:=strDigits[lo(w) shr 4];
  strWordToHex[4]:=strDigits[lo(w) and $F];
end;

{
  From Object Professional 1.30.
  (c) by TurboPower Software 1987, 1992, 1994.
}
Function strLongToHex(const l:longInt):string;
begin
  With Long(l) do
    strLongToHex:=strWordToHex(HighWord)+strWordToHex(LowWord);
end;

Function strHexToInt(const S:string):LongInt;
Var
  i,Sum,Divi:longInt;
  Illegal:boolean;
Begin
  Illegal:=False;
  Sum:=0; Divi:=1;
  For i:=Length(s) DownTo 1 Do
  Begin
    If s[i] in ['0'..'9'] Then Sum:=Sum+((Ord(s[i])-48)*Divi)
    Else If UpCase(s[i]) in ['A'..'F'] Then Sum:=Sum+((Ord(UpCase(s[i]))-55)*Divi)
    Else Illegal:=True;
    Divi:=Divi shl 4;
  End;
  If Illegal Then strHexToInt:=-1 Else strHexToInt:=Sum;
End;

Function strLongToAny(l:longint;const base:byte):string;
Var
  b : byte;
  sTemp : string;
begin
  sTemp:='';

  If base in [2..36] then
    begin
      repeat
        b:=l mod base;
        l:=l div base;
        sTemp:=strDigits[b]+sTemp;
      until l=0;
    end;

  strLongToAny:=sTemp;
end;

Function strAnyToLong(const S:string;const base:byte):longint;
Var
  b : byte;
  lTemp : longint;
begin
  lTemp:=-1;

  If base in [2..36] then
    begin
      lTemp:=0;
      For b:=1 to byte(S[0]) do
        lTemp:=lTemp*base+(Pos(Copy(S,b,1),strDigits)-1);
    end;

  strAnyToLong:=lTemp;
end;

Function strRightStr(const S:string;const n:byte):string;
Var
  sTemp : string;
begin
  If n>length(S) then strRightStr:=S
    else strRightStr:=Copy(S,succ(length(S)-n),n);
end;

Function strLeftStr(const S:string;const n:byte):string;
begin
  If n>length(S) then strLeftStr:=S
    else strLeftStr:=Copy(S,1,n);
end;

{
  strWildcard (WildEqu)
  (c) by Vladimir S. Lokhov <vsl@tula.net> <2:5022/18.14>, 1994-2000.
}
Type
 TCheckWildcardStack = record
  Src, Mask: Byte;
 end;

Function strWildcard(const Src, Mask: string):Boolean;
 var
  Stack: array[1..128] of TCheckWildcardStack;
  StackPointer,
  SrcPosition, MaskPosition,
  SrcLength, MaskLength: Byte;
 begin
  strWildCard:=False;

  if not ((Src = '') xor (Mask <> '')) then
   Exit;

  MaskLength:=Length(Mask);
  SrcLength:=Length(Src);

  if Mask[MaskLength] <> '*' then
   while (MaskLength > 1) and (SrcLength > 1) do
    begin
     if (Mask[MaskLength] = '*') or (Mask[MaskLength] = '?') then
      Break;

     if Mask[MaskLength] <> Src[SrcLength] then
      Exit;

     Dec(MaskLength);
     Dec(SrcLength);
    end;

  if Mask[MaskLength] = '*' then
   while (Mask[MaskLength - 1] = '*') and (MaskLength > 1) do
    Dec(MaskLength);

  StackPointer:=0;

  SrcPosition:=1;
  MaskPosition:=1;

  while (SrcPosition <= SrcLength) and (MaskPosition <= MaskLength) do
   begin
    case Mask[MaskPosition] of
     '?':
      begin
       Inc(SrcPosition);
       Inc(MaskPosition);
      end;
     '*':
      begin
       if (MaskPosition = 1) or (Mask[MaskPosition - 1] <> '*') then
        Inc(StackPointer);

       Stack[StackPointer].Mask:=MaskPosition;

       Inc(MaskPosition);

       if MaskPosition <= MaskLength then
        if (Mask[MaskPosition] <> '?') and (Mask[MaskPosition] <> '*') then
         while (SrcPosition <= Length(Src)) and (Src[SrcPosition] <> Mask[MaskPosition]) do
          Inc(SrcPosition);

       Stack[StackPointer].Src:=SrcPosition + 1;
      end;
    else
     if Src[SrcPosition] = Mask[MaskPosition] then
      begin
       Inc(SrcPosition);
       Inc(MaskPosition);
      end
     else
      begin
       if StackPointer = 0 then
        Exit;

       SrcPosition:=Stack[StackPointer].Src;
       MaskPosition:=Stack[StackPointer].Mask;

       Dec(StackPointer)
      end;
    end;

    while not ((SrcPosition <= SrcLength) xor (MaskPosition > MaskLength)) do
     begin
      if (MaskPosition >= MaskLength) and (Mask[MaskLength] = '*') then
       Break;

      if StackPointer = 0 then
       Exit;

      SrcPosition:=Stack[StackPointer].Src;
      MaskPosition:=Stack[StackPointer].Mask;

      Dec(StackPointer)
     end;
   end;

  strWildCard:=True;
end;

Function strReplaceChar(S:string;const c1,c2:char):string;
begin
  While Pos(c1,S)<>0 do S[Pos(c1,S)]:=c2;
  strReplaceChar:=S;
end;

Function strWildCardEx(S:string;Wild:string):boolean;
Var
  Invert : boolean;
begin
  strWildCardEx:=False;
  Invert:=False;

  S:=strUpper(S);
  Wild:=strUpper(Wild);

  If Wild[1]='!' then
    begin
      Invert:=True;
      Wild:=strTrimL(Wild,['!']);
    end;

  If Wild[1]='~' then
  begin
    Wild:=strTrimL(Wild,['~']);

    If Pos(Wild,S)<>0 then
        If not Invert then strWildCardEx:=True;

  end
  else
  begin

    If strWildCard(S,Wild) then
      If not Invert then strWildCardEx:=True;
  end;

end;

end.
