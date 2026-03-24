#!/usr/bin/env Rscript
# ============================================================================
# Variants_filtering.R
# Filtre un tableau de variants (issu de VCF_to_TSV.R) selon des criteres
# de frequence populationnelle et de consequence fonctionnelle
#
# Auteur  : Marwa Zidi — Universite Paris Cite
# Usage   : Rscript Variants_filtering.R <fichier.vcf.tsv>
# Sortie  : Filtered_<fichier.vcf.tsv> dans le meme dossier
#
# Filtres appliques :
#   1. Frequence dans la population generale < 5% (ou absente de gnomAD)
#   2. Consequence fonctionnelle significative (voir liste ci-dessous)
# ============================================================================

# ----------------------------------------------------------------------------
# 0. Chargement des librairies
# ----------------------------------------------------------------------------
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

# ----------------------------------------------------------------------------
# 1. Lecture des arguments et verification
# ----------------------------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  cat("Usage : Rscript Variants_filtering.R <fichier.vcf.tsv>\n")
  cat("Exemple : Rscript Variants_filtering.R Results/Diagnosis_vep.vcf.tsv\n")
  quit(status = 1)
}

fichier <- args[1]

if (!file.exists(fichier)) {
  stop(paste("Fichier introuvable :", fichier))
}

cat("Lecture du fichier :", fichier, "\n")
table <- read_tsv(fichier, show_col_types = FALSE)
cat("Variants avant filtrage :", nrow(table), "\n\n")

# ----------------------------------------------------------------------------
# 2. Filtre 1 — Frequence dans la population generale (gnomAD AF_pop)
# Seuil : < 5% (variants rares, potentiellement pathogenes)
# Les variants absents de gnomAD (NA) sont conserves
# ----------------------------------------------------------------------------
n_avant <- nrow(table)
table <- filter(table, AF_pop < 0.05 | is.na(AF_pop))
cat("Apres filtre frequence populationnelle (AF_pop < 5%) :", nrow(table),
    "variants retenus (", n_avant - nrow(table), "exclus)\n")

# ----------------------------------------------------------------------------
# 3. Filtre 2 — Consequence fonctionnelle
# Seules les consequences avec impact potentiel sur la proteine sont conservees
# ----------------------------------------------------------------------------
consequences_retenues <- c(
  "missense_variant",        # Changement d'acide amine
  "frameshift_variant",      # Decalage du cadre de lecture
  "stop_gained",             # Codon stop premature
  "stop_lost",               # Perte du codon stop
  "start_lost",              # Perte du codon d'initiation
  "splice_donor_variant",    # Alteration du site donneur d'epissage
  "splice_acceptor_variant"  # Alteration du site accepteur d'epissage
)

n_avant <- nrow(table)
table <- filter(table, Consequence %in% consequences_retenues)
cat("Apres filtre consequence fonctionnelle :", nrow(table),
    "variants retenus (", n_avant - nrow(table), "exclus)\n")

# ----------------------------------------------------------------------------
# 4. Resume des variants retenus
# ----------------------------------------------------------------------------
cat("\n--- Variants retenus ---\n")
if (nrow(table) > 0) {
  resume <- table %>%
    select(any_of(c("CHROM", "POS", "REF", "ALT", "SYMBOL",
                    "Consequence", "HGVSp", "VAF", "AF_pop"))) %>%
    as.data.frame()
  print(resume)
} else {
  cat("Aucun variant ne passe les filtres.\n")
}

# ----------------------------------------------------------------------------
# 5. Ecriture du fichier de sortie
# ----------------------------------------------------------------------------
nom_fichier_sortie <- paste0("Filtered_", basename(fichier))
dossier_sortie     <- dirname(fichier)
chemin_sortie      <- file.path(dossier_sortie, nom_fichier_sortie)

write_tsv(table, chemin_sortie)
cat("\nFichier filtre genere :", chemin_sortie, "\n")
cat("Nombre de variants dans le fichier final :", nrow(table), "\n")
