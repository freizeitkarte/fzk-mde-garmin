@set __prev_logincr=%__logincr%
@call sl + ppp -q
@rem if "%PP_PERLPATH%" == "" set PP_PERLPATH=%binpath%\bat\Preproc
@if "%PP_PERLPATH%" == "" set PP_PERLPATH=%cd%
@perl "%PP_PERLPATH%\ppp.pl" "%~1" "%~2" %3 %4 %5 %6 %7 %8 %9
@set __logincr=%__prev_logincr%
