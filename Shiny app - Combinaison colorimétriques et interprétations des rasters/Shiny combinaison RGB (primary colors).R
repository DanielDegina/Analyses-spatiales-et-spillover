# ==============================================================================
# SCRIPT SHINY : VISUALISEUR INTERACTIF DE COULEURS RGB
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. GESTION ET INSTALLATION AUTOMATIQUE DES PACKAGES MANQUANTS
# ------------------------------------------------------------------------------
needed_packages <- c("shiny", "bslib", "ggplot2")

# Vérifier quels packages ne sont pas encore installés
new_packages <- needed_packages[!(needed_packages %in% installed.packages()[, "Package"])]

# Installer les packages manquants automatiquement
if (length(new_packages) > 0) {
  message("Installation des packages manquants : ", paste(new_packages, collapse = ", "))
  install.packages(new_packages, repos = "https://cloud.r-project.org")
}

# Charger toutes les bibliothèques
library(shiny)
library(bslib)
library(ggplot2)

# ------------------------------------------------------------------------------
# 2. INTERFACE UTILISATEUR (UI)
# ------------------------------------------------------------------------------
ui <- page_sidebar(
  title = "Visualiseur de Combinaison de Couleurs RGB",
  theme = bs_theme(bootswatch = "flatly"),
  
  # Panneau latéral : Sliders pour ajuster R, G et B
  sidebar = sidebar(
    title = "Canaux RGB (0 à 255)",
    sliderInput("r", "Rouge (R) :", min = 0, max = 255, value = 255, step = 1),
    sliderInput("g", "Vert (G) :", min = 0, max = 255, value = 51, step = 1),
    sliderInput("b", "Bleu (B) :", min = 0, max = 255, value = 0, step = 1)
  ),
  
  # Disposition principale
  layout_columns(
    fill = FALSE,
    
    # Carte 1 : Bloc de la couleur résultante
    card(
      card_header("Couleur Résultante"),
      uiOutput("color_preview_box"),
      div(
        style = "text-align: center; margin-top: 10px;",
        h4(textOutput("hex_code")),
        p(textOutput("rgb_values"))
      )
    ),
    
    # Carte 2 : Barres de progression (Intensité Bootstrap)
    card(
      card_header("Intensité des Canaux (Barres de Progression)"),
      uiOutput("progress_bars")
    )
  ),
  
  # Carte 3 : Graphique des composantes avec ggplot2
  card(
    card_header("Décomposition Graphique des Intensités"),
    plotOutput("rgb_plot", height = "300px")
  )
)

# ------------------------------------------------------------------------------
# 3. LOGIQUE SERVEUR
# ------------------------------------------------------------------------------
server <- function(input, output, session) {
  
  # Réactivité : Conversion des valeurs R, G, B en code Hexadécimal
  hex_color <- reactive({
    rgb(input$r, input$g, input$b, maxColorValue = 255)
  })
  
  # 1. Rendu du carré de couleur résultante
  output$color_preview_box <- renderUI({
    div(
      style = sprintf(
        "background-color: %s; height: 120px; width: 100%%; border-radius: 8px; border: 1px solid #ccc; box-shadow: inset 0 0 10px rgba(0,0,0,0.15);",
        hex_color()
      )
    )
  })
  
  # Textes dynamiques d'information
  output$hex_code <- renderText({ paste("Code Hex :", hex_color()) })
  output$rgb_values <- renderText({ 
    sprintf("Valeurs Normalisées (0 à 1) : (%.2f ; %.2f ; %.2f)", input$r/255, input$g/255, input$b/255) 
  })
  
  # 2. Rendu des barres de progression
  output$progress_bars <- renderUI({
    tagList(
      p(strong("Rouge (R) : "), sprintf("%d / 255 (%.0f%%)", input$r, (input$r/255)*100)),
      div(class = "progress", style = "margin-bottom: 15px;",
          div(class = "progress-bar bg-danger", style = sprintf("width: %.2f%%;", (input$r/255)*100))),
      
      p(strong("Vert (G) : "), sprintf("%d / 255 (%.0f%%)", input$g, (input$g/255)*100)),
      div(class = "progress", style = "margin-bottom: 15px;",
          div(class = "progress-bar bg-success", style = sprintf("width: %.2f%%;", (input$g/255)*100))),
      
      p(strong("Bleu (B) : "), sprintf("%d / 255 (%.0f%%)", input$b, (input$b/255)*100)),
      div(class = "progress", style = "margin-bottom: 15px;",
          div(class = "progress-bar bg-primary", style = sprintf("width: %.2f%%;", (input$b/255)*100)))
    )
  })
  
  # 3. Rendu du graphique ggplot2
  output$rgb_plot <- renderPlot({
    df <- data.frame(
      Canal = factor(c("Rouge (R)", "Vert (G)", "Bleu (B)"), levels = c("Rouge (R)", "Vert (G)", "Bleu (B)")),
      Valeur = c(input$r, input$g, input$b),
      Couleur = c("#DC3545", "#198754", "#0D6EFD")
    )
    
    ggplot(df, aes(x = Canal, y = Valeur, fill = Couleur)) +
      geom_bar(stat = "identity", width = 0.5, color = "black") +
      scale_fill_identity() +
      scale_y_continuous(limits = c(0, 255), breaks = seq(0, 255, 51)) +
      geom_text(aes(label = Valeur), vjust = -0.5, fontface = "bold", size = 5) +
      theme_minimal(base_size = 14) +
      labs(x = NULL, y = "Intensité (0-255)") +
      theme(
        panel.grid.major.x = element_blank(),
        axis.text.x = element_text(face = "bold")
      )
  })
}

# ------------------------------------------------------------------------------
# 4. LANCEMENT DE L'APPLICATION
# ------------------------------------------------------------------------------
shinyApp(ui = ui, server = server)