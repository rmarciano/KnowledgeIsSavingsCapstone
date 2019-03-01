library(readr)
library(caTools)
library(DAAG)
library(caret)
library(leaps)
library(ggvis)
library(rpart)
library(rpart.plot)
library(e1071)
library(ROCR)

#Linear Regression
payment_zip <-read.csv("Payment Zip.csv", stringsAsFactors = FALSE)
payment_zip <- subset(payment_zip, select = c("DRG_Code", "Provider_Id", "Provider_Zip", "Total_Discharges", "Average_Covered_Charges", "Average_Total_Payments", "Average_Patient_Payments", "latitude", "longitude", "irs_estimated_population_2015"))


set.seed(100)

split <- sample.split(payment_zip$Average_Patient_Payments, SplitRatio = 0.5)

train <- subset(payment_zip, split == TRUE)
test <- subset(payment_zip, split == FALSE)

regfit_payment <- regsubsets(Average_Patient_Payments ~ ., data = payment_zip, nvmax = 9)
regfit_summary <- summary(regfit_payment)
regfit_summary


rsq <- as.data.frame(regfit_summary$rsq)

names(rsq) <- "R2"

rsq %>% 
  ggvis(x = ~ c(1:nrow(rsq)), y = ~ R2) %>% 
  layer_points(fill = ~ R2) %>% 
  add_axis("y", title = "R2") %>% 
  add_axis("x", title = "Number of variables")



plot(regfit_summary$rss, xlab = "Number of Variables", ylab = "RSS")
plot(regfit_summary$adjr2, xlab = "Number of Variables", ylab = "Adjusted RSq")
plot(regfit_summary$cp, xlab = "Number of Variables", ylab = "CP")
plot(regfit_summary$bic, xlab = "Number of Variables", ylab = "BIC")


coef(regfit_payment, 6)

data_setup <- trainControl(method = "cv", number = 10)

crossvalid_paymentmodel <- train(Average_Patient_Payments ~ DRG_Code + Provider_Id + Provider_Zip + Total_Discharges + Average_Covered_Charges + Average_Total_Payments, data = train, trControl = data_setup, method = "lm")

crossvalid_paymentmodel
crossvalid_paymentmodel$finalModel
crossvalid_paymentmodel$resample
sd(crossvalid_paymentmodel$resample$Rsquared)
summary(crossvalid_paymentmodel$finalModel)


payment_model <- crossvalid_paymentmodel$finalModel


confint(payment_model)

par(mar = c(4, 4, 2, 2), mfrow = c(1, 2)) 
plot(payment_model, which = c(1, 2))

plot(payment_model$residuals)


prediction <- predict(payment_model, newdata = test)
Actual_Prediction <- data.frame(cbind(actuals = test$Average_Patient_Payments, predicteds = prediction))

plot(Actual_Prediction)

correlation_accuracy <- cor(Actual_Prediction)
correlation_accuracy


    
#CART


summary(payment_zip$Average_Patient_Payments)


split2 <- sample.split(payment_zip$Average_Patient_Payments, SplitRatio = 0.5)

train2 <- subset(payment_zip, split2 == TRUE)
test2 <- subset(payment_zip, split2 == FALSE)


regression_tree <- rpart(Average_Patient_Payments ~ ., data = train2)
prp(regression_tree)


cp_model <- train(Average_Patient_Payments ~ DRG_Code + Provider_Id + Zip + Total_Discharges + Average_Covered_Charges + Average_Total_Payments, data = train2, method = "rpart", trControl = trainControl("cv", number = 10), tuneLength = 10)
plot(cp_model)
cp_model$bestTune
plot(cp_model$finalModel)
text(cp_model$finalModel, digits = 1)
cp_model$finalModel

tree_prediction <- cp_model %>% predict(test2)
predict_sse <- sum((tree_prediction - test2$Average_Patient_Payments)^2)
RMSE(tree_prediction, test2$Average_Patient_Payments)


#Binary CART

colnames(payment_zip) <- c("DRG Code", "Provider ID", "Zip Code", "Tot Discharges", "Avg Covered Charges", "Avg Tot Payments", "Average_Patient_Payments", "Latitude", "Longitude", "Est Pop 2015")

payment_zip$Average_Patient_Payments <- factor(ifelse(payment_zip$Average_Patient_Payments < 1000, 0, 1))


split3 <- sample.split(payment_zip$Average_Patient_Payments, SplitRatio = 0.5)
train3 <- subset(payment_zip, split3 == TRUE)
test3 <- subset(payment_zip, split3 == FALSE)

binary_tree <- rpart(Average_Patient_Payments ~., data = train3, method = "class", control = rpart.control(minbucket = 25))

prp(binary_tree)

predict_binary_tree <- predict(binary_tree, newdata = test3, type = "class")
table(test3$Average_Patient_Payments, predict_binary_tree)

(41791 + 10393)/(41791 + 10393 + 6772 + 24024)

PredictROC <- predict(binary_tree, newdata = test3)



pred <- prediction(PredictROC[,2], test3$Average_Patient_Payments)
perf = performance(pred, "tpr", "fpr")
plot(perf, colorize = TRUE, print.cutoffs.at = seq(0,1,0.1), text.adj = c(-0.2,1.7))



fitControl <- trainControl(method = "cv", number = 10)
cartGrid <- expand.grid(.cp = (1:50)*0.001)
train(Average_Patient_Payments ~ ., data = train3, method = "rpart", trControl = fitControl, tuneGrid = cartGrid, na.action = na.omit)

binary_treeCV <- rpart(Average_Patient_Payments ~., method = "class", data = train3, control = rpart.control(cp = 0.001))
predictCV <- predict(binary_treeCV, newdata = test3, type = "class")
table(test3$Average_Patient_Payments, predictCV)

(41799 + 12558)/(41799 + 12558 + 6764 + 21859)
