var selected = new Set();
var pairwise_data = new Map();
var age_scale;
var phylo_root;
var reconst_root;
var colors = [];
var ncolors = 30;
for (var i = 0; i < ncolors; i++) {
    colors.push(d3.interpolateRainbow(i/ncolors));
}

var color_scale = d3.scaleOrdinal(colors);
var strokeWidth = 5;
var axis_phylo;
var axis_g_phylo;
var axis_reconst;
var axis_g_reconst;
var scale_range;
var reconstructed_file = "reconstruction_100.csv"
var phylo_file = "reference.csv"
          

var max_update = 262145;
var min_update = 262030;
var rect_opacity = 1;

var all_reconstructions;

const phylo_svg = d3.select("#phylo_canvas");
const reconstruct_svg = d3.select("#reconstruct_canvas");

function update_tree() {

    phylo_root.each(d => {
        // console.log(d.y, age_scale(d.data.origin_time) );
        d.y = age_scale(d.data.origin_time - min_update);
    });

    reconst_root.each(d => {
        d.y = age_scale(d.data.origin_time - min_update);
    });


    d3.selectAll(".phylo_path")
       .attr("d", d3.link(d3.curveStepAfter)//d3.linkVertical()
              .x(d => d.x)
              .y(d => d.y));

    phylo_svg.selectAll("a")
        .attr("transform", d => `translate(${d.x},${d.y})`);

    reconstruct_svg.selectAll("a")
        .attr("transform", d => `translate(${d.x},${d.y})`);


    new_ticks = [age_scale.invert(scale_range[0]), age_scale.invert((scale_range[1] - scale_range[0])*.25 + scale_range[0]), age_scale.invert((scale_range[1] - scale_range[0])*.5 + scale_range[0]), age_scale.invert((scale_range[1] - scale_range[0])*.75 + scale_range[0]), age_scale.invert(scale_range[1])];
    axis_phylo.tickValues([])
    axis_g_phylo.call(axis);

    axis_reconst.tickValues([])
    axis_g_reconst.call(axis);
}

function update_reconst() {

    reconstruct_svg.selectAll("*").remove();
    
    // console.log(pairwise_data);
    reconst_root = Tree(all_reconstructions, {
        // id: function(d){return d.id},
        // parentId: function(d){
        //     if (d.ancestor_list == "[NONE]") {
        //         return null;
        //     }
        //     return JSON.parse(d.ancestor_list)[0];
        // },
        // tree: d3.flextree,
        width: 1600,
        height: 1000,
        padding: 50,
        fill: "black",
        axis_space: 40,
        strokeWidth: strokeWidth,
        svg_id: "#reconstruct_canvas",
        sort: function(a, b) {console.log(a.label_name, b.label_name, d3.descending(a.label_name, b.label_name)); return d3.descending(a.label_name, b.label_name);}                
    });
}

function update_age_scale(exponent) {
    console.log(age_scale.exponent(), age_scale(262072));
    age_scale.exponent(exponent);
    console.log(age_scale.exponent(), age_scale(262072));
    update_tree();

}

function get_curr_policy() {
    var resolution = $('#resolution_select').val();
    reconstructed_file = "reconstruction_"+resolution+".csv"

}

get_curr_policy();

$("#exponent_slider").on("input change", function() {
    var e = $('#exponent_slider').val();
    update_age_scale(e);
});

$(".policy_control").on("input change", function() {
    phylo_svg.selectAll("*").remove();   
    reconstruct_svg.selectAll("*").remove();  
    get_curr_policy();
    load_data();
});

function AssignSortLabels(curr) {

    var parents = [];
    for (node of curr) {
        if (node.children === undefined) {
            node.max_descendant = node.data.label_name;
        } else {
            node.max_descendant = d3.max(node.children, function(d){return d.max_descendant;});
        }
        if (node.parent != null) {
            parents.push(node.parent);
        }
    }

    if (parents.length > 0) {
        AssignSortLabels(parents);
    }
}

function handle_click(e, d) {
    console.log(e, d);
}

