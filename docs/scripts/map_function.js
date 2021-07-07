const latitude  = 54.216918399
const longitude = -4.1826492694


// Zoom function.  This allows a zoom and pan effect using the users mouse/interaction.
function zoom(svg){
      let zoom = d3.zoom()
      .scaleExtent([0.5, 3]) // Allow the user to zoom between 50% to 300% of the image
      .on('zoom', function(event) {
        svg.selectAll('path')
          .attr('transform', event.transform);
      });

    svg.call(zoom);
}

const map_default = function(url, svg, projection, path) {

Promise.all([
    d3.json(url)
  ]).then(function(loadData){

  // The width and height for the map svg
  let console_width = d3.select("body").node().getBoundingClientRect().width;
  let map_width = console_width*.28;
  let map_height = map_width * 1.5;

  projection.translate([map_width/2, map_height/2])
            .center([longitude,latitude])
            .scale(map_width*3.25);


  let topo = loadData[0]
    
  // Draw the map
  let map = svg.append("svg")
    .attr("preserveAspectRatio", "xMinYMin meet")
    .attr("viewBox", "0 0 " + 400 + " " + 600)
    .classed("svg-content", true);
    
  let map_g = map
    .append("g").selectAll("path")
    .data(topo.features)
    .join("path")
      // draw each council
    .attr("d", d3.geoPath()
      .projection(projection))
    .attr("fill", "lightgrey");
  zoom(map)
  })
}


const map_choropleth = function(topo, data_set, svg, projection, path, colorScale, title) {
// This is the main function to create a choropleth map_choropleth
//  topo | A topoGeoJson file for the map_choropleth
//  data_set | A data_set, pre-formatted with an 'id' and 'attribute' column, for the colours
//  svg | An SVG to append the map to
//  project | A projection to use for the map
//  path | A path to use for the map
//  colorScale | A color scale to apply to the choropleth and legend
//  title | The title to display

  // The width and height for the map svg
  let console_width = d3.select("body").node().getBoundingClientRect().width;
  let map_width = console_width*.28;
  let map_height = map_width * 1.5;

  projection.translate([map_width/2, map_height/2])
            .center([longitude,latitude])
            

            .scale(map_width*3.25);

  // Set up a new map svg, appended to the provided svg, using the width and height
  let map = svg.append("svg")
    .attr("preserveAspectRatio", "xMinYMin meet")
    .attr("viewBox", "0 0 " + map_width + " " + map_height)
    .classed("svg-content", true);

  // Draw the map    
  let map_g = map
    .append("g").selectAll("path")
    .data(topo.features)
    .join("path")
    .attr("d", d3.geoPath().projection(projection))
    
    // set the color of each district
    .attr("fill", function (d) {
      // This applies a function that takes the data_set and filters this to each
      //   id (region), to extract the attribute (value).
        function getFilteredData(data, id) { // the data_set and the region to match against
	        return data.filter(function(d) { return d.id === (id); }) // filter data_set to the region
	        .map(function(d) { // map the return value to return what we need
            return {attribute: d.attribute}}) // return just the attribute
        }
          // use function, or return a 0 if the data is not found.
          let data_filtered = getFilteredData(data_set, d.id)[0]||{attribute:"0"} 
          d.total = data_filtered.attribute
        return colorScale(d.total);
      });

  // Create a title
  plotGroup = map
    .append("g")
    .append("text")
    .text(title)
    .style("fill", "#000")
    .style("font-weight", "bold")
    .style("font-size", "10pt")
    .style("font-family", "Arial Black")
    .style("text-align", "center")
    .attr("x", "50%")
    .attr("y", "4%")
    .attr("text-anchor", "middle");
  //        .attr("x", (map_width/2)-(.style("width")/2))


  // Create a legend
  let legend_svg = map
    .append("g")
    .attr("transform", "translate(10,10)");
  legend({obj:legend_svg, color: colorScale, title: "Legend", width: 135, tickFormat: (d => d + "%")});
  legend_svg.selectAll(".tick text")
    .attr("font-size", "7")
    .attr("font-family", "calibri");
  
  // Allow zooming and panning of the map, by applying the previously defined zoom function
  zoom(map);
}




const map_choropleth_dual = function(topo, data_set, svg, projection, path, colorScale1, colorScale2, title) {
// This is the main function to create a dual coloured choropleth map_choropleth
//  topo | A topoGeoJson file for the map_choropleth
//  data_set | A data_set, pre-formatted with an 'id' and 'attribute' column, for the colours
//  svg | An SVG to append the map to
//  project | A projection to use for the map
//  path | A path to use for the map
//  colorScale(1 nd 2) | A color scale to apply to the choropleth
//  title | The title to display

  // The width and height for the map svg
  let console_width = d3.select("body").node().getBoundingClientRect().width;
  let map_width = console_width*.28;
  let map_height = map_width * 1.5;

  projection.translate([map_width/2, map_height/2])
            .scale(map_width*3.25)
            .center([longitude,latitude]);

  // Set up a new map svg, appended to the provided svg, using the width and height
  let map = svg.append("svg")
    .attr("preserveAspectRatio", "xMinYMin meet")
    .attr("viewBox", "0 0 " + map_width + " " + map_height)
    .classed("svg-content", true);

  // Draw the map    
  let map_g = map
    .append("g").selectAll("path")
    .data(topo.features)
    .join("path")
    .attr("d", d3.geoPath().projection(projection))
    
    // set the color of each district
    .attr("fill", function (d) {
      // This applies a function that takes the data_set and filters this to each
      //   id (region), to extract the attribute (value).
        function getFilteredData(data, id) { // the data_set and the region to match against
	        return data.filter(function(d) { return d.id === (id); }) // filter data_set to the region
	        .map(function(d) { // map the return value to return what we need
            return {attribute: d.attribute, pick: d.pick}}) // return just the attribute
        }
          // use function, or return a 0 if the data is not found.
          let data_filtered = getFilteredData(data_set, d.id)[0]||{attribute:"0"} 
          d.total = data_filtered.attribute
        if (data_filtered.pick == 0) {return colorScale1(d.total)}
            else    { return colorScale2(d.total) }
      });

  // Create a title
  plotGroup = map
    .append("g")
    .append("text")
    .text(title)
    .style("fill", "#000")
    .style("font-weight", "bold")
    .style("font-size", "10pt")
    .style("font-family", "Arial Black")
    .style("text-align", "center")
    .attr("x", "50%")
    .attr("y", "4%")
    .attr("text-anchor", "middle");
  //        .attr("x", (map_width/2)-(.style("width")/2))


  // Create a legend
  let legend_svg1 = map.append("g").attr("transform", "translate(10,15)");
  let legend_svg2 = map.append("g").attr("transform", "translate(10,25)");

  legend({obj:legend_svg1, color: colorScale1, title: "Legend", width: 225, tickFormat: d=>""});
  legend({obj:legend_svg2, color: colorScale2, title: "", width: 225, tickFormat: (d => d + "%")});
  legend_svg2.selectAll(".tick text")
    .attr("font-size", "10")
    .attr("font-family", "calibri");
  
  // Allow zooming and panning of the map, by applying the previously defined zoom function
  zoom(map);
}