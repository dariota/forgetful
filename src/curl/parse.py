import csv
import os


def parse_time(time_str):
    parts = time_str.split("m")
    parts[1] = parts[1][:-1]
    return float(parts[0]) * 60 + float(parts[1])


# taking in some collection of values, leave only 4 or 5 inner values,
# removing outliers depending on whether the source list was even or odd
def dump_outliers(values):
    length = len(values)
    if length < 5:
        return values

    values = sorted(values)
    target_len = 4 + (length % 2)
    to_drop = int((length - target_len) / 2)
    return values[to_drop:(length - to_drop)]


time_types = ["real", "user", "sys"]

writers = {}

for time_type in time_types:
    writers[time_type] = csv.writer(open("{}-times.csv".format(time_type), "w"))
    writers[time_type].writerow(["build", "min", "avg", "max"])

for timing_filename in sorted(os.listdir("timings")):
    contents = open("timings/{}".format(timing_filename)).readlines()
    lines = list(map(str.split, filter((lambda x: x != ""), [line.strip() for line in contents])))

    for time_type in time_types:
        time_strs = filter((lambda x: x[0] == time_type), lines)
        times = dump_outliers(list(map((lambda x: parse_time(x[1])), time_strs)))
        writer = writers[time_type]
        writer.writerow([timing_filename,
                         min(times),
                         sum(times) / len(times),
                         max(times)])
