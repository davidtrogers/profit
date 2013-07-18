(function($) {
  var charts = {};
  $("#key_links a").each(function() {
    var key = $(this).attr('id');
    var ctx = document.getElementById("chart_" + key).getContext("2d");
    var times = $(window.data[key]).map(function() { return this['recorded_time'] });
    var labels = $(window.data[key]).map(function() { return this['start_time'] });
    var data = {
      labels : labels,
      datasets : [
        {
          fillColor : "rgba(151,187,205,0.5)",
          strokeColor : "rgba(151,187,205,1)",
          pointColor : "rgba(151,187,205,1)",
          pointStrokeColor : "#fff",
          data : times
        }
      ]
    }
    charts[key] = new Chart(ctx).Line(data);
  });

  $('a[data-toggle="tab"]').on('shown', function (e) {
    var targetAnchor = $(e.target).attr('id');
    var baseUrl = document.location.href.split("#")[0];
    document.location.href = baseUrl + "#" + targetAnchor;
  });

  $(document).ready(function() {
    var targetAnchor = document.location.href.split("#")[1];
    $("#" + targetAnchor).tab("show");
  });

})(jQuery);
