$(window).on("load", function () {
  if (window.invokeNative) {
    var phoneWrapper = $("#phone-bank");
    var app = phoneWrapper.find(".app");

    app.insertBefore(phoneWrapper);
    phoneWrapper.remove();
    return;
  }

  $("#phone-bank").css("display", "block");
  $("body").css("visibility", "visible");

  var center = function () {
    $("#phone-bank").css(
      "transform",
      "scale(" + window.innerWidth / 1920 + ")"
    );
  };
  center();
  $(window).on("resize", center);
});
