import os
import re
import matplotlib.pyplot as plt

def parse_kmeans(file):
    # open file and read only
    # the lines that start with
    # <whitespace> nloops
    with open(file, 'r') as f:
        lines = f.readlines()
        lines = [line.strip() for line in lines]
        lines = [line for line in lines if line.startswith('nloops')]
        # now we have a list of lines that look like this
        # nloops = 10  (total = 8.7326s) (per loop = 0.8733s)
        numbers_in_parentheses = [re.findall('\((.*?)\)', line) for line in lines]

        # Extract the numbers from the strings
        total_time    = [float(re.findall('\d+.\d+', nums[0])[0]) for nums in numbers_in_parentheses]
        per_loop_time = [float(re.findall('\d+.\d+', nums[1])[0]) for nums in numbers_in_parentheses]

        sequential          = (total_time[0], per_loop_time[0])
        naive_aff_off       = (total_time[1::5], per_loop_time[1::5])        
        naive_aff_on        = (total_time[2::5], per_loop_time[2::5])
        reduction           = (total_time[3::5], per_loop_time[3::5])
        reduction_first_on  = (total_time[4::5], per_loop_time[4::5])
        reduction_first_off = (total_time[5::5], per_loop_time[5::5])


        return (
            sequential,
            naive_aff_off,
            naive_aff_on,
            reduction,
            reduction_first_on,
            reduction_first_off
        )
    
def parse_fw(file):
    with open(file, 'r') as f:
        lines = f.readlines()
        lines = [line.strip() for line in lines]
        fw_sr = [line for line in lines if line.startswith('FW_SR')]
        fw_seq = [line for line in lines if line.startswith('FW') and not line.startswith('FW_SR')]

        fw_sr = [line.split(',') for line in fw_sr]
        fw_seq = [line.split(',') for line in fw_seq]

        fw_sr_times  = [float(elements[-1]) for elements in fw_sr]
        fw_seq_times = [float(elements[-1]) for elements in fw_seq]

        fw_sr_1024  = fw_sr_times[0::3]
        fw_sr_2048  = fw_sr_times[1::3]
        fw_sr_4096  = fw_sr_times[2::3]
        fw_sr_times = [fw_sr_1024, fw_sr_2048, fw_sr_4096]

        return (fw_sr_times, fw_seq_times)

def parse_tiled(file):
    with open(file, 'r') as f:
        lines = f.readlines()
        lines = [line.strip() for line in lines]
        fw_sr = [line for line in lines if line.startswith('FW_TILED')]

        fw_sr = [line.split(',') for line in fw_sr]
        fw_sr_times  = [float(elements[-1]) for elements in fw_sr]

        fw_sr_1024  = fw_sr_times[0::3]
        fw_sr_2048  = fw_sr_times[1::3]
        fw_sr_4096  = fw_sr_times[2::3]
        fw_sr_times = [fw_sr_1024, fw_sr_2048, fw_sr_4096]

        return (fw_sr_times, fw_seq_times)

    
if __name__ == "__main__":
    (
        seq,
        n_aff_off,
        n_aff_on,
        red,
        red_f_on,
        red_f_off
        
    ) = parse_kmeans("run_kmeans.out")
    
    (
        fw_sr_time,
        fw_seq_times

    ) = parse_fw("run_fw.out")

    SEQUENTIAL = [1.3388, 11.4978, 95.6359]

    THREADS    = [1, 2, 4, 8, 16, 32, 64]
    FW_SR_1024 = [1.246, 0.9701, 0.966, 0.9624, 1.0352, 0.9779, 1.0235]
    FW_SR_2048 = [10.1721, 7.486, 7.3971, 7.4234, 7.4408, 7.4125, 7.6797]
    FW_SR_4096 = [78.4274, 59.1636, 59.5069, 59.3304, 59.6939, 59.7067, 60.8575]

    (
        fw_sr_time,
        fw_seq_times

    ) = parse_tiled("run_tiled.out")
    print(fw_sr_time)

    
