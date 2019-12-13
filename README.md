# Analysetechniken
Defibrillatoren in Wien - heute und in 20 Jahren


```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

## Inhalt des Projekts
Im Rahmen unseres Projekts haben wir den Bedarf von Defibrillatoren in den Wiener Gemeindebezirken heute und in 20 Jahren abgeschätzt. Hierbei haben wir die Anzahl der Defibrillatoren und deren Verteilung über das Wiener Stadtgebiet und dem Anteil von Personen über 60 Jahren in den jeweiligen Wiener Stadtbezirken gegenübergestellt. Ziel der Untersuchung ist den Bedarf nach Defibrillatoren und auch die Frage nach der ausreichenden Versorgung der alternden Bevölkerung abzuschätzen.

## Libraries
```{r message=FALSE, warning=FALSE}
library(tidyverse)    # erforderlich für die Joins der Datensätze
library(sf)           # für die Verarbeitung der Shapefiles erforderlich
library(tmap)         # für Plots notwendig
library(stringr)      # Bezirksnummer bearbeiten
```

## Verwendete Datensätze
Wir haben für das vorliegende Projekt zwei Datensätze von OpenData Österreich und einen Datensatz der Statistik Austria verwendet. Von OpenData wurden die Shapefiles für die Wiener Gemeindebezirke sowie die Defibrillatoren (Standorte der Geräte in den Bezirken) verwendet. Von Statistik Austria wurden die Daten für die Beölkerungsprognose für die Jahre 2018-28 verwendet.

Quellen der Datensätze:

[Shapefile Wiener Bezirksgrenzen](https://www.data.gv.at/katalog/dataset/stadt-wien_bezirksgrenzenwien)

[Shapefile Defibrillatoren](https://www.data.gv.at/katalog/dataset/stadt-wien_defibrillatorenstandortewien/resource/873612b1-7760-413b-9e04-f07d8085563b)

[Bevölkerungsdaten](https://www.data.gv.at/katalog/dataset/32b03b8c-e860-4416-a433-fab84cb935a6)

### Wien
#### Datenfelder
```{r echo=FALSE, message=FALSE, warning=FALSE}
library(knitr)
library(kableExtra)

spalten <-  factor(c("NAMEK", "BEZNR", "BEZ_RZ", "NAMEK_NUM", "NAMEK_RZ", "NAMEG", "LABEL", "BEZ", "DISTRICT_CODE", "STATAUSTRIA_BEZ_CODE", "STATAUSTRIA_GEM", "FLAECHE", "UMFANG", "AKT_TIMESTAMP", "geometry"))
datentyp <- factor(c("String", "Numeric", "String", "String", "String", "String", "String", "String", "Numeric", "Numeric", "Numeric", "Numeric", "Numeric", "Date", "Geometry Type"))
beschreibung <- factor(c("Bezirksname (Wiener Gemeindebezirksname)", "Bezirksnummer", "Bezirksnummer (in römischen Zahlen)", "Bezirksnummern kombiniert mit dem Bezirksnamen", "Bezirksnummern (in römischen Zahlen) kombiniert mit dem Bezirksnamen", "Bezirksname", "Bezirksnummer (in römischen Zahlen)", "Bezirksnummer", "Bezirkscode", "Bezirkscode gem. Spezifikation der Statistik Austria", "Gemeindecode gem. Spezifikation der Statistik Austria", "Fläche in Quadratmetern", "Umfang in Metern", "Aktualisierungsdatum", "Geodaten (Koordinaten)"))

wien_data <- data.frame(spalten, datentyp, beschreibung)
colnames(wien_data) <- c("Spalten", "Datentyp", "Beschreibung")

kable(wien_data) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"))
```


#### Visualisierung der Daten
Die nachstehende Grafik zeigt die 23 Wiener Gemeindebezirke. Zur Orientierung werden die Bezirksnummern angezeigt. 
```{r results='hide'}
wien <- st_read(dsn = "Daten/BEZIRKSGRENZEOGD/BEZIRKSGRENZEOGDPolygon.shp")
```

```{r}
tm_shape(wien) + tm_borders() + tm_text("BEZ_RZ")
```

### Defibrillatoren
#### Datenfelder
```{r echo=FALSE, message=FALSE, warning=FALSE}
library(knitr)
library(kableExtra)

spalten <-  factor(c("OBJECTID", "ADRESSE", "BEZIRK", "STOCK", "INFO", "HINWEIS", "geometry"))
datentyp <- factor(c("Numeric", "String", "Numeric", "Numeric", "String", "String", "Geometry Type"))
beschreibung <- factor(c("ID des Defibrilatordatensatzes", "Adresse", "Bezirksnummer", "Stocknummer", "Information zum Defibrilator (Wo es genau zu finden ist)", "Hinweis (wie Öffnungszeiten und Verfügbarkeit)", "Geodaten (Koordinaten)"))

