-- Introduce the necessary modules/libraries we need for this plugin 
local core      = require("apisix.core")
local http      = require("resty.http")
local plugin    = require("apisix.plugin")
local cjson     = require("cjson")

-- Declare the plugin's name
local plugin_name = "hospital-schedules"

local default_uri = "/hospital/schedules"

-- Define the plugin schema format
local plugin_schema = {
    type = "object",
}

local attr_schema = {
    type = "object",
    properties = {
        uri = {
            type = "string",
            description = "uri for hospital schedule aggregation",
            default = default_uri
        }
    },
}

-- Define the plugin with its version, priority, name, and schema
local _M = {
    version = 1.0,
    priority = 1000,
    name = plugin_name,
    schema = plugin_schema,
    attr_schema = attr_schema,
    scope = "global"
}

-- Declare the hospitals endpoints
local http_string = "http://"
local GRANDOAK_ENDPOINT = table.concat({http_string, os.getenv("GRANDOAK_ENDPOINT"), "/doctors"})
local PINEVALLEY_ENDPOINT = table.concat({http_string, os.getenv("PINEVALLEY_ENDPOINT"), "/appointments"})
local SPRUCECITY_ENDPOINT = table.concat({http_string, os.getenv("SPRUCECITY_ENDPOINT"), "/schedules"})

-- Function to check if the plugin configuration is correct
function _M.check_schema(conf)
  -- Validate the configuration against the schema
  local ok, err = core.schema.check(plugin_schema, conf)
  -- If validation fails, return false and the error
  if not ok then
      return false, err
  end
  -- If validation succeeds, return true
  return true
end

local function format_time(hour, minute)
    local period = "AM"
    hour = tonumber(hour)

    if hour >= 12 then
        period = "PM"
        if hour > 12 then
            hour = hour - 12
        end
    elseif hour == 0 then
        hour = 12
    end

    return string.format("%02d:%02d %s", hour, tonumber(minute), period)
end

--  Function to convert XML to table
local function xml_to_table(xml_string)
    local result = { doctors = {} }
    
    for doctor_element in xml_string:gmatch("<doctor>(.-)</doctor>") do
        local doctor = {}
        
        -- Extract first name and last name
        for field, value in doctor_element:gmatch("<(%w+[_%w]*)>(.-)</%1>") do

            if field == "first_name" then
                doctor.first_name = value
            elseif field == "last_name" then
                doctor.last_name = value
            elseif field == "gender" then
                doctor.gender = value == "true" and "Male" or "Female"
            elseif field == "id" then
                doctor.id = tonumber(value)
            elseif field == "phone" then
                doctor.phone = value
            elseif field == "specialty" then
                doctor.specialty = value
            end
        end
        
        -- Extract schedule
        doctor.schedule = {}
        for schedule_detail in doctor_element:gmatch("<schedule>(.-)</schedule>") do
            local day = schedule_detail:match("<day>(.-)</day>")
            local start_hour = schedule_detail:match("<start_time><hour>(.-)</hour><minute>(.-)</minute></start_time>")
            local end_hour = schedule_detail:match("<end_time><hour>(.-)</hour><minute>(.-)</minute></end_time>")

            if day and start_hour and end_hour then
                local start_time = format_time(start_hour, schedule_detail:match("<start_time><hour>.-</hour><minute>(.-)</minute></start_time>"))
                local end_time = format_time(end_hour, schedule_detail:match("<end_time><hour>.-</hour><minute>(.-)</minute></end_time>"))

                -- Create the schedule entry
                local schedule_entry = {
                    day = day,
                    start_time = start_time,
                    end_time = end_time
                }
                table.insert(doctor.schedule, schedule_entry)
            end
        end

        -- Add the doctor to the result
        table.insert(result.doctors, doctor)
    end

    return result
end

-- Function to be called during the access phase
local function get_hospitals()
    local httpc = http.new()
    local res_grandoak, err = httpc:request_uri(GRANDOAK_ENDPOINT, {
        method = "GET",
    })

    local res_pinevalley, err = httpc:request_uri(PINEVALLEY_ENDPOINT, {
        method = "GET",
    })

    local res_sprucecity, err = httpc:request_uri(SPRUCECITY_ENDPOINT, {
        method = "GET",
    })

    -- Combine the tables together
    local grandoak_data = cjson.decode(res_grandoak.body)
    local pinevalley_data = cjson.decode(res_pinevalley.body)
    local sprucecity_data = xml_to_table(res_sprucecity.body) 

    -- Transform Grand Oak data to the expected format
    local transformed_grandoak_data = {}
    for _, doctor in ipairs(grandoak_data) do
        local transformed_doctor = {
            id = doctor.id,
            phone = doctor.phone,
            specialty = doctor.specialty,
            gender = doctor.gender,
            first_name = doctor.full_name:match("Dr%.%s*(%w+)%s+(%w+)"),
            last_name = doctor.full_name:match("Dr%.%s*%w+%s+(%w+)"),
            schedule = {}
        }

        -- Process the schedule
        for _, schedule in ipairs(doctor.schedule) do
            local start_time, end_time = schedule.available_range:match("(%d+:%d+ %a+) %- (%d+:%d+ %a+)")
            table.insert(transformed_doctor.schedule, {
                day = schedule.day,
                start_time = start_time,
                end_time = end_time
            })
        end

        table.insert(transformed_grandoak_data, transformed_doctor)
    end

    -- Combine all data
    local combined_response = transformed_grandoak_data
    combined_response = table.move(pinevalley_data, 1, #pinevalley_data, #combined_response + 1, combined_response)
    
    if sprucecity_data and sprucecity_data.doctors then
        for _, doctor in ipairs(sprucecity_data.doctors) do
            table.insert(combined_response, doctor)
        end
    end

    return 200, combined_response
end

function _M.api()
    local uri = default_uri
    local attr = plugin.plugin_attr(plugin_name)
    if attr then
        uri = attr.uri or default_uri
    end
    return {
        {
            methods = {"GET"},
            uri = uri,
            handler = get_hospitals,
        }
    }
end

-- Return the plugin so it can be used by APISIX
return _M