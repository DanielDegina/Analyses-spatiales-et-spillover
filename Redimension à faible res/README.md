# Agrégation multi-bande par quintiles et analyse de déforestation

## 1. Description

Ce script Python agrège un raster continu de **10 m à 1 km** et produit un raster GeoTIFF multibande décrivant la distribution spatiale des valeurs selon leurs **quintiles globaux**.

L'application actuelle concerne la variable de **déforestation entre 2018 et 2021** dans la province du **Sankuru, République Démocratique du Congo (RDC)**.

Le traitement est réalisé **par blocs (`windowed processing`)**, ce qui permet de traiter des rasters volumineux sans charger l'ensemble du raster en mémoire.

### Principe général

Pour chaque pixel de 1 km, le script calcule :

1. la **classe de quintile dominante** ;
2. la **proportion de pixels appartenant au quintile 4 (Q4)** ;
3. la **proportion de pixels appartenant au quintile 5 (Q5)**.

Le raster de sortie contient donc **3 bandes**.

---

## 2. Objectif méthodologique

L'objectif est de conserver, après passage de **10 m à 1 km**, non seulement une valeur synthétique, mais également une information sur la **composition interne de chaque pixel agrégé**.

Cela permet notamment de distinguer :

* une cellule de 1 km majoritairement constituée de valeurs faibles ;
* une cellule dominée par des valeurs élevées ;
* une cellule présentant une forte proportion de valeurs appartenant aux classes élevées Q4 et Q5.

Cette représentation est destinée à être utilisée dans une analyse spatiale du **risque de spillover écologique**, notamment pour caractériser les perturbations environnementales liées à la déforestation.

---

## 3. Entrée

Le fichier d'entrée attendu est :

```text
../geodata_outputs/deforest_2018_2021.tif
```

### Caractéristiques attendues

* Format : GeoTIFF (`.tif`)
* Résolution initiale : **10 m**
* Variable : raster continu de déforestation
* Valeurs `NoData` : automatiquement prises en compte
* Système de coordonnées : conservé à partir du raster d'entrée

---

## 4. Sortie

Le fichier produit est :

```text
../geodata_outputs/deforest_2018_2021_redim_1km_class_propDefor.tif
```

### Caractéristiques

| Propriété          | Valeur                        |
| ------------------ | ----------------------------- |
| Format             | GeoTIFF                       |
| Résolution         | 1 km                          |
| Nombre de bandes   | 3                             |
| Type numérique     | `float32`                     |
| NoData             | `-9999`                       |
| Compression        | LZW                           |
| CRS                | Identique à l'entrée          |
| Extension spatiale | Zone utile du raster d'entrée |

---

## 5. Signification des bandes

### Bande 1 — Classe dominante du quintile

Nom :

```text
Classe dominante du quintile (1-5)
```

Chaque pixel de 1 km reçoit la classe de quintile la plus fréquente parmi ses pixels de 10 m.

| Valeur | Signification           |
| -----: | ----------------------- |
|      1 | Q1 : 0–20 % des valeurs |
|      2 | Q2 : 20–40 %            |
|      3 | Q3 : 40–60 %            |
|      4 | Q4 : 60–80 %            |
|      5 | Q5 : 80–100 %           |

La classe dominante correspond donc au **mode** des classes de quintiles présentes dans le pixel de 1 km.

---

### Bande 2 — Proportion de Q4

Nom :

```text
Proportion du quintile Q4 (0-1)
```

Elle représente la proportion des pixels valides de 10 m appartenant au **Q4** dans chaque cellule de 1 km.

Formellement :

[
P_{Q4} =
\frac{N(Q4)}{N_{\text{valides}}}
]

avec :

* (N(Q4)) = nombre de pixels classés Q4 ;
* (N_{\text{valides}}) = nombre total de pixels valides dans la cellule de 1 km.

La valeur est comprise entre **0 et 1**.

Exemple :

```text
0.35 = 35 % des pixels valides appartiennent au Q4
```

---

### Bande 3 — Proportion de Q5

Nom :

```text
Proportion du quintile Q5 (0-1)
```

Elle représente la proportion des pixels valides de 10 m appartenant au **Q5**.

[
P_{Q5} =
\frac{N(Q5)}{N_{\text{valides}}}
]

Exemple :

```text
0.60 = 60 % des pixels valides appartiennent au Q5
```

---

## 6. Détermination des quintiles

Les seuils des quintiles sont calculés **globalement sur l'ensemble de la zone utile du raster**, et non indépendamment pour chaque bloc.