function handle_mouseover(e, data) {
    var desc = data.target.links();
    // console.log(e);
    
    domRect = document.getElementById("phylo_canvas").getBoundingClientRect();;

    var click_y = e.clientY - domRect.top;
    // console.log(click_y, e.pageY, e.clientY, domRect.top);

    var ends = new Set();

    d3.selectAll(".phylo_path")
      .data(desc, function(d){return d.target.data.unique_id;})
      .join(
        enter => enter.append("path"),
        update => update,
        exit => exit.style("stroke-opacity", function(d){
            if (d.target.max_descendant == data.target.max_descendant) {
                return 1;
            }
            for (a of d.target.ancestors()) {
                if (a.max_descendant == data.target.max_descendant) {
                    if (click_y > a.y) {
                        // data.target.unique_id == a.unique_id) {
                        if (d.target.children === undefined) {
                            ends.add(d.target);
                        }    
                        return .2;
                    }
                    return 1;
                }
            }
            if (d.target.children === undefined) {
                ends.add(d.target);
            }            
            return .2;
        })
      );
    // d3.selectAll("circle")
    //     .style("opacity", function(d){
    //         if (d.max_descendant == data.target.max_descendant) {
    //             return 1;
    //         }
    //         for (a of d.ancestors()) {
    //             if (a.max_descendant == data.target.max_descendant) {
    //                 if (click_y > a.y) {
    //                     // data.target.unique_id == a.unique_id) {
    //                     return .2;
    //                 }
    //                 return 1;
    //             }
    //         }
            
    //         return .2;
    //     });
    // console.log(ends);
    d3.selectAll("circle")
        .data(ends, function(d){return d.data.unique_id;})
        .style("opacity", .2);
}

function handle_mouseout(e, data) {
    d3.selectAll(".phylo_path")
      .style("stroke-opacity", 1);

    d3.selectAll("circle")
      .style("opacity", 1);
}

