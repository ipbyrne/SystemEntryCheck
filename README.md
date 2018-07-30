# SystemEntryCheck
A template used to test entry signals of different technical indicators using a White's Reality Check to see how the p-value changes over time. The main idea being you can monitor the systems WRC p-value in real time so you can stop trading the system as soon as the value drifts above the alpha of your choice, typically 0.05 or 5%.

This tests both the original signal, and the reverse of that signal, and plots the values in an indicator on MT4 and also prints out a CSV file that can be used to analyze the data in Python or Excel.

The entry used in this file is a very bastic MA entry that has a p-value that remains steady for sometime on the EURGBP pair using a 5 minute chart. This uses a fixed take profit of 25 pips and fixed SL of 50 pips.

Below is an image of the data:
O = Original Signal | R = Reverse of the Original Signal
