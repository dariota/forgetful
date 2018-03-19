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


# compare the results to our predictions
def score_results(count, stats):
    def dump_proportion(stat):
        return list(map((lambda x: x[1]), stat))

    def score_deviation(target, results):
        target["deviation"] = {}
        target["deviation"]["max"] = (results[-1][0] - 1) * 100
        target["deviation"]["min"] = (results[1][0] - 1) * 100
        deviations = []
        for i in range(1, len(results)):
            deviations.append(results[i][0] / results[i - 1][0])
        target["deviation"]["avg"] = (sum(deviations) / len(deviations) - 1) * 100

    # external and stack should have no overhead and always be fastest
    # when dynamic chooses to use the stack, it should be faster than malloc
    def score_with_stack_use(target, results):
        score_deviation(target, results)
        results = dump_proportion(results)
        if results == ["EXTERNAL", "STACK", "DYNAMIC", "MALLOC"]:
            target["score"] = 2
        elif results[3] == "MALLOC":
            target["score"] = 1
        elif results[2:] == ["MALLOC", "DYNAMIC"]:
            target["score"] = 0.5
        else:
            target["score"] = 0

    # when dynamic chooses not to use the stack, it should perform the same as
    # or worse than malloc
    def score_without_stack_use(target, results):
        score_deviation(target, results)
        results = dump_proportion(results)
        if results == ["EXTERNAL", "STACK", "MALLOC", "DYNAMIC"]:
            target["score"] = 2
        elif results[3] == "DYNAMIC":
            target["score"] = 1
        elif results[2:] == ["DYNAMIC", "MALLOC"]:
            target["score"] = 0.5
        else:
            target["score"] = 0

    # if there are 64 or less items (512 bytes), the dynamic method will use
    # the stack
    count = int(count)
    results = {"size": count, "min": {}, "avg": {}, "max": {}}
    target_func = None
    if count <= 64:
        target_func = score_with_stack_use
    else:
        target_func = score_without_stack_use

    target_func(results["min"], stats["mins"])
    target_func(results["avg"], stats["avgs"])
    target_func(results["max"], stats["maxs"])

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

# produce sorted lists indicating the relative performance of each method
# the first item in each list was the fastest and so forth
for olevel in computed:
    for i_count in computed[olevel]:
        for category in computed[olevel][i_count]:
            results = sorted(computed[olevel][i_count][category])
            computed[olevel][i_count][category] = list(map((lambda x: [x[0]/results[0][0], x[1]]), results))

# score everything using our scoring function above
scored = {}
for olevel in computed:
    scored[olevel] = []
    for item_count in computed[olevel]:
        scored[olevel].append(score_results(item_count, computed[olevel][item_count]))

print({"scored": scored, "computed": computed})
