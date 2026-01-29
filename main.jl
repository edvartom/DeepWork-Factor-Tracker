# Include necessary packages
using Dates, Plots, Plots.Measures

#######################################################################################
################################ Functions and structs ################################
#######################################################################################

""" Read data from the file """
function read_data(filepath::String)
    # Making one vector for each column in the file
    dates::Vector{Date} = []
    fell_asleeps::Vector{Float64} = []
    woke_ups::Vector{Time} = []
    sleep_qualities::Vector{Int} = []
    time_awakes::Vector{Time} = []
    session_starts_vec::Vector{Vector{Time}} = []
    session_ends_vec::Vector{Vector{Time}} = []
    meal_befores_vec::Vector{Vector{Time}} = []
    activities_vec::Vector{Vector{String}} = []
    interest_levels_vec::Vector{Vector{Int}} = []
    # Gather all of the lines into a variable
    all_lines::Vector{String} = collect(eachline(filepath))
    # Process each line
    for line::String in all_lines[2:end]
        # Split lines into columns
        line_vec = split(line, ";")
        # Further splitting for the lines containing more than one deep work session
        session_starts::Vector{Time} = Time.(String.(split(line_vec[6], ", ")), "HH:MM")
        session_ends::Vector{Time} = Time.(String.(split(line_vec[7], ", ")), "HH:MM")
        meal_befores::Vector{Time} = Time.(String.(split(line_vec[8], ", ")), "HH:MM")
        activities::Vector{String} = String.(split(line_vec[9], ", "))
        interest_levels::Vector{Int} = parse.(Int, String.(split(line_vec[10], ", ")))
        # Adjusting fell_asleeps to show ex. 25 o'clock instead of 1 o'clock, for better plotting
        fell_asleeps_00::Float64 = Dates.value(Time(String(line_vec[2]), "HH:MM"))/3600e9
        fell_asleeps_24::Float64 = fell_asleeps_00 < 3 ? fell_asleeps_00 + 24 : fell_asleeps_00
        # Converting to the right data-types, and pushing to the column vectors
        push!(dates, Date(String(line_vec[1]), "dd.mm.yyyy"))
        push!(fell_asleeps, fell_asleeps_24)
        push!(woke_ups, Time(String(line_vec[3]), "HH:MM"))
        push!(sleep_qualities, parse(Int, String(line_vec[4])))
        push!(time_awakes, Time(String(line_vec[5]), "HH:MM"))
        push!(session_starts_vec, session_starts)
        push!(session_ends_vec, session_ends)
        push!(meal_befores_vec, meal_befores)
        push!(activities_vec, activities)
        push!(interest_levels_vec, interest_levels)
    end
    # Return column vectors
    return (
           dates, fell_asleeps, woke_ups, sleep_qualities, time_awakes,
           session_starts_vec, session_ends_vec, meal_befores_vec,
           activities_vec, interest_levels_vec
           )
end

""" Find nr of deep work sessions each day, and put them into a list """
function find_nrs_of_sessions(session_starts_vec::Vector{Vector{Time}}, session_ends_vec::Vector{Vector{Time}})
    nrs_of_sessions::Vector{Int} = []
    # For every deep work session ...
    for day_nr::Int in eachindex(session_starts_vec)
        session_lengths::Vector{Nanosecond} = session_ends_vec[day_nr] - session_starts_vec[day_nr]
        # ... if the logged session does not have zero duration
        if session_lengths != [Nanosecond(0)]
            nr_of_sessions_this_day::Int = length(session_lengths) 
            push!(nrs_of_sessions, nr_of_sessions_this_day)
        else
            push!(nrs_of_sessions, 0)
        end
    end
    return nrs_of_sessions
end

""" Find total duration of the deep work sessions each day, and put it into a list """
function find_total_session_durations(session_durations_vec::Vector{Vector{Nanosecond}})
    total_session_durations::Vector{Time} = []
    for session_durations_this_day::Vector{Nanosecond} in session_durations_vec
        tot_session_duration_this_day::Time = Time(sum(session_durations_this_day))
        push!(total_session_durations, tot_session_duration_this_day)
    end
    return total_session_durations
