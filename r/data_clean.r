#### SETUP ####
# Libaries
library(tidyverse)
# Folder Locations
.project_folder <- getwd()
.data_folder <- paste0(.project_folder,"/data/")

#### DATA FILES ####
# Various data files from ONS
#    Low Birth Weight, Immunity, Breastfeeding and others
.data_low_birth_1     <- "low_birth_weight_20210604.csv"
.data_immunity_1      <- "immunity_20210604.csv"
.data_breastfeeding_1 <- "breastfeeding_20210604.csv"

# The age of first time mothers dataset is large and couldn't be downloaded in one file. 
#  The count and ratio files were downloaded individually and will be stitched back together.
.data_age_count_19under <- "age_at_first_birth_count_19under_20210623.csv"
.data_age_count_35over  <- "age_at_first_birth_count_35over_20210623.csv"
.data_age_ratio_19under <- "age_at_first_birth_ratio_19under_20210604.csv"
.data_age_ratio_35over  <- "age_at_first_birth_ratio_35over_20210604.csv"

# The smoking at booking dataset is large and couldn't be downloaded in one file.
# The 4 statues as counts and ratio files were downloaded individually and will be stiched back together.
.data_smoking_count_unknown <- "smoking_count_unknown_20210626.csv"
.data_smoking_count_never   <- "smoking_count_never_20210626.csv"
.data_smoking_count_former  <- "smoking_count_former_20210626.csv"
.data_smoking_count_current <- "smoking_count_current_20210626.csv"
.data_smoking_ratio_unknown <- "smoking_ratio_unknown_20210626.csv"
.data_smoking_ratio_never   <- "smoking_ratio_never_20210626.csv"
.data_smoking_ratio_former  <- "smoking_ratio_former_20210626.csv"
.data_smoking_ratio_current <- "smoking_ratio_current_20210626.csv"


# The local authority districts (LAD) ~ council regions of Scotland.
.data_LAD             <- "Local_Authority_Districts_(April_2020)_Names_and_Codes_in_the_United_Kingdom.csv"

# Loading the data files
low_birth_weight_raw      <- read_csv(paste0(.data_folder, .data_low_birth_1))
immunity_raw              <- read_csv(paste0(.data_folder, .data_immunity_1))
breastfeeding_raw         <- read_csv(paste0(.data_folder, .data_breastfeeding_1))

age_count_19under_raw     <- read_csv(paste0(.data_folder, .data_age_count_19under))
age_count_35over_raw      <- read_csv(paste0(.data_folder, .data_age_count_35over))
age_ratio_19under_raw     <- read_csv(paste0(.data_folder, .data_age_ratio_19under))
age_ratio_35over_raw      <- read_csv(paste0(.data_folder, .data_age_ratio_35over))

smoking_count_unknown_raw <- read_csv(paste0(.data_folder, .data_smoking_count_unknown))
smoking_count_never_raw   <- read_csv(paste0(.data_folder, .data_smoking_count_never))
smoking_count_former_raw  <- read_csv(paste0(.data_folder, .data_smoking_count_former))
smoking_count_current_raw <- read_csv(paste0(.data_folder, .data_smoking_count_current))

smoking_ratio_unknown_raw <- read_csv(paste0(.data_folder, .data_smoking_ratio_unknown))
smoking_ratio_never_raw   <- read_csv(paste0(.data_folder, .data_smoking_ratio_never))
smoking_ratio_former_raw  <- read_csv(paste0(.data_folder, .data_smoking_ratio_former))
smoking_ratio_current_raw <- read_csv(paste0(.data_folder, .data_smoking_ratio_current))

LAD_raw                   <- read_csv(paste0(.data_folder, .data_LAD))

#### CLEANING ####
# The data files contain records not just for the LAD (local authority district) but for 
#  other breakdowns, such as health board areas and electoral wards.
# Therefore, each dataset needs to be filtered to the 32 LAD's as well as cleaned before 
#  they can be combined into one combined dataset.

## Local Area Districts
LAD_tidy <- LAD_raw %>%
  filter(str_starts(LAD20CD, "S")) %>% # All LAD's that start with 'S' are Scottish.
  select(-FID, -LAD20NMW) %>% # Remove unneeded columns 
  add_row(LAD20CD = "S92000003", LAD20NM = "Scotland") # Add Scotland (for overall average)

