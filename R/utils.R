##' @title formatPhrase
##'
##' @param phrase a phrase with taxon name(s)
##' @param taxon a taxon name to be italisized
##' @export
##' @author Chenhao Li, Guangchuang Yu
##' @description generate an expression for the phrase with the given taxon italisized
formatPhrase <- function(sentence, taxon){
    ## already an expression
    if(!is.character(sentence)) return(sentence)
    ## no pattern matched
    if(length(grep(x=sentence, taxon, fixed = TRUE))==0) return(sentence)
    p <- taxon
    s <- paste0("'~italic('", taxon, "')~'")
    str <- gsub(x=paste0("'",sentence,"'"), p, s, fixed = TRUE)
    return(parse(text=bquote(.(str))))
}

################################################################################

##' @title summarize_taxa
##'
##' @param physeq a phyloseq object
##' @param level the taxonomy level to summarize
##' @importFrom magrittr "%>%"
##' @importFrom reshape2 melt dcast
##' @import dplyr
##' @export
##' @author Chenghao Zhu, Chenhao Li, Guangchuang Yu
##' @description Summarize a phyloseq object on different taxonomy level

summarize_taxa = function(physeq, level, keep_full_tax = TRUE){
    # do some checking here
    if (!requireNamespace("phyloseq", quietly = TRUE)) {
        stop("Package \"phyloseq\" needed for this function to work. Please install it.",
             call. = FALSE)
    }

    otutab = phyloseq::otu_table(physeq)
    taxtab = phyloseq::tax_table(physeq)

    if(keep_full_tax){
        taxonomy = apply(taxtab[,1:level], 1, function(x)
            paste(c("r__Root", x), collapse="|"))
    }else{
        taxonomy = taxtab[,level]
    }

    otutab %>%
        as.data.frame %>%
        mutate(taxonomy = taxonomy) %>%
        melt(id.var = "taxonomy",
             variable.name = "sample_id") %>%
        group_by(taxonomy, sample_id) %>%
        summarize(value=sum(value)) %>%
        dcast(taxonomy~sample_id)
}

################################################################################

##' @title fix_duplicate_tax
##'
##' @param physeq a phyloseq object
##' @author Chenghao Zhu, Chenhao Li, Guangchuang Yu
##' @export
##' @description fix the duplicatae taxonomy names of a phyloseq object

fix_duplicate_tax = function(physeq){
    if (!requireNamespace("phyloseq", quietly = TRUE)) {
        stop("Package \"phyloseq\" needed for this function to work. Please install it.",
             call. = FALSE)
    }
    taxtab <- phyloseq::tax_table(physeq)
    for(i in 3:ncol(taxtab)){
        uniqs = unique(taxtab[,i])
        for(j in 1:length(uniqs)){
            if(is.na(uniqs[j])) next
            ind = which(taxtab[,i]== as.character(uniqs[j]))
            if(length(unique(taxtab[ind,i-1]))>1){
                taxtab[ind,i] = paste(taxtab[ind,i-1], taxtab[ind,i], sep="_")
            }
        }
    }
    phyloseq::tax_table(physeq) = taxtab
    return(physeq)
}