defi_data <- data.frame(spalten, datentyp, beschreibung)
colnames(defi_data) <- c("Spalten", "Datentyp", "Beschreibung")

kable(defi_data) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"))
```

#### Visualisierung der Daten
Die folgende Grafik zeigt die Standorte der Defibrillatoren im Wiener Stadtgebiet. Man kann bereits hier erkennen, dass es eine starke Konzentration im ersten Bezirk sowie den Bezirken innerhalb des Gürtels gibt. Die Flächenbezirke östlich der Donau erscheinen unterversorgt. 
```{r results='hide'}
defi <- st_read(dsn = "Daten/DEFIBRILLATORoGD/DEFIBRILLATORoGDPoint.shp")
```

Verteilungen der Defibrillatoren aktuell in Wien:

```{r}
a <- tm_shape(wien)
a <- a + tm_borders() 
a <- a + tm_shape(defi) + tm_dots(col='blue') 
a
```

### Bevölkerung
#### Datenfelder
```{r echo=FALSE, message=FALSE, warning=FALSE}
library(knitr)
library(kableExtra)

spalten <-  factor(c("NUTS1", "NUTS2", "NUTS3", "DISTRICT_CODE", "SUB_DISTRICT_CODE", "SEX", "AGE_00_02", "AGE_03_05", "AGE_06_09", "AGE_10_14", "AGE_15_19", "AGE_20_24", "AGE_25_29", "AGE_30_44", "AGE_45_59", "AGE_60_74", "AGE_75.", "REF_DATE"))
datentyp <- factor(c("String", "String", "String", "Numeric", "Numeric", "Numeric", "Numeric", "Numeric", "Numeric", "Numeric", "Numeric", "Numeric", "Numeric", "Numeric", "Numeric", "Numeric", "Numeric", "Date"))
beschreibung <- factor(c("Region (Gruppe von Bundesländern) ", "Region (Bundesland)", "Region (Gruppe von Bezirken)", "Gemeindebezirkskennzahl", "Zählbezirkskennzahl", "Geschlecht (1 = Mann, 2 = Frau)", "Altersgruppe 0- bis 2-Jährige", "Altersgruppe 3- bis 5-Jährige", "Altersgruppe 6- bis 9-Jährige", "Altersgruppe 10- bis 14-Jährige", "Altersgruppe 15- bis 19-Jährige", "Altersgruppe 20- bis 24-Jährige", "Altersgruppe 25- bis 29-Jährige", "Altersgruppe 30- bis 44-Jährige", "Altersgruppe 45- bis 59-Jährige","Altersgruppe 60- bis 74-Jährige", "Altersgruppe 75 und Mehrjährige", "Referenzdatum"))

bev_data <- data.frame(spalten, datentyp, beschreibung)
colnames(bev_data) <- c("Spalten", "Datentyp", "Beschreibung")

