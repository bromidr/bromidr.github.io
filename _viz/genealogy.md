---
# The three dashed lines above and below the comments are needed so that jekyll
# shall process this file and output the resultant page when building this site
---

<div id="cy" style="width: 100%; height: 100%;"></div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.3.3/cytoscape.min.js"
        integrity="sha256-K6FGD6tqGrGTOGMAJLDqbbtXwCgz4Evfy3bVfGeVzy8="
        crossorigin="anonymous"></script>

<script>
  var elements = [];

  {%- for p in site.data.genealogy.people -%}
      elements.push({
          data: {
              id: "{{- "p_" | append: p.id | escape -}}",
              type: "person",
              name: "{{- p.name | escape -}}",
              gender: "{{- p.gender | escape -}}"
          }
      });
  {%- endfor -%}

  {%- for r in site.data.genealogy.rels -%}
      {%- if r.parents.size > 1 or r.children.size > 1 -%}
          {%- assign id = "f_" | append: r.id | escape -%}

          elements.push({
              data: {
                  id: "{{- id -}}",
                  type: "family",
                  name: ""
              }
          });

          {%- for p in r.parents -%}
              elements.push({
                  data: {
                      source: "{{- "p_" | append: p | escape -}}",
                      target: "{{- id -}}",
                      type: "parent"
                  },
                  selectable: false
              });
          {%- endfor -%}
      {%- else -%}
          {% assign id = "p_" | append: r.parents[0] | escape %}
      {%- endif -%}

      {%- for c in r.children -%}
          elements.push({
              data: {
                  source: "{{- id -}}",
                  target: "{{- "p_" | append: c | escape -}}",
                  type: "child"
              },
              selectable: false
          });
      {%- endfor -%}
  {%- endfor -%}

  var cyAll = cytoscape({
    headless: true,
    elements: elements
  });

  var cySome = cytoscape({
    container: document.getElementById("cy"),
    style: [{
      selector: "node",
      style: {
        "background-color": function (ele) {
          var gender = ele.data("gender");
          if ("m" === gender) {
            return ele.selected() ? "#0070BB" : "#89CFF0"; // spanish blue : baby blue
          }
          else if ("f" === gender) {
            return ele.selected() ? "#FF69B4" : "#FFC0CB"; // hotpink : pink
          }
          else {
            var type = ele.data("type");
            if ("person" === type) {
              return ele.selected() ? "#2E8B57" : "#71EEB8"; // sea green : seafoam green
            }
            else {
              return ele.selected() ? "#696969" : "#C0C0C0"; // dim gray : silver
            }
          }
        },
        "label": "data(name)",
        "text-valign": "bottom",
        "text-margin-y": 5
      }
    }, {
      selector: "edge",
      style: {
        "line-color": "#C0C0C0", // silver
        "mid-target-arrow-shape": "triangle",
        "mid-target-arrow-fill": "hollow",
        "arrow-scale": 1.2
      }
    }, {
      selector: "edge[type='parent']",
      style: {
        "line-style": "dashed"
      }
    }],
    autoungrabify: true,
    userPanningEnabled: false,
    userZoomingEnabled: false
  });

  cySome.on("tap", "node", function (event) {
    if (event.target.selectable()) {
      updateView(event.target.id());
    }
  });

  function updateView (nodeId) {
    if ("#" !== nodeId.charAt(0)) {
      nodeId = "#" + nodeId;
    }
    cySome.elements().remove();
    cySome.add(cyAll.nodes(nodeId).closedNeighborhood().closedNeighborhood());
    cySome.nodes(nodeId).selectify().select().unselectify();
    cySome.layout({
      name: "cose",
      nodeRepulsion: 8192,
      idealEdgeLength: 64,
      edgeElasticity: 64
    }).run();
  }

  updateView(window.location.hash || "#p_god");
</script>
