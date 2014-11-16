# Description
#   Script integrates hubot with Who's on Staging? — a simple tool to track who is using staging servers
#
# Commands:
#   hubot I know the secret <secret code> - connects you to Who's on Staging?
#   hubot reserve me <server name> - reserves staging server
#   hubot reserve me <server name> (<comments>) - reserves staging server with comments
#   hubot reserve me <server name> for <duration> - reserves staging server for some time
#   hubot reserve me <server name> for <duration> (<comments>) - reserves staging server for some time with comments
#   hubot reserve me <server name> for <duration> from <start at> - reserves staging server for some time from specific date/time
#   hubot reserve me <server name> for <duration> from <start at> (<comments>) - reserves staging server for some time from specific date/time with comments
#   hubot reserve me <server name> for <duration> till <finish at> - reserves staging server for some time till specific date/time
#   hubot reserve me <server name> for <duration> till <finish at> (<comments>) - reserves staging server for some time till specific date/time with comments
#   hubot reserve me <server name> from <start at> to <finish at> - reserves staging server from specific date/time and till specific date/time
#   hubot reserve me <server name> from <start at> to <finish at> (<comments>) - reserves staging server from specific date/time and till specific date/time with comments
#   hubot reserve me <server name> from <start at> - reserves staging server from specific date/time
#   hubot reserve me <server name> from <start at> (<comments>) - reserves staging server from specific date/time with comments
#   hubot reserve me <server name> to <finish at> - reserves staging server till specific date/time
#   hubot reserve me <server name> to <finish at> (<comments>) - reserves staging server till specific date/time with comments
#   hubot release <server name> - releases staging server
#   hubot cancel my reservation for <server name> - cancels reservation for staging server
#   hubot who is on <server name> - who is currently on staging server
#
# Notes:
#   For more details, please, visit: https://whosonstaging.com
#
# Author:
#   maximgladkov

module.exports = (robot) ->
  HOST = "https://whosonstaging.com"

  robot.router.put '/hubot/whosonstaging/users/:user_id/api_key', (req, res) ->
    userId = req.params.user_id
    apiKey = req.body.api_key

    robot.brain.set("user#{ userId }_apiKey", apiKey)

    res.send 'OK'

  request = (msg, url, data, callback) ->
    userId = msg.message.user.id
    apiKey = robot.brain.get("user#{ userId }_apiKey")

    if apiKey
      data.api_key = apiKey
      robot.http(url)
        .query(data)
        .post() (err, res, body) ->
          if err || res.statusCode != 200
            msg.reply err || body
          else
            callback(body)
    else
      msg.reply "Are you even connected to Who's on Staging?"

  robot.respond /I know the secret (.+)/i, (msg) ->
    data = {
      secret:  msg.match[1],
      user_id: msg.message.user.id,
      address: process.env.BIND_ADDRESS,
      port:    process.env.PORT || 8080
    }

    robot.http("#{ HOST }/api/v0/hubot/users/connect.json")
      .query(data)
      .post() (err, res, body) ->
        if err || res.statusCode != 200
          msg.reply err || body
        else
          msg.reply "You are now connected to Who's on Staging?"

  robot.respond /reserve me (.+)/i, (msg) ->
    request msg, "#{ HOST }/api/v0/servers/reserve.json", { query: msg.match[1] }, (body) ->
      msg.reply body

  robot.respond /release (.+)/i, (msg) ->
    request msg, "#{ HOST }/api/v0/servers/release.json", { server_name: msg.match[1] }, (body) ->
      msg.reply body

  robot.respond /cancel my reservation for (.+)/i, (msg) ->
    request msg, "#{ HOST }/api/v0/servers/cancel_reservation.json", { server_name: msg.match[1] }, (body) ->
      msg.reply body

  robot.respond /who is on (.+)/i, (msg) ->
    request msg, "#{ HOST }/api/v0/servers/who.json", { server_name: msg.match[1] }, (body) ->
      msg.reply body
