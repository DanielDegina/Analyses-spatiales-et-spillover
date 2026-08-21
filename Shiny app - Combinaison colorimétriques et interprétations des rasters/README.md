# \# Outils Shiny d'inspection multi-bande et de visualisation RGB

# 

# \## 1. Description

# 

# Ce répertoire contient deux applications \*\*Shiny en R\*\* développées pour faciliter l'inspection, la compréhension et la visualisation des rasters multi-bandes utilisés dans l'analyse spatiale du risque de spillover dans le \*\*Sankuru, République Démocratique du Congo (RDC)\*\*.

# 

# Les deux scripts sont complémentaires :

# 

# | Script                  | Fonction principale                                           |

# | ----------------------- | ------------------------------------------------------------- |

# | `inspecteur\_multitif.R` | Inspecter les valeurs et les bandes d'un ou plusieurs GeoTIFF |

# | `visualiseur\_rgb.R`     | Explorer interactivement la combinaison des trois canaux RGB  |

# 

# Le premier script travaille directement avec les rasters géospatiaux. Le second constitue principalement un \*\*outil pédagogique et exploratoire\*\* permettant de comprendre comment les valeurs des trois bandes déterminent la couleur RGB finale.

# 

# \---

# 

# \# 2. Script 1 — Inspecteur multi-TIF descriptif

# 

# \## 2.1 Objectif

# 

# Le premier script permet d'examiner simultanément jusqu'à \*\*trois rasters GeoTIFF\*\* correspondant à différentes périodes.

# 

# Dans la configuration actuelle :

# 

# \* Raster 1 : \*\*2018–2021\*\*

# \* Raster 2 : \*\*2019–2021\*\*

# \* Raster 3 : \*\*2020–2021\*\*

# 

# Chaque raster est supposé contenir jusqu'à trois bandes :

# 

# 1\. classe dominante du quintile ;

# 2\. proportion de Q4 ;

# 3\. proportion de Q5.

# 

# L'application permet de cliquer sur une cellule de la carte et d'obtenir les valeurs correspondantes ainsi qu'une interprétation descriptive.

# 

# \---

# 

# \## 2.2 Fonctionnement

# 

# Pour chaque raster :

# 

# ```text

# GeoTIFF

# &#x20;  │

# &#x20;  ├── Bande 1 → Classe dominante Q1–Q5

# &#x20;  ├── Bande 2 → Proportion Q4

# &#x20;  └── Bande 3 → Proportion Q5

# &#x20;            │

# &#x20;            ▼

# &#x20;      Visualisation RGB

# &#x20;            │

# &#x20;            ▼

# &#x20;      Inspection interactive

# &#x20;            │

# &#x20;            ▼

# &#x20;      Interprétation descriptive

# ```

# 

# \---

# 

# \## 2.3 Transformation de la bande 1

# 

# La bande 1 contient une classe comprise entre \*\*1 et 5\*\*.

# 

# Lorsque l'option est activée :

# 

# ```r

# (b1\_raw - 1) / 4

# ```

# 

# transforme la classe en une valeur comprise entre \*\*0 et 1\*\*.

# 

# | Classe | Valeur transformée | Intensité rouge |

# | -----: | -----------------: | --------------: |

# |      1 |               0.00 |        minimale |

# |      2 |               0.25 |          faible |

# |      3 |               0.50 |   intermédiaire |

# |      4 |               0.75 |          élevée |

# |      5 |               1.00 |        maximale |

# 

# Cette valeur transformée constitue le canal \*\*Rouge (R)\*\*.

# 

# \---

# 

# \## 2.4 Construction RGB

# 

# Lorsque le raster possède exactement trois bandes :

# 

# ```text

# R = Bande 1 transformée

# G = Bande 2

# B = Bande 3

# ```

# 

# Les trois valeurs sont limitées à l'intervalle :

# 

# ```text

# 0–1

# ```

# 

# puis converties en couleur hexadécimale.

# 

# Ainsi :

# 

# \[

# RGB = (R,G,B)

# ]

# 

# avec :

# 

# \[

# R=\\frac{B1-1}{4}

# ]

# 

# si la transformation est activée.

# 

