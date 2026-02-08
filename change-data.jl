# Include necessary packages
using Dates, Distributions

#######################################################################################
################################ Functions and structs ################################
#######################################################################################

"""Function that converts a vector of floats to a vector of strings on the format 'HH:MM'"""
function floats_to_time_strings(floats::Vector{Float64})
    # The hours is just the int after removing the decimals from the float:
    hour_ints::Vector{Int64} = div.(floats, 1)
    # Converting the numbers after the decimal point to minutes
    # Example: The float 0.5 means 30 minutes:
    minute_ints::Vector{Int64} = floor.(mod.(floats, 1)*60)
    # Converting to strings:
    hour_strs::Vector{String} = string.(hour_ints)
    minute_strs::Vector{String} = string.(minute_ints)
    # Making each hour- and minute-string contain exactly two digits:
    for i in eachindex(hour_strs)
        if length(hour_strs[i]) == 1
            hour_strs[i] = "0" * hour_strs[i]
        end
        if length(minute_strs[i]) == 1
            minute_strs[i] = "0" * minute_strs[i]
        end
        if (length(hour_strs[i]) != 2) || (length(minute_strs[i]) != 2)
            # Throwing error if the hours and minutes do not consist of two digits
            error("error: length(hour_strs) != 2 OR length(minute_strs) != 2\nlength(hour_strs): $length(hour_strs)\nlength(minute_strs): $length(minute_strs)")
        end
    end
    # Make final vector of the format "HH:MM" (hour hour:minute minute)
    time_strs::Vector{String} = hour_strs .* ":" .* minute_strs
    return time_strs
end

function generate_dates(len::Int64)
    start_date::Date = Date(2026, 1, 1)
    date_dates::Vector{Date} = collect(start_date : Day(1) : start_date + Day(len - 1))
    date_strs::Vector{String} = Dates.format.(date_dates, "dd.mm.yyyy")
    return date_strs
end

function generate_fell_asleeps(len::Int64)
    fell_asleep_floats_24::Vector{Float64} = rand(Normal(23.5, 1.0), len)
    fell_asleep_floats_00::Vector{Float64} = ifelse.(fell_asleep_floats_24 .>= 24, fell_asleep_floats_24 .- 24, fell_asleep_floats_24)
    fell_asleep_strs::Vector{String} = floats_to_time_strings(fell_asleep_floats_00)
    return fell_asleep_strs, fell_asleep_floats_00
end

function generate_woke_ups(len::Int64)
    woke_up_floats::Vector{Float64} = rand(Normal(9.0, 2.0), len)
    for i in [1:7:length(woke_up_floats)]
        woke_up_floats[i] .= 7.0
    end
    woke_up_strs::Vector{String} = floats_to_time_strings(woke_up_floats)
    return woke_up_strs, woke_up_floats
end

function generate_sleep_qualities(len::Int64)
    sleep_quality_ints::Vector{Int64} = ceil.(Int64, 10*rand(len))
    return string.(sleep_quality_ints)
end

function generate_hours_awakes(len::Int64)
    hours_awake_floats::Vector{Float64} = rand(Normal(0.5, 0.7), len)
    hours_awake_floats[hours_awake_floats .< 0] .= 0
    hours_awake_strs::Vector{String} = floats_to_time_strings(hours_awake_floats)
    return hours_awake_strs
end

function generate_session_times(interval_start::Float64, interval_end::Float64)
    session_duration::Float64 = rand(Normal(0.5, 0.25))
    session_duration = session_duration < 0.25 ? 0.25 : session_duration
    time_since_meal::Float64 = rand(Normal(2.0, 1.0))
    time_since_meal = time_since_meal < 0.05 ? 0.05 : time_since_meal
    session_start_float::Float64 = rand().*(interval_end - interval_start - session_duration - time_since_meal) .+ interval_start .+ time_since_meal
    session_end_float::Float64 = session_start_float + session_duration
    meal_before_float::Float64 = session_start_float - time_since_meal
    session_start_str::String, session_end_str::String, meal_before_str::String = (
        floats_to_time_strings([session_start_float, session_end_float, meal_before_float]))
    return session_start_str, session_end_str, meal_before_str
end

struct Activity
    title::String
    time_amount::Int64 # Number from 1 to 10, amount of day spent on this activity
    interest_level::Array{Int64} # Numbers from 1 to 10, how interesting what is concentrates on is
end

function generate_activities_and_interest_levels(activity_acts::Vector{Activity})
    activity_time_amounts::Vector{Int64} = getproperty.(activity_acts, :time_amount)
    activity_index::Int64 = rand(Categorical(activity_time_amounts ./ sum(activity_time_amounts)))
    activity_during_session::Activity = activity_acts[activity_index]
    activity_title::String = activity_during_session.title
    interest_level_vec::Vector{Int64} = activity_during_session.interest_level
    interest_level::String = string(ceil(Int64, rand() * length(interest_level_vec) + interest_level_vec[1]))
    return activity_title, interest_level
