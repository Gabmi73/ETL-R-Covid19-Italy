library(tidyverse) 
library(rsdmx) 
library(readxl)

# ========= ETL DATA COVID-19 ITALY  

# ====================== EXTRACTIONS ========================

# NATIONAL DATA
dpcNaz <- read.csv(
  "https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-andamento-nazionale/dpc-covid19-ita-andamento-nazionale.csv",
  header = TRUE, encoding = "UTF-8") %>% 
  mutate(data = as.Date(data))

# REGIONAL DATA
dpcReg <- read.csv(
  "https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-regioni/dpc-covid19-ita-regioni.csv",
  header = TRUE, encoding = "UTF-8") %>% 
  mutate(data = as.Date(data))

# VACCINATION DATA
openVax <- read.csv(
  "https://raw.githubusercontent.com/italia/covid19-opendata-vaccini/master/dati/somministrazioni-vaccini-summary-latest.csv",
  header = TRUE, encoding = "UTF-8") %>% 
  mutate(data = as.Date(data))


# ISTAT ITALIAN NATIONAL STATISTICS
#1) REGIONS, PROVINCES AND AREA CODES
ITTER107 <- tibble(
  ITTER107 = 
    c("IT","ITC","ITC1","ITC11","ITC12","ITC13","ITC14", "ITC15","ITC16","ITC17",
      "ITC18","ITC2","ITC3","ITC31","ITC32","ITC33","ITC34","ITC4","ITC41","ITC42",
      "ITC43","ITC44","ITC45","ITC46","ITC47","ITC48","ITC49","ITC4A","ITC4B","ITD",
      "ITDA","ITD1","ITD2","ITD3","ITD31","ITD32","ITD33","ITD34","ITD35","ITD36","ITD37",
      "ITD4","ITD41","ITD42","ITD43","ITD44","ITD5","ITD51","ITD52","ITD53","ITD54","ITD55",
      "ITD56","ITD57","ITD58","ITD59","ITE","ITE1","ITE11","ITE12","ITE13","ITE14","ITE15",
      "ITE16","ITE17","ITE18","ITE19","ITE1A","ITE2","ITE21","ITE22","ITE3","ITE31","ITE32",
      "ITE33","ITE34","ITE4","ITE41","ITE42","ITE43","ITE44","ITE45","ITF","ITF1","ITF11",
      "ITF12","ITF13","ITF14","ITF2","ITF21","ITF22","ITF3","ITF31","ITF32","ITF33","ITF34",
      "ITF35","ITF4","ITF41","ITF42","ITF43","ITF44","ITF45","ITF5","ITF51","ITF52","ITF6",
      "ITF61","ITF62","ITF63","ITF64","ITF65","ITG","ITG1","ITG11","ITG12","ITG13","ITG14",
      "ITG15","ITG16","ITG17","ITG18","ITG19","ITG2","ITG25","ITG26","ITG27","ITG28","IT108",
      "IT109","IT110","IT111"))

# RESIDENT POPULATION BY MOTH FROM 2020 UNTIL LAST AVAILABLE DATA
# it takes about 3/4 minutes
pop_mese <- readSDMX(providerId = "ISTAT",
                     resource = "data", 
                     flowRef  = "22_315", 
                     dsd = FALSE,
                     key = list(NULL, NULL, "9", "POPEND"),
                     start = 2020) %>% 
  as.data.frame(labels = TRUE) %>% 
  select(ITTER107, obsTime, N=obsValue)

# REGION'S AREAS IN KMQ2
# it takes about 1/2 minutes
superfici <- readSDMX(providerId = "ISTAT",
                      resource = "data", 
                      flowRef  = "729_1050", 
                      dsd = FALSE,
                      key = list(NULL, NULL,"TOTAREA2"),
                      start = 2020,
                      end = 2020) %>% 
  as.data.frame(labels = TRUE) %>% 
  select(ITTER107, kmq2 = obsValue) %>%
  right_join(ITTER107)

# MERGE AREA AND POPULATION AND SELECT ONLY ITALY/ DEALING WITH DATES
sup_pop <- superfici %>% 
  left_join(pop_mese) %>% 
  filter(ITTER107 == "IT") %>% 
  select(-ITTER107) %>% 
  rename(data = obsTime) %>% 
  mutate(data = as.Date(paste0(data, "-01"), "%Y-%m-%d")) %>% 
  mutate(data = lubridate::ceiling_date(data, "month") - lubridate::days(1))


