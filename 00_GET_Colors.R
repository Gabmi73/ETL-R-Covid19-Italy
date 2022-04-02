library(tidyverse)
library(rvest) 

urls <- paste0("https://www.gazzettaufficiale.it/attiAssociati/",
               1:3,
               "?areaNode=17")

get_ord <- function(urls) {
  soup <- read_html(urls)
  data <- soup %>% 
    html_nodes(".riferimento") %>% 
    html_text(trim = T) %>% 
    tibble(data = str_extract_all(., "\\d+-\\d+-\\d+")) %>% 
    unnest(data) %>% 
    mutate(data = as.Date(data, format = "%d-%m-%Y")) %>% 
    select(-c("."))
  
  #ordinances with regions in the text but not referred to colors
  not_col <-"22A01119|22A01121|21A06279|21A04917|21A03740|
            |21A03618|21A03419|21A03151|20A06371|20A01272|
            |20A01273|20A01274|20A01275|20A01276|20A01277"
  
  ordinanze <- soup %>% 
    html_nodes(".risultato a+ a") %>% 
    html_text(trim = T) %>% 
    tibble(nr_ord = str_extract_all(., "\\([:alnum:]{8}+")) %>%
    rename(text = ".") %>% 
    mutate(nr_ord = str_remove_all(nr_ord, "\\(+"),
           text = tolower(text))
    
  regioni <- soup %>% 
    html_nodes(".risultato a+ a") %>% 
    html_text(trim = T) %>%
    tolower() %>% 
    tibble(regioni = str_extract_all(., 
           "abruzzo|basilicata|calabria|campania|emilia|friuli|lazio|
           |liguria|lombardia|marche|molise|piemonte|puglia|sardegna|
           |sicilia|toscana|trento|trentino|umbria|aosta|veneto|bolzano")) %>% 
    rename(text = ".")
  
  
  df <- cbind(data, ordinanze) %>% 
    full_join(regioni, by ="text") %>% 
    unnest_longer(regioni) %>% 
    filter(!is.na(regioni))%>% 
    filter(!str_detect(nr_ord, not_col)) 
} 

# first ordinances were published with a different structure, file "ordinances_integration.csv"
# has been manually created to such integration
integr <- read_csv("ordinances_integration.csv", 
                   col_types = cols(data = col_date(format = "%Y-%m-%d")))

ord <- map_df(urls, get_ord) %>%
  bind_rows(integr) %>% 
  mutate(col = 0) %>% # adding columns for colors
  select(-text) 

# write.csv(ord, "ordinances.csv", row.names = F, quote = F)

