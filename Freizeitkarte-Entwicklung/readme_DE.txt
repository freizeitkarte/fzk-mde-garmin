Freizeitkarte-OSM.de - Entwicklungsumgebung
Readme.txt - 26.09.2013 - Klaus Tockloth

Diese  Entwicklungsumgebung ist lauffähig unter OS X, Windows und Linux
Das Hauptverzeichnis in dem die komplette Entwicklungsumgebung beim Entpacken abgelegt wird lautet:
   Freizeitkarte-Entwicklung

Der Name dieses Verzeichnisses kann frei gewählt werden, darf jedoch keine Leerzeichen enthalten.
Namen von Unterverzeichnissen des Hauptverzeichnises dürfen keinesfalls abgeändert werden.

Die Entwicklungsumgebung kann auch vollständig auf einem externen Datenträger installiert sein 
und von dort aus genutzt werden.
Direkt im Hauptverzeichnis befindet sich das Utility "mt.pl" (MapTool), das von hier aus aufgerufen wird. 
Vorbedingungen:
- Perl (mind. Version 5.10) muß installiert sein
- Java (mind. Version 7) muß installiert sein
- Computer verfügt über mindestens 2 GB Hauptspeicher
 
Terminal / Kommandofenster:
- die Arbeitsschritte zur Erzeugung einer Karte erfolgen über ein Terminal
  Synonym für Terminal in einer Windowsumgebung lautet oft auch "Kommandofenster"
- hier sind einzelne Kommandos nacheinander manuell einzugeben 
  sie können alternativ auch mit entsprechenden Batchdateien abgearbeitet werden


Ruft man das Utility "perl mt.pl" (MapTool) ohne Parameter auf, wird ein minimaler Hilfetext ausgegeben.
Ein umfangreicher Hilfetext wird durch "perl mt.pl -?" erzeugt.


Minimaler Befehlsaufruf zur Erstellung einer Freizeitkarte (Beispiel: Freizeitkarte_Saarland):

Wechseln Sie zunächst in das Hauptverzeichnis der Entwicklungsumgebung:
 
   cd Freizeitkarte-Entwicklung (o.ä.)

Um eine lauffähige Entwicklungsumgebung zu kriegen, müssen noch die sogenannten boundary files nachgeladen werden (ca 450 MB).
Dies ist nur beim ersten mal nötig, danach sind die Dateien in der Entwicklungsumgebung vorhanden.
Dafür wird das folgende Kommando benötigt:

   perl mt.pl bootstrap

Nun können die Karten gebildet werden:

1. perl mt.pl create Freizeitkarte_Saarland
2. perl mt.pl fetch_osm Freizeitkarte_Saarland
   perl mt.pl fetch_ele Freizeitkarte_Saarland
3. perl mt.pl join Freizeitkarte_Saarland
4. perl mt.pl split Freizeitkarte_Saarland
5. perl mt.pl build Freizeitkarte_Saarland
6. je nachdem wofür die erstellte Karte weitere Verwendung finden soll:
   - Erzeugen einer gmap-Datei zur Installation unter OS X ("Garmin MapManager")
     perl mt.pl gmap Freizeitkarte_Saarland
   - Erzeugen einer ausführbaren Windows-Installerdatei
     perl mt.pl nsis Freizeitkarte_Saarland
   - Erzeugen einer gmapsupp-Image-Datei für ein Garmin-GPS
     perl mt.pl gmapsupp Freizeitkarte_Saarland

Um besondere Karte (wie beispielsweise Freizeitkarte_DEU+) zu bilden muss der oben beschriebene Ablauf angepasst werden:
- bei fetch_osm wird anstatt Freizeitkarte_DEU+ die übergeordnete Region Freizeitkarte_EUROPE geladen
- vor fetch_ele wird extract_osm Freizeitkarte_DEU+ ausgeführt

Schalter:
In den Kartenstyles sind einige logische Schalter (bedingte Übersetzung) eingebaut, die aktiviert werden können:
Die Syntax um diese Schalter aufzurufen ist folgende
     perl mt.pl build <Karte> D<Schalter>
Also zum Beispiel
     perl mt.pl build Freizeitkarte_Saarland DKULTURLAND

Folgende Schalter existieren:
- WINTERSPORT: Darstellung von Linien für Wintersportaktivitäten (Pisten, Loipen, ...) [lines-master]
- T36ROUTING: Routing auch über (Berg-)Wanderwege der Klassen T3-T6 [lines-master]
- TRIGMARK: Darstellung von Trigonometrischen Markierungen [points-master]
- NODRINKINGWATER: Abschalten der Darstellung von Trinkwasserstellen [points-master]
- KULTURLAND: Darstellung von Ackerflächen [polygons-master]


   

Anmerkungen:
- der Einstieg in die Kartenentwicklung sollte mit einer möglichst kleinen Karte erfolgen (z.B. Freizeitkarte_Saarland)
- der Buildprozeß einer kompletten Deutschlandkarte dauert bei Verwendung eines Standard-PC mit 4GB RAM mehr als 7 Stunden
- unter 64-Bit Linux-Systemen muss die Unterstützung für 32-Bit Programme installiert sein
- für das Erstellen des Windows-Installers unter Linux muss das Paket NSIS (Nullsoft Scriptable Install System) installiert sein




Verzeichnisstruktur der Entwicklungsumgebung

