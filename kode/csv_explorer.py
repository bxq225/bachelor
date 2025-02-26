import csv
import numpy as np
import pandas as pd

with open('C:/Users/marti/Documents/Bachelor/xavier_files/stata_scripts/replication_stata/final_data/Yr_UCC_IncDecileThenAgeDecile_AdjbyIncQuintile.csv', newline='') as csvfile:
    reader = csv.reader(csvfile)
    header = next(reader)  # Skip the header row
    year = []
    counter = 0
    for row in reader:
        print(counter)
        counter += 1
        year.append(row[0])

    year_array = np.array([])

    for i in year:
        if i == 0:
            year_array = np.array(year[i])
        elif i == year[year.index(i) - 1]:
            year_array = np.append(year_array, i)
    print(year_array)