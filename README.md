## ETL-R-Covid19-Italy
*under construction/ review*

The aim of this project is twice: 

1. to provide a dataset with the colors of all the days, for each Italian region, due to the Italian Government "zoning by four colors according to the C19 parameters severity indices" by decree of the DPCM dtd 06/nov/2020 and subsequent ordinances. The period starts form 06/Nov/2020 until 31/Mar/2022. The colors, increasing from the lowest to the highest impact, are: 1) white, 2) yellow, 3) orange, 4) red.

2. to provide an ETL pipline and one simple and short dataset, derived from the Italian Covid19 opendata and other sources during the quite exact two years of pandemic. IT gathers some most important features, either new, such as the colors, or transformed, starting from 09/Mar/2020 to 31/Mar/22.
These variables serve, in the intentions - but absolutely not exhaustives, to get a semi-ready-to-use csv file for all kind of analysis, as Times Series, Statistics, Machine Learing, Deep Learning tecniques.


#### **METHODOLOGICAL NOTES**

- Unfortunately not all data have been publicly provided, important elements such as age ranges, sex both on covid trend and vaccine somministration are not available. Therefore, e.g., I have calculated the Incidence on 100k only on pure numbers of total population. It is basicly less precise and it looses al lot of information, but can almost give an overall view of the incidence.

- The result dataframe is aggregated on national data, not by each region. However, the scripts contain also regional extractions and transformations can be easily made.

- #####  **Colors** feature

  I've scraped the GU source extracting three variables: date, number of ordinances and related regions, plus added one: the colors,  has been created manually as it is impossible to automatically detect the colors form the text and associate it to each region, even if by deeper scraping into the full contents and attachments of each ordinance.

  Furthermore, the structure itself of the page of the ordinances is not always coherent, therefore some additional handwork has been made in the 00_GET_Colors.R code and, presumably, will be done for future records.

  Don't worry! You will not must tediously apply as the full completed *colors.csv* file is  available.

  In the aggregated dataframe the colors have been aggregated only by sum, so one can decide whether to use it as row data, or transform/ standardize it, both on categorical and numerical sense as desired.


#### **SOURCES**

- DPC: [ITALY TREND COVID-19 OPENDATA - PROTEZIONE CIVILE](https://github.com/pcm-dpc/COVID-19/blob/master/dati-andamento-covid19-italia.md)

- DPC-V: [ITALY COVID-19 OPENDATA VACCINE](https://github.com/italia/covid19-opendata-vaccini/blob/master/README.md)

- ISS: [Italian Istituto Superiore Sanità OPENDATA](https://www.epicentro.iss.it/coronavirus/sars-cov-2-sorveglianza-dati)

- ISTAT: [ITALIAN RESIDENT POPULATION STATISTICS AND AREAS (SDMX flow refs: 22_315 and 729_1050)](http://dati.istat.it/)

- GU: [ITALIAN GAZZETTA UFFICIALE: Collection of documents containing urgent measures regarding the containment and management of the epidemiological emergency from COVID-19 - Collection of documents issued by the Ministry of Health](https://www.gazzettaufficiale.it/attiAssociati/1?areaNode=17)


#### **FEATURES**
##### **(O)riginal, (T)ransformed, (N)ew**
###### *all daily based*

| Original Name| New Name | O/T/N | Description | Source | Type |
| :----------- | :----------- | :----------- | :------------- | :----------- | :----------- |
| data | date | O | date yyyy-m-d | == | date |
| == | week | T | week_number_yyyy | == | chr |
| == | colors | N | for each day, sum of color number (see methodological notes) | GU | int |
| nuovi_positivi | new_pos | O | Total amount of current positive cases (Hospitalised patients + Home confinement) | DPC | int |
| == | tot_hosp | O | Total of hospitalized (recovered + intensive) | DPC | int |
| == | perc_pos | T | Percentage of new positives (new_pos/new_buffers*100) | DPC | dbl |
| == | RT_sym | T | RT based on symptomatics | ISS | dbl |
| == | RT_hosp | T | RT based on hospitaized | DPC | dbl |
| == | var_hosp | T | Variation of hospitalized | DPC | int |
| == | new_die | T | New dies | DPC | int |
| == | new_tests | T | New covid tests | DPC | int |
| totale | vax | T | Total number of administred dose of vaccines (sum of all regional data)  | DPC-V | int |
| tamponi | tot_tests | O | All tests performed | DPC | int |
| totale_casi | tot_case | O | Total amount of positive cases | DPC | int |
| == | CI_low_sym | T | Confidence Interval Low Bound symptomatic | ISS | dbl |
| == | CI_up_sym | T | Confidence Interval High Bound symptomatic | ISS | dbl |
| == | CI_low_hosp | T | Confidence Interval Low Bound hospitalized | DPC | dbl |
| == | CI_up_hosp | T | Confidence Interval High Bound hospitalized | DPC | dbl |
| == | incid_100k_7ns | T | Not-standarized 1 week incidence on 100.000 (See methodological notes) | DPC, ISTAT | dbl |
| *==* | *prev* | *T* | *Covid19 Prevalence Index* | *under cosntruction* |