Les seuils utilisés sont :

```text
20e percentile
40e percentile
60e percentile
80e percentile
```

La classification est donc :

```text
Q1 : valeur ≤ P20
Q2 : P20 < valeur ≤ P40
Q3 : P40 < valeur ≤ P60
Q4 : P60 < valeur ≤ P80
Q5 : valeur > P80
```

Cette approche garantit que les mêmes seuils sont utilisés dans l'ensemble de la zone d'étude.

---

## 7. Gestion des rasters volumineux

Le script utilise un traitement **par fenêtres (`windowed processing`)**.

Le raster n'est pas chargé intégralement en mémoire. Il est parcouru par blocs d'environ :

```text
1000 × 1000 pixels
```

À 10 m de résolution, un bloc représente approximativement :

```text
10 km × 10 km
```

Le traitement comporte deux passes principales :

### Passe 1 — Statistiques globales

Le script :

1. parcourt la zone utile ;
2. récupère les pixels valides ;
3. élimine les valeurs non finies ;
4. effectue, lorsque nécessaire, un échantillonnage aléatoire limité à 100 000 valeurs par bloc ;
5. calcule les seuils globaux des quintiles.

Un générateur pseudo-aléatoire fixé à :

```python
seed = 123
```

est utilisé afin de rendre l'échantillonnage reproductible.

### Passe 2 — Agrégation

Le script :

1. relit les données par blocs ;
2. attribue chaque pixel de 10 m à un quintile ;
3. regroupe les pixels par cellules de 1 km ;
4. calcule le mode des classes ;
5. calcule les proportions Q4 et Q5 ;
6. écrit directement les résultats dans le GeoTIFF de sortie.

---

## 8. Gestion des dimensions

Le facteur d'agrégation est calculé automatiquement :

[
Facteur = \frac{Résolution_{finale}}{Résolution_{initiale}}
]

Dans la configuration actuelle :

[
\frac{1000}{10}=100
]

Ainsi :

```text
100 × 100 pixels de 10 m
        ↓
1 pixel de 1 km
```

Le script exige que la résolution finale soit un multiple entier de la résolution initiale.

Les dimensions du raster sont également ajustées afin d'être strictement divisibles par le facteur d'agrégation.

La bordure résiduelle qui ne permet pas de constituer des blocs complets est retirée **avant l'agrégation**.

---

## 9. Gestion des valeurs manquantes

Les pixels `NoData` et les valeurs non finies (`NaN`, `Inf`) sont exclus des calculs.

Pour chaque cellule de 1 km :

[
N_{\text{valides}}
]

correspond uniquement aux pixels réellement utilisables.

Une cellule ne contenant aucun pixel valide reçoit :

```text
-9999
```

pour les trois bandes.

---

## 10. Dépendances

Les bibliothèques suivantes sont nécessaires :

```text
numpy
rasterio
scipy
```

Le script vérifie automatiquement leur présence et tente de les installer avec `pip` lorsqu'elles sont absentes.

### Installation manuelle recommandée

Pour une utilisation reproductible, il est préférable d'installer les dépendances avant l'exécution :

```bash
pip install numpy rasterio scipy
```

---

## 11. Configuration

Les principaux paramètres sont définis à la fin du script :

```python
resinit = 10
resfin = 1000

dir_input = Path("../geodata_outputs")
dir_output = Path("../geodata_outputs")

input_file = dir_input / "deforest_2018_2021.tif"

output_file = (
    dir_output /
    "deforest_2018_2021_redim_1km_class_propDefor.tif"
)
```

Pour traiter un autre raster, il suffit principalement de modifier :

* `input_file`
* `output_file`
* `resinit`
* `resfin`

---

## 12. Exécution

Depuis le répertoire contenant le script :

```bash
python nom_du_script.py
```

Le script vérifie automatiquement l'existence du fichier d'entrée.

Si le fichier est absent, l'exécution s'arrête avec son chemin attendu.

En cas de succès, le chemin du raster produit est affiché dans le terminal.

---

## 13. Contrôles automatiques

Le script réalise plusieurs contrôles :

* vérification de l'existence du raster d'entrée ;
* vérification de la compatibilité des résolutions ;
* vérification de la présence de pixels valides ;
* vérification de l'absence de `NaN` dans les seuils de quintiles ;
* vérification de la divisibilité des blocs ;
* vérification du nombre de bandes produites ;
* statistiques de répartition de la classe dominante ;
* moyenne spatiale de la proportion Q4 ;
* moyenne spatiale de la proportion Q5.

---

## 14. Interprétation spatiale

