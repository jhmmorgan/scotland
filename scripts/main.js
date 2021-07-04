// URLS
const url_data_path = "https://raw.githubusercontent.com/jhmmorgan/scotland/main/data/"
let url_topo_scotland = url_data_path + "topo_scotland_lad.geojson"
let url_csv_smoker = url_data_path + "data_smoking_ratio.csv"
let url_csv_weight = url_data_path + "data_weight_ratio.csv"


// Map and projection
const path = d3.geoPath().projection;
const projection = d3.geoMercator()

// ------ DEFAULT MAP ------
const svg_default_map = d3.select("div#map_container")
map_default(url_topo_scotland, svg_default_map, projection, path)


// ------ SMOKERS ------
//const color_scale_smoker = d3.scaleThreshold()
//  .domain([0, 3, 6, 9, 12, 15, 18, 21, 24])
//  .range(d3.schemeGreens[9]);


// Create the maps
Promise.all([
    d3.json(url_topo_scotland), 
    d3.csv(url_csv_smoker)])
  .then(function(loadedData) {

  const svg_smoker_then = d3.select("div#smoker_map_then")
  const svg_smoker_now  = d3.select("div#smoker_map_now")
  const color_scale_smoker = d3.scaleThreshold()
    .domain([0, 5, 10,15, 20, 25, 30, 35, 40])
    .range(d3.schemeBlues[9]);

  let loaded_map = loadedData[0]
  let data_smoker_then = loadedData[1]
    .filter(function(d) { return d.DateRange == 2000 })
    .map(function(d) {
      return {id: d.LAD20CD, attribute: d.Smoker_Current}})

  map_choropleth(loaded_map, 
                 data_smoker_then,
                 svg_smoker_then, 
                 projection, 
                 path, 
                 color_scale_smoker,
                 "Year 2000")


  let data_smoker_now = loadedData[1].filter(function(d) { return d.DateRange == 2017 })
                             .map(function(d) {
                                return {id: d.LAD20CD, attribute: d.Smoker_Current}})

  map_choropleth(loaded_map, 
                 data_smoker_now,
                 svg_smoker_now, 
                 projection, 
                 path, 
                 color_scale_smoker,
                 "Year 2017")
})





// ------ LOW BIRTH WEIGHT ------ 
Promise.all([d3.json(url_topo_scotland), d3.csv(url_csv_weight)])
  .then(function(loadedData) {

  const svg_weight_then = d3.select("div#weight_map_then")
  const svg_weight_now  = d3.select("div#weight_map_now")
  
  const color_scale_weight = d3.scaleThreshold()
    .domain([0, 1, 2, 3, 4, 5])
    .range(d3.schemeGreens[6]);

  let loaded_map = loadedData[0]
  let data_weight_then = loadedData[1]
    .filter(function(d) { return d.DateRange == 2000 })
    .map(function(d) {
      return {id: d.LAD20CD, attribute: d.Low_Weight_Births}})

  map_choropleth(loaded_map, 
                 data_weight_then,
                 svg_weight_then, 
                 projection, 
                 path, 
                 color_scale_weight,
                 "Year 2000")

  let data_weight_now = loadedData[1]
    .filter(function(d) { return d.DateRange == 2017 })
    .map(function(d) {
      return {id: d.LAD20CD, attribute: d.Low_Weight_Births}})

  map_choropleth(loaded_map, 
                 data_weight_now,
                 svg_weight_now, 
                 projection, 
                 path, 
                 color_scale_weight,
                 "Year 2017")
})

