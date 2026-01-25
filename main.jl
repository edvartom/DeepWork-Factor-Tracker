using Dates, Plots, Plots.Measures

function read_data()
    dates::Vector{Date} = []
    fell_asleep::Vector{Float64} = []
    woke_up::Vector{Time} = []
    sleep_quality::Vector{Int} = []
    time_awake::Vector{Time} = []
    session_start_vec::Vector{Vector{Time}} = []
    session_end_vec::Vector{Vector{Time}} = []
    meal_before_vec::Vector{Vector{Time}} = []
    activity_vec::Vector{Vector{String}} = []
    interest_level_vec::Vector{Vector{Int}} = []
    for line::String in eachline("tom_session_data.txt")
        line_vec = split(line, ";")
        # Adjusting fell_asleep to count more than 24 hours
        fell_asleep_00::Float64 = Dates.value(Time(String(line_vec[2]), "HH:MM"))/3600e9
        fell_asleep_24::Float64 = fell_asleep_00 < 3 ? fell_asleep_00 + 24 : fell_asleep_00
        push!(dates, Date(String(line_vec[1]), "dd.mm.yyyy"))
        push!(fell_asleep, fell_asleep_24)
        push!(woke_up, Time(String(line_vec[3]), "HH:MM"))
        push!(sleep_quality, parse(Int, String(line_vec[4])))
        push!(time_awake, Time(String(line_vec[5]), "HH:MM"))
        session_start::Vector{Time} = Time.(String.(split(line_vec[6], ", ")), "HH:MM")
        session_end::Vector{Time} = Time.(String.(split(line_vec[7], ", ")), "HH:MM")
        meal_before::Vector{Time} = Time.(String.(split(line_vec[8], ", ")), "HH:MM")
        activity::Vector{String} = String.(split(line_vec[9], ", "))
        interest_level::Vector{Int} = parse.(Int, String.(split(line_vec[10], ", ")))
        push!(session_start_vec, session_start)
        push!(session_end_vec, session_end)
        push!(meal_before_vec, meal_before)
        push!(activity_vec, activity)
        push!(interest_level_vec, interest_level)
    end
    return (
           dates, fell_asleep, woke_up, sleep_quality, time_awake,
           session_start_vec, session_end_vec, meal_before_vec,
           activity_vec, interest_level_vec
           )
end

function find_nr_of_sessions(session_start::Vector{Vector{Time}}, session_end::Vector{Vector{Time}})
    nr_of_sessions::Array{Int} = []
    for i::Int in eachindex(session_start)
        session_length::Vector{Nanosecond} = session_end[i] - session_start[i]
        if session_length != [Nanosecond(0)]
            push!(nr_of_sessions, length(session_length))
        else
            push!(nr_of_sessions, 0)
        end
    end
    return nr_of_sessions
end

function find_total_session_lengths(session_lengths)
    total_session_lengts::Vector{Time} = []
    for vec::Vector{Nanosecond} in session_lengths
        push!(total_session_lengts, Time(sum(vec)))
    end
    return total_session_lengts
end

function remove_zeros(vec)
    new_vec = []
    if typeof(vec) == Vector{Time}
        new_vec = vec[vec .!= Time(0,0,0)]
    elseif typeof(vec) == Vector{String}
        new_vec = vec[vec .!= ""]
    elseif typeof(vec) == Vector{Int}
        new_vec = vec[vec .!= 0]
    end
    return new_vec
end

INPUT = read_data()
(DATES, FELL_ASLEEP, WOKE_UP, SLEEP_QUALITY, TIME_AWAKE,
 SESSION_START, SESSION_END, MEAL_BEFORE,
 ACTIVITY, INTEREST_LEVEL
) = INPUT

Base.@kwdef struct PlotAxis
    title::String = ""
    data::Vector{Any} = []
    ticks::Any = :auto
    rotation::Int = 0
    label::String = ""
    description::String = ""
end

############ Alternative structs ####################
################ Length 97 ##########################
dates::PlotAxis = PlotAxis(
    title = "Dates",
    data = DATES,
    ticks = (DATES[1:10:end], Dates.format.(DATES[1:10:end], "dd.mm.yyyy")),
    rotation = 45,
    label = "Date",
    description = "Date"
)

fell_asleep::PlotAxis = PlotAxis(
    title = "Fell asleep",
    data = FELL_ASLEEP,
    label = "When Tom fell asleep the night\nbefore the deep work session",
    description = "When Tom fell asleep the night before the deep work session"
)

woke_up::PlotAxis = PlotAxis(
    title = "Woke up",
    data = WOKE_UP,
    label = "When Tom woke up the morning\nbefore the deep work session",
    description = "When Tom woke up the morning before the deep work session"
)

time_awake::PlotAxis = PlotAxis(
    title = "Time awake",
    data = TIME_AWAKE,
    label = "Total time Tom was awake during the night",
    description = "Total time Tom was awake during the night"
)

hours_of_sleep::PlotAxis = PlotAxis(
    title = "Hours of sleep",
    data = Dates.value.(WOKE_UP)/3600e9 + fill(24, length(WOKE_UP)) - FELL_ASLEEP - Dates.value.(TIME_AWAKE)/3600e9,
    label = "Hours of sleep Tom got during the\nnight before the deep work session",
    description = "Hours of sleep Tom got during the night before the deep work session"
)

