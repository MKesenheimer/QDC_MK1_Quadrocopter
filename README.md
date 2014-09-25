QDC MK1 Quadrocopter
====================

Software für einen Miniatur Quadrocopter (Nanocopter) auf Grundlage der MultiWii-Software. Es wird kein Arduino, sondern ein eigenständiger Flightcontroller (AtXmega32A4) verwendet. Die Software, mit der der Quadrocopter kalibriert werden kann, läuft momentan nur unter Mac OS X.

Um die Software zu kompilieren, müssen die Mac OSX Entwicklertools (XCode) oder GNU g++ installiert sein. Außerdem wird avr-gcc und ein Hardware Programmer (z.B. JTAGICE 3) benötigt.

Kompilieren und Hochladen über PDI der Firmware auf den Quadrocopter:
---------------------------------------------------------------------
- cd firmware
- ./make_Wall oder ./make
- make flash

Erzeugen der GUI QuadroCalibration:
-----------------------------------
- QuadroCalibration.xcodeproj mit XCode öffnen
- kompilieren

Sonstiges:
----------
- der Quadrocopter muss über die serielle Schnittstelle USARTD1 mit dem Computer verbunden werden. Dazu bietet sich ein Arduino an, der standardmäßig ein USB-zu-Seriell-Konverter besitzt. Wichtig: Pegel von 3.3V nicht überschreiten!
- an der seriellen Schnittstelle USARTD0 muss der RC-Empfänger angeschlossen werden (nicht im Schaltplan verzeichnet). In dieser Software Version wird ein DSM2 fähiger Deltang rx31b-K1 verwendet.

Der Quadrocopter lässt sich über eine bestimmte Hebelstellung der Fernsteuerung scharfstellen (Motoren an/aus) und neu initialisieren (Selbstkalibrierung von GYRO und ACCELEROMETER). Siehe dazu main.c 

Bekannte Fehler
---------------
- kein Failsafe implementiert
- keine Spannungsüberwachung
- PID-Werte noch nicht optimal


Bei Fragen, Anregungen, Wünsche und Verbesserungsvorschläge bin ich unter m.kesenheimer@gmx.net erreichbar.