# COLORS ISSUED BY ITALIAN GOV ORDINANCE (see script 00_GET_Colors.R)
col_ord <- read_csv("colors.csv", 
                    col_types = cols(data = col_date(format = "%Y-%m-%d")))

# RT WITH SINTHOMS FROM ISS DATA
temp = tempfile(fileext = ".xlsx") 
dataURL <- "http://www.epicentro.iss.it/coronavirus/open-data/covid_19-iss.xlsx"
download.file(dataURL, destfile = temp, mode="wb")

iss_sym <- read_excel(temp, sheet = "casi_inizio_sintomi_sint")

# ====================== FEATURE ENGENEERING =========

# CALCULATING NATIONAL COLORS SCORE BY SUM OF COLORS FOR EACH REGION
# AND THEN SUM OF COL REGIONS FOR EACH DAY
colors_sum <- dpcReg %>%
  rename(Territorio = denominazione_regione) %>% 
  mutate(Territorio = tolower(Territorio)) %>%
  left_join(col_ord) %>% 
  group_by(Territorio) %>% 
  fill(color, nr_ord) %>%
  select(data, Territorio, color) %>% 
  ungroup() %>% 
  group_by(data) %>% 
  summarise(col_day = sum(color)) %>% 
  mutate(col_day = ifelse(data < "2020-11-06", 0, col_day)) %>% # no color days
  mutate(col_day = ifelse(data > "2022-03-31", 0, col_day)) %>% 
  mutate(col_day = as.integer(col_day))


# RT FUNCTION
# Function based on R Epiestim script available at
# "https://www.epicentro.iss.it/coronavirus/open-data/calcolo_rt_italia.zip"

F_RT <- function(x) {
  require(EpiEstim)
  shape.stimato <- 1.87
  rate.stimato <- 0.28
  N <- 300
  intervallo.seriale <- dgamma(0:N, shape=shape.stimato,rate=rate.stimato) 
  SI <- (intervallo.seriale/sum(intervallo.seriale)) 
  stima <- estimate_R(incid=x, method="non_parametric_si",
                      config = make_config(list(si_distr = SI,
                                                n1=10000, mcmc_control=make_mcmc_control(thin=1,
                                                                                         burnin=1000000))))
  R.medio <- stima$R$`Mean(R)` 
  R.lowerCI <- stima$R$`Quantile.0.025(R)` 
  R.upperCI <- stima$R$`Quantile.0.975(R)` 
  sel.date <- stima$R[, "t_end"]
  date <- x[sel.date,1]
  RT_table <- tibble(date, RT = R.medio,
                     CI_low = R.lowerCI,
                     CI_up = R.upperCI) %>%
    mutate_if(is.numeric, round, 2) 
  return(RT_table)
}

# 1) RT SYMPTOMATIC (from ISS database)
RT_sym <- iss_sym %>% 
  select(dates = DATA_INIZIO_SINTOMI, I = CASI_SINT) %>% # Epiestim requires only two columns named exactly dates and I, i.e. nr of cases/ positives)
  mutate(dates = as.Date(dates, format = "%d/%m/%Y"),
         I = as.numeric(I)) %>% 
  slice(1:(n()-1)) %>% #get rid of last row that is the sum of column
  F_RT() %>% 
  rename(data = dates, RT_sym = RT, CI_low_sym = CI_low,
         CI_up_sym = CI_up)


# 2) RT HOSPITALIZED (from DPC database)
RT_hosp <- dpcNaz  %>%
  rename(I = "totale_ospedalizzati",
         dates = data) %>% # Epiestim requires only two columns named exactly dates and I, i.e. nr of cases/ positives)
  select(c(dates, I)) %>% 
  F_RT() %>% 
  rename(data = date, RT_hosp = RT, CI_low_hosp = CI_low,
         CI_up_hosp = CI_up)


