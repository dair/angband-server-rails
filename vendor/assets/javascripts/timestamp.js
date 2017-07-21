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
        text = "сейчас";
    }
    else if (diff < 60*60*1000) { // раньше чем час назад
        text = Math.round(diff / 60000) + " мин.";
    }
    else if (diff < 24*60*60*1000) { // раньше чем сутки назад
        text = Math.round(diff / (60*60*1000)) + " ч.";
    }
    else if (diff < 30*24*60*60*1000) {
        text = Math.round(diff / (24*60*60*1000)) + " д.";
    }

    if (text != fullText) {
        // no bootstrap
        //return "<div class=\"tooltip\">" + text + "<span class=\"tooltiptext\">" + fullText + "</span></div>";

        // bootstrap
        return "<span data-toggle=\"tooltip\" title=\"" + fullText + "\">" + text + "</span>";
    }
    else {
        return text;
    }
}

window.onload = function() {
    timestamps = document.getElementsByClassName("timestamp");

    for (var i = 0; i < timestamps.length; ++i) {
        var d = timestamps[i];
        
        value = d.innerHTML;
        var date = new Date(value * 1000);

        d.innerHTML = timeString(date);
    }
}