# Les bandes 2 et 3 sont utilisées directement comme valeurs normalisées, car elles sont déjà définies comme des proportions comprises entre 0 et 1.

# 

# \---

# 

# \# 3. Interprétation des bandes

# 

# \### Bande 1 — Classe dominante

# 

# Indique le quintile dominant dans chaque cellule de 1 km :

# 

# \* \*\*Q1\*\* : valeurs relativement faibles ;

# \* \*\*Q2\*\* : valeurs faibles à intermédiaires ;

# \* \*\*Q3\*\* : valeurs intermédiaires ;

# \* \*\*Q4\*\* : valeurs élevées ;

# \* \*\*Q5\*\* : valeurs très élevées relativement à la distribution étudiée.

# 

# \### Bande 2 — Proportion Q4

# 

# ```text

# 0 → aucun pixel Q4

# 1 → 100 % des pixels valides en Q4

# ```

# 

# \### Bande 3 — Proportion Q5

# 

# ```text

# 0 → aucun pixel Q5

# 1 → 100 % des pixels valides en Q5

# ```

# 

# Les proportions sont affichées à la fois sous forme décimale et en pourcentage.

# 

# \---

# 

# \# 4. Inspection interactive

# 

# L'utilisateur peut :

# 

# 1\. saisir ou modifier le chemin du fichier `.tif` ;

# 2\. charger le raster ;

# 3\. activer ou désactiver la transformation de la bande 1 ;

# 4\. visualiser la carte ;

# 5\. cliquer sur une cellule ;

# 6\. obtenir les valeurs des bandes ;

# 7\. obtenir une interprétation descriptive de la cellule sélectionnée.

# 

# La cellule la plus proche du point cliqué est identifiée.

# 

# Elle est signalée graphiquement par un marqueur.

# 

# \---

# 

# \# 5. Gestion des différents nombres de bandes

# 

# Le script gère trois situations.

# 

# \### Trois bandes

# 

# Le raster est visualisé en RGB :

# 

# ```text

# Bande 1 → Rouge

# Bande 2 → Vert

# Bande 3 → Bleu

# ```

# 

# \### Deux bandes

# 

# La bande 1 et la bande 2 sont disponibles.

# 

# La visualisation utilise la bande 1 comme variable continue.

# 

# \### Une bande

# 

# Seule la bande 1 est disponible.

# 

# Elle est visualisée comme une variable continue.

# 

# \### Plus de trois bandes

# 

# Le script ne tente pas de construire une représentation RGB et affiche :

# 

# ```text

# Le raster a plus de 3 bandes.

# ```

# 

# \---

# 

# \# 6. Gestion des rasters volumineux

# 

# Pour éviter de charger des rasters extrêmement volumineux dans leur totalité, le script applique un échantillonnage lorsque le raster contient plus de :

# 

# ```text

# 1 000 000 cellules

# ```

# 

# Dans ce cas, un échantillon de :

# 

# ```text

# 200 000 cellules

# ```

# 

# est utilisé pour la visualisation.

# 

# Cette opération est destinée à \*\*accélérer l'inspection interactive\*\*.

# 

# Elle ne modifie pas le fichier GeoTIFF original.

# 

# \---

# 

# \# 7. Dépendances du premier script

# 

# Packages R utilisés :

# 

# ```r

# shiny

# bslib

# terra

# ggplot2

# ```

# 

# Le script vérifie automatiquement leur présence et installe les packages manquants depuis CRAN.

# 

# Installation manuelle :

# 

# ```r

# install.packages(c(

# &#x20; "shiny",

# &#x20; "bslib",

# &#x20; "terra",

# &#x20; "ggplot2"

# ))

# ```

# 

# \---

# 

# \# 8. Configuration des rasters

# 

# Les chemins sont définis au début du script :

# 

# ```r

# raster1 <- "..."

# raster2 <- "..."

# raster3 <- "..."

# ```

# 

# Ils doivent être adaptés à l'organisation locale des données.

# 

# Exemple :

# 

# ```r

# raster1 <- "D:/projet/geodata\_outputs/dEVI\_2018\_2021\_redim\_1km\_class\_propDefor.tif"

# ```

# 

# L'utilisation de `/` est généralement plus simple dans les chemins R sous Windows.

# 

# \---

# 

