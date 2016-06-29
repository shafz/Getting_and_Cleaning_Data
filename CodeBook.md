## Introduction

This file describes the data, the variables, and the work that has been performed to clean up the data.

## Data Set Description

The experiments have been carried out with a group of 30 volunteers within an age bracket of 19-48 years. Each person performed six activities (WALKING, WALKING_UPSTAIRS, WALKING_DOWNSTAIRS, SITTING, STANDING, LAYING) wearing a smartphone (Samsung Galaxy S II) on the waist. Using its embedded accelerometer and gyroscope, we captured 3-axial linear acceleration and 3-axial angular velocity at a constant rate of 50Hz. The experiments have been video-recorded to label the data manually. The obtained dataset has been randomly partitioned into two sets, where 70% of the volunteers was selected for generating the training data and 30% the test data. 

The sensor signals (accelerometer and gyroscope) were pre-processed by applying noise filters and then sampled in fixed-width sliding windows of 2.56 sec and 50% overlap (128 readings/window). The sensor acceleration signal, which has gravitational and body motion components, was separated using a Butterworth low-pass filter into body acceleration and gravity. The gravitational force is assumed to have only low frequency components, therefore a filter with 0.3 Hz cutoff frequency was used. From each window, a vector of features was obtained by calculating variables from the time and frequency domain. 

### For each record it is provided:

* Triaxial acceleration from the accelerometer (total acceleration) and the estimated body acceleration.
* Triaxial Angular velocity from the gyroscope. 
* A 561-feature vector with time and frequency domain variables. 
* Its activity label. 
* An identifier of the subject who carried out the experiment.

### The dataset includes the following files:

* 'features_info.txt': Shows information about the variables used on the feature vector.
* 'features.txt': List of all features.
* 'activity_labels.txt': Links the class labels with their activity name.
* 'train/X_train.txt': Training set.
* 'train/y_train.txt': Training labels.
* 'test/X_test.txt': Test set.
* 'test/y_test.txt': Test labels.
* 'train/subject_train.txt': Each row identifies the subject who performed the activity for each window sample. Its range is from 1 to 30. 
* 'train/Inertial Signals/total_acc_x_train.txt': The acceleration signal from the smartphone accelerometer X axis in standard gravity units 'g'. Every row shows a 128 element vector. The same description applies for the 'total_acc_x_train.txt' and 'total_acc_z_train.txt' files for the Y and Z axis. 
* 'train/Inertial Signals/body_acc_x_train.txt': The body acceleration signal obtained by subtracting the gravity from the total acceleration. 
* 'train/Inertial Signals/body_gyro_x_train.txt': The angular velocity vector measured by the gyroscope for each window sample. The units are radians/second. 

## Variables

* `Xdata`, `Ydata` and `subjectdata` contain the data from the downloaded files.
* `Xdata`, `Ydata` and `subjectdata` merge the previous datasets to further analysis.
* `features` contains the correct names for the `Xdata` dataset, which are applied to the column names stored in `mean_and_std`, a numeric vector used to extract the desired data.
* A similar approach is taken with activity names through the `activity_labels` variable.
* `data` merges `Xdata`, `Ydata` and `subjectdata` in a big dataset.
* Finally, `tidy_dataset` contains the relevant averages which will be later stored in a `.txt` file. `ddply()` from the plyr package is used to apply `colMeans()` and ease the development.

## Work/Transformations

#### Load test and training sets and the activities


The data set has been stored in the `UCI HAR Dataset/` directory.

```
# download data
library(httr) 
url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
file <- "dataset.zip"
if(!file.exists(file)) {
    download.file(url, file, method="curl")
}
```

The `unzip` function is used to extract the zip file in this directory.

```
# unzip and create folders
datasetfolder <- "UCI HAR Dataset"
resultsfolder <- "results"

if(!file.exists(datasetfolder)) {
    unzip(file, list = FALSE, overwrite = TRUE)
} 

if(!file.exists(resultsfolder)) {
    dir.create(resultsfolder)
} 
```

The script is running as a whole using recycle functions for both test and train data.

```
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
```

Then all the result will be stored in a file.

```
# save the resulting data in the indicated folder
saveresults <- function (data,name){
    print(paste("saving results", name))
    file <- paste(resultsfolder, "/", name,".txt" ,sep="")
    write.table(data,file)
}
```

#### Activities

##### Step 1 - Merges the training and the test sets to create one data set.

```
library(plyr)
data <- rbind(train, test)
data <- arrange(data, id)
```

##### Step 2 - Extracts only the measurements on the mean and standard deviation for each measurement. 
```
mean_and_std <- data[,c(1,2,grep("std", colnames(data)), grep("mean", colnames(data)))]
saveresults(mean_and_std,"mean_and_std")
```

##### Step 3 - Uses descriptive activity names to name the activities in the data set
```
activity_labels <- gettables("activity_labels.txt")
setnames(activity_labels, names(activity_labels), c("activityNum", "activityName"))
```

##### Step 4 - Appropriately labels the data set with descriptive variable names. 
```
data$activity <- factor(data$activity, levels=activity_labels$activityNum, labels=activity_labels$activityName)
```

##### Step 5 - Creates a independent tidy data set with the average of each variable for each activity and each subject. 
```
tidy_dataset <- ddply(mean_and_std, .(id, activity), .fun=function(x){ colMeans(x[,-c(1:2)]) })
colnames(tidy_dataset)[-c(1:2)] <- paste(colnames(tidy_dataset)[-c(1:2)], "_mean", sep="")
saveresults(tidy_dataset,"tidy_dataset")
```

