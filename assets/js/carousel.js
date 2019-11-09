(function() {
  var carousels = document.querySelectorAll(".carousel");
  Array.prototype.forEach.call(carousels, function (carousel) {
    var items = carousel.querySelectorAll(".items > figure");
    if (1 < items.length) {
      // more than one carousel item
      var obj = {
        items: items,
        curr: 0
      };
      (function(obj) {
        var prev = carousel.querySelector("a.prev");
        prev.addEventListener("click", function (e) {
          var curr = obj.curr;
          if (0 === curr) {
            obj.curr = obj.items.length - 1;
          } else {
            obj.curr--;
          }
          obj.items[curr].className = "";
          obj.items[obj.curr].className = "curr";
        });
        var next = carousel.querySelector("a.next");
        next.addEventListener("click", function (e) {
          var curr = obj.curr;
          if ((obj.items.length - 1) === curr) {
            obj.curr = 0;
          } else {
            obj.curr++;
          }
          obj.items[curr].className = "";
          obj.items[obj.curr].className = "curr";
        });
      })(obj);
    } else {
      // only one carousel item
      var controls = carousel.querySelectorAll(".controls");
      Array.prototype.forEach.call(controls, function (control) {
        control.style.display = "none";
      });
    }
  });
})();