sleep_quality::PlotAxis = PlotAxis(
    title = "Sleep quality",
    data = SLEEP_QUALITY,
    label = "Sleep quality of the night\n before the deep work session\n(1 is worst, 10 is best)",
    description = "Sleep quality of the night before the deep work session"
)

nr_of_sessions::PlotAxis = PlotAxis(
    title = "Number of sessions",
    data = find_nr_of_sessions(SESSION_START, SESSION_END),
    label = "How many deep work sessions\nTom had each day",
    description = "How many deep work sessions Tom had each day"
)

tot_duration_sessions::PlotAxis = PlotAxis(
    title = "Total session duration",
    data = find_total_session_lengths(SESSION_START - SESSION_END),
    label = "Total duration of deep work sessions\nduring the day",
    description = "Total duration of deep work sessions during the day"
)

############ Alternative structs ####################
################ Length 39 ##########################
session_start::PlotAxis = PlotAxis(
    title = "Session start",
    data = remove_zeros(vcat(SESSION_START...)),
    label = "Start time of each deep work session",
    description = "Start time of each deep work session"
)

session_end::PlotAxis = PlotAxis(
    title = "Session end",
    data = remove_zeros(vcat(SESSION_END...)),
    label = "End time of each deep work session",
    description = "End time of each deep work session"
)

duration_sessions::PlotAxis = PlotAxis(
    title = "Duration of sessions",
    data = Time.(session_end.data - session_start.data),
    label = "Duration of each deep work session",
    description = "Duration of each deep work session"
)

meal_before::PlotAxis = PlotAxis(
    title = "Mealtime before", 
    data = remove_zeros(vcat(MEAL_BEFORE...)),
    label = "Time of the last meal\nbefore a deep work session",
    description = "Time of the last meal before a deep work session"
)

time_since_meal::PlotAxis = PlotAxis(
    title = "Time since meal",
    data = remove_zeros(Time.(vcat((SESSION_START - MEAL_BEFORE)...))),
    label = "Time from the last meal\nto the beginning of\nthe deep work session",
    description = "Time from the last meal to the beginning of the deep work session"
)

activity::PlotAxis = PlotAxis(
    title = "Activity",
    data = remove_zeros(vcat(ACTIVITY...)),
    ticks = :all,
    rotation = 45,
    label = "What Tom was doing while\nconcentrating deeply",
    description = "What Tom was doing while concentrating deeply"
)

interest_level::PlotAxis = PlotAxis(
    title = "Level of interest",
    data = remove_zeros(vcat(INTEREST_LEVEL...)),
    label = "How interested Tom was in what\nhe concentrated on from 1 to 10",
    description = "How interested Tom was in what he concentrated on from 1 to 10",
)
#################### Data_vector ####################
DATA_VEC::Vector{PlotAxis} = [
    dates, fell_asleep, woke_up, time_awake, hours_of_sleep, sleep_quality,
    nr_of_sessions, tot_duration_sessions, session_start, session_end, 
    duration_sessions, meal_before, time_since_meal, activity, interest_level
]
#####################################################

function plot_axes(x::PlotAxis, y::PlotAxis)
    if length(x.data) != length(y.data)
        error("error: You chose axes of different length.
The length of the the x- and the y-array are $(length(x.data)) and $(length(y.data)).
Please try again, and remember to read the instructions carefully.")
    end
    p = scatter(x.data, y.data;
        title = x.title * " vs. " * lowercase(y.title),
        titlefontsize = 12,
        xticks = x.ticks,
        xrotation = x.rotation,
        xlabel = x.label,
        xguidefontsize = 8,
        yticks = y.ticks,
        ylabel = y.label,
        yguidefontsize = 8,
        legend = false,
        marker = 2,
        bottom_margin = 10mm,
        top_margin = 10mm,
        left_margin = 10mm,
    )
    return p
end

function ask(x::PlotAxis)
    if length(x.data) == 0
        println("What do you want on the x-axis?
Choose a number:")
        for i in eachindex(DATA_VEC)
            println(i, " ", DATA_VEC[i].description)
        end
    elseif !(length(x.data) in length.(getproperty.(DATA_VEC, :data)))
        error("error: Error in the program itself. The array has a length that cannot be plotted (length: ", length(x.data), ")")
    else
        println("What do you want on the y-axis?
Choose a number:")
        for i in eachindex(DATA_VEC)
            if length(DATA_VEC[i].data) == length(x.data)
                println(i, " ", DATA_VEC[i].description)
            end
        end
    end
    println("DUE TO AN ERROR IN VSCODE, YOU MIGHT HAVE TO WRITE YOUR ANSWER TWO TIMES.
PRESS ENTER AT THE END EACH TIME.")
    answer::PlotAxis = DATA_VEC[parse(Int, readline())]
    return answer
end

function ask_and_plot()
    old_x_axis::PlotAxis = PlotAxis()
    x_axis::PlotAxis = ask(old_x_axis)
    y_axis::PlotAxis = ask(x_axis)
    p = plot_axes(x_axis, y_axis)
    savefig(p, "plot.pdf")
    return p
end

ask_and_plot()