:: @echo off
FOR /F "tokens=* USEBACKQ" %%g IN (`where.exe pp.bat`) do (SET "PPPATH=%%g")

%pppath% -o ../range_card_parser.exe src/range_card_parser.pl
