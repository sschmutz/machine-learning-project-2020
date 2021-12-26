# Machine Learning Project - 2020
>solving a practical machine learning problem for the BECS2 module

## Tasks and deadlines
- [x] Team choice: 13 November 2020
- [x] Dataset choice: 25 November 2020
- [x] Presentation: 16 December 2020
- [x] Written report and `MATLAB` code: before 18 January 2021

## Evaluation criteria
- Motivation and problem understanding  
- Technical soundness and choice of methods  
- Discussion and conclusions  
- Quality of the presentation  
- Quality of the report (up to two pages)  
- Code  
  - self contained  
  - reproduces presented results  
  - code skills will NOT be taken into account, as long as it works!  

## Chosen Dataset
News headlines (title and teaser) from two online news sites [20min.ch](https://www.20min.ch/) and [nzz.ch](https://www.nzz.ch/).  

### Data collection
All titles and teasers (if available) from the titlepage were collected twice a day (6am and 6pm local time) between 2019-02-04 and 2020-01-21.  

*Unique titles:*  
20min n=27'874  
nzz n=26'656

*Unique teasers:*  
20min n=27'295  
nzz n=5'484

### Format
[, 1]	date_time (POSIXct)  
[, 2]	object ("title" or "teaser")  
[, 3]	order (order headline appeared, makes it possible to link title and teaser)  
[, 4]	text (full text, all in lowercase and punctuation marks removed)

### Objective
Can we predict the source of a title or teaser based on the chosen words?  
We might want to try title or teaser separately, or a combination and compare the performances.

### Heads up
Some headlines might be advertisement. We could detect those by looking at how often they were visible. We'd expect advertisement to appear more frequently compared to actual news headlines.  

For the 20min dataset we have a teaser for almost every title, this is not the case for the nzz dataset where very often we only have a title without teaser.


## Chosen Estimator
Following the flow diagram below, we might want to try Naive Bayes or also additionally a Linear Support Vector Classification.  

![Choosing the right ML estimator - Cheatsheet](https://scikit-learn.org/stable/_static/ml_map.png)
