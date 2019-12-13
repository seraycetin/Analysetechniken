# weiterentwicklung mit bezirksgrenzen statt zählbezirken und plot mit anteil personen über 60 jahren
# anstelle von absoluten zahlen

rm(list = ls()) # environment leeren

library(tidyverse)    # benötigen für das joinen
library(sf)           # für die Shapefiles
library(tmap)         # zum plotten
library(stringr)    # bezirksnummer bearbeiten

# Shapefile: Wien laden
# anderer data set: bezirksgrenzen wien
# https://www.data.gv.at/katalog/dataset/stadt-wien_bezirksgrenzenwien/resource/f1540ea4-edd4-42f5-9b39-2cbba97fea36
wien <- st_read(dsn = "Daten/BEZIRKSGRENZEOGD/BEZIRKSGRENZEOGDPolygon.shp")
wien

# Plot wien (bezirksgrenzen)
tm_shape(wien) + tm_borders()

# Shapefile: Defibrillator laden
defi <- st_read(dsn = "Daten/DEFIBRILLATORoGD/DEFIBRILLATORoGDPoint.shp")
defi

# Defibrillatoren mit der Wien-Karte plotten
a <- tm_shape(wien)
a <- a + tm_borders()
a <- a + tm_shape(defi) + tm_dots(col='blue')
a

# Bevölkerunganzahl einlesen
# erste zeile nicht einlesen und header übernehmen
bev = read.csv("Daten/vie_303.csv", sep=";", skip = 1, header = TRUE)
bev <- bev[which(bev$REF_DATE == 20190101),]  # nur die aus 2019!
bev

# bezirksnummer aus district code (=Gemeindekennziffer) auslesen
# zuerst führende neun löschen, dann letzte beiden stellen löschen
bev$DISTRICT_CODE <- gsub("^9", "", bev$DISTRICT_CODE)
bev$DISTRICT_CODE <- str_sub(bev$DISTRICT_CODE, 1, str_length(bev$DISTRICT_CODE)-2)

# bevölkerungsdaten um nicht benötigte spalten bereinigen
bev <- bev[ , names(bev) %in% c("DISTRICT_CODE","AGE_00_02","AGE_03_05","AGE_06_09","AGE_10_14","AGE_15_19","AGE_20_24","AGE_25_29","AGE_30_44","AGE_45_59","AGE_60_74","AGE_75.")]

# bezirksnummer in numeric für join 
wien$BEZ = as.numeric(wien$BEZ)
bev$DISTRICT_CODE = as.numeric(bev$DISTRICT_CODE)

# groupby um werte von subbezirken auf bezirke aufzusummieren
bev_bez <- aggregate(.~bev$DISTRICT_CODE, bev, sum)
# spalte DISTRICT_CODE bereinigen
bev_bez = subset(bev_bez, select = -c(DISTRICT_CODE))

# prozentualer anteil personen über 60 Jahren = hauptbetroffene von herzinfarkten
bev_bez["gesamtBev"] <- rowSums(bev_bez [,-1])
#bev_bez["Anteilueber60"] <- round((bev_bez$AGE_60_74 + bev_bez$AGE_60_74) / bev_bez$gesamtBev,2)
bev_bez["Anteilueber60"] <- round((bev_bez$AGE_60_74 + bev_bez$AGE_75.) / bev_bez$gesamtBev,2)

# join wien und bev_bez mit der bezirksnummer
wien_bev_merge = wien %>% left_join(bev_bez, by = c("BEZ" = "bev$DISTRICT_CODE"))
wien_bev_merge

# plotten
a <- tm_shape(wien_bev_merge) + tm_fill(col = "Anteilueber60", palette = c("#f2ce7a", "#973738"))  # palette = "RdBu"
a <- a + tm_borders()
a <- a + tm_shape(defi) + tm_dots(col='blue')
a <- a + tm_legend(title = 'Verteilung im Jahr 2019')
a

# anteil der potentiell betroffenen bevölkerungsgruppe in 20 jahren
# dh heute 30-60 jährige, von den heute 60-74 jährigen erreichen 40% ein hohes alter
wien_bev_merge["anteil20j"] <- round((wien_bev_merge$AGE_30_44 + wien_bev_merge$AGE_45_59 + (0.4 * wien_bev_merge$AGE_60_74)) / wien_bev_merge$gesamtBev,3)

# plotten
b <- tm_shape(wien_bev_merge) + tm_fill(col = "anteil20j", palette = c("#f2ce7a", "#973738"))  # palette = "RdBu"
b <- b + tm_borders()
b <- b + tm_shape(defi) + tm_dots(col='blue')
b <- b + tm_legend(title = 'Prognose für 2039')
b


d = read.csv("Daten/DEFIBRILLATOROGD/DEFIBRILLATOROGD.csv", sep=",", header = TRUE)
d$count = 1 # neu Spalte "count" hinzufügen mit dem Wert 1
data = aggregate(d$count, by=list(d$BEZIRK), FUN=sum)
data$plus60 = bev_bez$AGE_60_74+bev_bez$AGE_75.

# Defi Anteil pro 1000 plus60 Menschen
data$Defi_pro_1000_60plus = data$x / (data$plus60/1000)
data
