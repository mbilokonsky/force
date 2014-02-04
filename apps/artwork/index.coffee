#
# Artwork page
#

express   = require 'express'
routes    = require './routes'

app = module.exports = express()
app.set 'views', __dirname + '/templates'
app.set 'view engine', 'jade'

app.get '/artwork/:id', routes.index

# Handled client-side
app.get '/artwork/:id/zoom', routes.index
app.get '/artwork/:id/more-info', routes.index
app.get '/artwork/:id/view-in-room', routes.index