# \# 9. Script 2 — Visualiseur de combinaison RGB

# 

# \## 9.1 Objectif

# 

# Le deuxième script est un \*\*visualiseur interactif de couleurs RGB\*\*.

# 

# Il permet de modifier manuellement :

# 

# \* le canal Rouge (R) ;

# \* le canal Vert (G) ;

# \* le canal Bleu (B).

# 

# Chaque canal varie entre :

# 

# ```text

# 0 et 255

# ```

# 

# L'application montre immédiatement :

# 

# \* la couleur résultante ;

# \* le code hexadécimal ;

# \* les valeurs RGB normalisées ;

# \* l'intensité de chaque canal ;

# \* un graphique comparatif des trois composantes.

# 

# \---

# 

# \# 10. Principe de la représentation RGB

# 

# Chaque canal est défini entre 0 et 255 :

# 

# \[

# R,G,B \\in \[0,255]

# ]

# 

# Pour l'analyse raster, les valeurs peuvent être normalisées entre 0 et 1 :

# 

# \[

# R\_n=\\frac{R}{255}

# ]

# 

# \[

# G\_n=\\frac{G}{255}

# ]

# 

# \[

# B\_n=\\frac{B}{255}

# ]

# 

# La combinaison :

# 

# \[

# (R,G,B)

# ]

# 

# détermine la couleur affichée.

# 

# \---

# 

# \# 11. Correspondance avec les rasters

# 

# Dans le contexte de l'analyse spatiale :

# 

# ```text

# Raster

# │

# ├── Bande 1 → R

# ├── Bande 2 → G

# └── Bande 3 → B

# ```

# 

# Pour la bande 1 :

# 

# ```r

# R = (Bande1 - 1) / 4

# ```

# 

# lorsque la transformation est utilisée.

# 

# Les bandes 2 et 3 correspondent directement aux proportions Q4 et Q5 :

# 

# ```text

# G = proportion Q4

# B = proportion Q5

# ```

# 

# Le visualiseur RGB permet donc de tester manuellement des combinaisons telles que :

# 

# ```text

# R = 1.00

# G = 0.30

# B = 0.60

# ```

# 

# et d'observer immédiatement leur rendu visuel.

# 

# \---

# 

# \# 12. Fonctionnement de l'interface RGB

# 

# L'interface comporte trois curseurs :

# 

# ```text

# Rouge (R) : 0–255

# Vert  (G) : 0–255

# Bleu  (B) : 0–255

# ```

# 

# La couleur résultante est calculée dynamiquement avec :

# 

# ```r

# rgb(

# &#x20; input$r,

# &#x20; input$g,

# &#x20; input$b,

# &#x20; maxColorValue = 255

# )

# ```

# 

# Le code hexadécimal correspondant est affiché automatiquement.

# 

# \---

# 

# \# 13. Informations affichées

# 

# Pour chaque combinaison RGB, l'application fournit :

# 

# \### Couleur résultante

# 

# Aperçu direct de la couleur générée.

# 

# \### Code hexadécimal

# 

# Exemple :

# 

# ```text

# \#FF3300

# ```

# 

# \### Valeurs normalisées

# 

# Exemple :

# 

# ```text

# (1.00 ; 0.20 ; 0.00)

# ```

# 

# \### Barres d'intensité

# 

# Chaque barre représente l'intensité relative d'un canal :

# 

# ```text

# R = R / 255

# G = G / 255

# B = B / 255

# ```

# 

# \### Graphique

# 

# Un graphique à barres présente les intensités absolues :

# 

# ```text

# 0 ───────────────────── 255

# ```

# 

# pour chacun des trois canaux.

# 

# \---

# 

# \# 14. Complémentarité des deux scripts

# 

# Les deux applications répondent à deux besoins différents.

# 

# | Besoin                                    | Script               |

# | ----------------------------------------- | -------------------- |

# | Inspecter un GeoTIFF                      | Inspecteur multi-TIF |

# | Examiner les bandes d'une cellule         | Inspecteur multi-TIF |

# | Obtenir une interprétation descriptive    | Inspecteur multi-TIF |

# | Visualiser la combinaison RGB d'un raster | Inspecteur multi-TIF |

# | Tester manuellement une couleur           | Visualiseur RGB      |