kable(bev_data) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"))
```

#### Datenaufbereitung
Als nächsten Schritt lesen wir die Bevölkerungsdaten ein und bereinigen den Datensatz um die nicht benötigten Spalten. FÜr unsere weitere Arbeit benötigen wir die Nummer der Bezirke, diese müssen wir zuerst aus der Gemeindekennziffer auslesen. Die Gemeindekennziffer wird von der Statistik Austria für alle österreichischen Gemeinden vergeben. Die 1. Stelle der Gemeindekennziffer bildet das Bundesland ab, die ersten 3 Stellen sind ident mit der Politischen Bezirkskennziffer (Quelle: [Statistik Austria](https://www.statistik.at/web_de/klassifikationen/regionale_gliederungen/gemeinden/index.html)).
```{r}
# Bevölkerunganzahl einlesen
# erste zeile nicht einlesen und header übernehmen
bev = read.csv("Daten/vie_303.csv", sep=";", skip = 1, header = TRUE)
bev <- bev[which(bev$REF_DATE == 20190101),]  # nur die aus 2019!
```

```{r}
# bezirksnummer aus district code (=Gemeindekennziffer) auslesen
# zuerst führende neun löschen, dann letzte beiden stellen löschen
bev$DISTRICT_CODE <- gsub("^9", "", bev$DISTRICT_CODE)
bev$DISTRICT_CODE <- str_sub(bev$DISTRICT_CODE, 1, str_length(bev$DISTRICT_CODE)-2)
```

```{r}
# bevölkerungsdaten um nicht benötigte spalten bereinigen
bev <- bev[ , names(bev) %in% c("DISTRICT_CODE","AGE_00_02","AGE_03_05","AGE_06_09","AGE_10_14","AGE_15_19","AGE_20_24","AGE_25_29","AGE_30_44","AGE_45_59","AGE_60_74","AGE_75.")]
```


## Analyse der Daten
Für die Analyse der Daten sollen die Bevölkerungsdaten mit dem Shapefile von Wien verknüft werden. Hierzu bringen wir die Daten in das passende Format (numeric). Zudem summieren wir die Bevölkerungszahlen auf Bezirksebene auf. Im ursprünglichen Datensatz waren die Bevölkerungsdaten auf Basis der Subbezirke (Zählbezirke für die Volkszählung) gegeben. Wir müssen diese Daten daher zuerst auf Ebene der Wiener Gemeindebezirke bringen.
```{r}
# bezirksnummer in numeric für join 
wien$BEZ = as.numeric(wien$BEZ)
bev$DISTRICT_CODE = as.numeric(bev$DISTRICT_CODE)
```

```{r}
# groupby um werte von subbezirken auf bezirke aufzusummieren
bev_bez <- aggregate(.~bev$DISTRICT_CODE, bev, sum)
# spalte DISTRICT_CODE bereinigen
bev_bez = subset(bev_bez, select = -c(DISTRICT_CODE))
```

### Methodik
Für unsere Analyse gehen wir von einem verstärkten Bedarf von Personen über 60 Jahren aus und betrachten daher für unsere Bedarfsanalyse nur diese Personengruppe. Als Basis für diese Annahme dienen die Informationen auf der Webseite des Robert Koch Instituts. In der folgenden Grafik werden die Anteile der Personen mit Herzerkrankungen an der gleichaltrigen Bevölkerung dargestellt:

![Herzerkrankungen Robert Koch Institut](Daten/InfografikHKK.jpg "Herzerkrankungen")

Quelle: [Robert Koch Institut](https://www.rki.de/DE/Content/Gesundheitsmonitoring/Themen/Chronische_Erkrankungen/HKK/HKK_node.html)

Der Anteil der Betroffenen ist bei Personen über 60 Jahren deutlich erhöht, daher haben wir für unsere Analyse diese Bevölkerungsgruppe als Personengruppe mit dem höchsten Bedarf definiert. Als nächsten Schritt berechnen wir den Anteil der über 60 jährigen pro Bezirk und joinen die Bevölkerungsdaten mit dem Shapefile für Wien. 

```{r}
# prozentualer Anteil von Personen über 60 Jahren = Hauptbetroffene von Herzinfarkten
bev_bez["gesamtBev"] <- rowSums(bev_bez [,-1])
bev_bez["Anteilueber60"] <- round((bev_bez$AGE_60_74 + bev_bez$AGE_75.) / bev_bez$gesamtBev,2)
```


```{r}
# join wien und bev_bez mit der bezirksnummer
wien_bev_merge = wien %>% left_join(bev_bez, by = c("BEZ" = "bev$DISTRICT_CODE"))
```

### Bedarf 2019
Die nachstehende Grafik zeigt den Anteil der über 60 jährigen Personen pro Gemeindebezirk und die Verteilung der Defibrillatoren über die Bezirke. Dunkler hervorgehobene Bezirke sind Regionen mit höherem Anteil von älteren Personen. Aus dieser Grafik kann man erkennen, dass die Bezirke 13, 14, 19 und 23 auch dann unterversorgt sind, wenn man die großen Grünflächen des Wienerwalds berücksichtigt. Der erste Bezirk erscheint hingegen überversorgt. Allerdings muss man hierbei anmerken dass nicht alle Defibrillatoren in diese Liste eingemeldet werden und v.a. in Unternehmen noch eine große Anzahl weiterere Geräte zur Verfügung stehen. Die Bevölkerungsanteile werden in Erdfarben dargestellt und die Defi-Standorte in blauer Farbe.

```{r}
# plotten des Bevölkerungsanteils der über 60 jährigen in den Wiener Bezirken gemeinsam
# mit den Defi-Standorten
a <- tm_shape(wien_bev_merge) + tm_fill(col = "Anteilueber60", palette = c("#f2ce7a", "#973738"), title = "Anteil über 60 jährige")
a <- a + tm_borders()
a <- a + tm_shape(defi) + tm_dots(col='blue')
a <- a + tm_legend(title = 'Bedarf 2019')
a
```

### Bedarf 2039
Die folgende Grafik zeigt den Bevölkerungsanteil der über 60 jährigen in zwanzig Jahren. Die Prognose beruht auf folgenden vereinfachten Annahmen: Wir berechnen den Bevölkerungsanteil auf Basis der heute 30 bis 60 jährigen sowie 40% der heute 60 bis 74 jährigen. D.h. wir nehmen an dass 40% der heute 60-74 jährigen ein hohes Alter erreichen werden. Das Bevölkerungswachstum und Wanderbewegungen bleiben unberücksichtigt.
Auch gehen wir in unserer Analyse von einer gleichbleibenden Anzahl und Verteilung der Defibrillatoren aus.

```{r}
# Anteil der potentiell betroffenen Bevölkerungsgruppe in 20 jahren
# dh. heute 30-60 jährige, von den heute 60-74 jährigen erreichen 40% ein hohes alter
wien_bev_merge["anteil20j"] <- round((wien_bev_merge$AGE_30_44 + wien_bev_merge$AGE_45_59 + (0.4 * wien_bev_merge$AGE_60_74)) / wien_bev_merge$gesamtBev,3)
```

```{r}
# plotten der Bevölkerungsanteile pro Bezirk und der Defi-Standorte
b <- tm_shape(wien_bev_merge) + tm_fill(col = "anteil20j", palette = c("#f2ce7a", "#973738"), title = "Anteil über 50 jährige")
b <- b + tm_borders()
b <- b + tm_shape(defi) + tm_dots(col='blue')
b <- b + tm_legend(title = 'Prognose Bedarf 2039')
b
```

Hier beobachten wir eine Verschiebung der älteren Bevölkerung in die Außenbezirke

## Defibrillatoren pro 1000 Personen 60plus

Anzahl der Defis pro Bezirk ermitteln
```{r}
d = read.csv("Daten/DEFIBRILLATOROGD/DEFIBRILLATOROGD.csv", sep=",", header = TRUE)
d$count = 1 # neue Spalte "count" hinzufügen mit dem Wert 1
data = aggregate(d$count, by=list(d$BEZIRK), FUN=sum)
data$plus60 = bev_bez$AGE_60_74+bev_bez$AGE_75.
```

Defi Anteil pro 1000 plus60 Menschen
```{r}
data$Defi_pro_1000_60plus = data$x / (data$plus60/1000)
```

Anzahl der älteren Bevölkerung und Anzahl der Defis in eine verbundene Tabelle bringen
```{r}
wien_bev_merge2 = wien_bev_merge %>% left_join(data, by = c("BEZNR" = "Group.1"))
```

### Heute
```{r echo=FALSE}
#data_heute <- data.frame(wien_bev_merge2$gesamtBev, wien_bev_merge2$Anteilueber60, wien_bev_merge2$anteil20j, wien_bev_merge2$x, wien_bev_merge2$plus60, wien_bev_merge2$Defi_pro_1000_60plus)
colnames(data) <- c("Bezirk", "AnzahlDefi", "plus60", "Defi_pro_1000_60plus")