La combinaison des trois bandes permet une lecture plus riche qu'une simple moyenne.

### Exemple

Une cellule peut présenter :

```text
Bande 1 = 5
Bande 2 = 0.30
Bande 3 = 0.55
```

Cela signifie que :

* le **Q5 est la classe dominante** ;
* 30 % des pixels valides appartiennent au Q4 ;
* 55 % appartiennent au Q5.

La cellule présente donc une forte concentration de valeurs élevées de déforestation.

À l'inverse :

```text
Bande 1 = 2
Bande 2 = 0.05
Bande 3 = 0.01
```

indique une cellule principalement caractérisée par des valeurs faibles à intermédiaires, avec une faible présence des classes élevées.

---

## 15. Utilisation dans l'analyse du risque de spillover

Le raster produit peut être utilisé comme composante environnementale dans une analyse spatiale du risque de spillover.

Les trois bandes permettent notamment de représenter séparément :

* **l'intensité dominante** de la perturbation environnementale ;
* **la proportion de perturbation élevée (Q4)** ;
* **la proportion de perturbation très élevée (Q5)**.

Ces variables peuvent ensuite être combinées avec d'autres composantes d'un indice spatial, par exemple :

* prédiction d'un modèle de distribution d'espèce (SDM) ;
* proximité des habitats forestiers ;
* population humaine ;
* autres indicateurs environnementaux ou d'interface humain-faune.

Le raster produit ne constitue donc **pas à lui seul une estimation du risque de spillover**. Il fournit une représentation spatiale de la composante environnementale considérée.

---

## 16. Points méthodologiques importants

### Quintiles globaux

Les quintiles sont calculés à partir de la distribution globale échantillonnée de la zone utile.

Ils ne sont **pas recalculés pour chaque bloc**.

### Proportions

Les bandes 2 et 3 sont exprimées entre :

```text
0 et 1
```

et non en pourcentage.

Ainsi :

```text
0.25 = 25 %
```

### Agrégation

L'agrégation ne calcule pas une moyenne des valeurs originales.

Elle transforme les valeurs continues en classes de quintiles puis calcule :

* le mode des classes ;
* la proportion de Q4 ;
* la proportion de Q5.

### Conservation spatiale

Le CRS, la transformation spatiale et la géoréférenciation sont conservés et adaptés à la nouvelle résolution.

---

## 17. Limites

1. **Les quintiles sont relatifs à la distribution de la zone étudiée.** Une valeur Q5 signifie une valeur située dans les 20 % supérieurs de cette distribution, et non nécessairement une déforestation correspondant à un seuil absolu écologiquement défini.

2. **Les seuils sont estimés à partir d'un échantillonnage lorsque les blocs contiennent plus de 100 000 pixels valides.** Les seuils peuvent donc être légèrement différents de ceux obtenus avec l'ensemble des pixels.

3. **La classe dominante ne décrit pas l'hétérogénéité complète de la cellule.** Deux cellules ayant la même classe dominante peuvent avoir des distributions internes différentes. Les bandes Q4 et Q5 apportent précisément une information complémentaire à ce sujet.

4. **Le traitement ne mesure pas directement le contact humain-faune.** La déforestation constitue un indicateur environnemental et ne doit pas être interprétée comme une mesure directe de l'exposition humaine ou du spillover.

5. **La bordure supprimée est limitée aux pixels nécessaires pour obtenir des dimensions compatibles avec l'agrégation.** Les blocs internes complets sont conservés.

---

## 18. Structure attendue du projet

```text
projet/
├── script/
│   └── nom_du_script.py
│
└── geodata_outputs/
    ├── deforest_2018_2021.tif
    └── deforest_2018_2021_redim_1km_class_propDefor.tif
```

---

## 19. Auteur

**Dr. Daniel M.Y. Degina**

Province du Sankuru,
République Démocratique du Congo.

---

## 20. Résumé du flux de traitement

```text
Raster continu 10 m
        │
        ▼
Sélection de la zone utile
        │
        ▼
Échantillonnage global des pixels valides
        │
        ▼
Calcul des seuils P20, P40, P60, P80
        │
        ▼
Classification globale en Q1–Q5
        │
        ▼
Agrégation 100 × 100 pixels
        │
        ├──────────────► Bande 1 : quintile dominant
        │
        ├──────────────► Bande 2 : proportion Q4
        │
        └──────────────► Bande 3 : proportion Q5
        │
        ▼
Raster multibande 1 km
        │
        ▼
Analyse spatiale de la perturbation environnementale
```
