#Creates a table from an object processed by bof()
library(lubridate)
library(plyr)
# Debugger ####
# source("R/Bof.R")
# source("R/SummarizeFunctions.R")
# 
# DayNightData<- read.table("data/DayNightData.csv", sep = ",", header = TRUE)
# boffed <- bof(object = DayNightData)
# 
# object = boffed; obs.lag = 2; ID = "Test"; dur.units = "mins"
# ###


# Table.bof ####

table.bof <- function(object, obs.lag = 2, ID = NULL, dur.units = "mins"){
  
  object$DateTime <- strptime(object$DateTime, "%Y-%m-%d %H:%M:%S")
  object$Date <- strftime(object$DateTime, format = "%Y-%m-%d")
  object$Time <- strftime(object$DateTime, format = "%H:%M:%S")

  # z <- unique(object$Date)
  # 
  # for(i in z){
  #   # i = z[1]
  #   sub <- object[object$Date == i, ]
  #   object$DayStart[object$Date == i] <- min(sub$Time)
  #   object$DayEnd[object$Date == i] <- max(sub$Time)
  # }
  
  BeginTime <- aggregate(object$DateTime, list(object$num), min)
  BeginTime$x <- BeginTime$x - minutes(obs.lag)
  EndTime <- aggregate(object$DateTime, list(object$num), max)
  # Duration <- rep(NA, length.out = nrow(BeginTime))
  minT <- aggregate(object$temp, list(object$num), min)
  maxT <- aggregate(object$temp, list(object$num), max)
  mean <- aggregate(object$temp, list(object$num), mean)
  depth <- aggregate(object$dif, list(object$num), sum)
  typ <- aggregate(object$typ, list(object$num), unique)
  # DayStart <- aggregate(as.POSIXct(object$DayStart, format = "%H:%M:%S"), list(object$num), min)
  # DayEnd <- aggregate(as.POSIXct(object$DayEnd, format = "%H:%M:%S"), list(object$num), min)
  
  if(is.null(ID)){
    # table <- data.frame(EndTime$x, BeginTime$x, EndTime$x, NA, minT$x, maxT$x, mean$x, depth$x ,typ$x, strftime(DayStart$x, format = "%H:%M:%S"), strftime(DayEnd$x, format = "%H:%M:%S"))
    table <- data.frame(EndTime$Group.1, BeginTime$x, EndTime$x, NA, minT$x, maxT$x, mean$x, depth$x ,typ$x)
    colnames(table) <- c("nbout", "BeginTime", "EndTime", "duration","minT", "maxT","meanT", "depthT","typ")
  }
  
  if(!is.null(ID)){
    # table <- data.frame(ID, EndTime$x, BeginTime$x, EndTime$x, NA, minT$x, maxT$x, mean$x, depth$x ,typ$x, strftime(DayStart$x, format = "%H:%M:%S"), strftime(DayEnd$x, format = "%H:%M:%S"))
    table <- data.frame(ID, EndTime$Group.1, BeginTime$x, EndTime$x, NA, minT$x, maxT$x, mean$x, depth$x ,typ$x)
    colnames(table) <- c("ID", "nbout", "BeginTime", "EndTime", "duration","minT", "maxT","meanT", "depthT","typ")
  }
  
  table$duration <- as.numeric(difftime(table$EndTime, table$BeginTime, units = dur.units))
  table <- table[order(table$BeginTime),]
  
  return(table)
}

# Day.sum ####

# Debugger
# rm(list = ls())
# source("R/Bof.R")
# source("R/SummarizeFunctions.R")

# DayNightData<- read.table("data/DayNightData.csv", sep = ",", header = TRUE)
# DayData<- read.table("data/DayData.csv", sep = ",", header = TRUE)
# boffed <- bof(object = DayData)
# 
# object = boffed; sunrise = "06:00:00"; sunset = "20:00:00"; ID = "Test"; obs.lag = 2; time.format = "%H:%M:%S"