end

function data_to_file(nr_of_samples::Int, filepath::String, activity_acts::Vector{Activity})
    dates::Vector{String} = generate_dates(nr_of_samples)
    fell_asleeps::Vector{String}, fell_asleep_floats::Vector{Float64} = generate_fell_asleeps(nr_of_samples)
    woke_ups::Vector{String}, woke_up_floats::Vector{Float64} = generate_woke_ups(nr_of_samples)
    sleep_qualities::Vector{String} = generate_sleep_qualities(nr_of_samples)
    hours_awakes::Vector{String} = generate_hours_awakes(nr_of_samples)
    nrs_of_sessions::Int64 = abs(round.(Int64, rand(Normal(40, 20))))
    session_indices::Vector{Int64} = sort!(ceil.(Int64, rand(nrs_of_sessions)*nr_of_samples))
    interval_starts::Vector{Float64} = woke_up_floats .+ 1
    fell_asleep_floats = ifelse.(fell_asleep_floats .< 6.0, fell_asleep_floats .+ 24, fell_asleep_floats)
    interval_ends::Vector{Float64} = fell_asleep_floats[2:end] .- 1
    push!(interval_ends, 24.0)
    open(filepath, "w") do io
        write(io, "Dates;Fell asleep;Woke up;Sleep quality;Hours awake;Session start;Session end;Time since meal;Activity;Interest level\n")
        for i in eachindex(dates)
            if !(i in session_indices)
                write(
                    io,
                    dates[i] * ";" *
                    fell_asleeps[i] * ";" *
                    woke_ups[i] * ";" *
                    sleep_qualities[i] * ";" *
                    hours_awakes[i] * ";00:00;00:00;00:00;;0\n"
                )
            else
                session_starts::String = ""
                session_ends::String = ""
                meal_befores::String = ""
                activities::String = ""
                interest_levels::String = ""
                for j in session_indices
                    if j == i
                        session_start::String, session_end::String, meal_before::String = generate_session_times(interval_starts[i], interval_ends[i])
                        activity::String, interest_level::String = generate_activities_and_interest_levels(activity_acts)
                        session_starts *= session_start * ", "
                        session_ends *= session_end * ", "
                        meal_befores *= meal_before * ", "
                        activities *= activity * ", "
                        interest_levels *= interest_level * ", "
                    end
                end
                # Removing the last comma and space:
                session_starts = session_starts[1:end-2]
                session_ends = session_ends[1:end-2]
                meal_befores = meal_befores[1:end-2]
                activities = activities[1:end-2]
                interest_levels = interest_levels[1:end-2]
                write(
                    io,
                    dates[i] * ";" *
                    fell_asleeps[i] * ";" *
                    woke_ups[i] * ";" *
                    sleep_qualities[i] * ";" *
                    hours_awakes[i] * ";" *
                    session_starts * ";" * 
                    session_ends * ";" * 
                    meal_befores * ";" *
                    activities * ";" *
                    interest_levels * "\n"
                )
            end
        end
    end
end

#######################################################################################
################## Application of the previous functions and structs ##################
#######################################################################################

nr_of_samples = 100

bird_watching::Activity = Activity(
    "Bird Watching", 1, [5,6,7,8,9]
)

solving_crossword::Activity = Activity(
    "Solving crossword", 3, [7,8,9]
)

going_for_a_walk::Activity = Activity(
    "Going for a walk", 5, [1,2,3,4,5,6,7,8,9,10]
)

woodworking::Activity = Activity(
    "Woodworking", 4, [4,5,6,7]
)

model_building::Activity = Activity(
    "Model building", 2, [4,5,6,7]
)

studying::Activity = Activity(
    "Studying", 10, [1,2,3,4,5,6,7,8,9,10]
)

resting::Activity = Activity(
    "Resting", 3, [4,5,6,7,8,9,10]
)

gardening::Activity = Activity(
    "Gardening", 1, [10]
)

golfing::Activity = Activity(
    "Golfing", 5, [7,8,9]
)

cooking::Activity = Activity(
    "Cooking", 1, [9,10]
)

reading::Activity = Activity(
    "Reading", 5, [2,3,4,5,6,7,8,9,10]
)

listening_to_records::Activity = Activity(
    "Listening to records", 6, [4,5,6,7,8,9,10]
)

activity_acts = [
    bird_watching, solving_crossword, going_for_a_walk,
    woodworking, model_building, studying, resting, gardening,
    golfing, cooking, reading, listening_to_records
]

data_to_file(nr_of_samples, "tom_session_data.txt", activity_acts)