# Matthew Holman        5-12-2020
# Agent Communication
#
# Final Metrics Plotter

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Labels
xLabel = "Relative Rankings"
yLabel = "Averages for All Tests"
saveTitle = "Final_Metrics-Mean_Time"
graphTitle = "Mean Time"

# Read in data
data_csv = pd.read_csv("Mean_Time_Comparison.csv", index_col="Strategy")
dataT = data_csv.transpose()

# Create subplot
fmfig, fm = plt.subplots() # Random Crystals, Random Start

# Plot data
fm.plot(dataT["Communication"], color="blue", marker="o", label="Communication")
fm.plot(dataT["Non-Communication"], color="green", marker="*", label="Non-Communication")
fm.plot(dataT["Brute Force Detecting"], color="orange", marker="+", label="Brute Force Detecting")
fm.plot(dataT["Brute Force Non-Detecting"], color="red", marker="x", label="Brute Force Non-Detecting")

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
fm.set_xlabel(xLabel)
fm.set_ylabel(yLabel)

# Show the graph
#plt.show()

# Save the graph
fmfig.savefig(saveTitle + ".png")