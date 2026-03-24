# TP Bioinformatique — Seance 6 : Variant Calling

> Travaux pratiques d'identification et d'annotation de variants somatiques et constitutionnels a partir de donnees de sequencage cible (panel de 15 genes), dans un environnement Docker Jupyter pre-configure.

**Auteur : Marwa Zidi** — Universite Paris Cite

---

## Description

Ce TP suit un pipeline complet de variant calling applique a un cas clinique reel de leucemie aigue myeloide (LAM). Deux echantillons sont analyses en parallele : un prelevement tumoral (moelle osseuse au diagnostic) et un echantillon constitutionnel (fibroblastes cutanes).

L'objectif est d'identifier les mutations somatiques acquises par les blastes ainsi que les eventuelles mutations constitutionnelles predisposantes.

---

## Acces a l'environnement

L'environnement de TP est disponible en ligne via l'infrastructure Docker de l'Universite Paris Cite :

**[Lancer l'environnement Jupyter](https://mydocker.universite-paris-saclay.fr/course/df98369f-0b3f-4efe-af02-8bc4955a03d0/magic-link)**

> Aucune installation locale necessaire. L'environnement inclut tous les outils NGS pre-installes (BWA, Samtools, FastQC, Qualimap, VarScan, VEP, IGV...) ainsi que les donnees cliniques.

---

## Contexte clinique

Patient de 76 ans, diagnostique d'une leucemie aigue myeloide (LAM).

| Echantillon | Prelevement | Envahissement tumoral |
|-------------|-------------|----------------------|
| `Diagnosis` | Moelle osseuse au diagnostic | 30% de blastes |
| `Germline` | Biopsie cutanee — fibroblastes | Aucun |

Le sequencage cible (panel de 15 genes) a ete realise en paired-end sur sequenceur Illumina.

---

## Structure des notebooks

| Notebook | Description | Mode |
|----------|-------------|------|
| `Variant_calling_student.ipynb` | Cellules a completer par l'etudiant | Exercice |
| `Variant_calling_reponses.ipynb` | Toutes les reponses et explications | Correction |

---

## Pipeline d'analyse

```
Raw_data/*.fastq
      |
      | 1. Controle qualite (FastQC)
      v
Quality_control/
      |
      | 2. Alignement (BWA mem)
      v
Intermediate_files/*.sam
      |
      | 3. Compression + tri + indexation (Samtools)
      v
Intermediate_files/*_sorted.bam
      |
      | 4. Qualite alignement (Qualimap + Samtools)
      v
Quality_control/*_bamqc/
      |
      | 5. Appel de variants (VarScan mpileup2cns)
      v
Results/*.vcf
      |
      | 6. Annotation (VEP)
      v
Results/*_vep.vcf
      |
      | 7. Conversion + filtrage (VCF_to_TSV.R + Variants_filtering.R)
      v
Results/Filtered_*.tsv
```

---

## Structure des donnees

```
/data/
├── Raw_data/
│   ├── Diagnosis_R1.fastq
│   ├── Diagnosis_R2.fastq
│   ├── Germline_R1.fastq
│   └── Germline_R2.fastq
├── Reference_genome/
│   ├── hg38.fa          (+ index bwa et fai)
│   └── Genes_exons.gtf
└── Scripts/
    ├── VCF_to_TSV.R
    └── Variants_filtering.R
```

---

## Outils utilises

| Outil | Version | Role |
|-------|---------|------|
| FastQC | 0.12.1 | Controle qualite des reads bruts |
| BWA mem | 0.7.17 | Alignement paired-end sur hg38 |
| Samtools | 1.21 | Compression SAM→BAM, tri, indexation, mpileup |
| Qualimap | 2.3 | Qualite de l'alignement (couverture, MAPQ...) |
| VarScan | 2.4.6 | Appel de variants SNP et indels |
| VEP | 88 | Annotation des variants (Ensembl) |
| IGV | 2.16.2 | Visualisation interactive (via VNC) |
| R (vcfR, dplyr) | 4.2.2 | Conversion VCF→TSV et filtrage |

---

## Scripts R

### VCF_to_TSV.R
Convertit un fichier VCF annote par VEP en tableau TSV lisible sous Excel.
Extrait et restructure les champs INFO, CSQ (annotations VEP) et GT (genotype).

```bash
Rscript Scripts/VCF_to_TSV.R Results/Diagnosis_vep.vcf
```

### Variants_filtering.R
Filtre les variants selon deux criteres :
- Frequence dans la population generale < 5% (AF_pop < 0.05)
- Consequence fonctionnelle : missense, frameshift, stop_gained, splice...

```bash
Rscript Scripts/Variants_filtering.R Results/Diagnosis_vep.vcf.tsv
```

---

## Parametres VarScan recommandes

| Parametre | Valeur | Description |
|-----------|--------|-------------|
| `--min-coverage` | 10 | Profondeur minimale |
| `--min-reads2` | 2 | Reads variants minimaux |
| `--min-var-freq` | 0.02 | Frequence allelique minimale (2%) |
| `--min-avg-qual` | 20 | Qualite de base minimale |
| `--p-value` | 0.01 | Seuil biais de brin |
| `--strand-filter` | 1 | Activation du filtre de brin |

---

## Objectifs pedagogiques

A l'issue de ce TP, l'etudiant sera capable de :

- Evaluer la qualite de donnees de sequencage cible (FastQC, Qualimap)
- Aligner des reads paired-end sur un genome de reference (BWA mem)
- Manipuler des fichiers SAM/BAM avec Samtools
- Appeler des variants SNP et indels avec VarScan
- Annoter des variants avec VEP (consequence, population, prediction pathogenicite)
- Distinguer variants somatiques et constitutionnels
- Interpreter la VAF dans le contexte de la fraction tumorale
- Utiliser IGV pour la validation visuelle des variants

---

## Pour aller plus loin

Les variants pathogenes de **DDX41** sont associes aux syndromes myelodysplasiques et aux LAM chez les patients de plus de 60 ans. La decouverte d'un tel variant a des implications pour la prise en charge du patient ET pour le depistage de ses apparentes.

Reference : *Germline DDX41 mutations define a significant entity within adult MDS/AML patients.* Sebert et al. Blood 2019 — https://pubmed.ncbi.nlm.nih.gov/31484648/

---

## Licence

Ce materiel pedagogique est distribue a des fins educatives dans le cadre des enseignements de bioinformatique de l'Universite Paris Cite.
