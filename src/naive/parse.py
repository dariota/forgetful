import csv

# taking in some collection of values, leave only 4 or 5 inner values,
# removing outliers depending on whether the source list was even or odd
def dump_outliers(values):
    length = len(values)
    if length < 5:
        return values

    target_len = 4 + (length % 2)
    to_drop = int((length - target_len) / 2)
    return values[to_drop:(length - to_drop)]


# parse a csv into the following dict
# { "alloc_type": # Dynamic, stack, etc
#   { "item_count": # 1, 8, 16, etc
#     [ <times> ]
#   }
# }
def process_csv(csv):
    results = {}
    for row in csvs[olevel]:
        memtype = row[0]
        size = row[1]
        time = float(row[2][:-1])

        if memtype not in results:
            results[memtype] = {}

        if size not in results[memtype]:
            results[memtype][size] = []

        results[memtype][size].append(time)
    return results


csvs = {}

# read in the 4 different results files for the various optimisation levels
for i in range(0, 4):
    csvs["O{}".format(i)] = csv.reader(open("resultsO{}.csv".format(i)))

results = {}

# parse out all the CSVs into one dict
for olevel in csvs:
    results[olevel] = process_csv(csvs[olevel])

computed = {}

# transform the preceding dict into
# { "olevel":
#   { "item_count":
#     {
#       "avgs": [ (<time>, "alloc_type"), ... ],
#       "mins": [ (<time>, "alloc_type"), ... ],
#       "maxs": [ (<time>, "alloc_type"), ... ]
#     }
#   }
# }
# however, when calculating the avgs/mins/maxs, dump the outliers first
for olevel in results:
    computed[olevel] = {}
    for memtype in results[olevel]:
        for i_count in results[olevel][memtype]:
            i_stats = None
            if i_count not in computed[olevel]:
                i_stats = {
                    "mins": [],
                    "avgs": [],
                    "maxs": []
                }
                computed[olevel][i_count] = i_stats
            else:
                i_stats = computed[olevel][i_count]

            current = dump_outliers(sorted(results[olevel][memtype][i_count]))
            i_stats["avgs"].append((sum(current) / len(current), memtype))
            i_stats["maxs"].append((max(current), memtype))
            i_stats["mins"].append((min(current), memtype))


for olevel in computed:
    writer = csv.writer(open("processed{}.csv".format(olevel), "w"))
    writer.writerow(["Items", "External Min", "Stack Min", "Dynamic Min", "External Avg", "Stack Avg", "Dynamic Avg", "External Max", "Stack Max", "Dynamic Max"])

    for i_count in computed[olevel]:
        row = [i_count]
        for category in ["mins", "avgs", "maxs"]:
            external = None
            stack = None
            dynamic = None
            malloc = None

            for time_tuple in computed[olevel][i_count][category]:
                if time_tuple[1] == "EXTERNAL":
                    external = time_tuple[0]
                if time_tuple[1] == "STACK":
                    stack = time_tuple[0]
                if time_tuple[1] == "DYNAMIC":
                    dynamic = time_tuple[0]
                if time_tuple[1] == "MALLOC":
                    malloc = time_tuple[0]

            row.append(external / malloc)
            row.append(stack / malloc)
            row.append(dynamic / malloc)
        writer.writerow(row)