# | Comprendre l'effet de R, G et B           | Visualiseur RGB      |

# | Explorer les valeurs normalisées          | Les deux             |

# 

# Le premier script est donc principalement un \*\*outil d'analyse spatiale interactive\*\*, tandis que le second est un \*\*outil de compréhension et de calibration visuelle du système RGB\*\*.

# 

# \---

# \# 16. Limites et précautions

# 

# \### 16.1 RGB n'est pas une mesure statistique

# 

# La couleur produite est une \*\*représentation visuelle\*\* des trois bandes.

# 

# Elle ne constitue pas directement une mesure quantitative du risque de spillover.

# 

# \### 16.2 Les quintiles sont relatifs

# 

# Une classe Q5 indique une position élevée dans la distribution utilisée pour définir les quintiles.

# 

# Elle ne correspond pas nécessairement à un seuil écologique absolu.

# 

# \### 16.3 Les couleurs peuvent être ambiguës

# 

# Une même couleur peut résulter de différentes combinaisons de R, G et B.

# 

# L'interprétation scientifique doit donc être basée sur les \*\*valeurs des trois bandes\*\*, et non uniquement sur la couleur affichée.

# 

# \### 16.4 Échantillonnage

# 

# Lorsque le raster est volumineux, l'application utilise un échantillon pour accélérer la visualisation.

# 

# Les valeurs du raster original ne sont pas modifiées.

# 

# \### 16.5 Inspection ponctuelle

# 

# Après un clic, le script identifie la cellule la plus proche des coordonnées sélectionnées. Il ne s'agit donc pas d'une extraction statistique zonale.

# 

# \---

# 

# \# 17. Interprétation dans le contexte du spillover

# 

# Dans l'application utilisée pour les données de déforestation ou de perturbation environnementale :

# 

# ```text

# R → classe dominante de perturbation

# G → proportion de Q4

# B → proportion de Q5

# ```

# 

# La couleur finale représente donc une \*\*signature spatiale combinée\*\* de ces trois dimensions.

# 

# Il faut éviter de traduire automatiquement une couleur en :

# 

# > « risque élevé de spillover »

# 

# sans considérer les autres composantes du modèle.

# 

# Une couleur indique uniquement la combinaison des variables représentées par les trois canaux.

# 

# L'interprétation du risque doit être réalisée à partir de l'ensemble du modèle ou indice spatial utilisé.

# 

# \---

# 

# \# 18. Résumé du système

# 

# ```text

# &#x20;                INSPECTEUR MULTI-TIF

# &#x20;                        │

# &#x20;                        ▼

# &#x20;               GeoTIFF multi-bande

# &#x20;                        │

# &#x20;            ┌───────────┼───────────┐

# &#x20;            ▼           ▼           ▼

# &#x20;           B1          B2          B3

# &#x20;            │           │           │

# &#x20;            ▼           ▼           ▼

# &#x20;         Classe       Q4 (%)       Q5 (%)

# &#x20;            │           │           │

# &#x20;            ▼           ▼           ▼

# &#x20;            R           G           B

# &#x20;             \\          │          /

# &#x20;              \\         │         /

# &#x20;               └────────┼────────┘

# &#x20;                        ▼

# &#x20;                   Couleur RGB

# &#x20;                        │

# &#x20;                        ▼

# &#x20;              Inspection interactive

# 

# 

# &#x20;                 VISUALISEUR RGB

# &#x20;                        │

# &#x20;            ┌───────────┼───────────┐

# &#x20;            ▼           ▼           ▼

# &#x20;         Curseur R   Curseur G   Curseur B

# &#x20;            │           │           │

# &#x20;            └───────────┼───────────┘

# &#x20;                        ▼

# &#x20;                   Couleur RGB

# &#x20;                        │

# &#x20;             ┌──────────┼──────────┐

# &#x20;             ▼          ▼          ▼

# &#x20;          HEX code   Valeurs 0–1   Graphique

# ```

# 

# \---

# 

# \## 20. Auteur

# 

# \*\*Dr. Daniel M.Y. Degina\*\*

# 

# Projet d'analyse spatiale et d'épidémiologie spatiale

# Sankuru, République Démocratique du Congo



