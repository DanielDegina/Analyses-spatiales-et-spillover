# Redimensionnement et analyse de rasters multi-bandes

Ce répertoire regroupe deux outils complémentaires développés pour le traitement et l'analyse spatiale de rasters dans le cadre de l'étude du **risque de spillover écologique dans le Sankuru, RDC**.

## 1. Redimensionnement et agrégation des rasters

Le premier outil permet de transformer un raster continu haute résolution, notamment **10 m**, vers une résolution plus faible, notamment **1 km**, par traitement par blocs.

L'agrégation repose sur la classification des valeurs en **quintiles globaux (Q1–Q5)** et produit un raster à **3 bandes** :

* **Bande 1 :** classe dominante parmi Q1–Q5 ;
* **Bande 2 :** proportion de pixels appartenant au Q4 ;
* **Bande 3 :** proportion de pixels appartenant au Q5.

Le traitement est réalisé par fenêtres afin de limiter l'utilisation de la mémoire et permettre le traitement de rasters volumineux.

Les données spatiales et la géoréférenciation sont conservées et adaptées à la nouvelle résolution.

---

## 2. Analyse et visualisation des rasters multi-bandes

Le second ensemble d'outils fournit une interface **Shiny interactive** permettant d'inspecter les rasters produits.

Il permet notamment de :

* charger et comparer plusieurs rasters ;
* visualiser leurs trois bandes sous forme de **composition RGB** ;
* cliquer sur une cellule pour examiner ses valeurs ;
* visualiser la classe dominante, les proportions Q4 et Q5 ;
* obtenir une interprétation descriptive de la cellule sélectionnée.

La composition RGB utilise :

| Canal        | Variable                                                    |
| ------------ | ----------------------------------------------------------- |
| 🔴 Rouge (R) | Classe dominante de la Bande 1, transformée de 1–5 vers 0–1 |
| 🟢 Vert (G)  | Proportion Q4                                               |
| 🔵 Bleu (B)  | Proportion Q5                                               |

Un visualiseur RGB complémentaire permet également de modifier indépendamment les intensités **Rouge, Vert et Bleu** afin de comprendre et explorer la correspondance entre les valeurs des bandes et les couleurs produites.

---

## 3. Flux général

```text
Raster haute résolution
        │
        ▼
Classification en quintiles
        │
        ▼
Agrégation 10 m → 1 km
        │
        ▼
Raster multi-bandes
 ┌──────┼──────┐
 ▼      ▼      ▼
 B1     B2     B3
 Qdom   Q4     Q5
  │      │      │
  └──────┼──────┘
         ▼
    Composition RGB
         │
         ▼
Inspection et interprétation spatiale
```

Ces outils permettent ainsi de passer de la **préparation des variables spatiales** à leur **exploration et interprétation visuelle** dans l'analyse spatiale des données rasters.
