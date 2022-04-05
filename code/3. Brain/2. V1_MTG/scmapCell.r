remove(list = ls())

#install packages

#if (!requireNamespace("BiocManager", quietly = TRUE))
#  install.packages("BiocManager")
#BiocManager::install("scmap")

#if (!requireNamespace("BiocManager", quietly = TRUE))
#  install.packages("BiocManager")
#BiocManager::install("SingleCellExperiment")

library("SingleCellExperiment")
library("scmap")
set.seed(0)

args=commandArgs(trailingOnly = TRUE)
train_inp=as.character(args[1])
test_inp=as.character(args[2])

print(paste0("============ scmapCell: train=",train_inp," test=",test_inp,"======"))


# !!! 1. Load Data
#=================================================
#read datasets
train_dat=readRDS(paste0(train_inp,".rds"))
test_dat=readRDS(paste0(test_inp,".rds"))

print(paste0("initial genes number: ",ncol(train_dat)))

#!!! 2. pre-processing data
#=================================================
#!!!a) remove the celltype which is not present in the training
train_cellnames=names(table(train_dat[,1]))
test_dat=test_dat[which(test_dat[,1]%in%train_cellnames),]


#training data
ann_train=data.frame(cell_type1=train_dat[,1])
rownames(ann_train)=rownames(train_dat)

sce=SingleCellExperiment(assay=list(logcounts=as.matrix(t(train_dat[,-1]))),
                         colData=ann_train)

# use gene names as feature symbols
rowData(sce)$feature_symbol <- rownames(sce)
# remove features with duplicated names
sce <- sce[!duplicated(rownames(sce)), ]

# feature selection
sce <- selectFeatures(sce, suppress_plot = FALSE)
# scmap-cluster
sce <- indexCell(sce)

#testing data
ann_test=data.frame(cell_type1=test_dat[,1])
rownames(ann_test)=rownames(test_dat)

sce_test=SingleCellExperiment(assay=list(logcounts=as.matrix(t(test_dat[,-1]))),
                         colData=ann_test)
# use gene names as feature symbols
rowData(sce_test)$feature_symbol <- rownames(sce_test)
sce_test <- selectFeatures(sce_test, suppress_plot = TRUE)



testfunc <- function(sce_test , sce) {
  
  scmapCell_results <- scmapCell(sce_test, list(sce@metadata$scmap_cell_index))
  scmapCell_clusters <- scmapCell2Cluster(scmapCell_results,list(as.character(colData(sce)$cell_type1)))
  
  return (scmapCell_clusters)
} 

scmapCell_clusters <- testfunc(sce_test, sce)



labels=data.frame(cell_label=colData(sce_test),
                  prediction=scmapCell_clusters$combined_labs)


saveRDS(labels,paste0("labels_scmapCell_",train_inp,"_",test_inp,".rds"))