kable(data) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"))
```

```{r}
c <- tm_shape(wien_bev_merge2) + tm_fill(col = "Defi_pro_1000_60plus", palette = c("#f2ce7a", "#973738"))
c <- c + tm_borders()
c <- c + tm_legend(title = 'Defi_pro_1000_60plus')
c
```

Hier sehen wir einzig im Ersten Bezirk einen Anteil von annähernd 20 Defis pro 1000 älterer Personen. In allen anderen Bezirken liegt der Anteil bei weniger als 5 Defibrillatoren.

### in 20 Jahren

Anzahl der potentiell betroffenen Bevölkerungsgruppe in 20 jahren
```{r}
data["Anzahl60plusIn20J"] <- round((wien_bev_merge2$AGE_30_44 + wien_bev_merge2$AGE_45_59 + (0.4 * wien_bev_merge2$AGE_60_74)) ,3)
```

Defi Anteil pro 1000 plus60 Menschen
```{r}
data$Defi_pro_1000_60plus_in20J = data$AnzahlDefi / (data$Anzahl60plusIn20J/1000)
```

```{r echo=FALSE}
kable(data) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"))
```

join: 
```{r}
wien_bev_merge3 = wien_bev_merge %>% left_join(data, by = c("BEZNR" = "Bezirk"))
```


```{r}
d <- tm_shape(wien_bev_merge3) + tm_fill(col = "Defi_pro_1000_60plus_in20J", palette = c("#f2ce7a", "#973738"))
d <- d + tm_borders()
d <- d+ tm_legend(title = 'Defi_pro_1000_60plus_in20J')
d
```

Hier beobachten wir unter der Annahme des Zuwaches der Gruppe "60 plus" bei gleichzeitig gleichbleibender Anzahl von öffentlich zugänglichen Defibrillatoren eine massive Unterversorgung in allen Wiener Gemeindebezirken von unter 7 Stück pro 1000 Personen "60 plus"

## Conclusio
Unter der Annahme des Zuwaches der Gruppe “60 plus” bei gleichzeitig gleichbleibender Anzahl von öffentlich zugänglichen Defibrillatoren
=> massive Unterversorgung in allen Wiener Gemeindebezirken von unter 7 Stück pro 1000 Personen “60 plus”
