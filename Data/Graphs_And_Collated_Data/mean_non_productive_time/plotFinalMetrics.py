# Matthew Holman        5-12-2020
# Agent Communication
#
# Final Metrics Plotter

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Labels
xLabel = "Relative Rankings"
yLabel = "Averaged #'s of Rankings Over All Tests"
saveTitle = "Final_Metrics-Mean_Non_Productive_Time"
graphTitle = "Mean Non-Productive Time"

# Read in data
data_csv = pd.read_csv("Mean_Non_Productive_Time_Comparison.csv", index_col="Strategy")
dataT = data_csv.transpose()

# Create subplot
fmfig, fm = plt.subplots() # Random Crystals, Random Start

# Plot data
index = np.arange(4)
bar_width = 0.15
fm.bar(index, dataT["Communication"], bar_width, color="blue", label="Communication")
fm.bar(index+bar_width, dataT["Non-Communication"], bar_width, color="green", label="Non-Communication")
fm.bar(index+bar_width*2, dataT["Brute Force Detecting"], bar_width, color="orange", label="Brute Force Detecting")
fm.bar(index+bar_width*3, dataT["Brute Force Non-Detecting"], bar_width, color="red", label="Brute Force Non-Detecting")

# Change plot size
box = fm.get_position()
fm.set_position([box.x0, box.y0 + box.height * 0.2, box.width, box.height * 0.8])
plt.ylim([0, 11])
plt.yticks(np.arange(0, 12, step=1))

# Place the legend
fm.legend(loc='upper center', bbox_to_anchor=(0.5, -0.18), fancybox=True, shadow=True, ncol=2)

# Set the title
fm.set_title(graphTitle)

# Set the axis labels
fm.set_xticks(index + bar_width + bar_width / 2)
fm.set_xticklabels(["# Best", "# 2nd", "# 3rd", "# Worst"])
fm.set_xlabel(xLabel)
fm.set_ylabel(yLabel)

# Show the graph
#plt.show()

# Save the graph
fmfig.savefig(saveTitle + ".png")