function CircleTree(data, { // data is either tabular (array of objects) or hierarchy (nested objects)
    path, // as an alternative to id and parentId, returns an array identifier, imputing internal nodes
    svg_id,
    id = Array.isArray(data) ? d => d.id : null, // if tabular data, given a d in data, returns a unique identifier (string)
    parentId = Array.isArray(data) ? d => d.parentId : null, // if tabular data, given a node d, returns its parent’s identifier
    children, // if hierarchical data, given a d in data, returns its children
    tree = d3.tree, // layout algorithm (typically d3.tree or d3.cluster)
    separation = tree === d3.tree ? (a, b) => (a.parent == b.parent ? 1 : 2) / a.depth : (a, b) => a.parent == b.parent ? 1 : 2,
    sort, // how to sort nodes prior to layout (e.g., (a, b) => d3.descending(a.height, b.height))
    label, // given a node d, returns the display name
    title, // given a node d, returns its hover text
    link, // given a node d, its link (if any)
    linkTarget = "_blank", // the target attribute for links (if any)
    width = 640, // outer width, in pixels
    height = 400, // outer height, in pixels
    margin = 60, // shorthand for margins
    marginTop = margin, // top margin, in pixels
    marginRight = margin, // right margin, in pixels
    marginBottom = margin, // bottom margin, in pixels
    marginLeft = margin, // left margin, in pixels
    radius = Math.min(width - marginLeft - marginRight, height - marginTop - marginBottom) / 2, // outer radius
    r = 3, // radius of nodes
    padding = 1, // horizontal padding for first and last column
    fill = "#999", // fill for nodes
    fillOpacity, // fill opacity for nodes
    stroke = "#555", // stroke for links
    strokeWidth = 1.5, // stroke width for links
    strokeOpacity = 0.4, // stroke opacity for links
    strokeLinejoin, // stroke line join for links
    strokeLinecap, // stroke line cap for links
    halo = "#fff", // color of label halo 
    haloWidth = 3, // padding around the labels
  } = {}) {
    
    // If id and parentId options are specified, or the path option, use d3.stratify
    // to convert tabular data to a hierarchy; otherwise we assume that the data is
    // specified as an object {children} with nested objects (a.k.a. the “flare.json”
    // format), and use d3.hierarchy.
    const root = path != null ? d3.stratify().path(path)(data)
        : id != null || parentId != null ? d3.stratify().id(id).parentId(parentId)(data)
        : d3.hierarchy(data, children);
  
    // Sort the nodes.
    if (sort != null) root.sort(sort);
  
    // Compute labels and titles.
    const descendants = root.descendants();
    const L = label == null ? null : descendants.map(d => label(d.data, d));
  
    // Compute the layout.
    tree().size([2 * Math.PI, radius]).separation(separation)(root);

    svg = d3.select(svg_id);
    svg = svg
        .attr("viewBox", [-marginLeft - radius, -marginTop - radius, width, height])
        .attr("width", width)
        .attr("height", height)
        .attr("style", "max-width: 100%; height: auto; height: intrinsic;")
        .attr("font-family", "sans-serif")
        .attr("font-size", 10);
  
    svg.append("g")
        .attr("fill", "none")
        .attr("stroke", stroke)
        .attr("stroke-opacity", strokeOpacity)
        .attr("stroke-linecap", strokeLinecap)
        .attr("stroke-linejoin", strokeLinejoin)
        .attr("stroke-width", strokeWidth)
      .selectAll("path")
      .data(root.links())
      .join("path")
        .attr("d", d3.linkRadial()
            .angle(d => d.x)
            .radius(d => d.y));
  
    const node = svg.append("g")
      .selectAll("a")
      .data(root.descendants())
      .join("a")
        .attr("xlink:href", link == null ? null : d => link(d.data, d))
        .attr("target", link == null ? null : linkTarget)
        .attr("transform", d => `rotate(${d.x * 180 / Math.PI - 90}) translate(${d.y},0)`);
  
    node.append("circle")
        .attr("fill", d => d.children ? stroke : fill)
        .attr("r", r);
  
    if (title != null) node.append("title")
        .text(d => title(d.data, d));
  
    if (L) node.append("text")
        .attr("transform", d => `rotate(${d.x >= Math.PI ? 180 : 0})`)
        .attr("dy", "0.32em")
        .attr("x", d => d.x < Math.PI === !d.children ? 6 : -6)
        .attr("text-anchor", d => d.x < Math.PI === !d.children ? "start" : "end")
        .attr("paint-order", "stroke")
        .attr("stroke", halo)
        .attr("stroke-width", haloWidth)
        .text((d, i) => L[i]);
  
    return svg.node();
  }


