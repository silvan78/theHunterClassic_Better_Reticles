:: @echo off
FOR /F "tokens=* USEBACKQ" %%g IN (`where.exe pp.bat`) do (SET "PPPATH=%%g")

%pppath% -o ../range_card_parser.exe range_card_parser/range_card_parser.pl
