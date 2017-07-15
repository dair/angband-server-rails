function timeString(t) {
    if (t == null) {
        return "null";
    }
    
    var fullText = t.toLocaleString('ru', {
                                      year: 'numeric',
                                      month: 'long',
                                      day: 'numeric',
                                      hour: 'numeric',
                                      minute: 'numeric'
                                  });

    var now = new Date();
    var diff = now - t;

    var text = fullText;
    
    if (diff < 60*1000) {
        text = "только&nbsp;что";
    }
    else if (diff < 15*60*1000) {
        text = Math.round(diff / 60000) + " минут назад";
    }

    if (text != fullText) {
        return "<div class=\"tooltip\">" + text + "<span class=\"tooltiptext\">" + fullText + "</span></div>";
    }
    else {
        return text;
    }
}

//window.alert(window.onload);
window.onload = function() {
    timestamps = document.getElementsByClassName("timestamp");

    for (var i = 0; i < timestamps.length; ++i) {
        var d = timestamps[i];
        value = d.innerHTML;
        var date = new Date(value * 1000);

        d.innerHTML = timeString(date);
    }
}

