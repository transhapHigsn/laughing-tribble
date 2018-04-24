
import "phoenix_html"

import {Socket, Presence} from  "phoenix"

let user = document.getElementById("User").innerText
let socket = new Socket("/socket", {params: {
    user: user
}})
socket.connect()

let presences = {}
let formatTimestamp = (timestamp) => {
  let current_time = Date.now()
  let new_time = timestamp  
  if (typeof(timestamp) === 'string'){
      new_time = Date.parse(timestamp)
  }

  let date = new Date(new_time)
  if(current_time - new_time >= 8640000){
    return date.toDateString()
  }

  return date.toLocaleTimeString()
}

let listBy = (user, {metas: metas}) => {
    return {
        user: user,
        onlineAt: formatTimestamp(metas[0].online_at)
    }
}

let userList = document.getElementById("UserList")
let render = (presences) => {
  userList.innerHTML = Presence.list(presences, listBy)
    .map(presence => `
      <li>
        ${presence.user}
        <br>
        <small>online since ${presence.onlineAt}</small>
      </li>
    `)
    .join("")
}

// Channels
let baseURI = window.location.href
let params = baseURI.split('?')
var roomId = 'lobby';
if(params.length > 1){
  let splitParam = params[0].split('/')
  let splitParamLength = splitParam.length;
  roomId = splitParam[splitParamLength-1];
}

let roomName = 'room:' + roomId
let room = socket.channel(roomName)
room.on("presence_state", state => {
  presences = Presence.syncState(presences, state)
  render(presences)
})

room.on("presence_diff", diff => {
  presences = Presence.syncDiff(presences, diff)
  render(presences)
})

let messageInput = document.getElementById("NewMessage")
messageInput.addEventListener("keypress", (e) => {
  if (e.keyCode == 13 && messageInput.value != "") {
    room.push("message:new", {message: messageInput.value, room: roomId})
    messageInput.value = ""
  }
})

let messageList = document.getElementById("MessageList")
let renderMessage = (message) => {
  let messageElement = document.createElement("li")
  messageElement.innerHTML = `
    <b>${message.user}</b>
    <i>${formatTimestamp(message.timestamp)}</i>
    <p>${message.body}</p>
  `
  messageList.appendChild(messageElement)
  messageList.scrollTop = messageList.scrollHeight;
}

let contentArea = document.getElementById("contentArea")
let renderContent = (message) => {
  let messageElement = document.createElement("li")
  messageElement.setAttribute('class', 'clusterize-no-data')
  messageElement.setAttribute('id', 'message')
  messageElement.innerHTML = `
    <img src="https://png.icons8.com/color/50/000000/circled-user-male-skin-type-4.png">
    <div>
    <b>${message.user}</b>
    <i>${formatTimestamp(message.timestamp)}</i>
    <p>${message.body}</p>
    </div>
    `

  if (contentArea.hasChildNodes()){
    contentArea.insertBefore(messageElement, contentArea.childNodes[0]);
  } else {
  contentArea.appendChild(messageElement)
  }
  contentArea.scrollTop = contentArea.scrollHeight;
}

room.on("message:new", message => {
  console.log(message)
  console.log(message.hasOwnProperty('body'))
  let body = message.body
  if (typeof(body) === 'object'){
    let msgObj = {
      'user': message.user,
      'timestamp': message.timestamp,
      'body': body.message
    }
    renderContent(msgObj)
  } else {
    renderContent(message)
  }
})
room.on("reload", (message) => {
  contentArea.innerHTML = ``
  room.push("screen:reload", "Reload messages")
})

room.join()
