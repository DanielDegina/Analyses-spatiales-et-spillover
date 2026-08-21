# ==============================================================================
# SCRIPT SHINY : INSPECTEUR MULTI-TIF DESCRIPTIF (ROUGE / GESTION DES BANDES)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. PACKAGES
# ------------------------------------------------------------------------------
needed_packages <- c("shiny", "bslib", "terra", "ggplot2")
new_packages <- needed_packages[!(needed_packages %in% installed.packages()[, "Package"])]

if (length(new_packages) > 0) {
  install.packages(new_packages, repos = "https://cloud.r-project.org")
}

library(shiny)
library(bslib)
library(terra)
library(ggplot2)

zone = "Sankuru"

raster1 <- 'D:\\MASG M2\\Spatial Epidemiology\\TP prof Dav\\Spatial_Epidemio_Sankuru\\geodata_outputs\\dEVI_2018_2021_redim_1km_class_propDefor.tif'
raster2 <- 'D:\\MASG M2\\Spatial Epidemiology\\TP prof Dav\\Spatial_Epidemio_Sankuru\\geodata_outputs\\dEVI_2019_2021_redim_1km_class_propDefor.tif'
raster3 <- 'D:\\MASG M2\\Spatial Epidemiology\\TP prof Dav\\Spatial_Epidemio_Sankuru\\geodata_outputs\\dEVI_2020_2021_redim_1km_class_propDefor.tif'

# ------------------------------------------------------------------------------
# 2. LOGIQUE D'INTERPRÉTATION DESCRIPTIVE
# ------------------------------------------------------------------------------
get_descriptive_interpretation <- function(b1_init, b1_trans, b2_raw, b3_raw, period_label, n_bands) {
  if (n_bands > 3) {
    return("Le raster a plus de 3 bandes.")
  }
  
  prefix_txt <- if (n_bands < 3) "Ce raster a moins de 3 bandes. " else ""
  
  if (is.na(b1_init)) return(paste0(prefix_txt, "Pixel hors limites ou donnée absente (NoData)."))
  
  class_txt <- paste0("Classe dominante égale à ", b1_init, 
                      " (valeur transformée R = ", sprintf("%.4f", b1_trans), ")")
  
  q4_txt <- if (!is.na(b2_raw)) {
    sprintf("%.2f%% de pixels appartenant au Quintile 4 (Q4)", b2_raw * 100)
  } else {
    "Bande 2 non disponible"
  }
  
  q5_txt <- if (!is.na(b3_raw)) {
    sprintf("%.2f%% de pixels appartenant au Quintile 5 (Q5)", b3_raw * 100)
  } else {
    "Bande 3 non disponible"
  }
  
  return(sprintf("%s[%s] %s, caractérisée par une proportion de %s et %s.", 
                 prefix_txt, period_label, class_txt, q4_txt, q5_txt))
}

# ------------------------------------------------------------------------------
# 3. INTERFACE UTILISATEUR (UI)
# ------------------------------------------------------------------------------
ui <- page_fluid(
  theme = bs_theme(bootswatch = "flatly"),
  
  h3(paste0("Inspecteur Multi-Bandes de l'indice - ", zone), class = "my-3 text-center"),
  
  layout_columns(
    col_widths = c(4, 4, 4),
    
    # --- RASTER 1 ---
    card(
      card_header("RASTER 1", class = "bg-danger text-white"),
      textInput("p1_path", "Chemin TIF (2018-2021) :", value = raster1),
      actionButton("load_1", "Charger RASTER 2018-2021", class = "btn-danger w-100 mb-2"),
      checkboxInput("trans_1", "Transformer Bande 1 : (n - 1) / 4", value = TRUE),
      hr(),
      plotOutput("plot_1", click = "plot_click", height = "300px"),
      hr(),
      card_body(
        h6(strong("Résultats RASTER 1 (2018-2021) :")),
        uiOutput("info_1")
      )
    ),
    
    # --- RASTER 2 ---
    card(
      card_header("RASTER 2", class = "bg-success text-white"),
      textInput("p2_path", "Chemin TIF (2019-2021) :", value = raster2),
      actionButton("load_2", "Charger RASTER 2019-2021", class = "btn-success w-100 mb-2"),
      checkboxInput("trans_2", "Transformer Bande 1 : (n - 1) / 4", value = TRUE),
      hr(),
      plotOutput("plot_2", click = "plot_click", height = "300px"),
      hr(),
      card_body(
        h6(strong("Résultats RASTER 2 (2019-2021) :")),
        uiOutput("info_2")
      )
    ),
    
    # --- RASTER 3 ---
    card(
      card_header("RASTER 3", class = "bg-primary text-white"),
      textInput("p3_path", "Chemin TIF (2020-2021) :", value = raster3),
      actionButton("load_3", "Charger RASTER 3", class = "btn-primary w-100 mb-2"),
      checkboxInput("trans_3", "Transformer Bande 1 : (n - 1) / 4", value = TRUE),
      hr(),
      plotOutput("plot_3", click = "plot_click", height = "300px"),
      hr(),
      card_body(
        h6(strong("Résultats RASTER 3 (2020-2021) :")),
        uiOutput("info_3")
      )
    )
  )
)

