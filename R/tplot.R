tplot = function(object,time_unit="months",free_scale=TRUE){
  UseMethod('tplot')
}

# Variable declaration to satisfy CRAN check
utils::globalVariables(c("data.source", "status", "n"))

tplot.meltt = function(object,time_unit="months",free_scale=TRUE){

  n.datasets = length(object$inputDataNames)
  key = object$processed$deduplicated_index[,c(1,2)]
  d.sets = object$inputDataNames
  colors_pal = c("#8DD3C7","#80B1D3","#FDB462","#FFFFB3","#FB8072","#BEBADA",
                 "#B3DE69","#FCCDE5","#D9D9D9","#BC80BD","#CCEBC5","#FFED6F")
  colors = c("black",colors_pal[1:length(d.sets)-1])

  for(d in seq_along(d.sets)){
    if(d==1){unique_dates=c();dup_dates=c();base=c()}
    sub = object$inputData[[d]]
    base = rbind(base,sub[,c("data.source","date")])
    unique_dates = rbind(unique_dates,sub[sub$obs.count %in% key[key[,1] == d,2],][,c("data.source","date")])
    dup_dates = rbind(dup_dates,sub[!sub$obs.count %in% key[key[,1] == d,2],][,c("data.source","date")])
  }


  # Break up by specified temporal unit
  unique_dates$unit <-  as.Date(cut(unique_dates$date,breaks = time_unit,start.on.monday = FALSE))
  dup_dates$unit <-  as.Date(cut(dup_dates$date,breaks = time_unit,start.on.monday = FALSE))
  base$unit <-  as.Date(cut(base$date,breaks = time_unit,start.on.monday = FALSE))

  # ensure alignment
  frame = data.frame(unit=unique(base$unit))
  dup_dates = merge(frame,dup_dates,by="unit",all.x=T)
  unique_dates = merge(frame,unique_dates,by="unit",all.x=T)
  dup_dates$data.source[is.na(dup_dates$data.source)] = NA
  unique_dates$data.source[is.na(unique_dates$data.source)] = NA

  # gather data
  dup_dates$status = "Duplicate Entries"
  unique_dates$status = "Unique Entries"
  D <-
    bind_rows(dup_dates,unique_dates) %>%
    mutate(data.source=factor(data.source,levels=rev(d.sets)),
           status = factor(status,levels=c("Unique Entries","Duplicate Entries"))) %>%
    group_by(data.source,unit,status) %>%
    count() %>%
    drop_na()

  # plot time series
  ggplot() +
    geom_bar(data=D[D$status=="Unique Entries",],
             aes(x=unit,y=n,fill=data.source),
             stat="identity") +
    geom_bar(data=D[D$status=="Duplicate Entries",],
             aes(x=unit,y=-n,fill=data.source),
             stat="identity",alpha=.6) +
    geom_hline(yintercept=0,lwd=1,color="grey30") +
    {
      if(free_scale){
        facet_wrap(~status,scales="free_y",ncol=1,strip.position="right")
      }
    } +
    theme_light() +
    scale_fill_manual(values = rev(colors)) +
    labs(y="Count",x=paste0("Date (",time_unit,")"),fill='') +
    theme(strip.placement = "inside",
          panel.grid.minor = element_blank())
}