# WEEKLY INCIDENCE OVER 100.000
# NOTE: NOT STANDARDIZED, based only on pure population nr,
# without sex, age and vaccination risk standardization
incid100k7 <- dpcNaz  %>%
  left_join(sup_pop) %>%
  fill(N, .direction="up") %>% 
  select(data, nuovi_positivi, N) %>% 
  fill(N) %>%
  group_by(week = cut(data, "week", start.on.monday = TRUE)) %>% 
  summarise(data = data,
            incid_100k_7ns = round(sum(nuovi_positivi)/N*100000)) %>% 
  mutate(week = lubridate::isoweek(week),
         year = lubridate::isoyear(data)) %>%
  unite("week_nr", c("week", "year"), sep = "_") %>% 
  ungroup()

vax <- openVax  %>% 
  select(c(data, Territorio = reg, tot_vacc = totale,
           d1, d2, dpi, dbi, db2)) %>% 
  mutate(Territorio = ifelse(Territorio == "Friuli-Venezia Giulia" ,
                             "Friuli Venezia Giulia", Territorio),
         Territorio = ifelse(Territorio == "Provincia Autonoma Bolzano / Bozen" ,
                             "P.A. Bolzano", Territorio),
         Territorio = ifelse(Territorio == "Provincia Autonoma Trento" ,
                             "P.A. Trento", Territorio),
         Territorio = ifelse(Territorio == "Valle d'Aosta / Vallée d'Aoste" ,
                             "Valle d'Aosta", Territorio)) %>% 
  filter(Territorio %in% unique(dpcReg$denominazione_regione)) %>% 
  select(data, tot_vacc) %>% 
  group_by(data) %>% 
  summarise(vaccini = sum(tot_vacc))


# COMBINING ALL IN THE FINAL DATAFRAME AND ESTRACTING OTHER NEW FEATURES
nat_df <- dpcNaz %>%
  left_join(vax) %>% 
  left_join(sup_pop) %>% 
  fill(N, .direction="up") %>% 
  left_join(colors_sum) %>%
  left_join(RT_hosp) %>%
  left_join(RT_sym) %>% 
  fill(N, .direction="down") %>% 
  arrange(data) %>%
  mutate(nuovi_deceduti = deceduti - lag(deceduti, default = 0),
         nuovi_tamponi = tamponi - lag(tamponi, default = 0),
         var_ospedalizzati = totale_ospedalizzati - lag(totale_ospedalizzati,
                                                        default =0),
         var_ospedalizzat = as.integer(var_ospedalizzati)) %>% 
  mutate(perc_pos = round(nuovi_positivi/ nuovi_tamponi*100, digits = 2),
         perc_pos = ifelse(perc_pos <0,
                           (perc_pos[42]+perc_pos[44])/2,
                           perc_pos)) %>% # adjustment of a strange outlore
  mutate(col_day = ifelse(data >= "2020-03-09" & data <= "2020-05-04",
                          84, col_day), # first global lockdown in Italy corresponding about at the red zone
         col_day = ifelse(data >= "2020-05-05" & data <= "2020-11-04",
                          21, col_day),
         col_day = ifelse(data <= "2020-03-08",
                          0, col_day),
         col_day = as.integer(col_day)) %>% 
  left_join(incid100k7) %>% 
  select(date = data, week = week_nr, colors = col_day, new_pos = nuovi_positivi,
         tot_case = totale_casi, tot_hosp = totale_ospedalizzati, perc_pos,
         RT_sym, RT_hosp, var_hosp = var_ospedalizzati, new_dies = nuovi_deceduti,
         tot_dies =deceduti, new_tests = nuovi_tamponi, tot_tests = tamponi,
         vax = vaccini, CI_low_sym, CI_up_sym, CI_low_hosp, CI_up_hosp, incid_100k_7ns)

remove("ITTER107", "pop_mese", "sup_pop", "superfici",
       "col_ord", "colors_sum", "dataURL", "dpcNaz", "dpcReg",
       "F_RT", "incid100k7", "iss_sym", "openVax", "RT_hosp",
       "RT_sym", "temp", "vax")

# ============= SAVE  ========================

# # select only period within colors 
# nat_df2 <- nat_df %>% 
#   filter(date >= "2020-11-05" & date <= "2022-03-31")

write.csv(nat_df, "Covid_Italy_ETL.csv", row.names = FALSE,
          quote = FALSE)