# ------------------------------------------------------------------------------
# 4. LOGIQUE SERVEUR
# ------------------------------------------------------------------------------
server <- function(input, output, session) {
  
  clean_path <- function(path_str) {
    if (is.null(path_str) || path_str == "") return("")
    cleaned <- gsub('^["\']|["\']$', '', trimws(path_str))
    cleaned <- gsub("\\\\+", "/", cleaned)
    cleaned <- gsub("//+", "/", cleaned)
    return(cleaned)
  }
  
  process_raster_df <- function(path_str, apply_transform) {
    p <- clean_path(path_str)
    req(p)
    if (!file.exists(p)) {
      showNotification(paste("Fichier introuvable :", p), type = "error")
      return(NULL)
    }
    
    r <- tryCatch({ rast(p) }, error = function(e) { return(NULL) })
    if (is.null(r)) return(NULL)
    
    total_bands <- nlyr(r)
    
    # CAS : Plus de 3 bandes
    if (total_bands > 3) {
      return(list(n_bands = total_bands, df = NULL))
    }
    
    # Échantillonnage léger si très lourd
    if (size(r) > 1000000) {
      r <- spatSample(r, size = 200000, method = "regular", as.raster = TRUE)
    }
    
    df <- as.data.frame(r, xy = TRUE)
    
    # Traitement Bande 1
    names(df)[3] <- "b1_raw"
    df$b1_norm <- if (apply_transform) (df$b1_raw - 1) / 4 else df$b1_raw
    
    # CAS 1 : Exactement 3 bandes (Bande 1 -> Rouge)
    if (total_bands == 3) {
      names(df)[4:5] <- c("b2_raw", "b3_raw")
      df$b2_norm <- df$b2_raw
      df$b3_norm <- df$b3_raw
      
      r_chan <- pmin(pmax(df$b1_norm, 0), 1) # Bande 1 -> Rouge (R)
      g_chan <- pmin(pmax(df$b2_norm, 0), 1) # Bande 2 -> Vert (G)
      b_chan <- pmin(pmax(df$b3_norm, 0), 1) # Bande 3 -> Bleu (B)
      
      df$hex <- rgb(r = r_chan, g = g_chan, b = b_chan)
    } 
    # CAS 2 : Moins de 3 bandes (1 ou 2 bandes)
    else if (total_bands == 2) {
      names(df)[4] <- "b2_raw"
      df$b2_norm <- df$b2_raw
      df$b3_raw <- NA
    } else {
      df$b2_raw <- NA
      df$b3_raw <- NA
    }
    
    return(list(n_bands = total_bands, df = df))
  }
  
  res1 <- eventReactive(input$load_1, { process_raster_df(input$p1_path, input$trans_1) })
  res2 <- eventReactive(input$load_2, { process_raster_df(input$p2_path, input$trans_2) })
  res3 <- eventReactive(input$load_3, { process_raster_df(input$p3_path, input$trans_3) })
  
  click_coords <- reactiveVal(NULL)
  
  observeEvent(input$plot_click, {
    click <- input$plot_click
    req(click)
    click_coords(c(x = click$x, y = click$y))
  })
  
  render_ggplot <- function(res) {
    if (is.null(res)) {
      plot.new()
      title("Chargez un fichier TIF.")
      return()
    }
    
    if (res$n_bands > 3) {
      plot.new()
      text(0.5, 0.5, "Le raster a plus de 3 bandes.", col = "red", cex = 1.2, font = 2)
      return()
    }
    
    df <- res$df
    if (is.null(df)) return()
    
    if (res$n_bands == 3) {
      p <- ggplot(df, aes(x = x, y = y, fill = hex)) +
        geom_raster() +
        scale_fill_identity()
    } else {
      p <- ggplot(df, aes(x = x, y = y, fill = b1_raw)) +
        geom_raster() +
        scale_fill_viridis_c(option = "magma", na.value = "transparent")
    }
    
    p <- p + coord_equal() +
      theme_void() +
      theme(panel.background = element_rect(fill = "#f8f9fa", color = NA))
    
    pt <- click_coords()
    if (!is.null(pt)) {
      dist <- (df$x - pt["x"])^2 + (df$y - pt["y"])^2
      sp <- df[which.min(dist), ]
      p <- p + geom_point(data = sp, aes(x = x, y = y), color = "#00FFFF", size = 4, shape = 4, stroke = 2)
    }
    p
  }
  
  output$plot_1 <- renderPlot({ render_ggplot(res1()) })
  output$plot_2 <- renderPlot({ render_ggplot(res2()) })
  output$plot_3 <- renderPlot({ render_ggplot(res3()) })
  
  build_info_ui <- function(res, period_name, theme_color) {
    if (is.null(res)) return(p(class = "text-muted", "Cliquez sur 'Charger' pour ce TIF."))
    
    n_bands <- res$n_bands
    
    if (n_bands > 3) {
      return(
        div(class = "p-3 rounded bg-light border-left border-4 border-danger",
            h6(strong("Interprétation Descriptive :")),
            p("Le raster a plus de 3 bandes.", style = "color: #D9534F; font-weight: bold; margin-bottom: 0;")
        )
      )
    }
    
    df <- res$df
    pt <- click_coords()
    if (is.null(pt)) return(p(class = "text-muted", "Cliquez sur la carte pour inspecter le pixel."))
    
    dist <- (df$x - pt["x"])^2 + (df$y - pt["y"])^2
    sp <- df[which.min(dist), ]
    
    b1_raw_min <- min(df$b1_raw, na.rm = TRUE)
    b1_raw_max <- max(df$b1_raw, na.rm = TRUE)
    
    b1_trans_min <- min(df$b1_norm, na.rm = TRUE)
    b1_trans_max <- max(df$b1_norm, na.rm = TRUE)
    
    descriptive_text <- get_descriptive_interpretation(sp$b1_raw, sp$b1_norm, sp$b2_raw, sp$b3_raw, period_name, n_bands)
    
    ui_elements <- list(
      p(strong("Bande 1 (Classe initiale) : "), sp$b1_raw, 
        span(class = "text-muted", sprintf(" (min: %g, max: %g)", b1_raw_min, b1_raw_max))),
      
      p(strong("Bande 1 (Transformée R)  : "), sprintf("%.4f", sp$b1_norm), 
        span(class = "text-muted", sprintf(" (min: %.4f, max: %.4f)", b1_trans_min, b1_trans_max)))
    )
    
    if (n_bands >= 2) {
      b2_min <- min(df$b2_raw, na.rm = TRUE)
      b2_max <- max(df$b2_raw, na.rm = TRUE)
      ui_elements[[length(ui_elements) + 1]] <- p(
        strong("Bande 2 (Proportion Q4)  : "), sprintf("%.4f (%.2f%%)", sp$b2_raw, sp$b2_raw * 100),
        span(class = "text-muted", sprintf(" (min: %.4f, max: %.4f)", b2_min, b2_max))
      )
    }
    
    if (n_bands == 3) {
      b3_min <- min(df$b3_raw, na.rm = TRUE)
      b3_max <- max(df$b3_raw, na.rm = TRUE)
      ui_elements[[length(ui_elements) + 1]] <- p(
        strong("Bande 3 (Proportion Q5)  : "), sprintf("%.4f (%.2f%%)", sp$b3_raw, sp$b3_raw * 100),
        span(class = "text-muted", sprintf(" (min: %.4f, max: %.4f)", b3_min, b3_max))
      )
    }
    
    ui_elements[[length(ui_elements) + 1]] <- hr()
    ui_elements[[length(ui_elements) + 1]] <- div(
      class = "p-3 rounded bg-light border-left border-4", 
      style = sprintf("border-left-color: %s !important;", theme_color),
      h6(strong("Interprétation Descriptive :")),
      p(descriptive_text, style = "color: #1B365D; margin-bottom: 0;")
    )
    
    tagList(ui_elements)
  }
  
  output$info_1 <- renderUI({ build_info_ui(res1(), "2018-2021", "#DC3545") })
  output$info_2 <- renderUI({ build_info_ui(res2(), "2019-2021", "#198754") })
  output$info_3 <- renderUI({ build_info_ui(res3(), "2020-2021", "#0D6EFD") })
}

# ------------------------------------------------------------------------------
# 5. LANCEMENT DE L'APPLICATION
# ------------------------------------------------------------------------------
shinyApp(ui = ui, server = server)