day.sum <- function(object, sunrise = NULL, sunset = NULL, obs.lag = NULL, time.format ="%H:%M:%S" , ID = NULL) {
  
# Using an bof output
  
  # Seperate Night/Day
  
  if(!is.null(sunrise) & !is.null(sunset) & !is.null(time.format)) {
    object$DateTime <- strptime(object$DateTime, format = "%Y-%m-%d %H:%M:%S")
    object$date <- strptime(object$DateTime, format = "%Y-%m-%d")
    object$time <- strptime(strftime(object$DateTime, format = "%H:%M:%S"), format = "%H:%M:%S")
    object$period <- ifelse(object$time > strptime(sunrise, format = time.format) & object$time < strptime(sunset, format = time.format), "Day", "Night")
    object[object$period == "Night" & object$time < strptime(sunrise, format = "%H:%M:%S"), ]$date <- object[object$period == "Night" & object$time < strptime(sunrise, format = "%H:%M:%S"), ]$date - days(1)
    
    object <- object[, -which(colnames(object) == "time")]
    object$date.period <- paste(object$date, object$period, sep = "")
    
    # if("in" %in% object$typ) {
    #   TimeIn <- aggregate(x = object[object$typ == "in", "typ"], by = list(object[object$typ == "in", "date.period"]), FUN = length)
    #   colnames(TimeIn) <- c("date.period", "TimeIn")
    #   TimeIn$TimeIn <- TimeIn$TimeIn*obs.lag
    #   
    #   OnBoutCount <- aggregate(x = object[object$typ == "in", "num"], by = list(object[object$typ == "in", "date.period"]), FUN = unique)
    #   colnames(OnBoutCount) <- c("date.period", "OnBoutCount")
    #   OnBoutCount$OnBoutCount <- lengths(OnBoutCount$OnBoutCount)
    #   
    #   MeanOnT <-  aggregate(x = object[object$typ == "in", "temp"], by = list(object[object$typ == "in", "date.period"]), FUN = mean)
    #   colnames(MeanOnT) <- c("date.period", "MeanOnT")
    #   
    #   minOnT <-  aggregate(x = object[object$typ == "in", "temp"], by = list(object[object$typ == "in", "date.period"]), FUN = min)
    #   colnames(minOnT) <- c("date.period", "minOnT")
    #   
    #   maxOnT <-  aggregate(x = object[object$typ == "in", "temp"], by = list(object[object$typ == "in", "date.period"]), FUN = max)
    #   colnames(maxOnT) <- c("date.period", "maxOnT")
    # } else { 
    #   
    #   } 
    
    TimeOut <- aggregate(x = object[object$typ == "out", "typ"], by = list(object[object$typ == "out", "date.period"]), FUN = length)
    colnames(TimeOut) <- c("date.period", "TimeOut")
    TimeOut$TimeOut <- TimeOut$TimeOut*obs.lag
    
    
    
    OffBoutCount <- aggregate(x = object[object$typ == "out", "num"], by = list(object[object$typ == "out", "date.period"]), FUN = unique)
    colnames(OffBoutCount) <- c("date.period", "OffBoutCount")
    OffBoutCount$OffBoutCount <- lengths(OffBoutCount$OffBoutCount)
    
   
    MeanOffT <-  aggregate(x = object[object$typ == "out", "temp"], by = list(object[object$typ == "out", "date.period"]), FUN = mean)
    colnames(MeanOffT) <- c("date.period", "MeanOffT")
    
    minT <-  aggregate(x = object[, "temp"], by = list(object[, "date.period"]), FUN = min)
    colnames(minT) <- c("date.period", "minT")
    
    maxT <-  aggregate(x = object[, "temp"], by = list(object[, "date.period"]), FUN = max)
    colnames(maxT) <- c("date.period", "maxT")
    
    minOffT <-  aggregate(x = object[object$typ == "out", "temp"], by = list(object[object$typ == "out", "date.period"]), FUN = min)
    colnames(minOffT) <- c("date.period", "minOffT")
    
    maxOffT <-  aggregate(x = object[object$typ == "out", "temp"], by = list(object[object$typ == "out", "date.period"]), FUN = max)
    colnames(maxOffT) <- c("date.period", "maxOffT")
    
    dur <- aggregate(object$typ, by = list(object$num), FUN = length)
    object$dur <- ifelse(object$num %in% dur$Group.1, dur$x[match(object$num, dur$Group.1)], NA)
    object$dur <- object$dur*obs.lag
    MeanOnDur <- aggregate(x = (object[object$typ == "in", "dur"]), by = list(object[object$typ == "in", "date.period"]), FUN = mean)
    colnames(MeanOnDur) <- c("date.period", "MeanOnDur")
    
    MeanOffDur <- aggregate(x = (object[object$typ == "out", "dur"]), by = list(object[object$typ == "out", "date.period"]), FUN = mean)
    colnames(MeanOffDur) <- c("date.period", "MeanOffDur")
    
    # DayTable <- join_all(dfs = list(TimeIn, TimeOut, MeanOnDur, OnBoutCount, MeanOffDur ,OffBoutCount, MeanOnT, MeanOffT, minT, maxT, minOnT, maxOnT, minOffT, maxOffT),
    #                      by = "date.period", match = "all")
    
    DayTable <- list(TimeIn, TimeOut, MeanOnDur, OnBoutCount, MeanOffDur ,OffBoutCount, MeanOnT, MeanOffT, minT, maxT, minOnT, maxOnT, minOffT, maxOffT) %>%
      Reduce(function(dtf1,dtf2) full_join(dtf1,dtf2,by="date.period"), .)
    
    DayTable[is.na(DayTable$TimeIn), "TimeIn"] <- 0
    DayTable[is.na(DayTable$TimeOut), "TimeOut"] <- 0
    
    DayTable[is.na(DayTable$OnBoutCount), "OnBoutCount"] <- 0
    DayTable[is.na(DayTable$OnBoutCount), "OnBoutCount"] <- 0
    
    DayTable$IncCon <- (DayTable$TimeIn)/(DayTable$TimeIn + DayTable$TimeOut)
    
    DayTable$date <- strptime(substr(DayTable$date.period, 1, 10), format = "%Y-%m-%d")
    DayTable$period <- substr(DayTable$date.period, 11, nchar(DayTable$date.period))
    
    DayTable <- cbind(DayTable[, c(which(colnames(DayTable) == c("date", "period")))], DayTable[, -c(which(colnames(DayTable) == c("date.period","date", "period")))])
    
    if(!is.null(ID)) {
      DayTable <- cbind(ID, DayTable)
    }   
  }
  
  # Night and Day together
  
  if(is.null(sunrise) & is.null(sunset)) {
    object$DateTime <- strptime(object$DateTime, format = "%Y-%m-%d %H:%M:%S")
    object$date <- strftime(object$DateTime, format = "%Y-%m-%d")
    
    dur <- aggregate(object$typ, by = list(object$num), FUN = length)
    object$dur <- ifelse(object$num %in% dur$Group.1, dur$x[match(object$num, dur$Group.1)], NA)
    object$dur <- object$dur*obs.lag
    
    if("in" %in% object$typ) {
      OnDur <- object[object$typ == "in", c("date", "dur", "num")]
      OnDur <- OnDur[!duplicated(OnDur$num), ]

      TimeIn <- aggregate(x = OnDur$dur, by = list(OnDur$date), FUN = sum)
      colnames(TimeIn) <- c("date", "TimeIn")
            
      OnBoutCount <- aggregate(x = object[object$typ == "in", "num"], by = list(object[object$typ == "in", "date"]), FUN = unique)
      colnames(OnBoutCount) <- c("date", "OnBoutCount")
      if(nrow(OnBoutCount) > 1) {
        OnBoutCount$OnBoutCount <- lengths(OnBoutCount$OnBoutCount)
      } else {
        OnBoutCount$OnBoutCount <- length(OnBoutCount$OnBoutCount)
      }
      
      MeanOnT <-  aggregate(x = object[object$typ == "in", "temp"], by = list(object[object$typ == "in", "date"]), FUN = mean)
      colnames(MeanOnT) <- c("date", "MeanOnT")
      
      minOnT <-  aggregate(x = object[object$typ == "in", "temp"], by = list(object[object$typ == "in", "date"]), FUN = min)
      colnames(minOnT) <- c("date", "minOnT")
      
      maxOnT <-  aggregate(x = object[object$typ == "in", "temp"], by = list(object[object$typ == "in", "date"]), FUN = max)
      colnames(maxOnT) <- c("date", "maxOnT")
      
      MeanOnDur <- aggregate(x = (OnDur$dur), list(OnDur$date), FUN = mean)
      colnames(MeanOnDur) <- c("date", "MeanOnDur")
   
    } else {
      TimeIn <- data.frame(unique(object$date), NA);  colnames(TimeIn) <- c("date", "TimeIn")
      OnBoutCount <- data.frame(unique(object$date), NA);  colnames(OnBoutCount) <- c("date", "OnBoutCount")
      MeanOnT <- data.frame(unique(object$date), NA);  colnames(MeanOnT) <- c("date", "MeanOnT")
      minOnT <- data.frame(unique(object$date), NA);  colnames(minOnT) <- c("date", "minOnT")
      maxOnT <- data.frame(unique(object$date), NA);  colnames(maxOnT) <- c("date", "maxOnT")
      MeanOnDur <- data.frame(unique(object$date), NA);  colnames(MeanOnDur) <- c("date", "MeanOnDur")
    }  
    
    if("out" %in% object$typ) {
      OffDur <- object[object$typ == "out", c("date", "dur", "num")]
      OffDur <- OffDur[!duplicated(OffDur$num), ]

      TimeOut <- aggregate(x = OffDur$dur, by = list(OffDur$date), FUN = sum)
      colnames(TimeOut) <- c("date", "TimeOut")
      
      OffBoutCount <- aggregate(x = object[object$typ == "out", "num"], by = list(object[object$typ == "out", "date"]), FUN = unique)
      colnames(OffBoutCount) <- c("date", "OffBoutCount")
      if(nrow(OffBoutCount) > 1) {
        OffBoutCount$OffBoutCount <- lengths(OffBoutCount$OffBoutCount)
      } else {
        OffBoutCount$OffBoutCount <- length(OffBoutCount$OffBoutCount)
      }
      
      MeanOffT <-  aggregate(x = object[object$typ == "out", "temp"], by = list(object[object$typ == "out", "date"]), FUN = mean)
      colnames(MeanOffT) <- c("date", "MeanOffT")
      
      minOffT <-  aggregate(x = object[object$typ == "out", "temp"], by = list(object[object$typ == "out", "date"]), FUN = min)
      colnames(minOffT) <- c("date", "minOffT")
      
      maxOffT <-  aggregate(x = object[object$typ == "out", "temp"], by = list(object[object$typ == "out", "date"]), FUN = max)
      colnames(maxOffT) <- c("date", "maxOffT")
     
      MeanOffDur <- aggregate(x = (OffDur$dur), list(OffDur$date), FUN = mean)
      colnames(MeanOffDur) <- c("date", "MeanOffDur")
      
      
    } else {
      TimeOut <- data.frame(unique(object$date), NA);  colnames(TimeOut) <- c("date", "TimeOut")
      OffBoutCount <- data.frame(unique(object$date), NA);  colnames(OffBoutCount) <- c("date", "OffBoutCount")
      MeanOffT <- data.frame(unique(object$date), NA);  colnames(MeanOffT) <- c("date", "MeanOffT")
      minOffT <- data.frame(unique(object$date), NA);  colnames(minOffT) <- c("date", "minOffT")
      maxOffT <- data.frame(unique(object$date), NA);  colnames(maxOffT) <- c("date", "maxOffT")
      MeanOffDur <- data.frame(unique(object$date), NA);  colnames(MeanOffDur) <- c("date", "MeanOffDur")
    }
    
    
    minT <-  aggregate(x = object[, "temp"], by = list(object[, "date"]), FUN = min)
    colnames(minT) <- c("date", "minT")
    
    maxT <-  aggregate(x = object[, "temp"], by = list(object[, "date"]), FUN = max)
    colnames(maxT) <- c("date", "maxT")
    
    DayTable <- join_all(dfs = list(TimeIn, TimeOut, MeanOnDur, OnBoutCount, MeanOffDur ,OffBoutCount, MeanOnT, MeanOffT, minT, maxT, minOnT, maxOnT, minOffT, maxOffT),
                         by = "date", match = "all", type = "full")
    
    # DayTable <- list(TimeIn, TimeOut, MeanOnDur, OnBoutCount, MeanOffDur, OffBoutCount, MeanOnT, MeanOffT, minT, maxT, minOnT, maxOnT, minOffT, maxOffT) %>%
      # Reduce(function(dtf1,dtf2) full_join(dtf1,dtf2,by="date"), .)
    
    DayTable[is.na(DayTable$TimeIn), "TimeIn"] <- 0
    DayTable[is.na(DayTable$OnBoutCount), "OnBoutCount"] <- 0
    
    DayTable[is.na(DayTable$TimeOut), "TimeOut"] <- 0
    DayTable[is.na(DayTable$OnBoutCount), "OnBoutCount"] <- 0
    
    DayTable$IncCon <- (DayTable$TimeIn)/(DayTable$TimeIn + DayTable$TimeOut)
    
    if(!is.null(ID)) {
      DayTable <- cbind(ID, DayTable$date, DayTable[, -c(which(colnames(DayTable) == c("date", "period")))])
      colnames(DayTable)[2] <- "date"
    } else { 
      DayTable <- cbind(DayTable$date, DayTable[, -c(which(colnames(DayTable) == c("date", "period")))])
      colnames(DayTable)[1] <- "date"
    }
  }     

DayTable  
}  
