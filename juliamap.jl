using DataFrames, JLD, CSV, Missings

page = readstring("teaching.md");
page = split(page, "## Classes")[2]
page = split(page, "## Installing Julia")[1]

df = DataFrame(institution=String[], course=String[], lat=Union{Missing, Float64}[], lon=Union{Missing, Float64}[])

institution = ""
lat = missing
lon = missing
for line in eachline(IOBuffer(page), chomp=true)
	l = strip(line)
	if startswith(l, "-")
		institution = strip(l[2:end])
		if contains(institution, "<!--") # geo location
			institution, geo = strip.(split(institution, "<!--"))
			lat, lon = parse.(Float64, split(split(geo, "-->")[1], ","))
		else
			lat = missing
			lon = missing
		end
	elseif startswith(l, "*")
		push!(df, [institution, lstrip(l[2:end]), lat, lon])
	end
end

# @save "courses.jld" df

# plot world map
using PyCall
@pyimport folium
@pyimport markdown2

md = markdown2.Markdown()

# make an empty map
# m = folium.Map(location=(20, 0), tiles="Mapbox Bright", zoom_start=2)
m = folium.Map(location=(20, 9), tiles="cartodbpositron", zoom_start=2)
# m = folium.Map(location=(20, 0), tiles="openstreetmap", zoom_start=2)

places = df[.!(ismissing.(df[:lat])),:]

for g in groupby(places, :institution)
	place = md[:convert](g[:institution][1])
	popup = place * "<ul>"
	for c in 1:nrow(g)
		popup *= "<li>"*md[:convert](g[c, :course])*"</li>"
	end
	popup *= "</ul>"
	lat = g[:lat][1]
	lon = g[:lon][1]
	folium.Marker([lat, lon], popup=popup)[:add_to](m)
end
 
# Save it as html
m[:save]("juliamap.html")
m