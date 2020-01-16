function toggleNav() {
    let x = document.body.querySelector('#login_form');
    x.classList.toggle('unhidden');
}


function sendTicket() {
    let inputs = document.querySelectorAll('span > input');
    if (inputs.length > 1) {
        var tickets = [];
        for (input of inputs) {
            tickets.push({
                id: input.name.replace('ticket', ''),
                amount: input.attributes[4].value,
                booking_id: window.location.href.split('/')[window.location.href.split('/').length - 1]
            });
        }
    } else {
        tickets = [inputs.name, inputs.val];
    }
    return JSON.stringify(tickets);
}

// Sends ticket order to server
if ((window.location.href).includes('service')) {
    document.getElementById('submitticket').addEventListener('click', function () {
        console.log('Button pressed')
        // const data = await fetch("http://localhost:9292/ticket", {method: "post", body: JSON.stringify(sendTicket())})          
        // TODO: Research fetch for JavaScript

        const request = new XMLHttpRequest();
        const url = (window.location.protocol + "//" + window.location.hostname + ':9292');

        request.onload = function () {
            console.log(`${request.responseText} and status ${request.status}`);
        }

        request.onreadystatechange = function () {
            if (request.readyState === 4) {
                window.location.replace(url + request.response)
            }
        }
        request.open('POST', url + '/ticket', true);
        request.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
        request.setRequestHeader('cookie', document.cookie);
        request.send(JSON.stringify({
            value: sendTicket()
        }));
    });
}