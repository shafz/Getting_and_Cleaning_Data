# download data
library(httr) 
url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
file <- "dataset.zip"
if(!file.exists(file)) {
    download.file(url, file, method="curl")
}

# unzip and create folders
datasetfolder <- "UCI HAR Dataset"
resultsfolder <- "results"

if(!file.exists(datasetfolder)) {
    unzip(file, list = FALSE, overwrite = TRUE)
} 

if(!file.exists(resultsfolder)) {
    dir.create(resultsfolder)
} 

# read txt and covnert to data.frame
gettables <- function (filename,cols = NULL) {
    print(paste("Getting table:", filename))
    f <- paste(datasetfolder,filename,sep="/")
    data <- data.frame()
    if(is.null(cols)) {
        data <- read.table(f,sep="",stringsAsFactors=F)
    } else {
        data <- read.table(f,sep="",stringsAsFactors=F, col.names= cols)
    }
    data
}

# run and check gettables
features <- gettables("features.txt")

# read data and build database
getdata <- function(type, features) {
    print(paste("Getting data", type))
    subjectdata <- gettables(paste(type,"/","subject_",type,".txt",sep=""),"id")
    Ydata <- gettables(paste(type,"/","y_",type,".txt",sep=""),"activity")
    Xdata <- gettables(paste(type,"/","X_",type,".txt",sep=""),features$V2)
    return (cbind(subjectdata,Ydata,Xdata))
}

# run and check getdata
test <- getdata("test", features)
train <- getdata("train", features)

# save the resulting data in the indicated folder
saveresults <- function (data,name){
    print(paste("saving results", name))
    file <- paste(resultsfolder, "/", name,".txt" ,sep="")
    write.table(data,file)
}

# Activities 

# Step 1 - Merges the training and the test sets to create one data set.
library(plyr)
data <- rbind(train, test)
data <- arrange(data, id)

# Step 2 - Extracts only the measurements on the mean and standard deviation for each measurement. 
mean_and_std <- data[,c(1,2,grep("std", colnames(data)), grep("mean", colnames(data)))]
saveresults(mean_and_std,"mean_and_std")

# Step 3 - Uses descriptive activity names to name the activities in the data set
activity_labels <- gettables("activity_labels.txt")
setnames(activity_labels, names(activity_labels), c("activityNum", "activityName"))

# Step 4 - Appropriately labels the data set with descriptive variable names. 
data$activity <- factor(data$activity, levels=activity_labels$activityNum, labels=activity_labels$activityName)

# Step 5 - Creates a independent tidy data set with the average of each variable for each activity and each subject. 
tidy_dataset <- ddply(mean_and_std, .(id, activity), .fun=function(x){ colMeans(x[,-c(1:2)]) })
colnames(tidy_dataset)[-c(1:2)] <- paste(colnames(tidy_dataset)[-c(1:2)], "_mean", sep="")
saveresults(tidy_dataset,"tidy_dataset")