## Age Ratio
age_ratio_19under_clean  <- age_ratio_19under_raw %>% 
  mutate(Reference = str_sub(Reference, nchar(Reference)-8,99),
         Age = "Aged_19under",
         Measurement = "Ratio") %>%
  rename(LAD20CD = Reference) %>% 
  relocate(Age, .after = Area) %>%
  pivot_longer(cols = 4:21, names_to = "DateRange", values_to = "Value")

age_ratio_35over_clean  <- age_ratio_35over_raw %>% 
  mutate(Reference = str_sub(Reference, nchar(Reference)-8,99),
         Age = "Aged_35over",
         Measurement = "Ratio") %>%
  rename(LAD20CD = Reference) %>% 
  relocate(Age, .after = Area) %>%
  pivot_longer(cols = 4:21, names_to = "DateRange", values_to = "Value")

# Combine the various age_ratio files into one dataset.
age_ratio_tidy <- rbind(age_ratio_19under_clean, age_ratio_35over_clean) %>%
  filter(LAD20CD %in% LAD_tidy$LAD20CD) # Filter the dataset to only include the 32 LAD's


## Age Count
age_count_19under_clean  <- age_count_19under_raw %>% 
  mutate(Reference = str_sub(Reference, nchar(Reference)-8,99),
         Age = "Aged_19under",
         Measurement = "Count") %>%
  rename(LAD20CD = Reference) %>% 
  relocate(Age, .after = Area) %>%
  pivot_longer(cols = 4:21, names_to = "DateRange", values_to = "Value")

age_count_35over_clean  <- age_count_35over_raw %>% 
  mutate(Reference = str_sub(Reference, nchar(Reference)-8,99),
         Age = "Aged_35over",
         Measurement = "Count") %>%
  rename(LAD20CD = Reference) %>% 
  relocate(Age, .after = Area) %>%
  pivot_longer(cols = 4:21, names_to = "DateRange", values_to = "Value")

# Combine the various age_count files into one dataset.
age_count_tidy <- rbind(age_count_19under_clean, age_count_35over_clean) %>%
  filter(LAD20CD %in% LAD_tidy$LAD20CD) # Filter the dataset to only include the 32 LAD's


# Age Tidy - combine the tidy count and ratio into one big dataset
age_tidy <- rbind(age_ratio_tidy, age_count_tidy) %>%
  mutate(DateRange = str_sub(DateRange,1,4)) %>%
  rename(Category = Age) %>%
  select(LAD20CD, DateRange, Measurement, Category, Value) %>%
  arrange(LAD20CD, DateRange, Measurement, Category)


## Immunity / Vaccination
immunity_tidy <- immunity_raw %>%
  rename(LAD20CD = FeatureCode,
         Category = `Vaccination Uptake`) %>%
  mutate(DateRange = as.character(DateCode)) %>%
  relocate(Value, .after = Category) %>%
  select(-Units, -DateCode) %>%
  filter(LAD20CD %in% LAD_tidy$LAD20CD) %>%
  arrange(LAD20CD, DateRange, Measurement, Category) %>%
  mutate(Category = Category %>% str_replace_all("Number In 24 Month Cohort", "Number_24months")) %>%
  mutate(Category = Category %>% str_replace_all("Vaccinated by 24 Months", "Vaccinated_24months"))

## Breastfeeding
breastfeeding_tidy <- breastfeeding_raw %>%
  mutate(DateRange = str_sub(DateCode, 1, 4)) %>%
  rename(LAD20CD = FeatureCode,
         Category = `Population Group`,
         CollectionTime = `Breastfeeding Data Collection Time`) %>%
  relocate(CollectionTime, .after = Category) %>%
  relocate(Value, .after = CollectionTime) %>%
  select(LAD20CD, DateRange, Measurement, Category, CollectionTime, Value) %>%
  filter(LAD20CD %in% LAD_tidy$LAD20CD) %>%
  arrange(LAD20CD, DateRange, Measurement, Category, CollectionTime) %>%
  mutate(Category = Category %>% str_replace_all("Exclusively Breastfed", "Breastfed_Exclusively")) %>%
  mutate(CollectionTime = CollectionTime %>% str_replace_all("First Visit", "Review_First_Visit"))%>%
  mutate(CollectionTime = CollectionTime %>% str_replace_all("6 To 8 Week Review", "Review_6to8_Week"))