// Copyright 2021 Observable, Inc.
// Released under the ISC license.
// https://observablehq.com/@d3/tree
function Tree(data, { // data is either tabular (array of objects) or hierarchy (nested objects)
    path, // as an alternative to id and parentId, returns an array identifier, imputing internal nodes
    id = Array.isArray(data) ? d => d.id : null, // if tabular data, given a d in data, returns a unique identifier (string)
    parentId = Array.isArray(data) ? d => d.parentId : null, // if tabular data, given a node d, returns its parent’s identifier
    children, // if hierarchical data, given a d in data, returns its children
    tree = d3.tree, // layout algorithm (typically d3.tree or d3.cluster)
    sort = (a, b) => {console.log(a, b); return d3.descending(+a.data.label_name, +b.data.label_name);}, // how to sort nodes prior to layout (e.g., (a, b) => d3.descending(a.height, b.height))
    label,// = function(data, d){return data.label_name.includes("Inner") ? "" : data.label_name;}, // given a node d, returns the display label_name
    title = function(d){return d.label_name;}, // given a node d, returns its hover text
    link, // given a node d, its link (if any)
    linkTarget = "_blank", // the target attribute for links (if any)
    width = 640, // outer width, in pixels
    height, // outer height, in pixels
    r = 3, // radius of nodes
    padding = 1, // horizontal padding for first and last column
    fill = "#999", // fill for nodes
    fillOpacity, // fill opacity for nodes
    stroke = "#555", // stroke for links
    strokeWidth = 1.5, // stroke width for links
    strokeOpacity = 1, // stroke opacity for links
    strokeLinejoin, // stroke line join for links
    strokeLinecap, // stroke line cap for links
    halo = "#fff", // color of label halo
    haloWidth = 3, // padding around the labels
    axis_space = 20,
    svg_id = ""
  } = {}) {
    svg = d3.select(svg_id);
    svg.selectAll("*").remove();
    extant = {};
    var e = $('#exponent_slider').val();
    // If id and parentId options are specified, or the path option, use d3.stratify
    // to convert tabular data to a hierarchy; otherwise we assume that the data is
    // specified as an object {children} with nested objects (a.k.a. the “flare.json”
    // format), and use d3.hierarchy.
    // console.log("before");
    root = path != null ? d3.stratify().path(path)(data)
        : id != null || parentId != null ? d3.stratify().id(id).parentId(parentId)(data)
        : d3.hierarchy(data, children);
    console.log(root.data.origin_time);

    age_scale = d3.scalePow().exponent(e).domain([0,max_update-min_update]).range([padding, width - 2*padding]);
    // age_scale = d3.scalePow().domain([262030,max_update]).range([padding, width - 2*padding]);
    scale_range = age_scale.range();
    // new_ticks = [age_scale.invert(scale_range[0]), age_scale.invert((scale_range[1] - scale_range[0])*.25 + scale_range[0]), age_scale.invert((scale_range[1] - scale_range[0])*.5 + scale_range[0]), age_scale.invert((scale_range[1] - scale_range[0])*.75 + scale_range[0]), age_scale.invert(scale_range[1])];
    axis = d3.axisLeft(age_scale)
             .tickValues([]);

    // console.log(root.leaves());
    AssignSortLabels(root.leaves());
    // Sort the nodes.
    // root.sort(function(a, b){return d3.ascending(a.max_descendant,b.max_descendant);});
    root.sort(sort);

    // Compute labels and titles.
    const descendants = root.descendants();
    const L = label == null ? null : descendants.map(d => label(d.data, d));


    // Compute the layout.
    const dx = 10 + axis_space;
    console.log(root.height);
    const dy = width / (root.height + padding);
    // tree().nodeSize([dx, dy])(root);
    tree().size([width - axis_space, height])(root);
    // tree({
    //     nodeSize: node => [1, node.data.destruction_time - node.data.origin_time],
    //     spacing: (nodeA, nodeB) => nodeA.path(nodeB).length,
    // })(root);

    // Center the tree.
    let x0 = Infinity;
    let x1 = -x0;
    root.each(d => {
      if (d.x > x1) x1 = d.x;
      if (d.x < x0) x0 = d.x;
      d.x += axis_space;
        // console.log(d.y, d.data.origin_time, age_scale(d.data.origin_time));
      d.y = age_scale(d.data.origin_time - min_update);
    });

    // Compute the default height.
    if (height === undefined) height = x1 - x0 + dx * 2 + axis_space;

    svg.attr("viewBox", [0, 0, width, height])
        .attr("width", width)
        .attr("height", height)
        // .attr("style", "max-width: 100%; height: auto; height: intrinsic;")
        .attr("font-family", "sans-serif")
        .attr("font-size", 10);

    svg.append("g")
        .attr("fill", "none")
        // .attr("stroke", stroke)
        // .attr("stroke-opacity", strokeOpacity)
        .attr("stroke-linecap", strokeLinecap)
        .attr("stroke-linejoin", strokeLinejoin)
        .attr("stroke-width", strokeWidth)
      .selectAll("path")
        .data(root.links())
        .join("path")
          .attr("d", d3.link(d3.curveStepAfter)//3.linkVertical()
              .x(d => d.x)
              .y(d => d.y))
          .classed("phylo_path", true)
          .attr("stroke", function(d){return color_scale(+d.target.max_descendant);})
          .on("mouseover", handle_mouseover)
          .on("mouseout", handle_mouseout);

    const node = svg.append("g")
      .selectAll("a")
      .data(root.descendants())
      .join("a")
        .attr("xlink:href", link == null ? null : d => link(d.data, d))
        .attr("target", link == null ? null : linkTarget)
        .attr("transform", d => `translate(${d.x},${d.y})`);

    node.append("circle")
        .attr("fill", function(d){return color_scale(+d.max_descendant);})
        .attr("r", function(d){return d.data.destruction_time == max_update && !d.children ? 5 : 0;})
        .on("click", handle_click);


    if (title != null) node.append("title")
        .text(d => title(d.data, d));

    if (L) node.append("text")
        .attr("dy", "0.32em")
        .attr("x", d => d.children ? -6 : 6)
        .attr("text-anchor", d => d.children ? "end" : "start")
        .text((d, i) => d.children ? "" : L[i])
        .call(text => text.clone(true))
        .attr("fill", "none")
        .attr("stroke", halo)
        .attr("stroke-width", haloWidth);
    // console.log(extant);

    axis_g = svg.append("g")
       .attr("transform", "translate("+ axis_space +","+ 0 + ")")
       .call(axis);

    svg.append("text")
        .attr("transform", "translate(" + height/2 + ","+ 0 + ")")
        .attr("dy", "-2em")
        .style("text-anchor", "middle")
        .style("font-size", 18)
        .text("Time");

    if (svg_id == "#reconstruct_canvas") {
        axis_reconst = axis;
        axis_g_reconst = axis_g;
    } else {
        axis_phylo = axis;
        axis_g_phylo = axis_g;        
    }

    return root;
  }

