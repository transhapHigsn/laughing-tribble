// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"
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
let room = socket.channel("room:lobby")
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
    room.push("message:new", messageInput.value)
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
  // let prevElement = document.querySelector('#message')
  // prevElement.removeAttribute('id')
  let messageElement = document.createElement("li")
  messageElement.setAttribute('class', 'clusterize-no-data')
  messageElement.setAttribute('id', 'message')
  messageElement.innerHTML = `
    <b>${message.user}</b>
    <i>${formatTimestamp(message.timestamp)}</i>
    <p>${message.body}</p>
    `
  contentArea.appendChild(messageElement)
  contentArea.scrollTop = contentArea.scrollHeight;
  // contentArea.focus()
}


room.on("message:new", message => renderMessage(message))
room.on("reload", (message) => {
  contentArea.innerHTML = ``
  messageList.innerHTML = ``
  room.push("screen:reload", "Reload messages")
})

window.onload = () => {
  console.log("Window reloading...")
  messageList.innerHTML = ``
  contentArea.innerHTML = ``

}

room.join()