end

""" Remove zeroes or empty strings from a vector of type Vector{Time}, Vector{String} or Vector{Int} """
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

""" Struct defining an axis to be plotted, with default values """
Base.@kwdef struct PlotAxis
    title::String = ""
    data::Vector{Any} = []
    ticks::Any = :auto
    rotation::Int = 0
    label::String = ""
    description::String = ""
end

""" Function making a scatter plot out of two PlotAxis objects """
function plot_axes(x_pla::PlotAxis, y_pla::PlotAxis)
    if length(x_pla.data) != length(y_pla.data)
        error("error: You chose axes of different length.
The length of the the x- and the y-array are $(length(x_pla.data)) and $(length(y_pla.data)).
Please try again, and remember to read the instructions carefully.")
    end
    # Plotting
    p = scatter(x_pla.data, y_pla.data;
        title = x_pla.title * " vs. " * lowercase(y_pla.title),
        titlefontsize = 12,
        xticks = x_pla.ticks,
        xrotation = x_pla.rotation,
        xlabel = x_pla.label,
        xguidefontsize = 8,                 # Fontsize x-label
        yticks = y_pla.ticks,
        ylabel = y_pla.label,
        yguidefontsize = 8,                 # Fontsize y-label
        legend = false,
        marker = 2,                         # Markersize
        # Adjusting margins around the plot
        bottom_margin = 10mm,
        top_margin = 10mm,
        left_margin = 10mm,
    )
    return p
end

""" Function that asks users what they want to plot """
function ask(x_pla::PlotAxis, axes_pla::Vector{PlotAxis})
    # If there is no x-axis already ...
    if length(x_pla.data) == 0
        # ... make the x-axis
        println("What do you want on the x-axis?
Choose a number:")
        for i in eachindex(axes_pla)
            println(i, " ", axes_pla[i].description)
        end
    elseif !(length(x_pla.data) in length.(getproperty.(axes_pla, :data)))
        error("error: Error in the program itself. The array has a length that cannot be plotted (length: ", length(x_pla.data), ")")
    else
        println("What do you want on the y-axis?
Choose a number:")
        for i in eachindex(axes_pla)
            if length(axes_pla[i].data) == length(x_pla.data)
                println(i, " ", axes_pla[i].description)
            end
        end
    end
    println("DUE TO AN ERROR IN VSCODE, YOU MIGHT HAVE TO WRITE YOUR ANSWER TWO TIMES.
PRESS ENTER AT THE END EACH TIME.")
    answer::PlotAxis = axes_pla[parse(Int, readline())]
    return answer
end

function ask_and_plot(axes_pla::Vector{PlotAxis})
    old_x_pla::PlotAxis = PlotAxis()
    x_pla::PlotAxis = ask(old_x_pla, axes_pla)
    y_pla::PlotAxis = ask(x_pla, axes_pla)
    p = plot_axes(x_pla, y_pla)
    savefig(p, "plot.pdf")
    return p
end

#######################################################################################
################## Application of the previous functions and structs ##################
#######################################################################################

(
    dates, fell_asleeps, woke_ups, sleep_qualities, time_awakes,
    session_starts_vec, session_ends_vec, meal_befores_vec,
    activities_vec, interest_levels_vec
) = read_data("tom_session_data.txt")

############ Alternative structs ####################
################ Length 97 ##########################
dates_pla::PlotAxis = PlotAxis(
    title = "Dates",
    data = dates,
    ticks = (dates[1:10:end], Dates.format.(dates[1:10:end], "dd.mm.yyyy")),
    rotation = 45,
    label = "Date",
    description = "Date"
)

fell_asleeps_pla::PlotAxis = PlotAxis(
    title = "Fell asleep",
    data = fell_asleeps,
    label = "When Tom fell asleep the night\nbefore the deep work session",
    description = "When Tom fell asleep the night before the deep work session"
)

woke_ups_pla::PlotAxis = PlotAxis(
    title = "Woke up",
    data = woke_ups,
    label = "When Tom woke up the morning\nbefore the deep work session",
    description = "When Tom woke up the morning before the deep work session"
)

time_awakes_pla::PlotAxis = PlotAxis(
    title = "Time awake",
    data = time_awakes,
    rotation = 45,
    label = "Total time Tom was awake during the night",
    description = "Total time Tom was awake during the night"
)

hours_of_sleeps_pla::PlotAxis = PlotAxis(
    title = "Hours of sleep",
    data = Dates.value.(woke_ups)/3600e9 + fill(24, length(woke_ups)) - fell_asleeps - Dates.value.(time_awakes)/3600e9,
    label = "Hours of sleep Tom got during the\nnight before the deep work session",
    description = "Hours of sleep Tom got during the night before the deep work session"
)

sleep_qualities_pla::PlotAxis = PlotAxis(
    title = "Sleep quality",
    data = sleep_qualities,
    label = "Sleep quality of the night\n before the deep work session\n(1 is worst, 10 is best)",
    description = "Sleep quality of the night before the deep work session"
)

nrs_of_sessions_pla::PlotAxis = PlotAxis(
    title = "Number of sessions",
    data = find_nrs_of_sessions(session_starts_vec, session_ends_vec),
    label = "How many deep work sessions\nTom had each day",
    description = "How many deep work sessions Tom had each day"
)

tot_durations_sessions_pla::PlotAxis = PlotAxis(
    title = "Total session duration",
    # Substracting two objects of type Vector{Vector{Time}}, gives an object of type Vector{Vector{Nanosecond}}:
    data = find_total_session_durations(session_starts_vec - session_ends_vec),
    label = "Total duration of deep work sessions\nduring the day",
    description = "Total duration of deep work sessions during the day"
)

############ Alternative structs ####################
################ Length 39 ##########################
session_starts_pla::PlotAxis = PlotAxis(
    title = "Session start",
    data = remove_zeros(vcat(session_starts_vec...)),
    label = "Start time of each deep work session",
    description = "Start time of each deep work session"
)

session_ends_pla::PlotAxis = PlotAxis(
    title = "Session end",
    data = remove_zeros(vcat(session_ends_vec...)),
    label = "End time of each deep work session",
    description = "End time of each deep work session"
)

session_durations_pla::PlotAxis = PlotAxis(
    title = "Duration of sessions",
    data = Time.(session_ends_pla.data - session_starts_pla.data),
    label = "Duration of each deep work session",
    description = "Duration of each deep work session"
)

meal_befores_pla::PlotAxis = PlotAxis(
    title = "Mealtime before", 
    data = remove_zeros(vcat(meal_befores_vec...)),
    label = "Time of the last meal\nbefore a deep work session",
    description = "Time of the last meal before a deep work session"
)

times_since_meal_pla::PlotAxis = PlotAxis(
    title = "Time since meal",
    data = remove_zeros(Time.(vcat((session_starts_vec - meal_befores_vec)...))),
    label = "Time from the last meal\nto the beginning of\nthe deep work session",
    description = "Time from the last meal to the beginning of the deep work session"
)

activities_pla::PlotAxis = PlotAxis(
    title = "Activity",
    data = remove_zeros(vcat(activities_vec...)),
    ticks = :all,
    rotation = 45,
    label = "What Tom was doing while\nconcentrating deeply",
    description = "What Tom was doing while concentrating deeply"
)

interest_levels_pla::PlotAxis = PlotAxis(
    title = "Level of interest",
    data = remove_zeros(vcat(interest_levels_vec...)),
    label = "How interested Tom was in what\nhe concentrated on from 1 to 10",
    description = "How interested Tom was in what he concentrated on from 1 to 10",
)
#################### Data_vector ####################
axes_pla::Vector{PlotAxis} = [
    dates_pla, fell_asleeps_pla, woke_ups_pla, time_awakes_pla, hours_of_sleeps_pla, sleep_qualities_pla,
    nrs_of_sessions_pla, tot_durations_sessions_pla, session_starts_pla, session_ends_pla, 
    session_durations_pla, meal_befores_pla, times_since_meal_pla, activities_pla, interest_levels_pla
]
#####################################################

ask_and_plot(axes_pla)