## Low Birth Weight
low_birth_weight_tidy <- low_birth_weight_raw %>%
  rename(LAD20CD = FeatureCode,
         Category = `Birth Weight`) %>%
  #         DateRange = DateCode) %>%
  mutate(DateRange = str_sub(DateCode, 1, 4)) %>%
  relocate(Value, .after = Category) %>%
  select(-Units, -DateCode) %>%
  filter(LAD20CD %in% LAD_tidy$LAD20CD) %>%
  arrange(LAD20CD, DateRange, Measurement, Category) %>%
  mutate(Category = Category %>% str_replace_all("Live Singleton Births", "Live_Singleton_Births")) %>%
  mutate(Category = Category %>% str_replace_all("Low Weight Births", "Low_Weight_Births"))


## Smoking Count
smoking_count_unknown_clean  <- smoking_count_unknown_raw %>% 
  mutate(Reference = str_sub(Reference, nchar(Reference)-8,99),
         Category = "Smoker_Unknown",
         Measurement = "Count") %>%
  rename(LAD20CD = Reference) %>% 
  relocate(Category, .after = Area) %>%
  pivot_longer(cols = 4:21, names_to = "DateRange", values_to = "Value")

smoking_count_never_clean  <- smoking_count_never_raw %>% 
  mutate(Reference = str_sub(Reference, nchar(Reference)-8,99),
         Category = "Smoker_Never",
         Measurement = "Count") %>%
  rename(LAD20CD = Reference) %>% 
  relocate(Category, .after = Area) %>%
  pivot_longer(cols = 4:21, names_to = "DateRange", values_to = "Value")

smoking_count_former_clean  <- smoking_count_former_raw %>% 
  mutate(Reference = str_sub(Reference, nchar(Reference)-8,99),
         Category = "Smoker_Former",
         Measurement = "Count") %>%
  rename(LAD20CD = Reference) %>% 
  relocate(Category, .after = Area) %>%
  pivot_longer(cols = 4:21, names_to = "DateRange", values_to = "Value")

smoking_count_current_clean  <- smoking_count_current_raw %>% 
  mutate(Reference = str_sub(Reference, nchar(Reference)-8,99),
         Category = "Smoker_Current",
         Measurement = "Count") %>%
  rename(LAD20CD = Reference) %>% 
  relocate(Category, .after = Area) %>%
  pivot_longer(cols = 4:21, names_to = "DateRange", values_to = "Value")


# Combine the various smoking_count files into one dataset.
smoking_count_tidy <- rbind(smoking_count_unknown_clean, 
                            smoking_count_never_clean,
                            smoking_count_former_clean,
                            smoking_count_current_clean) %>%
  filter(LAD20CD %in% LAD_tidy$LAD20CD) # Filter the dataset to only include the 32 LAD's

## Smoking Ratio
smoking_ratio_unknown_clean  <- smoking_ratio_unknown_raw %>% 
  mutate(Reference = str_sub(Reference, nchar(Reference)-8,99),
         Category = "Smoker_Unknown",
         Measurement = "Ratio") %>%
  rename(LAD20CD = Reference) %>% 
  relocate(Category, .after = Area) %>%
  pivot_longer(cols = 4:21, names_to = "DateRange", values_to = "Value")

smoking_ratio_never_clean  <- smoking_ratio_never_raw %>% 
  mutate(Reference = str_sub(Reference, nchar(Reference)-8,99),
         Category = "Smoker_Never",
         Measurement = "Ratio") %>%
  rename(LAD20CD = Reference) %>% 
  relocate(Category, .after = Area) %>%
  pivot_longer(cols = 4:21, names_to = "DateRange", values_to = "Value")

