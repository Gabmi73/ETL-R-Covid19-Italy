## ETL-R-Covid19-Italy

Under construction

The aim of this project is to provide one ETL dataset, from the Italian Covid19 public databases and other sources, containing some most important transformations and new features engeneered.

These variables have the intent - but don't want to be exhaustives - a semi-ready-to-use csv file for all kind of analysis, as Times Series, Statistics, Machine Learing, Deep Learning tecniques.

#### **SOURCES**

- DPC: [ITALY TREND COVID-19 OPENDATA - PROTEZIONE CIVILE](https://github.com/pcm-dpc/COVID-19/blob/master/dati-andamento-covid19-italia.md)

- DPC-V: [ITALY COVID-19 OPENDATA VACCINE](https://github.com/italia/covid19-opendata-vaccini/blob/master/README.md)

- ISS: [Italian Istituto Superiore Sanità OPENDATA](https://www.epicentro.iss.it/coronavirus/sars-cov-2-sorveglianza-dati)

- ISTAT: [RESIDENT POPULATION STATISTICS AND AREAS (SDMX flow refs: 22_315 and 729_1050)](http://dati.istat.it/)


#### **FEATURES**
##### **(O)riginal, (T)ransformed, (N)ew**
###### *all daily based*

| Original Name| New Name | O - T - N | Description | Source |
| :----------- | :----------- | :----------- | :------------- | :----------- |
| data | date | O | date yyyy-m-d | == |
| == | week | T | week_number_yyyy | == |
| == | colors | N | for each day, sum of color number (see introduction) | GU |
| nuovi_positivi | new_pos | O | Total amount of current positive cases (Hospitalised patients + Home confinement) | DPC |
| == | perc_pos | T | Percentage of new positives (new_pos/new_buffers*100) | DPC |
| == | RT_sym | T | RT based on symptomatics | ISS |
| == | RT_hosp | T | RT based on hospitaized | DPC |
| == | new_hosp | T | New hospitalized | DPC |
| == | new_die | T | New dies | DPC |
| == | new_buff | T | New buffers | DPC |
| totale | vax | T | Total number of administred dose of vaccines (sum of all regional data)  | DPC-V |
| tamponi | tot_buff | O | All tests performed | DPC |
| totale_casi | tot_case | O | Total amount of positive cases | DPC |
| == | CI_low_sym | T | Confidence Interval Low Bound symptomatic | ISS |
| == | CI_up_sym | T | Confidence Interval High Bound symptomatic | ISS |
| == | CI_low_hosp | T | Confidence Interval Low Bound hospitalized | DPC |
| == | CI_up_hosp | T | Confidence Interval High Bound hospitalized | DPC |
| == | incid_100k_7ns | T | Not-standarized 1 week incidence on 100.000 (See introduction) | DPC, ISTAT |


