@echo off
for /R %%f in (*.o, *.ppu, *.or) do (
  del %%f
)

del /S /Q .\build\*
rd .\build\lng
rd .\build\scripts
rd .\build\tpls