Das Utility arbeitet mit der nachfolgend beschriebenen Verzeichnisstruktur und ist der zentrale Bestandteil der Entwicklungsumgebung.
Wir unterscheiden zwischen einer Grundstruktur und den Arbeitsverzeichnissen, welche im Laufe des Kartenerstellungsprozesses angelegt werden.



Grundstruktur:
Diese Verzeichnisse entstehen automatisch im Hauptverzeichnis beim Entpacken der Archivdatei


Freizeitkarte-Entwicklung/bounds:
Ablageort der Grenzdaten, die bei der Indexierung (z.B. für Adresssuche) benötigt werden.
Diese Dateien werden mit dem 'boostrap' Befehl in die Entwicklungsumgebung nachgeladen und integriert.

Freizeitkarte-Entwicklung/cities:
Ablageort der Geodaten aller Städte mit mehr als 15000 Einwohner.
Diese Daten werden benötigt, um beim Split-Prozeß den resultierenden Kacheln "sprechende" Namen zu geben.

Freizeitkarte-Entwicklung/nsis:
Konfigurationsdateien von nsis

Freizeitkarte-Entwicklung/poly:
Ablageort der Polygone von Sonderkarten (Skandinavien, Alpen, BeNeLux etc.)

Freizeitkarte-Entwicklung/sea:
Ablageort der Küstenlinien Europas.
Diese Datei wird beim Build-Prozeß für die Darstellung der Meere benötigt.
Diese Dateien werden mit dem 'boostrap' Befehl in die Entwicklungsumgebung nachgeladen und integriert.

Freizeitkarte-Entwicklung/style:
Ablageort für alle Dateien über die der Karteninhalt definiert wird:
- polygons
- lines
- points
- ...

Freizeitkarte-Entwicklung/tools:
Ablageort aller Tools für die eigentliche Kartenerzeugung:
- splitter
- mkgmap
- ...

Freizeitkarte-Entwicklung/tools/TYPViewer/windows:
Ablageort der Installationsdatei für den lokalen TYP-Editor "TYPViewer".
Der TYP-Editor ist nur in einer Windowsumgebung lauffähig. Er ist aber für die Erstellung der Karten nicht nötig.
Vor der eigentlichen Benutzung, muss er durch Aufruf des Programmes "Setup" installiert werden.
Dieses Programm besitzt aktuell eine englische oder französische Menüführung.

Freizeitkarte-Entwicklung/translations:
Ablageort für Übersetzungen verwendeter Begriffe in Master-STYLE- bzw. Master-TYP-Dateien.
Diese werden je nach Sprachgrundeinstellung der Zielkarte bzw. Sprachauswahl beim Aufruf des MapTools verwendet.

Freizeitkarte-Entwicklung/TYP:
Ablageort für binäre TYP-Dateien über welche das Design einer Karte definiert werden kann.
Hier liegt zunächst lediglich verschiedene Master-TYP-Datei (freizeit.TYP, contrast.TYP, small.TYP etc.)
Für das abweichende Design einer Zielkarte ist eine spezifische TYP-Datei (mit korrekter Family-ID) erforderlich.
Diese wird im Erstellungsprozess via "set-typ.pl"-Utility aus der jeweils ausgewählten Master-TYP-Datei abgeleitet.
Daraus folgt: Eigenständige Veränderungen an TYP-Datei sind immer an einer/allen Master-TYP-Datei/en vorzunehmen.

Freizeitkarte-Entwicklung/windows/wget:
Ablageort für das Utility "wget".
Hiermit kann unter Windows ein OSM-Daten-Extrakt aus dem Internet geladen werden.
Das Utility von MapTool aufgerufen und ist nur unter Windows lauffähig.
Unter OS X und Linux wird hierfür das Utility "curl" verwendet, das im Betriebssystem bereits enthalten ist.




Arbeitsverzeichnisse:
Folgende Verzeichnisse werden im Zuge der Kartenerstellung erzeugt und befüllt. 
Sie können am Ende auch wieder komplett gelöscht werden, da das Vorhandensein beim nächsten Start geprüft wird
und sie ggf. erneut erzeugt werden.
Durch Aufruf des Befehls "mt.pl create <"Kartenname">" kann z.B. zu Beginn einer Kartenerstellung 
ebenfalls der Ausgangszustand für diese Karte (wieder) hergestellt werden.


Freizeitkarte-Entwicklung/install:
Hier befindet sich für jede erzeugte Karte ein weiteres Unterverzeichnis.
Der Verzeichnisname entspricht hier dem Kartennamen.

Freizeitkarte-Entwicklung/install/"Kartenname":
Ablageort für alle direkt installierbaren Kartendateien und deren komprimierter Versionen (Zip Datein):
- *.gmap = Installationsdatei für OS X (und Windows)
- *.exe = Installer für Windows
- gmapsupp.img = Kartenimage für GPS-Gerät

Freizeitkarte-Entwicklung/work:
Hier befindet sich für jede erzeugte Karte ein weiteres Unterverzeichnis.
Der Verzeichnisname entspricht dem Kartennamen.

Freizeitkarte-Entwicklung/work/"Kartenname":
Ablageort für alle im Rahmen des Erzeugungsprozesses anfallenden Dateien.
Aus dem Build-Prozess resultierende Installdateien werden in das Verzeichnis "install" verschoben.
