## CCISS 2020 Step 2: Edatopic Overlap
## Kiri Daust, 2020
#dat = dat; Edatope = E1
edatopicOverlap <- function(dat,Edatope){
  SS <- Edatope[is.na(Special),.(BGC,SS_NoSpace,Edatopic)]
  SS <- unique(SS)
  BGC <- unique(dat)
  SSsp <- Edatope[!is.na(Codes),.(BGC,SS_NoSpace,Codes)]
  SSsp <- unique(SSsp)
  
  ##Special site series edatopes
  CurrBGC <- SSsp[BGC, on = "BGC", allow.cartesian = T]
  setkey(BGC, BGC.pred)
  setkey(SSsp, BGC)
  FutBGC <- SSsp[BGC, allow.cartesian = T]
  setnames(FutBGC, old = c("BGC","SS_NoSpace","i.BGC"), 
           new = c("BGC.pred","SS.pred","BGC"))
  FutBGC <- FutBGC[!is.na(SS.pred),]
  setkey(FutBGC, SiteNo, FuturePeriod, BGC,BGC.pred, Codes)
  setkey(CurrBGC,SiteNo,FuturePeriod, BGC,BGC.pred, Codes)
  new <- CurrBGC[FutBGC]
  SSsp.out <- new[,.(allOverlap = 1/.N,SS.pred,BGC.prop), keyby = .(SiteNo,FuturePeriod,BGC,BGC.pred,SS_NoSpace)]
  
  ##regular site series edatopes
  CurrBGC <- SS[BGC, on = "BGC", allow.cartesian = T]
  CurrBGC <- CurrBGC[!duplicated(CurrBGC),]
  setkey(BGC, BGC.pred)
  setkey(SS, BGC)
  FutBGC <- SS[BGC, allow.cartesian = T]
  FutBGC <- FutBGC[!duplicated(FutBGC),] 
  setnames(FutBGC, old = c("BGC","SS_NoSpace","i.BGC"), 
           new = c("BGC.pred","SS.pred","BGC"))
  FutBGC <- na.omit(FutBGC)
  
  setkey(FutBGC, SiteNo, FuturePeriod, BGC,BGC.pred, Edatopic)
  FutBGC[,BGC.prop := NULL]
 
  setkey(CurrBGC,SiteNo,FuturePeriod, BGC,BGC.pred, Edatopic)
  new <- left_join(CurrBGC,FutBGC)#  was merge with, all = T bit failing with some predictions make sure not causing issue
  setkey(new, SiteNo,FuturePeriod,BGC,BGC.pred,SS_NoSpace,SS.pred)
  ##new <- new[complete.cases(new),]
  
  ###forwards overlap
  SS.out <- new[,.(SS.prob = .N), 
                keyby = .(SiteNo,FuturePeriod,BGC,BGC.pred,SS_NoSpace,SS.pred)]
  SS.out2 <- new[,.(SS.Curr = length(unique(Edatopic)), BGC = unique(BGC.prop)), 
                 keyby = .(SiteNo,FuturePeriod,BGC,BGC.pred,SS_NoSpace)]
  comb <- SS.out2[SS.out]
  #comb <- comb %>% tidyr::drop_na()
  
  ###reverse overlap
  SS.out.rev <- new[,.(SS.prob = .N), 
                    keyby = .(SiteNo,FuturePeriod,BGC,BGC.pred,SS.pred,SS_NoSpace)]
  SS.out2.rev <- new[,.(SS.Curr = length(unique(Edatopic)), BGC = unique(BGC.prop)), 
                     keyby = .(SiteNo,FuturePeriod,BGC,BGC.pred,SS.pred)]
  combRev <- SS.out2.rev[SS.out.rev]
  #combRev <- combRev %>% tidyr::drop_na()
  ##combine them
  comb[,SSProb := SS.prob/SS.Curr]
  combRev[,SSProbRev := SS.prob/SS.Curr]
  combAll <- merge(comb,combRev,by = c("SiteNo","FuturePeriod","BGC","BGC.pred","SS_NoSpace","SS.pred"))
  combAll <-combAll[!(combAll$BGC == combAll$BGC.pred  &  combAll$SS_NoSpace != combAll$SS.pred),] ### removes overlap where past BGC = future BGC
  combAll[,allOverlap := SSProb*SSProbRev]
  setnames(combAll, old = "BGC.1.x",new = "BGC.prop")
  combAll <- combAll[,.(SiteNo, FuturePeriod, BGC, BGC.pred, SS_NoSpace, 
                        allOverlap, SS.pred, BGC.prop)]
  combAll <- rbind(combAll, SSsp.out)
  combAll <- combAll[!is.na(SS_NoSpace),] %>% distinct()

  
  ##add in BGC probability
  combAll <- combAll[complete.cases(combAll),]
  combAll[,SSratio := allOverlap/sum(allOverlap), by = .(SiteNo, FuturePeriod, BGC, BGC.pred,SS_NoSpace)] ##should check this?
  setorder(combAll, SiteNo, FuturePeriod, BGC, BGC.pred, SS_NoSpace)
  
  combAll <- unique(combAll)
  setkey(combAll, SiteNo, FuturePeriod, BGC,BGC.pred)
  temp <- unique(combAll[,.(SiteNo,FuturePeriod,BGC,BGC.pred,BGC.prop)])
  temp[,BGC.prop := BGC.prop/sum(BGC.prop), by = .(SiteNo,FuturePeriod,BGC)]
  temp <- unique(temp)
  combAll[,BGC.prop := NULL]
  combAll <- temp[combAll]
  combAll[,SSprob := SSratio*BGC.prop]
  combALL <- combAll[!duplicated(combAll),]
  
  return(combAll)
}
