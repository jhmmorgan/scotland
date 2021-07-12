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

age_compare <- age_ratio %>%
  mutate(age = if_else(Aged_19under >= Aged_35over, 1, 0)) %>% # 1 = 19young, 0 = 35over
  mutate(value = if_else(Aged_19under >= Aged_35over, Aged_19under, Aged_35over)) %>% # value is the ratio for the highest (19 or 35)
  select(LAD20CD, DateRange, age, value)
write_csv(age_compare, "data_age_ratio.csv")

#### Visualisations ####

data_smoker <- smoking_ratio %>%
  select(LAD20CD, DateRange, Smoker_Current, Smoker_Former) %>%
  filter(!is.na(Smoker_Current)) %>%
  pivot_longer(3:4) %>% left_join(LAD_tidy)

ggplot(data_smoker, aes(x = DateRange, y = value, fill = name)) + 
  geom_col(position = "dodge") + 
  scale_x_discrete(breaks = c("2001", "2003", "2005", "2007", "2010", "2012", "2014", "2016")) +
  labs(caption = "Ratio of expecting mothers, who either smoked during pregnancy (current smoker) or formerly smoked prior to pregnancy, from 2000 to 2017.") +
  facet_wrap(vars(LAD20NM)) +
  theme_void() + 
  theme(
    panel.background = element_rect(fill = "white",
                                    colour = "white",
                                    size = 0.5, linetype = "solid"),
    panel.grid.major = element_line(size = 0.5, linetype = 'solid',
                                    colour = "lightgrey"),
    axis.text.x = element_text(size = 7)
  ) +
  theme(panel.spacing = unit(1.5, "lines")) +
  theme(strip.text = element_text(face = "bold"),
        panel.grid  = element_blank()) +
  scale_fill_discrete(name = "Smoking during pregnancy", labels = c("Current Smoker", "Former Smoker")) +
  coord_polar()


data_age <- age_ratio %>%
  select(LAD20CD, DateRange, Aged_19under, Aged_35over) %>%
  pivot_longer(3:4) %>% left_join(LAD_tidy)
ggplot(data_age, aes(x = DateRange, y = value, fill = name)) + 
  geom_col(position = "dodge") + 
  scale_x_discrete(breaks = c("2000", "2002", "2004", "2006", "2009", "2011", "2013", "2015")) +
  labs(caption = "Ratio of first time mothers who were aged 35 and over or 19 and younger whilst pregnant, from 1999 to 2016.") +
  facet_wrap(vars(LAD20NM)) +
  theme_void() + 
  theme(
    panel.background = element_rect(fill = "white",
                                    colour = "white",
                                    size = 0.5, linetype = "solid"),
    panel.grid.major = element_line(size = 0.5, linetype = 'solid',
                                    colour = "lightgrey"),
    axis.text.x = element_text(size = 7)
  ) +
  theme(panel.spacing = unit(1.5, "lines")) +
  theme(strip.text = element_text(face = "bold"),
        panel.grid  = element_blank()) +
#  theme(axis.text.y = element_text(size = 7, margin=margin(r=20))) +
#  scale_y_continuous(breaks = c(0, 5, 10, 15, 20, 25), labels = c("0%", "5%", "10%", "15%", "20%", "25%")) +
  scale_fill_discrete(name = "First Time Mothers", labels = c("% aged 19 or younger", "% aged 35 or over")) +
  coord_polar()


data_weight_smoker_age <- 
  # Select data around 19under and 35over only
  age_ratio %>% select(-`20to34`) %>% 
  # Join the smoker data
  left_join(smoking_ratio %>% select(LAD20CD, DateRange, Smoker_Current), by = c("LAD20CD", "DateRange")) %>% 
  # And join the low birth weight data
  left_join(low_birth_weight_ratio, by = c("LAD20CD", "DateRange")) %>% 
  left_join(LAD_tidy, by = "LAD20CD") %>%
  # As we have no smoking data for 1999, remove this year
  filter(DateRange != 1999) %>% 
  # Pivot the ages into one name column and one value column
  pivot_longer(cols = c(Aged_19under, Aged_35over), names_to = "age", values_to = "age_value") %>% 
  # We now want to select only the age with the highest ratio, 19under or 35over, for each region per year
  group_by(LAD20CD, DateRange) %>%
    # New column, with the age category (19under / 35over), if its the highest, or record a dash
  mutate(age_category = if_else(age_value == max(age_value), age, "-")) %>%
    # Filter / remove all the dashes - the ages that don't have the highest ratio
  filter(age_category != "-") %>%
  select(-age, age_value)

ggplot(data_weight_smoker_age) +
  geom_point(aes(y = Smoker_Current, x = Low_Weight_Births, color = age_category)) +
  xlab("Ratio of babies born with a low birth weight") +
  scale_x_continuous(breaks = c(1, 2, 3), labels = c("1.00%", "2.00%", "3.00%")) +
  ylab("Ratio of expecting mothers who smoked during pregnancy") +
  scale_y_continuous(breaks = c(10, 20, 30), labels = c("10%", "20%", "30%")) +
  theme(
    panel.background = element_rect(fill = "white"),
    panel.grid.major = element_line(size = 0.5, 
                                    linetype = 'dashed',
                                    colour = "lightgrey"),
    axis.text.x = element_text(size = 9, margin=margin(t=10, b=10)),
    axis.text.y = element_text(size = 9, margin=margin(r=10, l=10))) +
  scale_color_discrete(name = "First Time Mothers", labels = c("Aged 19 or younger", "Aged 35 or over"))

