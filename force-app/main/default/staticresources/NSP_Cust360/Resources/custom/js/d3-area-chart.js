$(document).ready(function(){
function createAreaChart(callback){
        var format = d3.time.format("%m/%d/%y");
        var color = ["#6ab1db","#8dbdd9"]

        var margin = {top: 0, right: 0, bottom: 0, left: 0},
            width = 330 - margin.left - margin.right,
            height = 240 - margin.top - margin.bottom;

        var x = d3.time.scale()
            .range([0, width]);

        var y = d3.scale.linear()
            .range([height, 0]);

        var z = d3.scale.category20c();

        var xAxis = d3.svg.axis()
            .scale(x)
            .orient("top")
            .ticks(d3.time.days);
            

        var yAxis = d3.svg.axis()
            .scale(y)
            .orient("right")
           // .attr("opacity","0")
            // .attr("hide");

        var stack = d3.layout.stack()
            .offset("zero")
            .values(function(d) { return d.values; })
            .x(function(d) { return d.date; })
            .y(function(d) { return d.value; });

        var nest = d3.nest()
            .key(function(d) { return d.key; });

        var area = d3.svg.area()
            .interpolate("cardinal")
            .x(function(d) { return x(d.date); })
            .y0(function(d) { return y(d.y0); })
            .y1(function(d) { return y(d.y ); });

        var svg = d3.select("#performanceChart").append("svg")
            .attr("width", width + margin.left + margin.right)
            .attr("height", height + margin.top + margin.bottom)
        .append("g")
            .attr("transform", "translate(" + 0 + "," + (margin.top + margin.bottom) + ")");

        // d3.csv("data/area-data.csv", function(error, data) {
        // if (error) throw error;
       var data = [{key:"Group1",value:"15",date:"04/23/12"}, {key:"Group2",value:"10",date:"04/23/12"} ,
        {key:"Group1",value:"40",date:"04/24/12"},{key:"Group2",value:"28",date:"04/24/12"} ,
        {key:"Group1",value:"45",date:"04/25/12"},{key:"Group2",value:"40",date:"04/25/12"},{key:"Group1",value:"55",date:"04/26/12"},{key:"Group2",value:"43",date:"04/26/12"}] 

        data.forEach(function(d) {
            d.date = format.parse(d.date);
            d.value = +d.value;
        });

        var layers = stack(nest.entries(data));

        x.domain(d3.extent(data, function(d) { return d.date; }));
        y.domain([0, d3.max(data, function(d) { return d.y0 + d.y/3.5; })]);

        svg.selectAll(".layer")
            .data(layers)
            .enter().append("path")
            .attr("class", "layer")
            .attr("d", function(d) { return area(d.values); })
            .style("fill", function(d, i) { return color[i]; });
           
        svg.append("g")
            .attr("class", "x axis")
            .attr("transform", "translate(0," + height + ")")
            .call(xAxis);

        svg.append("g")
            .attr("class", "y axis")
            .call(yAxis);
        // });

        svg.append("text")
            .attr("transform", "rotate(0)")
            .attr("y", 30)
            .attr("x",height/3)
            .attr("dy", "1em")
            .style("text-anchor", "middle")
            .style("font-weight", "700")
            .text("My Performance vs Peer Avg");

           

            // // Add the Y Axis
            // svg.append("g")
            // .attr("class", "axisRed")
            // .call(yAxis);
           
           // callback();
        
    }


   // calling 
    createAreaChart(removeAxis);

    

    function removeAxis(){
        $(".y.axis").css("visibility","hidden");
        console.log($(".y.axis"));
    }

    setTimeout(function(){removeAxis()} ,0);

})
