require 'yelp'
require 'csv'

@client = Yelp::Client.new({ consumer_key: 'atcOW8wzksokuJjV_RDQTw',
                            consumer_secret: 'zz5t3khY4vQbA5CchwizLzQ7mEo',
                            token: 'vX0RFFkAOK0Nxy-f8IgfzAuUCAhEPyc2',
                            token_secret: '93c_gj4GWrNI8__uyMUvqELJlcY'
                          })

@params = { term: 'restaurant',
					 limit: 10,
					 sort: 0 }

location = { location: '94109' }

biz = []
sum_ratings = 0

def make_box(swlo, swla, nelo, nela) # order rearranged to fit yelp order
	{ sw_latitude: swla, sw_longitude: swlo, ne_latitude: nela, ne_longitude: nelo }
end

def split_into_boxes(big_box, longitude_size, latitude_size)
	box_array = []
	# subtract latitude and longitude size to prevent spillage past borders
	for lat in (big_box[:sw_latitude]..big_box[:ne_latitude]).step(latitude_size) do
		for lon in (big_box[:sw_longitude]..big_box[:ne_longitude]).step(longitude_size) do
			box_array << make_box(lon, lat, lon+longitude_size, lat+latitude_size) # fit yelp order
		end
	end
	box_array
end

def bounding_box_search(box)
	@client.search_by_bounding_box(box, @params).businesses
end

def calculate_box_rating(box)
	box_total = 0
	biz = bounding_box_search box
	biz.each { |b| box_total += b.rating }
	avg_rating = if biz.length > 4 then box_total/biz.length else 0 end # require sample size of 5 to get a rating
	avg_rating.round(2)
end

# output some stuff about the response
def output(biz)
	biz.each do |b|
		puts "#{b.name}, #{b.rating}, #{b.location.postal_code}"
	end
end

def generate_csv(box_array)
	CSV.open('data/yelp_data.csv', "w") do |csv|
		csv << ["sw_longitude", "sw_latitude", "ne_longitude", "ne_latitude", "box_rating"]
		box_array.each do |box|
			csv << [box[:sw_longitude], box[:sw_latitude], box[:ne_longitude], box[:ne_latitude], calculate_box_rating(box)]
		end
	end
	puts "CSV generated"
end

sample_box = make_box(-122.518631,37.70814,-122.363964,37.811471)
box_array = split_into_boxes(sample_box, 0.02, 0.01)
generate_csv(box_array)