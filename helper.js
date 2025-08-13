function send(data) {
	try {
		ws.send(data);
	} catch (e) {
        void(0);
	}
}

function log(msg) {
	send(msg === undefined ? 'undefined' : msg.toString());
	var el = null;
	try { el = document.getElementById("log"); } catch(_) {}
	var text = (msg === undefined ? 'undefined' : (""+msg));
	if (el) { el.innerHTML += text + "</br>"; }
	try { if (window.activityLog) window.activityLog.push(text); } catch(_) {}
}