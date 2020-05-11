# Matthew Holman            3-21-2020
#
# Run tests for Godot game

import os
import glob
import re
import numpy
import time
import sys

start_time = 0.0
end_time = 0.0

start_time = time.time()

numTests = 5
startSize = 15
endSize = 25
numAliens = 2
numCrystals = 20
testTime = 60

path = os.getcwd()
outDir = path + r"/../z_OUTPUT"
os.mkdir(outDir)

mean_time_dir = outDir + r"/mean_time"
os.mkdir(mean_time_dir)
stdd_time_dir = outDir + r"/stdd_time"
os.mkdir(stdd_time_dir)
mean_non_productive_time_dir = outDir + r"/mean_non_productive_time"
os.mkdir(mean_non_productive_time_dir)
stdd_non_productive_time_dir = outDir + r"/stdd_non_productive_time"
os.mkdir(stdd_non_productive_time_dir)
mean_crystal_dir = outDir + r"/mean_crystal"
os.mkdir(mean_crystal_dir)
stdd_crystal_dir = outDir + r"/stdd_crystal"
os.mkdir(stdd_crystal_dir)
mean_comm_dir = outDir + r"/mean_comm"
os.mkdir(mean_comm_dir)
stdd_comm_dir = outDir + r"/stdd_comm"
os.mkdir(stdd_comm_dir)

files = []
times = []
time_data = []
non_productive_times = []
non_productive_time_data = []
crystals = []
crystal_data = []
communications = []
communication_data = []

mean_time = 0
stdd_time = 0
mean_non_productive_time = 0
stdd_non_productive_time = 0
mean_crystal = 0
stdd_crystal = 0
mean_comm = 0
stdd_comm = 0

communicating = False
brute_force = False
detecting_crystals = False
obstacles = False
random_dropoff = False
clustering_crystals = False
spacing_crystals = False

experiment_parameters = []
curTest = 1
'''
    "ct_bf_dt_ot_rt_cf_sf", "ct_bf_dt_ot_rf_cf_sf", "ct_bf_dt_ot_rt_ct_sf", "ct_bf_dt_ot_rf_ct_sf", "ct_bf_dt_ot_rt_cf_st", "ct_bf_dt_ot_rf_cf_st",
    "ct_bf_dt_of_rt_cf_sf", "ct_bf_dt_of_rf_cf_sf", "ct_bf_dt_of_rt_ct_sf", "ct_bf_dt_of_rf_ct_sf", "ct_bf_dt_of_rt_cf_st", "ct_bf_dt_of_rf_cf_st",
    "cf_bf_dt_ot_rt_cf_sf", "cf_bf_dt_ot_rf_cf_sf", "cf_bf_dt_ot_rt_ct_sf", "cf_bf_dt_ot_rf_ct_sf", "cf_bf_dt_ot_rt_cf_st", "cf_bf_dt_ot_rf_cf_st",
    "cf_bf_dt_of_rt_cf_sf", "cf_bf_dt_of_rf_cf_sf", "cf_bf_dt_of_rt_ct_sf", "cf_bf_dt_of_rf_ct_sf", "cf_bf_dt_of_rt_cf_st", "cf_bf_dt_of_rf_cf_st",
    "cf_bt_dt_ot_rt_cf_sf", "cf_bt_dt_ot_rf_cf_sf", "cf_bt_dt_ot_rt_ct_sf", "cf_bt_dt_ot_rf_ct_sf", "cf_bt_dt_ot_rt_cf_st", "cf_bt_dt_ot_rf_cf_st",
    "cf_bt_dt_of_rt_cf_sf", "cf_bt_dt_of_rf_cf_sf", "cf_bt_dt_of_rt_ct_sf", "cf_bt_dt_of_rf_ct_sf", "cf_bt_dt_of_rt_cf_st", "cf_bt_dt_of_rf_cf_st",
    "cf_bt_df_ot_rt_cf_sf", "cf_bt_df_ot_rf_cf_sf", "cf_bt_df_ot_rt_ct_sf", "cf_bt_df_ot_rf_ct_sf", "cf_bt_df_ot_rt_cf_st", "cf_bt_dt_ot_rf_cf_st",
    "cf_bt_df_of_rt_cf_sf", "cf_bt_df_of_rf_cf_sf", "cf_bt_df_of_rt_ct_sf", "cf_bt_df_of_rf_ct_sf", "cf_bt_df_of_rt_cf_st", "cf_bt_df_of_rf_cf_st"

    "ct_bf_dt_of_rt_cf_sf", "ct_bf_dt_of_rf_cf_sf", "ct_bf_dt_of_rt_ct_sf", "ct_bf_dt_of_rf_ct_sf", "ct_bf_dt_of_rt_cf_st", "ct_bf_dt_of_rf_cf_st",
    "cf_bf_dt_of_rt_cf_sf", "cf_bf_dt_of_rf_cf_sf", "cf_bf_dt_of_rt_ct_sf", "cf_bf_dt_of_rf_ct_sf", "cf_bf_dt_of_rt_cf_st", "cf_bf_dt_of_rf_cf_st",
    "cf_bt_dt_of_rt_cf_sf", "cf_bt_dt_of_rf_cf_sf", "cf_bt_dt_of_rt_ct_sf", "cf_bt_dt_of_rf_ct_sf", "cf_bt_dt_of_rt_cf_st", "cf_bt_dt_of_rf_cf_st",
    "cf_bt_df_of_rt_cf_sf", "cf_bt_df_of_rf_cf_sf", "cf_bt_df_of_rt_ct_sf", "cf_bt_df_of_rf_ct_sf", "cf_bt_df_of_rt_cf_st", "cf_bt_df_of_rf_cf_st"
'''