function load_data() {
    phylo_svg.selectAll("*").remove();   
    reconstruct_svg.selectAll("*").remove();   

    // set_files();

    d3.csv(reconstructed_file, function(d) {
        // console.log(d);
        return {
            id: d.id,
            unique_id: "recon_" + d.id,
            label_name: d.taxon_label,
            parentId: d.ancestor_list == "[None]" ? null : JSON.parse(d.ancestor_list)[0],
            origin_time: +d.origin_time,
            destruction_time: isNaN(+d.destruction_time) ? max_update : +d.destruction_time,
            treatment: d.Treatment
        };
    }).then(

        function(data) {
            all_reconstructions = data;
            // var filtered = d3.filter(all_reconstructions, function(d) {return d.treatment == estimate;});

            // console.log(pairwise_data);
            reconst_root = Tree(all_reconstructions, {
                // id: function(d){return d.id},
                // parentId: function(d){
                //     if (d.ancestor_list == "[NONE]") {
                //         return null;
                //     }
                //     return JSON.parse(d.ancestor_list)[0];
                // },
                // tree: d3.flextree,
                width: 700,
                height: 600,
                padding: 50,
                fill: "black",
                axis_space: 40,
                strokeWidth: strokeWidth,
                svg_id: "#reconstruct_canvas",
                // sort: function(a, b) {return d3.descending(a.data.label_name, b.data.label_name);}                
            });

        }
    ).then( function(orig_data) {
        // d3.csv("example.csv", function(data){
        // 
        // d3.csv("https://files.osf.io/v1/resources/4sm72/providers/osfstorage/6218eef419ba8b044ae128ba",
        d3.csv(phylo_file,
        function(d) {
            return {
                id: d.id,
                unique_id: "phylo_" + d.loc,
                label_name: d.taxon_label,
                parentId: d.ancestor_list == "[None]" ? null : JSON.parse(d.ancestor_list)[0],
                origin_time: +d.origin_time,
                destruction_time: isNaN(+d.destruction_time) ? max_update : +d.destruction_time
            };
        }
        ).then(
            function(data) {
                // console.log(pairwise_data);
                phylo_root = Tree(data, {
                    // id: function(d){return d.id},
                    // parentId: function(d){
                    //     if (d.ancestor_list == "[NONE]") {
                    //         return null;
                    //     }
                    //     return JSON.parse(d.ancestor_list)[0];
                    // },
                    // tree: d3.flextree,
                    width: 700,
                    height: 600,
                    padding: 50,
                    fill: "black",
                    axis_space: 40,
                    strokeWidth: strokeWidth,
                    svg_id: "#phylo_canvas",
                    // sort: (a, b) => d3.descending(a.label_name, b.label_name)
                });

            }
        );
    });
}


load_data();