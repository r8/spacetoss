fpc -TGo32v2 -Fu./lib -Fu./lib/* -So -Og -Xs -XX -O3p1 -dRELEASE ./src/spctoss.pas
fpc -TGo32v2 -Fu./lib -Fu./lib/* -So -Og -Xs -XX -O3p1 -dRELEASE ./src/lng/spcres.pas

@call ./clean.cmd

move /Y .\src\*.exe .\build
copy .\src\*.lng .\build
copy .\cfg\*.* .\build

mkdir .\build\lng
copy .\src\lng\*.src .\build\lng
move /Y .\src\lng\*.exe .\build\lng

mkdir .\build\tpls
copy .\src\tpls\* .\build\tpls

mkdir .\build\scripts
copy .\src\scripts\* .\build\scripts