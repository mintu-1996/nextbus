require 'rest-client'
require 'json'
require 'Date'
ROUTES_API = 'http://svc.metrotransit.org/NexTrip/Routes'
DIRECTION_API = 'http://svc.metrotransit.org/NexTrip/Directions/'
STOP_API = 'http://svc.metrotransit.org/NexTrip/Stops/'
NEXT_BUS_API = 'http://svc.metrotransit.org/NexTrip/'
FORMAT = '?format=json'
MILLISECOND_CONVERSION_FACTOR = 1000
REQUIRED_PARAMETERS_LENGTH = 3
def get_response(url)
  return RestClient::Request.execute(
              method: :get,
              url: url)
end
def check_data_availability(records,value,comparision)
  records.each do |record|
    return record if record["#{comparision}"].include? value
  end
  return nil
end
unless ARGV.length == REQUIRED_PARAMETERS_LENGTH
  puts 'INVALID PARAMTERS'
  exit
end
routes = JSON.parse(get_response(ROUTES_API+FORMAT))
bus_route = check_data_availability(routes,ARGV[0],'Description')
unless bus_route
  puts 'BUS ROUTE NOT FOUND'
  exit
end
directions = JSON.parse(get_response(DIRECTION_API+bus_route['Route']+FORMAT))
direction = check_data_availability(directions,ARGV[2].upcase,'Text')
unless direction
  puts 'DIRECTION NOT FOUND'
  exit
end
stops = JSON.parse(get_response(STOP_API+bus_route['Route']+'/'+direction['Value']+FORMAT))
user_stop = check_data_availability(stops,ARGV[1],'Text')
unless user_stop
  puts 'BUS STOP NOT FOUND'
  exit
end
buses = JSON.parse(get_response(NEXT_BUS_API+bus_route['Route']+'/'+direction['Value']+'/'+user_stop['Value']+FORMAT))
if buses.any?
  bus = buses[0]
  # below code is to display the user time in hours minutes and seconds left as response from the api may give DepartureText as 3:35
  time_to_arrive = (((bus['DepartureTime'].split'(')[1].split'-')[0].to_i)/MILLISECOND_CONVERSION_FACTOR
  utc_time_in_seconds = Time.now.utc.to_i
  seconds = time_to_arrive - utc_time_in_seconds
  print_data = ''
  if seconds / 3600 > 0
    print_data += (seconds / 3600).to_s + ' hours '
    seconds = seconds % 3600
  end
  if seconds / 60 > 0
    print_data += (seconds / 60).to_s + ' minutes '
    seconds = seconds % 60
  end
  print_data += seconds.to_s + ' seconds'
  puts print_data
end