smoking_ratio_former_clean  <- smoking_ratio_former_raw %>% 
  mutate(Reference = str_sub(Reference, nchar(Reference)-8,99),
         Category = "Smoker_Former",
         Measurement = "Ratio") %>%
  rename(LAD20CD = Reference) %>% 
  relocate(Category, .after = Area) %>%
  pivot_longer(cols = 4:21, names_to = "DateRange", values_to = "Value")

smoking_ratio_current_clean  <- smoking_ratio_current_raw %>% 
  mutate(Reference = str_sub(Reference, nchar(Reference)-8,99),
         Category = "Smoker_Current",
         Measurement = "Ratio") %>%
  rename(LAD20CD = Reference) %>% 
  relocate(Category, .after = Area) %>%
  pivot_longer(cols = 4:21, names_to = "DateRange", values_to = "Value")


# Combine the various smoking_ratio files into one dataset.
smoking_ratio_tidy <- rbind(smoking_ratio_unknown_clean, 
                            smoking_ratio_never_clean,
                            smoking_ratio_former_clean,
                            smoking_ratio_current_clean) %>%
  filter(LAD20CD %in% LAD_tidy$LAD20CD) # Filter the dataset to only include the 32 LAD's

# Smoking Tidy - combine the tidy count and ratio into one big dataset
smoking_tidy <- rbind(smoking_ratio_tidy, smoking_count_tidy) %>%
  mutate(DateRange = str_sub(DateRange, 1, 4)) %>%
  select(LAD20CD, DateRange, Measurement, Category, Value) %>%
  arrange(LAD20CD, DateRange, Measurement, Category)

# Remove the raw data, keep the tidy data
rm(LAD_raw,
   age_ratio_19under_raw, age_ratio_35over_raw,
   age_ratio_19under_clean, age_ratio_35over_clean,
   age_count_19under_raw, age_count_35over_raw,
   age_count_19under_clean, age_count_35over_clean,
   age_ratio_tidy, age_count_tidy,
   immunity_raw,
   breastfeeding_raw,
   low_birth_weight_raw,
   smoking_count_unknown_raw, smoking_count_never_raw, smoking_count_former_raw, smoking_count_current_raw,
   smoking_count_unknown_clean, smoking_count_never_clean, smoking_count_former_clean, smoking_count_current_clean,
   smoking_ratio_unknown_raw, smoking_ratio_never_raw, smoking_ratio_former_raw, smoking_ratio_current_raw,
   smoking_ratio_unknown_clean, smoking_ratio_never_clean, smoking_ratio_former_clean, smoking_ratio_current_clean,
   smoking_ratio_tidy, smoking_count_tidy) 


#### WRANGLING ####
# For the purposes of the project, we'll be working with the ratio's only.
# So we'll filter each of the data sets accordingly

age_ratio <- age_tidy %>%
  filter(Measurement == "Ratio") %>%
  select(-Measurement) %>%
  pivot_wider(names_from = Category, values_from = Value) %>%
  mutate(`20to34` = (100-`Aged_19under`-`Aged_35over`))

breastfeeding_ratio <- breastfeeding_tidy %>%
  filter(Measurement == "Ratio") %>%
  select(-Measurement) %>%
  pivot_wider(names_from = c(Category, CollectionTime), values_from = Value)

immunity_ratio <- immunity_tidy %>%
  filter(Measurement == "Ratio") %>%
  select(-Measurement) %>%
  pivot_wider(names_from = Category, values_from = Value)

low_birth_weight_ratio <- low_birth_weight_tidy %>%
  filter(Measurement == "Ratio") %>%
  select(-Measurement) %>%
  pivot_wider(names_from = Category, values_from = Value)

smoking_ratio <- smoking_tidy %>%
  filter(Measurement == "Ratio") %>%
  select(-Measurement) %>%
  pivot_wider(names_from = Category, values_from = Value)

rm(age_tidy, breastfeeding_tidy, immunity_tidy, low_birth_weight_tidy, smoking_tidy)

#### Datasets ####
write_csv(low_birth_weight_ratio, "data_weight_ratio.csv")
write_csv(smoking_ratio, "data_smoking_ratio.csv")
smoking_dataset = smoking_ratio %>%
  select(id = LAD20CD, )