# (c) communicating (b) brute force (d) detecting crystals (o) obstacles (r) random dropoff (c) clustering crystals (s) spacing crystals
for t in [
    "ct_bf_dt_of_rt_cf_sf", "ct_bf_dt_of_rf_cf_sf", "ct_bf_dt_of_rt_ct_sf", "ct_bf_dt_of_rf_ct_sf", "ct_bf_dt_of_rt_cf_st", "ct_bf_dt_of_rf_cf_st",
    "cf_bf_dt_of_rt_cf_sf", "cf_bf_dt_of_rf_cf_sf", "cf_bf_dt_of_rt_ct_sf", "cf_bf_dt_of_rf_ct_sf", "cf_bf_dt_of_rt_cf_st", "cf_bf_dt_of_rf_cf_st",
    "cf_bt_dt_of_rt_cf_sf", "cf_bt_dt_of_rf_cf_sf", "cf_bt_dt_of_rt_ct_sf", "cf_bt_dt_of_rf_ct_sf", "cf_bt_dt_of_rt_cf_st", "cf_bt_dt_of_rf_cf_st",
    "cf_bt_df_of_rt_cf_sf", "cf_bt_df_of_rf_cf_sf", "cf_bt_df_of_rt_ct_sf", "cf_bt_df_of_rf_ct_sf", "cf_bt_df_of_rt_cf_st", "cf_bt_df_of_rf_cf_st"
    ]:
    # godot --path . <num rows> <num cols> <num aliens> <num crystals> <communicationg t/f> <brute force t/f>
    print(t + " Tests Starting - This is test: " + str(curTest) + " / 24")
    os.chdir(path)

    experiment_parameters = []
    settings = re.findall(r"\w(\w)_\w(\w)_\w(\w)_\w(\w)_\w(\w)_\w(\w)_\w(\w)", t)
    for sett in settings[0]:
        if sett == "t":
            experiment_parameters.append("true")
        else:
            experiment_parameters.append("false")
    for j in range(startSize, endSize + 1):
        newDir = outDir + r"/z_" + t + "_" + str(j) + "x" + str(j)
        os.mkdir(newDir)
        for i in range(0, numTests):
            os.system("godot --path . " + str(j) + " " + str(j) + " " + str(numAliens) + " " + str(numCrystals) + " " + str(testTime) + " " + 
            experiment_parameters[0] + " " + experiment_parameters[1] + " " + experiment_parameters[2] + " " + experiment_parameters[3] + " " + 
            experiment_parameters[4] + " " + experiment_parameters[5] + " " + experiment_parameters[6] + 
            " > " + str(newDir) + "/data_" + t + "_" + str(j) + "x" + str(j) + "_" + str(i) + ".txt")

            print("godot --path . " + str(j) + " " + str(j) + " " + str(numAliens) + " " + str(numCrystals) + " " + str(testTime) + " " + 
            experiment_parameters[0] + " " + experiment_parameters[1] + " " + experiment_parameters[2] + " " + experiment_parameters[3] + " " + 
            experiment_parameters[4] + " " + experiment_parameters[5] + " " + experiment_parameters[6] + 
            " > " + str(newDir) + "/data_" + t + "_" + str(j) + "x" + str(j) + "_" + str(i) + ".txt")
        
        files = glob.glob(newDir + r"/*.txt")
        for individual_file in files:
            with open(individual_file, "r") as f:
                for line in f:
                    times += re.findall(r"Experiment ended at:\s*(\d*.\d*)\s*seconds", line)
                    non_productive_times += re.findall(r"Total time spent NOT carrying crystals was:\s*(\d*.\d*)\s*seconds", line)
                    crystals += re.findall(r"There were:\s*(\d*)\s*/\s*(\d*)\s*crystals collected", line)
                    communications += re.findall(r"(## COMMUNICATION HAS OCCURRED! ##)", line)
            communication_data.append(len(communications))
            communications.clear()
        for time_value in times:
            time_data.append(float(time_value))
        for non_productive_time_value in non_productive_times:
            non_productive_time_data.append(float(non_productive_time_value))
        for crystal_value in crystals:
            crystal_data.append(float(crystal_value[0]))

        mean_time = str(numpy.mean(time_data))
        stdd_time = str(numpy.std(time_data))
        mean_non_productive_time = str(numpy.mean(non_productive_time_data))
        stdd_non_productive_time = str(numpy.std(non_productive_time_data))
        mean_crystal = str(numpy.mean(crystal_data))
        stdd_crystal = str(numpy.std(crystal_data))
        mean_comm = str(numpy.mean(communication_data))
        stdd_comm = str(numpy.std(communication_data))

        print("Mean time_data               : " + mean_time)
        print("Stdd time_data               : " + stdd_time)
        print("Mean non_productive_time_data: " + mean_non_productive_time)
        print("Stdd non_productive_time_data: " + stdd_non_productive_time)
        print("Mean crystal_data            : " + mean_crystal)
        print("Stdd crystal_data            : " + stdd_crystal)
        print("Mean communication_data      : " + mean_comm)
        print("Stdd communication_data      : " + stdd_comm)

        with open(mean_time_dir + r"/z_" + t + "_mean_time.csv", "a") as f:
            f.write(mean_time + "\n")
        with open(stdd_time_dir + r"/z_" + t + "_stdd_time.csv", "a") as f:
            f.write(stdd_time + "\n")
        with open(mean_non_productive_time_dir + r"/z_" + t + "_mean_non_productive_time.csv", "a") as f:
            f.write(mean_non_productive_time + "\n")
        with open(stdd_non_productive_time_dir + r"/z_" + t + "_stdd_non_productive_time.csv", "a") as f:
            f.write(stdd_non_productive_time + "\n")
        with open(mean_crystal_dir + r"/z_" + t + "_mean_crystal.csv", "a") as f:
            f.write(mean_crystal + "\n")
        with open(stdd_crystal_dir + r"/z_" + t + "_stdd_crystal.csv", "a") as f:
            f.write(stdd_crystal + "\n")
        with open(mean_comm_dir + r"/z_" + t + "_mean_comm.csv", "a") as f:
            f.write(mean_comm + "\n")
        with open(stdd_comm_dir + r"/z_" + t + "_stdd_comm.csv", "a") as f:
            f.write(stdd_comm + "\n")

        files.clear()
        times.clear()
        time_data.clear()
        non_productive_times.clear()
        non_productive_time_data.clear()
        crystals.clear()
        crystal_data.clear()
        communications.clear()
        communication_data.clear()
        mean_time = 0
        stdd_time = 0
        mean_non_productive_time = 0
        stdd_non_productive_time = 0
        mean_crystal = 0
        stdd_crystal = 0
        mean_comm = 0
        stdd_comm = 0
    print(t + " Tests Done...")
    print()

    # Ensure data structures are empty for next run
    files.clear()
    times.clear()
    time_data.clear()
    non_productive_times.clear()
    non_productive_time_data.clear()
    crystals.clear()
    crystal_data.clear()
    communications.clear()
    communication_data.clear()
    mean_time = 0
    stdd_time = 0
    mean_non_productive_time = 0
    stdd_non_productive_time = 0
    mean_crystal = 0
    stdd_crystal = 0
    mean_comm = 0
    stdd_comm = 0
    experiment_parameters.clear()
    curTest += 1

end_time = time.time()
print("Time = " + str(end_time - start_time) + " seconds")