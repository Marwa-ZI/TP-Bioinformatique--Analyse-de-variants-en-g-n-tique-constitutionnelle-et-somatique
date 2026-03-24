#!/usr/bin/env Rscript
# ============================================================================
# VCF_to_TSV.R
# Convertit un fichier VCF annote par VEP en tableau TSV lisible sous Excel
#
# Auteur  : Marwa Zidi — Universite Paris Cite
# Usage   : Rscript VCF_to_TSV.R <fichier_vep.vcf>
# Sortie  : <fichier_vep.vcf>.tsv
# ============================================================================

# ----------------------------------------------------------------------------
# 0. Chargement des librairies
# ----------------------------------------------------------------------------
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(vcfR)
  library(stringr)
})

# ----------------------------------------------------------------------------
# 1. Lecture des arguments et verification
# ----------------------------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  cat("Usage : Rscript VCF_to_TSV.R <fichier_vep.vcf>\n")
  cat("Exemple : Rscript VCF_to_TSV.R Results/Diagnosis_vep.vcf\n")
  quit(status = 1)
}

fichier <- args[1]

if (!file.exists(fichier)) {
  stop(paste("Fichier introuvable :", fichier))
}

cat("Lecture du fichier :", fichier, "\n")
vcf <- read.vcfR(fichier, verbose = FALSE)
cat("Nombre de variants :", nrow(vcf@fix), "\n")

# ----------------------------------------------------------------------------
# 2. Extraction des champs fixes (vcf@fix) — CHROM, POS, REF, ALT, INFO
# ----------------------------------------------------------------------------
vcf_fix <- as.data.frame(vcf@fix)

# Separation de la colonne INFO en champs individuels
vcf_fix <- vcf_fix %>%
  separate(INFO,
           into = c("ADP", "WT", "HET", "HOM", "NC", "CSQ"),
           sep  = ";",
           extra = "drop") %>%
  mutate(
    ADP = str_remove(ADP, "ADP="),
    WT  = str_remove(WT,  "WT="),
    HET = str_remove(HET, "HET="),
    HOM = str_remove(HOM, "HOM="),
    NC  = str_remove(NC,  "NC="),
    CSQ = str_remove(CSQ, "CSQ=")
  )

# Recuperation des noms de colonnes VEP depuis l'en-tete du VCF
csq_colonnes <- vcf@meta %>%
  grep("##INFO=<ID=CSQ", ., value = TRUE) %>%
  str_extract("Format:.*") %>%
  str_replace("Format: ", "") %>%
  str_split("\\|") %>%
  unlist()

if (length(csq_colonnes) == 0) {
  stop("Impossible de trouver les colonnes VEP dans le fichier. Verifiez que VEP a bien ete utilise.")
}

# Separation des annotations VEP (colonne CSQ)
vcf_fix <- vcf_fix %>%
  separate(CSQ, into = csq_colonnes, sep = "\\|", extra = "drop", fill = "right")

# ----------------------------------------------------------------------------
# 3. Extraction des informations de genotype (vcf@gt)
# ----------------------------------------------------------------------------
vcf_gt <- as.data.frame(vcf@gt)

# Identification du nom de l'echantillon (colonne apres FORMAT)
nom_echantillon <- setdiff(colnames(vcf_gt), "FORMAT")
if (length(nom_echantillon) == 0) {
  stop("Aucun echantillon trouve dans vcf@gt.")
}
nom_echantillon <- nom_echantillon[1]

# Recuperation des sous-champs du genotype
gt_colonnes <- str_split(vcf_gt$FORMAT[1], ":", simplify = TRUE)

vcf_gt <- vcf_gt %>%
  separate(all_of(nom_echantillon),
           into = gt_colonnes,
           sep  = ":",
           extra = "drop",
           fill = "right")

# ----------------------------------------------------------------------------
# 4. Assemblage du tableau final
# ----------------------------------------------------------------------------
table_finale <- cbind(vcf_fix, vcf_gt)

# Colonnes a conserver (les absentes sont ignorees)
colonnes_cibles <- c(
  "CHROM", "POS", "REF", "ALT",
  "GT", "GQ", "DP", "RD", "AD", "FREQ",
  "Consequence", "SYMBOL", "Gene", "Feature",
  "EXON", "INTRON", "HGVSc", "HGVSp",
  "Existing_variation", "SIFT", "PolyPhen",
  "AF", "CLIN_SIG"
)
colonnes_presentes <- intersect(colonnes_cibles, colnames(table_finale))
table_finale <- table_finale %>% select(all_of(colonnes_presentes))

# Conversion et renommage de AF (population) et FREQ (VAF)
table_finale <- table_finale %>%
  mutate(
    AF   = suppressWarnings(as.numeric(AF)),
    FREQ = suppressWarnings(as.numeric(sub("%", "", FREQ)) / 100)
  ) %>%
  rename(any_of(c(AF_pop = "AF", VAF = "FREQ")))

# ----------------------------------------------------------------------------
# 5. Ecriture du fichier TSV
# ----------------------------------------------------------------------------
fichier_sortie <- paste0(fichier, ".tsv")
write.table(table_finale, fichier_sortie, sep = "\t", row.names = FALSE, quote = FALSE)

cat("Fichier TSV genere :", fichier_sortie, "\n")
cat("Nombre de variants exportes :", nrow(table_finale), "\n")
