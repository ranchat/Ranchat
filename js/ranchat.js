var Ranchat = function()
{
  var callbacks = {};
  var uri       = document.URL.replace("http", "ws") + "/ws";

  /* Create websocket */
  if("undefined" == typeof WebSocket)
    {
      if("undefined" == typeof MozWebSocket)
        {
          alert("Sorry, unsupported browser");
        }
      else var conn = new MozWebSocket(uri);
    }
  else var conn = new WebSocket(uri);

  /* Set message handler */
  conn.onmessage = function(evt)
  {
    var data       = jQuery.parseJSON(evt.data);
    var event_name = data[0];
    var message    = data[1];

    dispatch(event_name, message);
  };

  /* Set open handler */
  conn.onopen = function(evt)
  {
    dispatch("system_connect", null);
  };

  /* Set close handler */
  conn.onclose = function(evt)
  {
    dispatch("system_disconnect", null);
  };

  /** bind
  * Bind event handler
  * @param[in]  event_name  Name of the event
  * @param[in]  callback    Event callback
  **/

  this.bind = function(event_name, callback)
  {
    callbacks[event_name] = callbacks[event_name] || [];
    callbacks[event_name].push(callback);
  };

  /** send
   * Send event to socket
   * @param[in]  event_name  Name of the event
   * @param[in]  data        Event data
   * @return Chainable object
   **/

  /* Add trigger */
  this.send = function(event_name, data)
  {
    var payload = JSON.stringify([event_name, data]);

    conn.send(payload);

    return this;
  };

  /** dispatch
   * Dispatch events
   * @param[in]  event_name  Name of the event
   * @param[in]  message     Event message
   **/

  var dispatch = function(event_name, message){
    var chain = callbacks[event_name];

    if("undefined" == typeof chain) return; ///< No callbacks for this event

    for(var i = 0; i < chain.length; i++)
      chain[i](message)
  }
}

/* Create dispatcher */
$(document).ready(function() {
  var rc = new Ranchat();

  /* Handle user_connect */
  rc.bind("user_connect", function(user_data) {
    $("#userlist").append("<li>" + user_data.name + "</li>");

    $("#chatlog").append("<li>&lt;" + user_data.name +
      "&gt; " + user_data.message + "</li>");
  });

  /* Handle user disconnect */
  rc.bind("user_disconnect", function(user_data) {
    alert(user_data);
  });

  /* Handle user message */
  rc.bind("user_message", function(user_data) {
    $("#chatlog").append("<li>&lt;" + user_data.from +
      "&gt; " + user_data.text + "</li>");
  });

  /* Handle system connect */
  rc.bind("system_connect", function(user_data) {
    var name = $("#name").val();

    $("#userlist").append("<li>" + name + "</li>");
  });

  /* Handle system disconnect */
  rc.bind("system_disconnect", function(user_data) {
    $("#chatlog").append("<li class=\"system\"> Disconnected</li>");
  });

  /* Handle system message */
  rc.bind("system_message", function(user_data) {
    $("#chatlog").append("<li class=\"system\">" +
      user_data.text + "</li>");
  });

  /* Handle form submit */
  $("form#chat").submit(function() {
    var name = $(this).find("#name").val();
    var text = $(this).find("#text").val();

    rc.send("user_message", { from: name, text: text });

    return false;
  });
});
