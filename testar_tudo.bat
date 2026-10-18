@echo off
rem Verificacao completa do projecto EmojiDictionary (ficha 3).
rem Uso: duplo-clique, ou  testar_tudo.bat  numa consola.
setlocal
cd /d "%~dp0"
echo ============================================================
echo  EmojiDictionary - verificacao do projecto (ficha 3)
echo ============================================================
python Tools\verify_project.py
if errorlevel 1 (
  echo.
  echo RESULTADO: FALHOU - ver a lista de falhas acima.
  exit /b 1
)
echo.
echo RESULTADO: todas as verificacoes passaram.
echo Documentos: ..\DDM_Ficha3_EmojiDictionary_Relatorio.pdf e ..\DDM_Ficha3_EmojiDictionary_Tutorial.pdf
endlocal
