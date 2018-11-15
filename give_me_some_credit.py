#!/usr/bin/env python
# coding: utf-8

# # Decouverte et Description des donnees

# In[1]:


import matplotlib.pyplot as plt
get_ipython().run_line_magic('matplotlib', 'inline')
import numpy as np
import pandas as pd
import statsmodels.api as sm
from statsmodels.nonparametric.kde import KDEUnivariate
from statsmodels.nonparametric import smoothers_lowess
from pandas import Series, DataFrame
from patsy import dmatrices
from sklearn import datasets, svm


# In[2]:


raw_data = pd.read_csv("./raw/cs-training.csv")


# On analyse rapidement les variables qui sont mise a notre disposition: 

# In[3]:


raw_data


# In[4]:


print(raw_data.describe())


# **SeriousDlqin2yrs** = defaut de paiement d'un client, c'est notre variable a predire.
# 
# **RevolvingUtilizationOfUnsecuredLines** = % de crédit utilise (toutes cartes de credit confondues hors biens immobiliers)
# 
# **age** = age du client
# 
# **DebtRatio** = Taux de depenses par rapport aux revenus
# 
# **MonthlyIncome** = Revenu mensuel
# 
# **NumberOfOpenCreditLinesAndLoans** = Nombre de ligne de credit ouvertes
# 
# **NumberRealEstateLoansOrLines** = Nombre de credit immobilier ou hypotheques
# 
# **NumberOfDependents** = Nombre de personnes a charge
# 
# **NumberOfTime30-59DaysPastDueNotWorse** = Nombre de fois que l'emprunteur a ete en souffrance de paiement de 30 a 59 jours dans les 2 dernieres annees.
# 
# **NumberOfTime60-89DaysPastDueNotWorse** = Nombre de fois que l'emprunteur a ete en souffrance de paiement de 60 a 89 jours dans les 2 dernieres annees.
# 
# **NumberOfTimes90DaysLate** = Nombre de fois que l'emprunteur a ete en souffrance de paiement de paiement de 90 jours ou plus
# 
# 

# In[ ]:


fig = plt.figure(figsize=(18,6), dpi=1600)
alpha=alpha_scatterplot = 0.2
alpha_bar_chart = 0.55

ax1 = plt.subplot2grid((2,3),(0,0))
raw_data.SeriousDlqin2yrs.value_counts().plot(kind='bar', alpha=alpha_bar_chart)
ax1.set_xlim(-1, 2)
plt.title("Distribution de SeriousDlqin2yrs, (1 = SeriousDlqin2yrs)")


plt.subplot2grid((2,3),(0,1))
plt.scatter(raw_data.SeriousDlqin2yrs, raw_data.age, alpha=alpha_scatterplot)
plt.ylabel("Age")
plt.grid(b=True, which='major', axis='y')
plt.title("SeriousDlqin2yrs par Age,  (1 = SeriousDlqin2yrs)")

#ax3 = plt.subplot2grid((2,3),(0,2))
#plt.boxplot(raw_data.age)


# In[ ]:




