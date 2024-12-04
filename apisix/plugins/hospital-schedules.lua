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

--  Function to convert XML to table
local function xml_to_table(xml_string)
    local result = { doctors = {} }
    
    for doctor_element in xml_string:gmatch("<doctor>(.-)</doctor>") do
        local doctor = {}
        for field, value in doctor_element:gmatch("<(%w+)>(.-)</%1>") do
            if field == "schedule" then
                doctor.schedule = {}
                for schedule_detail in doctor_element:gmatch("<schedule>(.-)</schedule>") do
                    local schedule = {}
                    for detail_field, detail_value in schedule_detail:gmatch("<(%w+)>(.-)</%1>") do
                        schedule[detail_field] = detail_value
                    end
                    table.insert(doctor.schedule, schedule)
                end
            else
                doctor[field] = value
            end
        end
        table.insert(result.doctors, doctor)
    end

    return result
end

local function print_table(t, indent)
    indent = indent or 0
    for k, v in pairs(t) do
        local prefix = string.rep("  ", indent) 
        if type(v) == "table" then
            core.log.warn(prefix .. tostring(k) .. ":")
            print_table(v, indent + 1)
        else
            core.log.warn(prefix .. tostring(k) .. ": " .. tostring(v))
        end
    end
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

    -- print the response body
    core.log.warn(res_grandoak.body)
    core.log.warn(res_pinevalley.body)
    core.log.warn(res_sprucecity.body)

    -- Combine the tables together
    local grandoak_data = cjson.decode(res_grandoak.body)
    local pinevalley_data = cjson.decode(res_pinevalley.body)
    local sprucecity_data = xml_to_table(res_sprucecity.body) 

    print_table(grandoak_data)
    print_table(pinevalley_data)
    print_table(sprucecity_data)

    core.log.warn(cjson.encode(grandoak_data))
    core.log.warn(cjson.encode(pinevalley_data))
    core.log.warn(cjson.encode(sprucecity_data))

    local combined_response = grandoak_data
    combined_response = table.move(pinevalley_data, 1, #pinevalley_data, #combined_response + 1, combined_response)
    
    if sprucecity_data and sprucecity_data.doctors then
        for _, doctor in ipairs(sprucecity_data.doctors) do
            table.insert(combined_response, doctor)
        end
    end

    core.log.warn(cjson.encode(combined_response))
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