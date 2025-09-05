import matplotlib.pyplot as plt
import sys

def main():
    # make sure the FILENAME is passed as an argument
    if len(sys.argv) < 2:
        print("Usage: python plot-stats.py <FILENAME>")
        return
    # set up some constants
    FILENAME = sys.argv[1]
    BASENAME = FILENAME.split('.')[0]
    if 'i' in FILENAME:
        MODE = "X"
    else:
        MODE = "Y"
    THREADS = [1, 2, 4, 6, 8]
    TESTS = len(THREADS)
    SIZES = [64, 1024, 4096]
    BOARDS = len(SIZES)

    # read the data
    with open(FILENAME, "r") as f:
        lines = f.readlines()
        lines = [line.strip().split() for line in lines]
        durations = [float(line[-1]) for line in lines if line[0] == "GameOfLife:"]

    # plot the function of time per board size for each thread
    FIGURES = 0
    plt.figure(FIGURES)
    FIGURES = FIGURES + 1
    x_axis = SIZES
    for index, thread in enumerate(THREADS):
        y_axis = durations[index * BOARDS: (index + 1) * BOARDS]
        plt.plot(x_axis, y_axis, label=f"{thread} threads", marker="*")
    plt.grid()
    plt.legend()
    plt.xticks(SIZES)
    plt.xlabel("Board size (N X N)")
    plt.ylabel("Duration (s)")
    plt.title(f"Game of Life - {MODE} Parallelization")
    plt.savefig(f"{BASENAME}-stats.png")

    # plot the speedup (serial time over parallel time) per thread for each board size
    plt.figure(FIGURES)
    FIGURES = FIGURES + 1
    base_case = [durations[i::BOARDS] for i in range(BOARDS)]
    for index, base in enumerate(base_case):
        serial = base[0]
        speedup = [serial / parallel for parallel in base]
        plt.plot(THREADS, speedup, label=f"board size {SIZES[index]}", marker="*")
    plt.grid()
    plt.legend()
    plt.xticks(THREADS)
    plt.xlabel("Number of Threads")
    plt.ylabel("Speedup")
    plt.title(f"Game of Life - {MODE} Parallelization")
    plt.savefig(f"{BASENAME}-speedup.png")

if __name__ == "__main__":
    main()
