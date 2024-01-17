library(dplyr)
library(purrr)
library(reticulate)

use_virtualenv("./.venv")

mongo_manager <- import_from_path("mongo_manager", path="./src/python")

#source_python("./src/python/mongo_manager.py")
result <- mongo_manager$write_to_mongo(data)
test <- mongo_manager$tester()
test <- mongo_manager_tester()
prices <- mongo_manager$get_price_history("westus")

length(prices)
last(prices)
df <- as_tibble(prices)
df <- tibble(prices)
df2 <- transpose(df)
df2[1]
df[1][1]
names(df)
length(df)
prices[500]
p <- map_dbl(prices, ~ as.numeric(.$unitPrice))
p|>unique()
